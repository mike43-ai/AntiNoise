import Foundation
import ImageIO
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

// Pulls payloads off NSItemProvider into the shared queue. Stays cheap on
// memory: images are downscaled + EXIF-stripped before write.
enum ShareItemExtractor {
    static func extractAll(from context: NSExtensionContext?) async -> [QueuedPayload] {
        guard let items = context?.inputItems as? [NSExtensionItem] else { return [] }
        var results: [QueuedPayload] = []

        for item in items {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                if let payload = await extract(provider) {
                    results.append(payload)
                }
            }
        }
        return results
    }

    private static func extract(_ provider: NSItemProvider) async -> QueuedPayload? {
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return await extractImage(provider)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            return await extractURL(provider)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            return await extractText(provider)
        }
        return nil
    }

    private static func extractURL(_ provider: NSItemProvider) async -> QueuedPayload? {
        await withCheckedContinuation { cont in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { value, _ in
                let urlString: String?
                if let url = value as? URL {
                    urlString = url.absoluteString
                } else if let raw = value as? String {
                    urlString = raw
                } else {
                    urlString = nil
                }
                guard let urlString else { cont.resume(returning: nil); return }
                cont.resume(returning: QueuedPayload(kind: .url, sourceURL: urlString))
            }
        }
    }

    private static func extractText(_ provider: NSItemProvider) async -> QueuedPayload? {
        await withCheckedContinuation { cont in
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { value, _ in
                let text: String?
                if let str = value as? String { text = str }
                else if let data = value as? Data { text = String(data: data, encoding: .utf8) }
                else { text = nil }
                guard let text, !text.isEmpty else { cont.resume(returning: nil); return }
                cont.resume(returning: QueuedPayload(kind: .text, rawText: text))
            }
        }
    }

    private static func extractImage(_ provider: NSItemProvider) async -> QueuedPayload? {
        let image: UIImage? = await withCheckedContinuation { cont in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { value, _ in
                if let img = value as? UIImage { cont.resume(returning: img); return }
                if let url = value as? URL, let data = try? Data(contentsOf: url) {
                    cont.resume(returning: UIImage(data: data)); return
                }
                if let data = value as? Data {
                    cont.resume(returning: UIImage(data: data)); return
                }
                cont.resume(returning: nil)
            }
        }
        guard let image else { return nil }
        // UIImage + UIGraphicsImageRenderer must run on main per Apple docs.
        // EXIF/GPS strip is via JPEG re-encode, not the redraw itself.
        let jpeg: Data? = await MainActor.run {
            let downscaled = downscale(image, maxEdge: 2048)
            return downscaled.jpegData(compressionQuality: 0.82)
        }
        guard let jpeg else { return nil }
        do {
            let filename = try SharedQueueStore.writeImage(jpeg, suggestedExtension: "jpg")
            return QueuedPayload(kind: .image, imageFilename: filename)
        } catch {
            return nil
        }
    }

    // Long-edge cap. EXIF gets dropped naturally because we redraw + re-encode.
    private static func downscale(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxEdge else { return image }
        let scale = maxEdge / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
