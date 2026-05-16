import Foundation
import UIKit

// Reads an image file from disk, downscales for vision, base64-encodes as
// a data URI suitable for GPT-4o multimodal `image_url` parts.
enum ImageEncoder {
    enum EncoderError: LocalizedError {
        case readFailed
        case encodeFailed

        var errorDescription: String? {
            switch self {
            case .readFailed:    return "Couldn't read the image file."
            case .encodeFailed:  return "Couldn't encode the image as JPEG."
            }
        }
    }

    // GPT-4o vision: 1024px long edge is plenty and keeps base64 payload small.
    static let maxLongEdge: CGFloat = 1024

    static func encodeAsDataURI(url: URL) async throws -> String {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            throw EncoderError.readFailed
        }
        let jpeg: Data? = await MainActor.run {
            let downscaled = downscale(image, maxEdge: maxLongEdge)
            return downscaled.jpegData(compressionQuality: 0.80)
        }
        guard let jpeg else { throw EncoderError.encodeFailed }
        let base64 = jpeg.base64EncodedString()
        return "data:image/jpeg;base64,\(base64)"
    }

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
