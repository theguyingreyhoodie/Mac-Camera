import SwiftUI

struct SettingsView: View {
    @AppStorage(PhotoboothSettings.mirrorSavedPhotosKey) private var mirrorSavedPhotos = false

    var body: some View {
        Form {
            Toggle("Mirror saved photos", isOn: $mirrorSavedPhotos)
            Text("The live preview is always mirrored like a mirror. Turn this on to save photos flipped the same way.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 380)
    }
}
