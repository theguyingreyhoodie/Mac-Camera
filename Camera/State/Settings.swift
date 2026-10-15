import Foundation

nonisolated enum PhotoboothSettings {
    static let mirrorSavedPhotosKey = "mirrorSavedPhotos"

    static let mirrorSavedPhotosDefault = true

    /// Whether saved photos are flipped horizontally to match the mirrored preview. On by default.
    static var mirrorSavedPhotos: Bool {
        UserDefaults.standard.object(forKey: mirrorSavedPhotosKey) as? Bool ?? mirrorSavedPhotosDefault
    }
}
