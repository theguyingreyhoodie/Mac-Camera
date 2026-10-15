import SwiftUI

struct StatusBannerView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.black.opacity(0.65), in: Capsule())
            .padding(.top, 16)
    }
}
