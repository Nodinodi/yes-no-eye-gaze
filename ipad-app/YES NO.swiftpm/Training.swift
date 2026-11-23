import SwiftUI
import ImageIO

// MARK: - Training mode: pictures from the folder chosen in Settings

/// A picture shown in the place of one answer button.
struct TrainingPicture {
    let on: String        // answer id: "yes" or "no"
    let image: UIImage
}

enum PictureFolder {
    static let extensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "gif", "webp", "bmp", "tif", "tiff"]

    /// The folder saved in Settings (the iPad gave the app permission through a bookmark).
    static func savedFolder() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: SettingsKey.trainingFolderBookmark),
              !data.isEmpty else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil,
                                 bookmarkDataIsStale: &stale) else { return nil }
        if stale {
            // The folder moved or was renamed: save a fresh bookmark.
            let allowed = url.startAccessingSecurityScopedResource()
            if let fresh = try? url.bookmarkData() {
                UserDefaults.standard.set(fresh, forKey: SettingsKey.trainingFolderBookmark)
            }
            if allowed { url.stopAccessingSecurityScopedResource() }
        }
        return url
    }

    /// Picture files directly inside the folder.
    static func pictures(in folder: URL) -> [URL] {
        let allowed = folder.startAccessingSecurityScopedResource()
        defer { if allowed { folder.stopAccessingSecurityScopedResource() } }
        let items = (try? FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return items.filter { extensions.contains($0.pathExtension.lowercased()) }
    }

    static func pictureCount() -> Int {
        guard let folder = savedFolder() else { return 0 }
        return pictures(in: folder).count
    }

    /// Loads a picture made smaller (max 2048 px), so big photos do not use too much memory.
    static func loadImage(_ url: URL, in folder: URL) -> UIImage? {
        let allowed = folder.startAccessingSecurityScopedResource()
        defer { if allowed { folder.stopAccessingSecurityScopedResource() } }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // keeps photos the right way up
            kCGImageSourceThumbnailMaxPixelSize: 2048,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// Random order, and every picture is shown once before any picture repeats.
final class PictureDeck {
    private var folder: URL?
    private var all: [URL] = []
    private var queue: [URL] = []
    private var last: String?

    /// Reads the folder again (pictures may have been added or removed). Returns how many pictures.
    @discardableResult
    func reload() -> Int {
        folder = PictureFolder.savedFolder()
        let found = folder.map { PictureFolder.pictures(in: $0) } ?? []
        // Keep the pictures not yet shown in this round (if they are still there); new ones join the next round.
        let waiting = Set(queue.map(\.lastPathComponent))
        all = found
        queue = found.filter { waiting.contains($0.lastPathComponent) }.shuffled()
        return all.count
    }

    func next() -> UIImage? {
        guard let folder = folder, !all.isEmpty else { return nil }
        for _ in 0..<all.count {   // skip a file that cannot be opened
            if queue.isEmpty {
                queue = all.shuffled()
                // No picture twice in a row when a new round starts.
                if queue.count > 1, queue.last?.lastPathComponent == last {
                    queue.swapAt(0, queue.count - 1)
                }
            }
            let url = queue.removeLast()
            last = url.lastPathComponent
            if let image = PictureFolder.loadImage(url, in: folder) {
                return image
            }
        }
        return nil
    }
}
