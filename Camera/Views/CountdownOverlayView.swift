import SwiftUI

struct CountdownOverlayView: View {
    let remaining: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("\(remaining)")
                .font(.system(size: 180, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 14)
                .contentTransition(.numericText(countsDown: true))
            Text("Press space or the shutter to cancel")
                .font(.callout.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.black.opacity(0.5), in: Capsule())
        }
        .animation(.snappy, value: remaining)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Taking photo in \(remaining)")
    }
}
