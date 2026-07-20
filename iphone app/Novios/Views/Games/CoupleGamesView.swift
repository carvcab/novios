import SwiftUI

private struct GameEntry: Identifiable {
    let id: GameType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

private let allGames: [GameEntry] = [
    GameEntry(id: .quiz, title: "Quiz", subtitle: "Trivia de pareja", icon: "questionmark.bubble", color: .blue),
    GameEntry(id: .truthOrDare, title: "Verdad o Reto", subtitle: "Truth or Dare", icon: "flame.fill", color: .orange),
    GameEntry(id: .memorama, title: "Memorama", subtitle: "Memory matching", icon: "square.grid.3x3.fill", color: .purple),
    GameEntry(id: .tictactoe, title: "Tres en Raya", subtitle: "Tic-Tac-Toe", icon: "grid.3x3", color: .cyan),
    GameEntry(id: .rps, title: "Piedra Papel Tijera", subtitle: "RPS", icon: "hand.raised.fill", color: .yellow),
    GameEntry(id: .hangman, title: "Ahorcado", subtitle: "Hangman love words", icon: "character.bubble", color: .green),
    GameEntry(id: .loveDice, title: "Dados del Amor", subtitle: "Love Dice", icon: "dice.fill", color: .pink),
    GameEntry(id: .higherCard, title: "Carta Mayor", subtitle: "Higher Card", icon: "rectangle.on.rectangle", color: .indigo),
    GameEntry(id: .wouldYouRather, title: "Que Prefieres?", subtitle: "Would You Rather", icon: "questionmark", color: .mint),
    GameEntry(id: .loveRoulette, title: "Ruleta del Amor", subtitle: "Love Roulette", icon: "arrow.triangle.2.circlepath", color: .red),
    GameEntry(id: .neverHaveIEver, title: "Yo Nunca Nunca", subtitle: "Never Have I Ever", icon: "wineglass", color: .teal),
    GameEntry(id: .spicy, title: "Picante", subtitle: "Spicy Zone", icon: "flame.fill", color: ThemeManager.shared.primaryPink),
]

private let sampleSessions: [GameSession] = [
    GameSession(id: "s1", type: .truthOrDare, state: .playing, myScore: 3, partnerScore: 2, currentTurn: "me", data: [:]),
    GameSession(id: "s2", type: .quiz, state: .waiting, myScore: 0, partnerScore: 0, currentTurn: "partner", data: [:]),
]

public struct CoupleGamesView: View {
    @State private var activeSessions: [GameSession] = sampleSessions
    @State private var showGamePicker = false
    @State private var selectedGame: GameEntry? = nil
    @State private var selectedMode: String? = nil
    @State private var navigateToGame = false

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if !activeSessions.isEmpty {
                            activeGamesBar
                        }

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            ForEach(allGames) { game in
                                Button {
                                    selectedGame = game
                                    showGamePicker = true
                                } label: {
                                    GameCardView(entry: game)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Juegos de Pareja")
            .sheet(isPresented: $showGamePicker) {
                if let game = selectedGame {
                    GameModeSheet(game: game, selectedMode: $selectedMode, navigateToGame: $navigateToGame, dismiss: { showGamePicker = false })
                        .presentationDetents([.height(240)])
                }
            }
            .background(
                NavigationLink(destination: destinationView, isActive: $navigateToGame) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        if let mode = selectedMode, let game = selectedGame {
            switch game.id {
            case .truthOrDare:
                TruthOrDareView()
            default:
                PlaceholderGameView(gameName: game.title, mode: mode)
            }
        } else {
            EmptyView()
        }
    }

    private var activeGamesBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green)
                Text("PARTIDAS ACTIVAS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(ThemeManager.shared.textSecondary)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activeSessions) { session in
                        GlassCard {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.type.rawValue.capitalized)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(session.state == .playing ? Color.green : Color.orange)
                                            .frame(width: 6, height: 6)
                                        Text(session.state == .playing ? "En vivo" : "Esperando")
                                            .font(.system(size: 11))
                                            .foregroundColor(ThemeManager.shared.textSecondary)
                                    }
                                    Text("\(session.myScore) - \(session.partnerScore)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                }
                                Button {
                                    selectedGame = allGames.first(where: { $0.id == session.type })
                                    selectedMode = "online"
                                    navigateToGame = true
                                } label: {
                                    Text("Jugar")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(ThemeManager.shared.neonGlowGradient)
                                        .cornerRadius(14)
                                }
                            }
                        }
                        .frame(width: 200)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct GameCardView: View {
    let entry: GameEntry

    var body: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: entry.icon)
                    .font(.system(size: 32))
                    .foregroundColor(entry.color)
                    .frame(height: 40)

                Text(entry.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(entry.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(ThemeManager.shared.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}

private struct GameModeSheet: View {
    let game: GameEntry
    @Binding var selectedMode: String?
    @Binding var navigateToGame: Bool
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: game.icon)
                    .font(.system(size: 36))
                    .foregroundColor(game.color)

                Text(game.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                VStack(spacing: 12) {
                    Button {
                        selectedMode = "online"
                        navigateToGame = true
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Jugar Online con mi pareja")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(16)
                    }

                    Button {
                        selectedMode = "local"
                        navigateToGame = true
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "iphone")
                            Text("Jugar en este mismo celular")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

private struct PlaceholderGameView: View {
    let gameName: String
    let mode: String

    var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(gameName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                Text("Modo: \(mode == "online" ? "Online" : "Local")")
                    .font(.system(size: 16))
                    .foregroundColor(ThemeManager.shared.textSecondary)
            }
        }
        .navigationTitle(gameName)
    }
}
