import SwiftUI

public struct GiftsView: View {
    private let gifts: [(emoji: String, name: String)] = [
        ("🌹", "Rosas"),
        ("💍", "Anillo"),
        ("🧸", "Peluche"),
        ("🍫", "Chocolates"),
        ("🎵", "Canción"),
        ("✉️", "Carta"),
        ("🌺", "Flor"),
        ("🎀", "Sorpresa")
    ]

    private let receivedGifts: [(emoji: String, name: String, from: String)] = [
        ("🌹", "Rosas", "Ana"),
        ("🧸", "Peluche", "Ana")
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(ThemeManager.shared.neonGlowGradient)

                            Text("Regalos Virtuales")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Envía un detalle especial a tu pareja")
                                .font(.system(size: 14))
                                .foregroundColor(ThemeManager.shared.textSecondary)
                        }
                        .padding(.top, 8)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(gifts, id: \.name) { gift in
                                GlassCard {
                                    VStack(spacing: 12) {
                                        Text(gift.emoji)
                                            .font(.system(size: 48))

                                        Text(gift.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.primary)

                                        Button("Enviar") {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(ThemeManager.shared.neonGlowGradient)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        if !receivedGifts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Regalos Enviados")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)

                                ForEach(receivedGifts, id: \.name) { gift in
                                    GlassCard {
                                        HStack(spacing: 16) {
                                            Text(gift.emoji)
                                                .font(.system(size: 36))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(gift.name)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(.primary)

                                                Text("De \(gift.from)")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(ThemeManager.shared.textSecondary)
                                            }

                                            Spacer()

                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(ThemeManager.shared.primaryPink)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Regalos")
        }
    }
}
