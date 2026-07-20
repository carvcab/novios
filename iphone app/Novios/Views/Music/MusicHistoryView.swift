import SwiftUI

public struct MusicHistoryView: View {
    @State private var songs: [(name: String, artist: String, date: String)] = [
        ("Beso", "Rauw Alejandro & Rosalía", "15 Ene 2026"),
        ("Mi Persona Favorita", "Río Roma", "28 Dic 2025"),
        ("Contigo", "Sebastián Yatra & Pablo Alborán", "10 Nov 2025"),
        ("Perfecta", "Marca MP & Luis R Conriquez", "02 Sep 2025"),
        ("La Incondicional", "Luis Miguel", "18 Jun 2025"),
        ("Amor Eterno", "Cristian Castro", "05 Mar 2025")
    ]
    @State private var showRestoreAlert = false
    @State private var restoredSong = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                content
            }
            .navigationTitle("Historial")
            .alert("Canción restaurada como 'Nuestra Canción'", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\"\(restoredSong)\" ahora es su canción principal.")
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Historial de Canciones").font(.system(size: 26, weight: .bold)).foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Array(songs.enumerated()), id: \.offset) { i, song in
                    songRow(song: song, index: i)
                }
            }.padding(20)
        }
    }

    private func songRow(song: (name: String, artist: String, date: String), index: Int) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12).fill(ThemeManager.shared.primaryPink.opacity(0.15)).frame(width: 50, height: 50)
                    .overlay(Image(systemName: "music.note").font(.system(size: 22)).foregroundColor(ThemeManager.shared.primaryPink))
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name).font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                    Text(song.artist).font(.system(size: 12)).foregroundColor(ThemeManager.shared.textSecondary)
                    Text(song.date).font(.system(size: 11)).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.7))
                }
                Spacer()
                Button {
                    restoredSong = song.name; showRestoreAlert = true
                } label: {
                    Text("Restaurar").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8).background(ThemeManager.shared.primaryPink).cornerRadius(12)
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { withAnimation { songs.remove(at: index) } }
                label: { Label("Eliminar", systemImage: "trash") }
        }
    }
}
