import SwiftUI

struct PermissionDeniedView: View {
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera access is turned off")
                .font(.title2.weight(.semibold))
            Text("Allow Photobooth to use the camera in System Settings → Privacy & Security → Camera.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
            Button("Open System Settings", action: openSettings)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .foregroundStyle(.white)
        .padding()
    }
}
