import Foundation

// MARK: - SavedTrack

struct SavedTrack: Codable, Identifiable, Equatable {
    var id: String
    let title: String
    let artist: String
    let url: String
    let videoId: String
    let thumbnailURL: String
    let isLocal: Bool
    let addedAt: Date

    // MARK: Conversion

    static func from(track: TrackInfo) -> SavedTrack {
        SavedTrack(
            id: track.videoId.isEmpty ? track.url : track.videoId,
            title: track.title,
            artist: track.artist,
            url: track.url,
            videoId: track.videoId,
            thumbnailURL: track.thumbnailURL,
            isLocal: track.url.hasPrefix("file://"),
            addedAt: Date()
        )
    }
}

// MARK: - MusicLibraryService

@MainActor
class MusicLibraryService: ObservableObject {

    // MARK: Published State

    @Published var history: [SavedTrack] = []
    @Published var favorites: [SavedTrack] = []
    @Published var localFiles: [SavedTrack] = []

    // MARK: Constants

    private let maxHistoryCount = 100

    private let supportDir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Petify", isDirectory: true)
    }()

    private var historyFileURL: URL {
        supportDir.appendingPathComponent("history.json")
    }

    private var favoritesFileURL: URL {
        supportDir.appendingPathComponent("favorites.json")
    }



    // MARK: Init

    init() {
        ensureSupportDirectory()
        load()
    }

    // MARK: - History

    func addToHistory(_ track: SavedTrack) {
        // Remove existing entry with the same id to deduplicate
        history.removeAll { $0.id == track.id }
        // Insert newest first
        history.insert(track, at: 0)
        // Trim to max count
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        save(history, to: historyFileURL)
    }

    func clearHistory() {
        history = []
        save(history, to: historyFileURL)
    }

    // MARK: - Favorites

    func toggleFavorite(_ track: SavedTrack) {
        if let index = favorites.firstIndex(where: { $0.id == track.id }) {
            favorites.remove(at: index)
        } else {
            favorites.insert(track, at: 0)
        }
        save(favorites, to: favoritesFileURL)
    }

    func isFavorite(id: String) -> Bool {
        favorites.contains { $0.id == id }
    }

    // MARK: - Local Music Scan

    func scanLocalMusic() async {
        let found = await Task.detached { () -> [SavedTrack] in
            return MusicLibraryHelper.scanDirectories()
        }.value

        localFiles = found
    }

    /// Convenience wrapper with a completion handler for UI use.
    func scanLocalMusic(completion: @escaping () -> Void) {
        Task {
            await scanLocalMusic()
            completion()
        }
    }

    // MARK: - Persistence

    func load() {
        history = loadTracks(from: historyFileURL)
        favorites = loadTracks(from: favoritesFileURL)
    }

    private func save(_ tracks: [SavedTrack], to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(tracks)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[MusicLibraryService] Failed to save to \(url.lastPathComponent): \(error)")
        }
    }

    private func loadTracks(from url: URL) -> [SavedTrack] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SavedTrack].self, from: data)
        } catch {
            print("[MusicLibraryService] Failed to load \(url.lastPathComponent): \(error)")
            return []
        }
    }

    // MARK: - Helpers

    private func ensureSupportDirectory() {
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
    }
}

// MARK: - Non-isolated Helper

enum MusicLibraryHelper {
    static let supportedExtensions: Set<String> = ["mp3", "m4a", "wav", "flac", "aac", "ogg"]

    static func scanDirectories() -> [SavedTrack] {
        let fm = FileManager.default
        let homeDir = fm.homeDirectoryForCurrentUser
        let scanDirs = [
            homeDir.appendingPathComponent("Music"),
            homeDir.appendingPathComponent("Downloads"),
        ]

        var results: [SavedTrack] = []

        for dir in scanDirs {
            guard let enumerator = fm.enumerator(
                at: dir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                guard supportedExtensions.contains(ext) else { continue }

                let filename = fileURL.deletingPathExtension().lastPathComponent
                let (title, artist) = parseFilename(filename)

                let track = SavedTrack(
                    id: fileURL.absoluteString,
                    title: title,
                    artist: artist,
                    url: fileURL.absoluteString,
                    videoId: "",
                    thumbnailURL: "",
                    isLocal: true,
                    addedAt: Date()
                )
                results.append(track)
            }
        }
        return results
    }

    static func parseFilename(_ filename: String) -> (title: String, artist: String) {
        let parts = filename.components(separatedBy: "-")
        if parts.count >= 2 {
            let artist = parts[0].trimmingCharacters(in: .whitespaces)
            let title = parts.dropFirst().joined(separator: "-").trimmingCharacters(in: .whitespaces)
            return (title, artist)
        }
        return (filename, "Unknown Artist")
    }
}
