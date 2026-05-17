import Foundation
import Observation
import SwiftData
import UIKit
import UserNotifications

@Observable
@MainActor
final class FocusSessionEngine {
    enum State: Equatable {
        case idle
        case running
        case paused
        case finished(completed: Bool)
    }

    private(set) var state: State = .idle
    /// Remaining seconds — recomputed from wall clock so it survives
    /// background / lock-screen periods accurately.
    private(set) var remainingSeconds: Int = 0
    private(set) var currentSessionID: UUID?
    /// Actual elapsed seconds at the moment we transitioned to `.finished`.
    /// Display this in the result UI (not `plannedDurationSeconds`).
    private(set) var lastElapsedSeconds: Int = 0
    private(set) var lastTargetLabel: String?

    private let modelContainer: ModelContainer
    private var endTime: Date?
    private var pausedRemaining: Int?
    private var ticker: Task<Void, Never>?
    private var sessionStart: Date?
    private var sessionPlanned: Int = 0
    private var sessionTargetKind: FocusTargetKind = .none
    private var sessionTargetID: UUID?
    private var sessionTargetLabel: String?

    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifier = "com.antinoise.focus.completion"

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func start(durationSeconds: Int, targetKind: FocusTargetKind = .none, targetID: UUID? = nil, targetLabel: String? = nil) {
        let now = Date()
        sessionStart = now
        sessionPlanned = durationSeconds
        sessionTargetKind = targetKind
        sessionTargetID = targetID
        sessionTargetLabel = targetLabel
        lastTargetLabel = targetLabel
        currentSessionID = UUID()

        endTime = now.addingTimeInterval(TimeInterval(durationSeconds))
        pausedRemaining = nil
        state = .running
        remainingSeconds = durationSeconds

        UIApplication.shared.isIdleTimerDisabled = true
        scheduleCompletionNotification(at: endTime!)
        startTicker()
    }

    func pause() {
        guard state == .running, let endTime else { return }
        pausedRemaining = max(0, Int(endTime.timeIntervalSinceNow.rounded()))
        remainingSeconds = pausedRemaining ?? 0
        state = .paused
        UIApplication.shared.isIdleTimerDisabled = false
        cancelCompletionNotification()
        stopTicker()
    }

    func resume() {
        guard state == .paused, let pausedRemaining else { return }
        endTime = Date().addingTimeInterval(TimeInterval(pausedRemaining))
        self.pausedRemaining = nil
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true
        scheduleCompletionNotification(at: endTime!)
        startTicker()
    }

    func abort() {
        finish(completed: false)
    }

    /// Called by the ticker when remaining hits 0, or manually if needed.
    func complete() {
        finish(completed: true)
    }

    /// Useful when the app returns from background — recompute remaining
    /// from wall clock, finish if elapsed, otherwise restart the ticker
    /// (iOS suspends it during background).
    func refresh() {
        guard state == .running, let endTime else { return }
        let remaining = max(0, Int(endTime.timeIntervalSinceNow.rounded()))
        remainingSeconds = remaining
        if remaining <= 0 {
            complete()
        } else if ticker == nil {
            startTicker()
        }
    }

    /// Manual hook for `FocusActiveView.onAppear` to re-enable
    /// `isIdleTimerDisabled` if the user navigated away and back.
    func reassertScreenOnIfNeeded() {
        if state == .running {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    /// Mirror for `.onDisappear` — safe to call even if state isn't running.
    /// Always clears the global flag so battery isn't drained when the view
    /// is gone for any reason (push, modal cover, etc.).
    func releaseScreenOn() {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func requestNotificationPermissionIfNeeded() async {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound])
    }

    // MARK: - Internals

    private func startTicker() {
        stopTicker()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run { self?.tick() }
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func tick() {
        guard state == .running, let endTime else { return }
        let remaining = max(0, Int(endTime.timeIntervalSinceNow.rounded()))
        remainingSeconds = remaining
        if remaining <= 0 {
            complete()
        }
    }

    private func finish(completed: Bool) {
        stopTicker()
        UIApplication.shared.isIdleTimerDisabled = false
        cancelCompletionNotification()

        let endedAt = Date()
        if let start = sessionStart {
            lastElapsedSeconds = max(0, Int(endedAt.timeIntervalSince(start).rounded()))
            persistSession(start: start, ended: endedAt, completed: completed)
        }
        lastTargetLabel = sessionTargetLabel

        state = .finished(completed: completed)
        endTime = nil
        pausedRemaining = nil
        remainingSeconds = 0
        sessionStart = nil
    }

    private func persistSession(start: Date, ended: Date, completed: Bool) {
        let context = ModelContext(modelContainer)
        let session = FocusSession(
            id: currentSessionID ?? UUID(),
            startedAt: start,
            plannedDurationSeconds: sessionPlanned,
            targetKind: sessionTargetKind,
            targetID: sessionTargetID,
            targetLabel: sessionTargetLabel
        )
        session.endedAt = ended
        let elapsed = ended.timeIntervalSince(start)
        let planned = TimeInterval(sessionPlanned)
        session.completed = completed && (planned == 0 || elapsed >= planned * 0.9)
        context.insert(session)
        try? context.save()
        if session.completed {
            Telemetry.track(.focusSessionCompleted(durationMinutes: Int(elapsed / 60)))
        }
    }

    private func scheduleCompletionNotification(at fireDate: Date) {
        let interval = fireDate.timeIntervalSinceNow
        guard interval > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Focus session complete"
        content.body = "Time's up. Take a breath."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        Task { try? await notificationCenter.add(request) }
    }

    private func cancelCompletionNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}

extension FocusSessionEngine {
    static func formatRemaining(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
