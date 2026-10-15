import Foundation

nonisolated enum PhotoboothSettings {
    static let mirrorSavedPhotosKey = "mirrorSavedPhotos"

    /// Whether saved photos are flipped horizontally to match the mirrored preview. Off by default.
    static var mirrorSavedPhotos: Bool {
        UserDefaults.standard.bool(forKey: mirrorSavedPhotosKey)
    }
}
