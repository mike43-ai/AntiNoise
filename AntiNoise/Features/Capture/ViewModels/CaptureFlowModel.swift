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

    init(
        modelContext: ModelContext,
        summarizerProvider: @escaping () -> SummarizerService,
        isOnline: @escaping () -> Bool
    ) {
        self.modelContext = modelContext
        self.summarizerProvider = summarizerProvider
        self.isOnline = isOnline
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

    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        defer { isSaving = false }

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
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
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
