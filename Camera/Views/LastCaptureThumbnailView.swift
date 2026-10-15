import SwiftUI

struct LastCaptureThumbnailView: View {
    let image: NSImage?
    let action: () -> Void

    var body: some View {
        Group {
            if let image {
                Button(action: action) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .buttonStyle(.plain)
                .help("Show in Finder")
            } else {
                Color.clear
            }
        }
        .frame(width: 64, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if image != nil {
                RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.8), lineWidth: 1.5)
            }
        }
    }
}
