import CoreImage
import CoreImage.CIFilterBuiltins

/// All photobooth looks. `apply(to:)` is the single code path used for the live preview,
/// saved photos and filter-strip thumbnails, so a filter looks the same at every resolution.
nonisolated enum PhotoboothFilter: String, CaseIterable, Identifiable, Sendable {
    case none, mono, noir, sepia, chrome, fade, instant, comic, pixellate, thermal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "Normal"
        case .mono: "Mono"
        case .noir: "Noir"
        case .sepia: "Sepia"
        case .chrome: "Chrome"
        case .fade: "Fade"
        case .instant: "Instant"
        case .comic: "Comic"
        case .pixellate: "Pixel"
        case .thermal: "Thermal"
        }
    }

    /// Comic's line weight is fixed in pixels, so it is always computed at this long-side size.
    private static let comicReferenceLongSide: CGFloat = 800
    /// Pixellate uses this many blocks along the image's long side.
    private static let pixelBlocksAlongLongSide: CGFloat = 80

    /// Returns an image with exactly the same extent as the input.
    func apply(to image: CIImage) -> CIImage {
        let extent = image.extent
        guard self != .none, extent.width > 0, extent.height > 0, !extent.isInfinite else { return image }
        let longSide = max(extent.width, extent.height)

        let output: CIImage?
        switch self {
        case .none:
            return image
        case .mono:
            let f = CIFilter.photoEffectMono(); f.inputImage = image; output = f.outputImage
        case .noir:
            let f = CIFilter.photoEffectNoir(); f.inputImage = image; output = f.outputImage
        case .sepia:
            let f = CIFilter.sepiaTone(); f.inputImage = image; f.intensity = 1; output = f.outputImage
        case .chrome:
            let f = CIFilter.photoEffectChrome(); f.inputImage = image; output = f.outputImage
        case .fade:
            let f = CIFilter.photoEffectFade(); f.inputImage = image; output = f.outputImage
        case .instant:
            let f = CIFilter.photoEffectInstant(); f.inputImage = image; output = f.outputImage
        case .thermal:
            let f = CIFilter.thermal(); f.inputImage = image; output = f.outputImage
        case .pixellate:
            let f = CIFilter.pixellate()
            f.inputImage = image.clampedToExtent()
            f.scale = Float(longSide / Self.pixelBlocksAlongLongSide)
            f.center = extent.origin   // anchor the block grid to the image, not to absolute coordinates
            output = f.outputImage
        case .comic:
            output = Self.comicAtReferenceSize(image)
        }
        return (output ?? image).cropped(to: extent)
    }

    private static func comicAtReferenceSize(_ image: CIImage) -> CIImage? {
        let extent = image.extent
        let scale = comicReferenceLongSide / max(extent.width, extent.height)

        let scaled: CIImage
        if scale < 1 {
            let down = CIFilter.lanczosScaleTransform()
            down.inputImage = image
            down.scale = Float(scale)
            down.aspectRatio = 1
            scaled = down.outputImage ?? image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        } else {
            scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        }

        let comic = CIFilter.comicEffect()
        comic.inputImage = scaled.clampedToExtent()
        guard let drawn = comic.outputImage else { return nil }
        return drawn
            .cropped(to: scaled.extent)
            .transformed(by: CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
    }
}
