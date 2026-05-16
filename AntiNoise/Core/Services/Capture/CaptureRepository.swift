import Foundation
import SwiftData

// Thin wrapper over a SwiftData ModelContext so views/view-models don't
// reach into SwiftData directly. Keeps capture creation centralized and
// makes Phase 07/08 mutations easier to audit.
@MainActor
struct CaptureRepository {
    let context: ModelContext

    func insert(_ capture: Capture) throws {
        context.insert(capture)
        try context.save()
    }

    func mark(_ capture: Capture, status: CaptureStatus, error: String? = nil) throws {
        capture.status = status
        capture.lastError = error
        try context.save()
    }

    func remove(id: UUID) throws {
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == id })
        if let target = try context.fetch(descriptor).first {
            context.delete(target)
            try context.save()
        }
    }

    func find(id: UUID) -> Capture? {
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == id })
        return (try? context.fetch(descriptor))?.first
    }
}
