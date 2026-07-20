import SwiftUI

public struct EncryptionView: View {
    @State private var showingCode = false

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Shield icon
                        GlassCard {
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 56))
                                    .foregroundColor(ThemeManager.shared.primaryPink)

                                // Status badge
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Cifrado activo")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.green)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Info cards
                        ForEach(encryptionInfo, id: \.title) { info in
                            GlassCard {
                                HStack(spacing: 14) {
                                    Text(info.emoji)
                                        .font(.system(size: 32))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(info.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(info.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.primary.opacity(0.5))
                                            .lineLimit(3)
                                    }
                                    Spacer()
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Verify button
                        GlassCard {
                            Button(action: { showingCode.toggle() }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "key.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Verificar clave de cifrado")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        if showingCode {
                            GlassCard {
                                VStack(spacing: 8) {
                                    Text("Tu clave de cifrado única")
                                        .font(.system(size: 12))
                                        .foregroundColor(.primary.opacity(0.5))
                                    Text("\(mockCode)")
                                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                }
                                .padding(20)
                            }
                            .padding(.horizontal, 16)
                            .transition(.opacity)
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Seguridad")
        }
    }

    private let encryptionInfo: [(emoji: String, title: String, description: String)] = [
        ("🔐", "Cifrado Extremo a Extremo", "Todos tus mensajes están cifrados de extremo a extremo"),
        ("🛡️", "Privacidad Garantizada", "Solo tú y tu pareja pueden leer los mensajes"),
        ("🔑", "Clave Única", "Cada conversación tiene una clave de cifrado única")
    ]

    private let mockCode = "8429 6153"
}
