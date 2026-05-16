import Foundation
import SwiftData

@MainActor
struct ClassificationRepository {
    let context: ModelContext

    func setUserClassification(captureID: UUID, scope: ClassificationScope?) throws {
        guard let capture = fetchCapture(id: captureID) else { return }
        capture.userClassificationRaw = scope?.rawValue
        try context.save()
    }

    func markDone(captureID: UUID, on date: Date = Date()) throws {
        guard let capture = fetchCapture(id: captureID) else { return }
        capture.completedAt = date
        try context.save()
    }

    func resetDone(captureID: UUID) throws {
        guard let capture = fetchCapture(id: captureID) else { return }
        capture.completedAt = nil
        try context.save()
    }

    func markSkipped(captureID: UUID) throws {
        guard let capture = fetchCapture(id: captureID) else { return }
        capture.skipCount += 1
        try context.save()
    }

    func archive(captureID: UUID) throws {
        guard let capture = fetchCapture(id: captureID) else { return }
        capture.archivedAt = Date()
        try context.save()
    }

    private func fetchCapture(id: UUID) -> Capture? {
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == id })
        return (try? context.fetch(descriptor))?.first
    }
}
