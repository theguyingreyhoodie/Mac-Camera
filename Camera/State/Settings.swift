import Foundation

nonisolated enum PhotoboothSettings {
    static let mirrorSavedPhotosKey = "mirrorSavedPhotos"

    static let mirrorSavedPhotosDefault = true

    static let countdownSecondsKey = "countdownSeconds"
    static let flashEnabledKey = "flashEnabled"

    /// Last-used timer choice; falls back to Off for unknown values.
    static var countdown: CountdownDuration {
        CountdownDuration(rawValue: UserDefaults.standard.integer(forKey: countdownSecondsKey)) ?? .off
    }

    /// Whether the screen lights up white before a photo. Off by default.
    static var flashEnabled: Bool {
        UserDefaults.standard.bool(forKey: flashEnabledKey)
    }

    /// Whether saved photos are flipped horizontally to match the mirrored preview. On by default.
    static var mirrorSavedPhotos: Bool {
        UserDefaults.standard.object(forKey: mirrorSavedPhotosKey) as? Bool ?? mirrorSavedPhotosDefault
    }
}
