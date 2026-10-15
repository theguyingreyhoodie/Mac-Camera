import Foundation

nonisolated enum FileStorageError: LocalizedError {
    case noPicturesDirectory

    var errorDescription: String? {
        "Couldn't locate the Pictures folder."
    }
}

nonisolated enum FileStorage {
    static let folderName = "Photobooth"

    /// ~/Pictures/Photobooth, created on first use.
    static func photosDirectory(fileManager: FileManager = .default) throws -> URL {
        guard let pictures = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first else {
            throw FileStorageError.noPicturesDirectory
        }
        let directory = pictures.appendingPathComponent(folderName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// e.g. `Photobooth-20261016-011924-123.jpg` (millisecond precision).
    static func filename(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return "Photobooth-\(formatter.string(from: date)).jpg"
    }

    /// Writes the JPEG into `directory` (default: the Photobooth folder), never overwriting an existing file.
    @discardableResult
    static func save(jpeg: Data, date: Date = .now, in directory: URL? = nil) throws -> URL {
        let directory = try directory ?? photosDirectory()
        let base = filename(for: date)
        var url = directory.appendingPathComponent(base)
        var counter = 1
        while FileManager.default.fileExists(atPath: url.path) {
            let stem = (base as NSString).deletingPathExtension
            url = directory.appendingPathComponent("\(stem)-\(counter).jpg")
            counter += 1
        }
        try jpeg.write(to: url, options: .atomic)
        return url
    }
}
