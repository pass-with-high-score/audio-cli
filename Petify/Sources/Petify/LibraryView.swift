import SwiftUI

struct LibraryView: View {
    @ObservedObject var state: AppState
    @ObservedObject var library: MusicLibraryService
    @State private var selectedTab: String = "history"
    @State private var isScanning: Bool = false
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary).font(.caption)
                TextField("Search in library...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
            // Tab Picker
            HStack(spacing: 0) {
                tabButton(title: "History", icon: "clock.fill", tab: "history", count: library.history.count)
                tabButton(title: "Favorites", icon: "heart.fill", tab: "favorites", count: library.favorites.count)
                tabButton(title: "Local", icon: "folder.fill", tab: "local", count: library.localFiles.count)
            }
            .padding(2)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Content
            switch selectedTab {
            case "history":
                trackList(tracks: library.history, emptyMessage: "No recently played tracks", emptyIcon: "clock")
            case "favorites":
                trackList(tracks: library.favorites, emptyMessage: "No favorite tracks yet", emptyIcon: "heart")
            case "local":
                localMusicContent
            default:
                EmptyView()
            }
        }
    }
    
    private func tabButton(title: String, icon: String, tab: String, count: Int) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                }
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9))
                        .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private func trackList(tracks: [SavedTrack], emptyMessage: String, emptyIcon: String) -> some View {
        let filtered = tracks.filter { 
            searchText.isEmpty || 
            $0.title.localizedCaseInsensitiveContains(searchText) || 
            $0.artist.localizedCaseInsensitiveContains(searchText) 
        }
        return Group {
            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: emptyIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(emptyMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(filtered) { track in
                            trackRow(track: track)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
    }
    
    private func trackRow(track: SavedTrack) -> some View {
        HStack(spacing: 8) {
            // Thumbnail
            if !track.thumbnailURL.isEmpty {
                if track.thumbnailURL.hasPrefix("file://"), let url = URL(string: track.thumbnailURL), let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .cornerRadius(6)
                } else {
                    AsyncImage(url: URL(string: track.thumbnailURL)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.secondary.opacity(0.2)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .cornerRadius(6)
                }
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: track.isLocal ? "music.note" : "play.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    )
            }
            
            // Title & Artist
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                if !track.artist.isEmpty {
                    Text(track.artist)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Favorite button
            Button(action: { library.toggleFavorite(track) }) {
                Image(systemName: library.isFavorite(id: track.id) ? "heart.fill" : "heart")
                    .font(.system(size: 12))
                    .foregroundColor(library.isFavorite(id: track.id) ? .pink : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            playFromLibrary(track: track)
        }
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    private var localMusicContent: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button(action: {
                    isScanning = true
                    library.scanLocalMusic {
                        isScanning = false
                    }
                }) {
                    HStack(spacing: 4) {
                        if isScanning {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                        }
                        Text(isScanning ? "Scanning..." : "Scan Music")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isScanning)
            }
            
            trackList(tracks: library.localFiles, emptyMessage: "Tap 'Scan Music' to find audio files\nin ~/Music and ~/Downloads", emptyIcon: "folder")
        }
    }
    
    private func playFromLibrary(track: SavedTrack) {
        let trackInfo = TrackInfo(
            title: track.title,
            videoId: track.videoId,
            url: track.url,
            artist: track.artist,
            localThumbnailURL: track.thumbnailURL.isEmpty ? nil : track.thumbnailURL
        )
        state.tracks.append(trackInfo)
        state.currentTrackIndex = state.tracks.count - 1
        state.playCurrentTrack()
    }
}
