import SwiftUI
import AVFoundation

public struct MusicView: View {
    @StateObject private var couple = CoupleService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showNew = false
    @State private var titleInput = ""
    @State private var artistInput = ""
    @State private var urlInput = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if couple.musica.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(couple.musica) { song in
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(ThemeManager.shared.primary.opacity(0.12)).frame(width: 44, height: 44)
                                        Image(systemName: "music.note").foregroundColor(ThemeManager.shared.primary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(song.titulo).appFont(size: 15, weight: .semibold)
                                        Text(song.artista).appFont(size: 12).foregroundColor(.secondary)
                                        Text("Agregado por \(song.agregadoPor)").appFont(size: 10).foregroundColor(ThemeManager.shared.textSecondary)
                                    }
                                    Spacer()
                                    if !song.url.isEmpty, let url = URL(string: song.url) {
                                        Link(destination: url) {
                                            Image(systemName: "play.circle.fill").appFont(size: 28).foregroundColor(ThemeManager.shared.primary)
                                        }
                                    }
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15)))
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Música y Playlist 🎵")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNew = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundColor(ThemeManager.shared.primary)
                    }
                }
            }
            .sheet(isPresented: $showNew) { newSongSheet }
            .task { await couple.fetchMusica() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primary.opacity(0.5))
            Text("Sin canciones aún").appFont(size: 18, weight: .semibold)
            Text("Agreguen las canciones de su historia 💕").appFont(size: 13).foregroundColor(.secondary)
        }
    }

    private var newSongSheet: some View {
        NavigationStack {
            Form {
                Section("Canción") {
                    TextField("Título", text: $titleInput)
                    TextField("Artista", text: $artistInput)
                    TextField("Link (YouTube/Spotify)", text: $urlInput)
                }
            }
            .navigationTitle("Nueva Canción 🎶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showNew = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await couple.addSong(titulo: titleInput, artista: artistInput, url: urlInput)
                            titleInput = ""; artistInput = ""; urlInput = ""; showNew = false
                        }
                    }
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
