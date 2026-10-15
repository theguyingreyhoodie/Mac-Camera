import AppKit

/// A synthesized "click-clack" shutter sound, so there is never a missing resource file.
enum ShutterSound {
    private static let sound: NSSound? = NSSound(data: makeWAV())

    static func play() {
        sound?.stop()
        sound?.play()
    }

    private static func makeWAV() -> Data {
        let sampleRate = 44_100
        let duration = 0.14
        let count = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: count)
        var seed: UInt32 = 12345

        // Two short noise bursts with fast decay: the shutter opening, then closing.
        let bursts: [(start: Double, decay: Double, gain: Double)] = [(0.0, 90, 0.8), (0.055, 70, 0.6)]
        for i in 0..<count {
            let t = Double(i) / Double(sampleRate)
            var value = 0.0
            for burst in bursts where t >= burst.start {
                seed = seed &* 1_664_525 &+ 1_013_904_223
                let noise = Double(Int32(bitPattern: seed)) / Double(Int32.max)
                let tone = sin(2 * .pi * 1_800 * t)
                value += (noise * 0.6 + tone * 0.4) * exp(-(t - burst.start) * burst.decay) * burst.gain
            }
            samples[i] = Int16(max(-1, min(1, value)) * 20_000)
        }

        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let dataSize = UInt32(count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36) + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1))                 // PCM, mono
        append(UInt32(sampleRate)); append(UInt32(sampleRate * 2))
        append(UInt16(2)); append(UInt16(16))                // block align, bits per sample
        data.append(contentsOf: Array("data".utf8)); append(dataSize)
        for sample in samples { append(sample) }
        return data
    }
}
