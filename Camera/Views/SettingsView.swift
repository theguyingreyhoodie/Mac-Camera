import SwiftUI

struct SettingsView: View {
    @AppStorage(PhotoboothSettings.mirrorSavedPhotosKey) private var mirrorSavedPhotos = PhotoboothSettings.mirrorSavedPhotosDefault

    var body: some View {
        Form {
            Toggle("Mirror saved photos", isOn: $mirrorSavedPhotos)
            Text("The live preview is always mirrored like a mirror. Turn this off to save photos unflipped, as others see you.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 380)
    }
}
