import AVFoundation
import CoreImage

nonisolated enum CameraError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case notRunning
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .deviceNotFound: "The selected camera isn't available."
        case .cannotAddInput: "Couldn't use the selected camera."
        case .notRunning: "The camera isn't running."
        case .captureFailed: "The photo couldn't be captured."
        }
    }
}

/// Owns the capture session. Not an actor: AVFoundation delegate callbacks are synchronous and
/// high-frequency. All session configuration happens on `sessionQueue`.
nonisolated final class CameraManager: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()
    /// Called (from any queue) when configuration fails.
    var onError: (@Sendable (String) -> Void)?

    private let sessionQueue = DispatchQueue(label: "camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let renderer: PreviewRenderer
    private var currentInput: AVCaptureDeviceInput?   // sessionQueue only
    private var outputsAdded = false                  // sessionQueue only

    init(renderer: PreviewRenderer) {
        self.renderer = renderer
        super.init()
    }

    /// Starts the session on the given device, or swaps to it if already running.
    func start(deviceID: String) {
        sessionQueue.async {
            do {
                try self.configure(deviceID: deviceID)
                if !self.session.isRunning { self.session.startRunning() }
            } catch {
                self.onError?(error.localizedDescription)
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    /// Restarts the session after a runtime error.
    func restart() {
        sessionQueue.async {
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    private func configure(deviceID: String) throws {
        guard let device = AVCaptureDevice(uniqueID: deviceID) else { throw CameraError.deviceNotFound }
        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if let currentInput { session.removeInput(currentInput) }
        guard session.canAddInput(input) else {
            if let currentInput, session.canAddInput(currentInput) { session.addInput(currentInput) }
            throw CameraError.cannotAddInput
        }
        session.addInput(input)
        currentInput = input

        // Not .photo: that preset makes the preview stream needlessly large.
        if session.canSetSessionPreset(.high) { session.sessionPreset = .high }

        if !outputsAdded {
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            outputsAdded = true
        }

        // Keep both outputs unmirrored; mirroring is applied explicitly (preview always, photos by setting).
        for connection in [videoOutput.connection(with: .video), photoOutput.connection(with: .video)].compactMap({ $0 }) {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }

        if let largest = device.activeFormat.supportedMaxPhotoDimensions.last {
            photoOutput.maxPhotoDimensions = largest
        }
    }

    /// Captures a full-resolution still and returns the encoded data (JPEG when available).
    func capturePhotoData() async throws -> Data {
        let delegate = PhotoCaptureDelegate()
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            sessionQueue.async {
                guard self.session.isRunning, self.photoOutput.connection(with: .video) != nil else {
                    delegate.finish(.failure(CameraError.notRunning))
                    return
                }
                let settings: AVCapturePhotoSettings
                if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                } else {
                    settings = AVCapturePhotoSettings()
                }
                settings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
        withExtendedLifetime(delegate) {}
        return data
    }
}

nonisolated extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        renderer.store(CIImage(cvPixelBuffer: pixelBuffer))
    }
}

nonisolated final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    var continuation: CheckedContinuation<Data, Error>?

    func finish(_ result: Result<Data, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            finish(.failure(error))
        } else if let data = photo.fileDataRepresentation() {
            finish(.success(data))
        } else {
            finish(.failure(CameraError.captureFailed))
        }
    }
}
