import SwiftUI

struct ContentView: View {
    @State private var model = PhotoboothViewModel()

    var body: some View {
        ZStack {
            Color.black

            if model.permission.isDenied {
                PermissionDeniedView(openSettings: model.permission.openSystemSettings)
            } else {
                MetalPreviewView(renderer: model.renderer)

                VStack {
                    if let text = model.bannerText {
                        StatusBannerView(text: text)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                    if model.isFilterStripVisible {
                        FilterStripView(
                            thumbnails: model.thumbnails.images,
                            selected: model.selectedFilter,
                            onSelect: model.select(filter:))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    controls
                }
                .animation(.easeInOut(duration: 0.2), value: model.bannerText)
                .animation(.easeInOut(duration: 0.2), value: model.isFilterStripVisible)

                if case .counting(let remaining) = model.countdown.phase {
                    CountdownOverlayView(remaining: remaining)
                }

                Color.white
                    .opacity(model.flashOpacity)
                    .allowsHitTesting(false)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .ignoresSafeArea()
        .task { await model.start() }
        .onDisappear { model.viewDidDisappear() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.appDidBecomeActive()
        }
    }

    private var controls: some View {
        ZStack {
            ShutterButtonView(isEnabled: model.canCapture, isCountingDown: model.countdown.isCounting,
                              action: model.handleShutterTap)

            HStack {
                LastCaptureThumbnailView(image: model.lastThumbnail, action: model.revealLastPhoto)
                Spacer()
                HStack(spacing: 12) {
                    RoundIconButton(
                        systemName: model.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill",
                        isOn: model.isFlashEnabled,
                        help: model.isFlashEnabled ? "Screen flash on" : "Screen flash off",
                        action: model.toggleFlash)
                    RoundIconButton(
                        systemName: "timer",
                        isOn: model.countdown.duration != .off,
                        badge: model.countdown.duration == .off ? nil : model.countdown.duration.label,
                        help: "Timer: \(model.countdown.duration.label)",
                        action: model.cycleTimer)
                    RoundIconButton(
                        systemName: "camera.filters",
                        isOn: model.isFilterStripVisible,
                        help: "Filters",
                        action: model.toggleFilterStrip)
                    CameraPickerView(
                        devices: model.discovery.devices,
                        selection: model.selectedDeviceID,
                        onSelect: model.select(deviceID:))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
