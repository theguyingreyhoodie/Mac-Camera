import AVFoundation
import AppKit
import Observation

@Observable
final class PermissionCoordinator {
    private(set) var status: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

    var isAuthorized: Bool { status == .authorized }
    var isDenied: Bool { status == .denied || status == .restricted }

    func refresh() {
        status = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestIfNeeded() async {
        refresh()
        guard status == .notDetermined else { return }
        _ = await AVCaptureDevice.requestAccess(for: .video)
        refresh()
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
    }
}
