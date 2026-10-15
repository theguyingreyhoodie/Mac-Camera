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
                    controls
                }
                .animation(.easeInOut(duration: 0.2), value: model.bannerText)

                Color.white
                    .opacity(model.flashOpacity)
                    .allowsHitTesting(false)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .ignoresSafeArea()
        .task { await model.start() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.appDidBecomeActive()
        }
    }

    private var controls: some View {
        ZStack {
            ShutterButtonView(isEnabled: model.canCapture, action: model.handleShutterTap)

            HStack {
                LastCaptureThumbnailView(image: model.lastThumbnail, action: model.revealLastPhoto)
                Spacer()
                CameraPickerView(
                    devices: model.discovery.devices,
                    selection: model.selectedDeviceID,
                    onSelect: model.select(deviceID:))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
