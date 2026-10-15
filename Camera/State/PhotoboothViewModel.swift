import AVFoundation
import AppKit
import Observation
import SwiftUI

@Observable
final class PhotoboothViewModel {
    let renderer = PreviewRenderer()
    let permission = PermissionCoordinator()
    let discovery = CameraDeviceDiscovery()
    let thumbnails = FilterThumbnailProvider()
    let countdown = CountdownController()
    @ObservationIgnored let camera: CameraManager
    let monitor: SessionMonitor

    private(set) var selectedDeviceID: String?
    private(set) var selectedFilter = PhotoboothFilter.none
    private(set) var isFilterStripVisible = false
    private(set) var isCapturing = false
    private(set) var isFlashEnabled = PhotoboothSettings.flashEnabled
    private(set) var flashOpacity = 0.0
    private(set) var lastThumbnail: NSImage?
    private(set) var lastPhotoURL: URL?
    private var errorMessage: String?
    private var deviceMessage: String?
    private var started = false

    init() {
        camera = CameraManager(renderer: renderer, thumbnailSource: thumbnails.source)
        monitor = SessionMonitor(session: camera.session)

        camera.onError = { [weak self] message in
            Task { @MainActor [weak self] in self?.showError(message) }
        }
        monitor.onRuntimeError = { [weak self] in self?.camera.restart() }
        monitor.onInterruption = { [weak self] in self?.countdown.cancel() }
        countdown.duration = PhotoboothSettings.countdown
        discovery.onDevicesChanged = { [weak self] in self?.devicesChanged() }
    }

    /// The single status line shown in the banner, most urgent first.
    var bannerText: String? {
        errorMessage ?? deviceMessage ?? monitor.message
    }

    /// The shutter stays enabled during a countdown so it can cancel it.
    var canCapture: Bool {
        selectedDeviceID != nil && !isCapturing && permission.isAuthorized
    }

    // MARK: Lifecycle

    func start() async {
        await permission.requestIfNeeded()
        beginCameraIfAuthorized()
    }

    /// Re-checks permission when returning from System Settings.
    func appDidBecomeActive() {
        permission.refresh()
        beginCameraIfAuthorized()
    }

    private func beginCameraIfAuthorized() {
        guard permission.isAuthorized, !started else { return }
        started = true
        discovery.refresh()
        guard let id = discovery.defaultDeviceID else {
            deviceMessage = "No camera found"
            return
        }
        select(deviceID: id)
    }

    // MARK: Camera selection

    func select(deviceID: String) {
        countdown.cancel()
        selectedDeviceID = deviceID
        deviceMessage = nil
        camera.start(deviceID: deviceID)
    }

    private func devicesChanged() {
        guard started else { return }
        let ids = discovery.devices.map(\.id)

        if let selected = selectedDeviceID, !ids.contains(selected) {
            if let fallback = discovery.defaultDeviceID {
                select(deviceID: fallback)
                showDeviceMessage("Camera disconnected. Switched cameras.")
            } else {
                countdown.cancel()
                selectedDeviceID = nil
                camera.stop()
                renderer.clear()
                deviceMessage = "Camera disconnected"
            }
        } else if selectedDeviceID == nil, let fallback = discovery.defaultDeviceID {
            select(deviceID: fallback)
        }
    }

    // MARK: Filters

    func select(filter: PhotoboothFilter) {
        selectedFilter = filter
        camera.setFilter(filter)
    }

    func toggleFilterStrip() {
        isFilterStripVisible.toggle()
        if isFilterStripVisible { thumbnails.start() } else { thumbnails.stop() }
    }

    // MARK: Capture

    /// Starts the countdown (or captures right away when the timer is Off). Tapping during a countdown cancels it.
    func handleShutterTap() {
        guard canCapture else { return }
        countdown.trigger { [weak self] in await self?.capturePhoto() }
    }

    func cycleTimer() {
        countdown.duration = countdown.duration.next
        UserDefaults.standard.set(countdown.duration.seconds, forKey: PhotoboothSettings.countdownSecondsKey)
    }

    func toggleFlash() {
        isFlashEnabled.toggle()
        UserDefaults.standard.set(isFlashEnabled, forKey: PhotoboothSettings.flashEnabledKey)
    }

    func viewDidDisappear() {
        countdown.cancel()
    }

    private func capturePhoto() async {
        isCapturing = true
        defer { isCapturing = false }

        let useScreenFlash = isFlashEnabled
        if useScreenFlash {
            await lightScreen()
        } else {
            triggerFlash()
        }
        ShutterSound.play()

        let data: Data
        do {
            data = try await camera.capturePhotoData()
        } catch {
            if useScreenFlash { fadeScreenLight() }
            showError(error.localizedDescription)
            return
        }
        if useScreenFlash { fadeScreenLight() }

        do {
            let result = try await PhotoProcessor.processAndSave(
                data: data,
                viewAspect: renderer.viewAspect,
                filter: selectedFilter,
                mirror: PhotoboothSettings.mirrorSavedPhotos)
            lastPhotoURL = result.url
            lastThumbnail = NSImage(cgImage: result.thumbnail, size: .zero)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func revealLastPhoto() {
        guard let lastPhotoURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([lastPhotoURL])
    }

    // MARK: Feedback

    /// Screen flash: the display goes bright white so it lights the subject, held briefly before the shot.
    private func lightScreen() async {
        withAnimation(.easeIn(duration: 0.12)) { flashOpacity = 1 }
        try? await Task.sleep(for: .milliseconds(450))
    }

    private func fadeScreenLight() {
        withAnimation(.easeOut(duration: 0.35)) { flashOpacity = 0 }
    }

    /// Quick blink used as shutter feedback when the screen flash is off.
    private func triggerFlash() {
        flashOpacity = 1
        Task {
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        Task {
            try? await Task.sleep(for: .seconds(4))
            if errorMessage == message { errorMessage = nil }
        }
    }

    private func showDeviceMessage(_ message: String) {
        deviceMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            if deviceMessage == message { deviceMessage = nil }
        }
    }
}
