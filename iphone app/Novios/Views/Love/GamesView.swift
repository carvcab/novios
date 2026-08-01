import SwiftUI
import FirebaseFirestore

public struct GamesView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    struct GameDef: Identifiable {
        let id: String; let icon: String; let name: String; let desc: String; let colors: [Color]; let destination: AnyView
    }

    private let games: [GameDef] = [
        GameDef(id: "collections", icon: "folder.fill", name: "Colecciones", desc: "Organiza tu contenido en carpetas", colors: [Color(red: 0.38, green: 0.49, blue: 0.55), Color(red: 0.56, green: 0.64, blue: 0.69)], destination: AnyView(CollectionsView())),
        GameDef(id: "quiz", icon: "questionmark.square.fill", name: "Quiz", desc: "Pon a prueba tu conocimiento", colors: [Color(red: 1, green: 0.36, blue: 0.54), Color(red: 1, green: 0.54, blue: 0.67)], destination: AnyView(CustomQuizView())),
        GameDef(id: "roulette", icon: "arrow.triangle.2.clockwise.rotate.90", name: "Ruleta", desc: "Gira por un reto o premio", colors: [Color(red: 0.06, green: 0.73, blue: 0.51), Color(red: 0.2, green: 0.83, blue: 0.6)], destination: AnyView(RouletteView())),
        GameDef(id: "hangman", icon: "person.fill.questionmark", name: "Ahorcado", desc: "Adivina palabras de amor", colors: [Color(red: 0.94, green: 0.33, blue: 0.31), Color(red: 0.94, green: 0.6, blue: 0.6)], destination: AnyView(HangmanView())),
        GameDef(id: "dice", icon: "dice.fill", name: "Dados", desc: "Accion y parte del cuerpo", colors: [Color(red: 0.93, green: 0.28, blue: 0.6), Color(red: 0.96, green: 0.25, blue: 0.37)], destination: AnyView(DiceView())),
        GameDef(id: "prefer", icon: "questionmark.bubble.fill", name: "Que Prefieres", desc: "Elige tu dilema amoroso", colors: [Color(red: 0.23, green: 0.51, blue: 0.96), Color(red: 0.02, green: 0.71, blue: 0.83)], destination: AnyView(WouldYouRatherView())),
        GameDef(id: "never", icon: "wineglass.fill", name: "Yo Nunca Nunca", desc: "Revela tus secretos", colors: [Color(red: 0.96, green: 0.62, blue: 0.04), Color(red: 0.98, green: 0.73, blue: 0.14)], destination: AnyView(NeverHaveIEverView())),
        GameDef(id: "truth_dare", icon: "heart.fill", name: "Verdad o Reto", desc: "Respuestas y desafios", colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.77, green: 0.71, blue: 0.99)], destination: AnyView(TruthOrDareCustomView())),
        GameDef(id: "love_game", icon: "heart.square.fill", name: "El Amor", desc: "Cartas del corazon", colors: [Color(red: 0.9, green: 0.2, blue: 0.4), Color(red: 1, green: 0.4, blue: 0.6)], destination: AnyView(LoveGameView())),
        GameDef(id: "compatibility", icon: "chart.pie.fill", name: "Compatibilidad", desc: "Que tanto se conocen", colors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.4, green: 0.8, blue: 1)], destination: AnyView(CompatibilityView())),
        GameDef(id: "spicy", icon: "flame.fill", name: "Zona Picante", desc: "Envia retos online a tu pareja", colors: [Color(red: 1, green: 0.44, blue: 0), Color(red: 1, green: 0.24, blue: 0)], destination: AnyView(SpicyGamesView())),
        GameDef(id: "history", icon: "clock.arrow.circlepath", name: "Historial", desc: "Partidas y estadisticas", colors: [Color(red: 0.45, green: 0.3, blue: 0.9), Color(red: 0.65, green: 0.45, blue: 1)], destination: AnyView(GameHistoryView())),
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(games) { game in
                            NavigationLink(destination: game.destination) {
                                GameCardView(game: game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Juegos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
            }
        }
    }
}

private struct GameCardView: View {
    let game: GamesView.GameDef
    @ObservedObject private var theme = ThemeManager.shared
    @State private var itemCount: Int = 0

    private let db = Firestore.firestore()
    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: game.icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Circle().fill(.ultraThinMaterial).opacity(0.3))

            Text(game.name)
                .appFont(size: 16, weight: .bold)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(game.desc)
                .appFont(size: 11, weight: .regular)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if itemCount > 0 {
                Text("\(itemCount) preguntas")
                    .appFont(size: 10, weight: .semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial).opacity(0.4))
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(
            LinearGradient(colors: game.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: game.colors[0].opacity(0.3), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .onAppear { loadCount() }
    }

    private func loadCount() {
        if game.id == "collections" {
            let ref = db.collection("parejas").document(coupleId).collection("colecciones")
            ref.getDocuments { snapshot, _ in
                itemCount = snapshot?.documents.count ?? 0
            }
        } else {
            let ref = db.collection("parejas").document(coupleId).collection("juegos").document(game.id).collection("items")
            ref.getDocuments { snapshot, _ in
                itemCount = snapshot?.documents.count ?? 0
            }
        }
    }
}
