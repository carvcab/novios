import SwiftUI

public struct VoiceMailboxView: View {
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                            Text("Mensajes de voz guardados para el futuro")
                                .font(.system(size: 13))
                                .foregroundColor(.primary.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        // Voice message list
                        ForEach(voiceMessages, id: \.title) { msg in
                            GlassCard {
                                HStack(spacing: 16) {
                                    Text(msg.emoji)
                                        .font(.system(size: 32))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(msg.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        HStack(spacing: 4) {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.primary.opacity(0.4))
                                            Text("Disponible: \(msg.unlockDate)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.primary.opacity(0.5))
                                        }
                                    }
                                    Spacer()
                                    Button(action: {}) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.primary.opacity(0.2))
                                    }
                                    .disabled(true)
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Record button
                        GlassCard {
                            Button(action: {}) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "mic.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Grabar nuevo mensaje")
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
            .navigationTitle("Buzón de Voz")
        }
    }

    private let voiceMessages: [(emoji: String, title: String, unlockDate: String)] = [
        ("🎵", "Mi canción favorita", "25 Dic 2026"),
        ("💕", "Te amo", "Próximo aniversario"),
        ("🤗", "Un abrazo virtual", "10 Dic 2026")
    ]
}
