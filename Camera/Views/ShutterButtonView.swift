import SwiftUI

struct ShutterButtonView: View {
    let isEnabled: Bool
    var isCountingDown = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().stroke(.white, lineWidth: 4)
                if isCountingDown {
                    RoundedRectangle(cornerRadius: 6).fill(.red).padding(22)
                } else {
                    Circle().fill(.white).padding(7)
                }
            }
            .frame(width: 72, height: 72)
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .keyboardShortcut(.space, modifiers: [])
        .accessibilityLabel(isCountingDown ? "Cancel countdown" : "Take photo")
    }
}
