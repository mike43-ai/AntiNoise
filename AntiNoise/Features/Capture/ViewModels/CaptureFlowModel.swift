import Foundation
import Observation
import SwiftData
import UIKit

enum CaptureMode: String, CaseIterable {
    case url, note, image

    var title: String {
        switch self {
        case .url:   return "Link"
        case .note:  return "Note"
        case .image: return "Image"
        }
    }

    var systemImage: String {
        switch self {
        case .url:   return "link"
        case .note:  return "text.alignleft"
        case .image: return "photo"
        }
    }
}

enum CaptureSaveOutcome {
    case saved
    case quotaExceeded
    case failed(String)
}

@Observable
@MainActor
final class CaptureFlowModel {
    var mode: CaptureMode = .url
    var urlText: String = ""
    var noteText: String = ""
    var pickedImage: UIImage?
    var isSaving = false
    var toastMessage: String?
    var errorMessage: String?

    private let modelContext: ModelContext
    private let summarizerProvider: () -> SummarizerService
    private let isOnline: () -> Bool
    private let quotaUIDProvider: () -> String?
    private let isProProvider: () -> Bool

    init(
        modelContext: ModelContext,
        summarizerProvider: @escaping () -> SummarizerService,
        isOnline: @escaping () -> Bool,
        quotaUIDProvider: @escaping () -> String? = { nil },
        isProProvider: @escaping () -> Bool = { false }
    ) {
        self.modelContext = modelContext
        self.summarizerProvider = summarizerProvider
        self.isOnline = isOnline
        self.quotaUIDProvider = quotaUIDProvider
        self.isProProvider = isProProvider
    }

    var canSave: Bool {
        switch mode {
        case .url:
            guard let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)),
                  let scheme = url.scheme?.lowercased() else { return false }
            return scheme == "http" || scheme == "https"
        case .note:
            return !noteText.trimmingCharacters(in: .whitespaces).isEmpty
        case .image:
            return pickedImage != nil
        }
    }

    func save() async -> CaptureSaveOutcome {
        guard canSave else { return .failed("Fill in the field first.") }
        isSaving = true
        defer { isSaving = false }

        let uid = quotaUIDProvider()
        let isPro = isProProvider()
        guard UsageQuotaService.consume(.capture, uid: uid, isPro: isPro) else {
            return .quotaExceeded
        }

        let repo = CaptureRepository(context: modelContext)
        do {
            let capture = try buildCapture()
            try repo.insert(capture)

            if isOnline() {
                toastMessage = "Captured. Summarizing…"
                let summarizer = summarizerProvider()
                Task { await summarizer.process(captureID: capture.id) }
            } else {
                toastMessage = "Captured. Will summarize when online."
            }
            reset()
            return .saved
        } catch {
            errorMessage = error.localizedDescription
            return .failed(error.localizedDescription)
        }
    }

    private func buildCapture() throws -> Capture {
        switch mode {
        case .url:
            return Capture(kind: .url, sourceURL: urlText.trimmingCharacters(in: .whitespaces))
        case .note:
            return Capture(kind: .text, rawText: noteText.trimmingCharacters(in: .whitespaces))
        case .image:
            guard let image = pickedImage,
                  let data = image.jpegData(compressionQuality: 0.82) else {
                throw CaptureFlowError.imageEncodingFailed
            }
            let filename = try SharedQueueStore.writeImage(data)
            return Capture(kind: .image, imageFilename: filename)
        }
    }

    private func reset() {
        urlText = ""
        noteText = ""
        pickedImage = nil
    }
}

enum CaptureFlowError: LocalizedError {
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed: return "Couldn't encode the picked image."
        }
    }
}
