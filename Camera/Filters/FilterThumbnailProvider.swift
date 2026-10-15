import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Observation
import Synchronization

/// Receives raw camera frames from the capture queue and keeps one small, throttled copy.
/// Does nothing (and keeps nothing) unless it's active, i.e. while the filter strip is visible.
nonisolated final class FilterThumbnailSource: Sendable {
    static let thumbnailWidth: CGFloat = 160
    static let thumbnailHeight: CGFloat = 120   // 4:3
    private static let minInterval: Duration = .milliseconds(120)   // ~8 fps

    private struct State {
        var isActive = false
        var lastAccepted: ContinuousClock.Instant?
        var latest: CIImage?
    }
    private let state = Mutex(State())

    func setActive(_ active: Bool) {
        state.withLock {
            $0.isActive = active
            $0.lastAccepted = nil
            if !active { $0.latest = nil }
        }
    }

    /// Called for every captured frame; cheap when inactive or throttled.
    func submit(_ frame: CIImage) {
        let now = ContinuousClock.now
        let isDue = state.withLock { s -> Bool in
            guard s.isActive else { return false }
            if let last = s.lastAccepted, now - last < Self.minInterval { return false }
            s.lastAccepted = now
            return true
        }
        guard isDue else { return }
        let small = Self.downsample(frame)
        state.withLock { if $0.isActive { $0.latest = small } }
    }

    func takeLatest() -> CIImage? {
        state.withLock { s in
            defer { s.latest = nil }
            return s.latest
        }
    }

    /// 4:3 center crop, Lanczos-downsampled and mirrored to match the live preview.
    static func downsample(_ frame: CIImage) -> CIImage {
        let cropped = PhotoProcessor.cropToAspect(frame, aspect: thumbnailWidth / thumbnailHeight)
        guard cropped.extent.width > 0 else { return cropped }
        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = cropped
        filter.scale = Float(thumbnailWidth / cropped.extent.width)
        filter.aspectRatio = 1
        let scaled = (filter.outputImage ?? cropped)
            .cropped(to: CGRect(x: 0, y: 0, width: thumbnailWidth, height: thumbnailHeight))
        return PhotoProcessor.mirrored(scaled)
    }
}

/// Renders every filter variant of the latest frame for the filter strip, only while started.
@Observable
final class FilterThumbnailProvider {
    let source = FilterThumbnailSource()
    private(set) var images: [PhotoboothFilter: NSImage] = [:]
    @ObservationIgnored private var task: Task<Void, Never>?

    var isRunning: Bool { task != nil }

    func start() {
        guard task == nil else { return }
        source.setActive(true)
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if let frame = self.source.takeLatest() {
                    let rendered = await Self.renderAll(frame)
                    guard !Task.isCancelled else { return }
                    self.images = rendered.mapValues { NSImage(cgImage: $0, size: .zero) }
                }
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        source.setActive(false)
    }

    @concurrent
    private static func renderAll(_ image: CIImage) async -> [PhotoboothFilter: CGImage] {
        var result: [PhotoboothFilter: CGImage] = [:]
        for filter in PhotoboothFilter.allCases {
            let output = filter.apply(to: image)
            if let cgImage = RenderContext.ciContext.createCGImage(
                output, from: output.extent, format: .RGBA8, colorSpace: RenderContext.colorSpace) {
                result[filter] = cgImage
            }
        }
        return result
    }
}
