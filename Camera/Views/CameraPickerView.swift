import SwiftUI

struct CameraPickerView: View {
    let devices: [CameraInfo]
    let selection: String?
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(devices) { device in
                Button {
                    onSelect(device.id)
                } label: {
                    if device.id == selection {
                        Label(device.name, systemImage: "checkmark")
                    } else {
                        Text(device.name)
                    }
                }
            }
        } label: {
            Image(systemName: "video.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.4), in: Circle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .disabled(devices.isEmpty)
        .help("Choose camera")
    }
}
