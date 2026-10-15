import AVFoundation
import Observation

/// Watches the capture session for interruptions and runtime errors and exposes a user-facing message.
@Observable
final class SessionMonitor {
    private(set) var message: String?
    /// Asked to restart the session after a runtime error.
    @ObservationIgnored var onRuntimeError: (() -> Void)?
    /// Called when the camera is taken away (interruption or error).
    @ObservationIgnored var onInterruption: (() -> Void)?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(session: AVCaptureSession) {
        let center = NotificationCenter.default

        observers.append(center.addObserver(forName: AVCaptureSession.wasInterruptedNotification,
                                            object: session, queue: .main) { [weak self] _ in
            // macOS doesn't report an interruption reason; in practice it means another app took the camera.
            MainActor.assumeIsolated {
                self?.message = "Camera in use by another app"
                self?.onInterruption?()
            }
        })
        observers.append(center.addObserver(forName: AVCaptureSession.interruptionEndedNotification,
                                            object: session, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.message = nil }
        })
        observers.append(center.addObserver(forName: AVCaptureSession.runtimeErrorNotification,
                                            object: session, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.message = "Camera error. Restarting…"
                self?.onInterruption?()
                self?.onRuntimeError?()
            }
        })
        observers.append(center.addObserver(forName: AVCaptureSession.didStartRunningNotification,
                                            object: session, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.message = nil }
        })
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
