import SwiftUI

public struct GamesView: View {
    @ObservedObject private var couple = CoupleService.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        gameCard(icon: "questionmark.square.fill", title: "Verdad o Reto", color: .orange, desc: "Preguntas y desafíos divertidos")
                        gameCard(icon: "heart.fill", title: "¿Qué prefieres?", color: .red, desc: "Descubre sus preferencias")
                        gameCard(icon: "sparkles", title: "Nunca he nunca", color: .purple, desc: "Secretos y confesiones")
                        gameCard(icon: "bolt.fill", title: "Retos", color: .yellow, desc: "Desafíos para la pareja")
                        gameCard(icon: "lightbulb.fill", title: "Preguntas", color: .blue, desc: "Conversaciones profundas")
                        gameCard(icon: "chart.bar.fill", title: "Historial", color: .green, desc: "Estadísticas de juegos")
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Juegos de Pareja 🎮")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cerrar") { dismiss() } } }
        }
    }

    private func gameCard(icon: String, title: String, color: Color, desc: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(color).appFont(size: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).appFont(size: 15, weight: .semibold)
                Text(desc).appFont(size: 12).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").appFont(size: 12).foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3)))
    }
}
