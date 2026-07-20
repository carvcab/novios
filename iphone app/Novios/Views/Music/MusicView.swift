import SwiftUI

public struct MusicView: View {
    @State private var isPlaying = false
    @State private var progress = 0.3

    private let queue: [(String, String, String)] = [
        ("Nuestra Canción", "Artista", "\u{2764}\u{FE0F}"),
        ("Amor Eterno", "Artista", "\u{2606}"),
        ("Tú y Yo", "Artista", "\u{2764}\u{FE0F}"),
        ("Para Siempre", "Artista", "\u{2606}"),
        ("Solo Tú", "Artista", "\u{2764}\u{FE0F}")
    ]

    private let history: [(String, String)] = [
        ("Beso", "Nuestra Canción"),
        ("Mi Persona Favorita", "Amor Eterno"),
        ("Contigo", "Tú y Yo")
    ]

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
                            ForEach(queue, id: \.0) { song in
                                GlassCard(cornerRadius: 16, opacity: 0.1) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(song.0)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text(song.1)
                                                .font(.system(size: 12))
                                                .foregroundColor(ThemeManager.shared.textSecondary)
                                        }

                                        Spacer()

                                        Text(song.2)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                        }

                        Text("Historial")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 10) {
                            ForEach(history, id: \.0) { item in
                                GlassCard(cornerRadius: 16, opacity: 0.1) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(ThemeManager.shared.textSecondary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.0)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text(item.1)
                                                .font(.system(size: 12))
                                                .foregroundColor(ThemeManager.shared.textSecondary)
                                        }

                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Música")
        }
    }
}
