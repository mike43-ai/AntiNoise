import Foundation

// Tracks consecutive days where the user completed ≥1 review session.
// Backed by UserDefaults (Set<String> of "yyyy-MM-dd" local-time keys) so
// we don't add a SwiftData entity for a small UI counter.
//
// Anonymous (no UID) accumulates under "_anon" so dev/testing still works.
struct StreakEngine {
    let uid: String?

    func markReviewedToday(now: Date = Date()) {
        var days = reviewedDays()
        let key = Self.dayKey(now)
        guard !days.contains(key) else { return }
        days.insert(key)
        UserDefaults.standard.set(Array(days), forKey: storageKey)
    }

    func currentStreak(now: Date = Date()) -> Int {
        let days = reviewedDays()
        guard !days.isEmpty else { return 0 }
        var count = 0
        var cursor = Calendar.current.startOfDay(for: now)
        while days.contains(Self.dayKey(cursor)) {
            count += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    func didReviewToday(now: Date = Date()) -> Bool {
        reviewedDays().contains(Self.dayKey(now))
    }

    // MARK: - Storage

    private var storageKey: String {
        let identity = (uid?.isEmpty == false ? uid! : "_anon")
        return "streak.days.\(identity)"
    }

    private func reviewedDays() -> Set<String> {
        let array = UserDefaults.standard.array(forKey: storageKey) as? [String] ?? []
        return Set(array)
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
