import CoreImage
import Metal
import MetalKit
import Synchronization

/// Shared GPU resources: one Metal device, one CIContext, one color space for preview and saved photos.
nonisolated enum RenderContext {
    static let device: MTLDevice = MTLCreateSystemDefaultDevice()!
    static let colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    static let ciContext = CIContext(mtlDevice: device)
}

/// Draws the most recent camera frame into an MTKView: mirrored, aspect-filled, Retina-sized.
nonisolated final class PreviewRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {
    private let latest = Mutex<CIImage?>(nil)
    private let aspect = Mutex<CGFloat>(16.0 / 9.0)
    private let commandQueue: MTLCommandQueue

    override init() {
        commandQueue = RenderContext.device.makeCommandQueue()!
        super.init()
    }

    /// Called on the capture queue. O(1): just keeps the newest frame.
    func store(_ image: CIImage) {
        latest.withLock { $0 = image }
    }

    func clear() {
        latest.withLock { $0 = nil }
    }

    /// Width / height of the preview drawable, used to crop saved photos to match what the user saw.
    var viewAspect: CGFloat {
        aspect.withLock { $0 }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        aspect.withLock { $0 = size.width / size.height }
    }

    func draw(in view: MTKView) {
        let size = view.drawableSize
        guard size.width > 0, size.height > 0,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let bounds = CGRect(origin: .zero, size: size)
        let output: CIImage
        if let frame = latest.withLock({ $0 }) {
            output = Self.aspectFill(frame, into: size, mirrored: true)
        } else {
            output = CIImage(color: .black).cropped(to: bounds)
        }
        RenderContext.ciContext.render(output, to: drawable.texture, commandBuffer: commandBuffer,
                                       bounds: bounds, colorSpace: RenderContext.colorSpace)
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    /// Scales the image to cover `size` (cropping the overflow, no stretching) and centers it.
    static func aspectFill(_ image: CIImage, into size: CGSize, mirrored: Bool) -> CIImage {
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return image }
        let scale = max(size.width / extent.width, size.height / extent.height)
        return image
            .transformed(by: CGAffineTransform(translationX: -extent.midX, y: -extent.midY))
            .transformed(by: CGAffineTransform(scaleX: mirrored ? -scale : scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: size.width / 2, y: size.height / 2))
    }
}
