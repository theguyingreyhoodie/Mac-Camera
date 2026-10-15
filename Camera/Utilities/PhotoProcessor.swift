import CoreImage
import Foundation

nonisolated enum PhotoProcessorError: LocalizedError {
    case decodeFailed
    case encodeFailed

    var errorDescription: String? {
        switch self {
        case .decodeFailed: "Couldn't read the captured photo."
        case .encodeFailed: "Couldn't encode the photo."
        }
    }
}

nonisolated enum PhotoProcessor {
    struct Result: Sendable {
        let url: URL
        let thumbnail: CGImage
    }

    /// Decodes the captured photo, crops it to the preview's aspect ratio, optionally mirrors it,
    /// encodes a JPEG and saves it to ~/Pictures/Photobooth.
    @concurrent
    static func processAndSave(data: Data, viewAspect: CGFloat, mirror: Bool) async throws -> Result {
        guard let decoded = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            throw PhotoProcessorError.decodeFailed
        }
        var image = cropToAspect(decoded, aspect: viewAspect)
        if mirror { image = mirrored(image) }

        let context = RenderContext.ciContext
        let colorSpace = RenderContext.colorSpace
        let quality = kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption
        guard let jpeg = context.jpegRepresentation(of: image, colorSpace: colorSpace, options: [quality: 0.92]) else {
            throw PhotoProcessorError.encodeFailed
        }
        let url = try FileStorage.save(jpeg: jpeg)

        let thumbScale = 160 / max(image.extent.width, 1)
        let small = image.transformed(by: CGAffineTransform(scaleX: thumbScale, y: thumbScale))
        guard let thumbnail = context.createCGImage(small, from: small.extent, format: .RGBA8, colorSpace: colorSpace) else {
            throw PhotoProcessorError.encodeFailed
        }
        return Result(url: url, thumbnail: thumbnail)
    }

    /// Center-crops to `aspect` (width / height) and moves the result's origin to (0, 0).
    static func cropToAspect(_ image: CIImage, aspect: CGFloat) -> CIImage {
        let extent = image.extent
        guard aspect > 0, extent.width > 0, extent.height > 0 else { return image }
        var width = extent.width
        var height = extent.height
        if width / height > aspect {
            width = (height * aspect).rounded()
        } else {
            height = (width / aspect).rounded()
        }
        let rect = CGRect(x: (extent.midX - width / 2).rounded(), y: (extent.midY - height / 2).rounded(),
                          width: width, height: height)
        return image.cropped(to: rect)
            .transformed(by: CGAffineTransform(translationX: -rect.minX, y: -rect.minY))
    }

    /// Horizontal flip that keeps the image's origin at (0, 0).
    static func mirrored(_ image: CIImage) -> CIImage {
        let extent = image.extent
        return image.transformed(by: CGAffineTransform(scaleX: -1, y: 1)
            .concatenating(CGAffineTransform(translationX: extent.minX + extent.maxX, y: 0)))
    }
}
