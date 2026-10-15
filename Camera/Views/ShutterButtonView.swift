import SwiftUI

struct ShutterButtonView: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().stroke(.white, lineWidth: 4)
                Circle().fill(.white).padding(7)
            }
            .frame(width: 72, height: 72)
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .keyboardShortcut(.space, modifiers: [])
        .accessibilityLabel("Take photo")
    }
}
