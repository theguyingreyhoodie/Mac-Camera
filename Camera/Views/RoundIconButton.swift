import SwiftUI

/// The small translucent circle buttons next to the shutter. Highlighted yellow when `isOn`.
struct RoundIconButton: View {
    let systemName: String
    var isOn = false
    var badge: String?
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundStyle(isOn ? Color.yellow : .white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.4), in: Circle())
                .overlay(alignment: .topTrailing) {
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.yellow, in: Capsule())
                            .offset(x: 4, y: -2)
                    }
                }
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}
