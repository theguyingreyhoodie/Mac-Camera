import AVFoundation
import Observation

struct CameraInfo: Identifiable, Hashable {
    let id: String
    let name: String
}

@Observable
final class CameraDeviceDiscovery {
    private(set) var devices: [CameraInfo] = []
    /// Called after the device list is refreshed because a camera was connected or disconnected.
    @ObservationIgnored var onDevicesChanged: (() -> Void)?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init() {
        refresh()
        for name in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.refresh()
                    self?.onDevicesChanged?()
                }
            }
            observers.append(token)
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func refresh() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified)
        devices = discovery.devices.map { CameraInfo(id: $0.uniqueID, name: $0.localizedName) }
    }

    /// The system-preferred camera if we list it, otherwise the first available one.
    var defaultDeviceID: String? {
        if let preferred = AVCaptureDevice.systemPreferredCamera?.uniqueID,
           devices.contains(where: { $0.id == preferred }) {
            return preferred
        }
        return devices.first?.id
    }
}
