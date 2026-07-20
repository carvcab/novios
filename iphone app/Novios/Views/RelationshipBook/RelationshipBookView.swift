import SwiftUI

public struct RelationshipBookView: View {
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Book header
                        GlassCard {
                            VStack(spacing: 12) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text("Nuestra Historia de Amor")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("Cada capítulo es un recuerdo que construimos juntos")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 16)

                        // Chapters
                        ForEach(chapters, id: \.title) { chapter in
                            GlassCard {
                                HStack(spacing: 16) {
                                    Text(chapter.emoji)
                                        .font(.system(size: 28))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chapter.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Capítulo \(chapters.firstIndex(where: { $0.title == chapter.title })! + 1)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.primary.opacity(0.4))
                                    }
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Button(action: {}) {
                                            Text("Escribir")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(ThemeManager.shared.primaryPink)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(ThemeManager.shared.primaryPink.opacity(0.12))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        Button(action: {}) {
                                            Text("Leer")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.primary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.white.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Export button
                        GlassCard {
                            Button(action: {}) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Exportar PDF")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        Color.clear.frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Nuestro Libro")
        }
    }

    private let chapters: [(emoji: String, title: String)] = [
        ("📖", "Nuestra Historia"),
        ("💑", "Cómo nos conocimos"),
        ("🎉", "Momentos especiales"),
        ("💪", "Superaciones"),
        ("🎯", "Metas juntos"),
        ("💌", "Cartas de amor")
    ]
}
