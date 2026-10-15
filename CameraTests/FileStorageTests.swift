import CoreImage
import Foundation
import Testing
@testable import Camera

struct FileStorageTests {
    private let utc = TimeZone(identifier: "UTC")!

    @Test func filenameHasMillisecondTimestamp() {
        // 2026-10-16 01:19:24.123 UTC
        let date = Date(timeIntervalSince1970: 1_792_113_564.123)
        let name = FileStorage.filename(for: date, timeZone: utc)
        #expect(name.hasPrefix("Photobooth-"))
        #expect(name.hasSuffix(".jpg"))
        #expect(name.contains("-123."))
    }

    @Test func differentMillisecondsGiveDifferentNames() {
        let a = FileStorage.filename(for: Date(timeIntervalSince1970: 1_000.001), timeZone: utc)
        let b = FileStorage.filename(for: Date(timeIntervalSince1970: 1_000.002), timeZone: utc)
        #expect(a != b)
    }

    @Test func saveNeverOverwritesExistingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoboothTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let date = Date()
        let first = try FileStorage.save(jpeg: Data([1]), date: date, in: directory)
        let second = try FileStorage.save(jpeg: Data([2]), date: date, in: directory)

        #expect(first != second)
        #expect(try Data(contentsOf: first) == Data([1]))
        #expect(try Data(contentsOf: second) == Data([2]))
    }

    @Test func photosDirectoryIsCreatedUnderPictures() throws {
        let directory = try FileStorage.photosDirectory()
        var isDirectory: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        #expect(directory.lastPathComponent == "Photobooth")
        print("PHOTOS_DIR:", directory.path)
    }

    @Test func cropMatchesRequestedAspect() {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 400, height: 300))
        let cropped = PhotoProcessor.cropToAspect(image, aspect: 2.0)
        #expect(cropped.extent.origin == .zero)
        #expect(cropped.extent.width == 400)
        #expect(cropped.extent.height == 200)
    }
}
