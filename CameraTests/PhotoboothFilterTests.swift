import CoreImage
import CoreImage.CIFilterBuiltins
import Testing
@testable import Camera

struct PhotoboothFilterTests {
    /// A gradient so filters have real content to work on.
    private func sample(_ rect: CGRect) -> CIImage {
        let gradient = CIFilter.linearGradient()
        gradient.point0 = rect.origin
        gradient.point1 = CGPoint(x: rect.maxX, y: rect.maxY)
        gradient.color0 = CIColor(red: 1, green: 0.2, blue: 0.1)
        gradient.color1 = CIColor(red: 0.1, green: 0.3, blue: 1)
        return gradient.outputImage!.cropped(to: rect)
    }

    @Test(arguments: PhotoboothFilter.allCases)
    func filterKeepsExtent(_ filter: PhotoboothFilter) {
        for rect in [CGRect(x: 0, y: 0, width: 160, height: 120),
                     CGRect(x: 0, y: 0, width: 1920, height: 1080),
                     CGRect(x: 37, y: 11, width: 640, height: 480)] {
            let output = filter.apply(to: sample(rect))
            #expect(output.extent == rect)
        }
    }

    @Test(arguments: PhotoboothFilter.allCases)
    func filterRendersAtEverySize(_ filter: PhotoboothFilter) {
        for size in [CGSize(width: 160, height: 120), CGSize(width: 1600, height: 1200)] {
            let output = filter.apply(to: sample(CGRect(origin: .zero, size: size)))
            let rendered = RenderContext.ciContext.createCGImage(
                output, from: output.extent, format: .RGBA8, colorSpace: RenderContext.colorSpace)
            #expect(rendered != nil)
            #expect(rendered?.width == Int(size.width))
        }
    }

    @Test func noneIsIdentity() {
        let image = sample(CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(PhotoboothFilter.none.apply(to: image) == image)
    }

    @Test func displayNamesAreUnique() {
        let names = PhotoboothFilter.allCases.map(\.displayName)
        #expect(Set(names).count == names.count)
    }
}
