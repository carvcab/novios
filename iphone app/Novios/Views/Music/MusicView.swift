import SwiftUI

private struct Song: Identifiable {
    let id: String
    let name: String
    let artist: String
    let isFavorite: Bool
}

public struct MusicView: View {
    @State private var isPlaying = false
    @State private var progress = 0.3
    @State private var songs: [Song] = []

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Tu Música")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        GlassCard {
                            VStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(ThemeManager.shared.primaryPink.opacity(0.15))
                                        .frame(height: 160)

                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 56))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                }

                                VStack(spacing: 4) {
                                    Text("Nuestra Canción")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text("Artista Favorito")
                                        .font(.system(size: 14))
                                        .foregroundColor(ThemeManager.shared.textSecondary)
                                }

                                Slider(value: $progress, in: 0...1)
                                    .accentColor(ThemeManager.shared.primaryPink)

                                HStack(spacing: 40) {
                                    Button(action: {}) {
                                        Image(systemName: "backward.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.primary)
                                    }

                                    Button(action: { isPlaying.toggle() }) {
                                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                    }

                                    Button(action: {}) {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }

                        Text("En Cola")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 10) {
                            ForEach(songs) { song in
                                GlassCard(cornerRadius: 16, opacity: 0.1) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(song.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text(song.artist)
                                                .font(.system(size: 12))
                                                .foregroundColor(ThemeManager.shared.textSecondary)
                                        }

                                        Spacer()

                                        if song.isFavorite {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(ThemeManager.shared.primaryPink)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Música")
            .task {
                let items = await FirestoreSyncService.shared.loadSongs()
                songs = items.map {
                    Song(id: $0["id"] as? String ?? UUID().uuidString,
                         name: $0["name"] as? String ?? "",
                         artist: $0["artist"] as? String ?? "",
                         isFavorite: $0["isFavorite"] as? Bool ?? false)
                }
            }
        }
    }
}
