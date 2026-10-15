import SwiftUI

struct FilterStripView: View {
    let thumbnails: [PhotoboothFilter: NSImage]
    let selected: PhotoboothFilter
    let onSelect: (PhotoboothFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PhotoboothFilter.allCases) { filter in
                    Button { onSelect(filter) } label: {
                        VStack(spacing: 4) {
                            thumbnail(for: filter)
                                .frame(width: 96, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(filter == selected ? Color.yellow : .white.opacity(0.3),
                                                lineWidth: filter == selected ? 3 : 1)
                                }
                            Text(filter.displayName)
                                .font(.caption.weight(filter == selected ? .bold : .regular))
                                .foregroundStyle(filter == selected ? Color.yellow : .white)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(filter.displayName)
                    .accessibilityAddTraits(filter == selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.black.opacity(0.55))
    }

    @ViewBuilder
    private func thumbnail(for filter: PhotoboothFilter) -> some View {
        if let image = thumbnails[filter] {
            Image(nsImage: image).resizable().scaledToFill()
        } else {
            Color.white.opacity(0.1)
        }
    }
}
