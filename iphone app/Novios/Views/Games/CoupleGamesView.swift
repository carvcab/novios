import SwiftUI

private struct ActiveGame: Identifiable {
    let id: String
    let type: String
    let status: String
    let sender: String
    let isSender: Bool
    let gameLabel: String
}

private struct GameCard: Identifiable {
    let id: String
    let type: String
    let icon: String
    let name: String
    let desc: String
    let gradient: LinearGradient
}

private let partnerName = "Pareja"

private let sampleActiveGames: [ActiveGame] = [
    ActiveGame(id: "ag1", type: "quiz", status: "pending", sender: "Yo", isSender: true, gameLabel: "Quiz"),
    ActiveGame(id: "ag2", type: "truth_dare", status: "pending", sender: "Pareja", isSender: false, gameLabel: "Verdad o Reto"),
    ActiveGame(id: "ag3", type: "memorama", status: "active", sender: "Yo", isSender: true, gameLabel: "Memorama"),
]

private let gameCards: [GameCard] = [
    GameCard(id: "quiz", type: "quiz", icon: "questionmark.bubble.fill", name: "Quiz", desc: "Pon a prueba tu conocimiento",
        gradient: LinearGradient(colors: [Color(red: 1.0, green: 0.361, blue: 0.541), Color(red: 1.0, green: 0.541, blue: 0.671)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "truth_dare", type: "truth_dare", icon: "heart.fill", name: "Verdad o Reto", desc: "Respuestas y desafíos",
        gradient: LinearGradient(colors: [Color(red: 0.655, green: 0.545, blue: 0.98), Color(red: 0.769, green: 0.71, blue: 0.992)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "memorama", type: "memorama", icon: "puzzlepiece.fill", name: "Memorama", desc: "Encuentra las parejas",
        gradient: LinearGradient(colors: [Color(red: 1.0, green: 0.718, blue: 0.302), Color(red: 1.0, green: 0.835, blue: 0.31)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "tictactoe", type: "tictactoe", icon: "grid.3x3", name: "Tres en Raya", desc: "Juego clásico por turnos",
        gradient: LinearGradient(colors: [Color(red: 0.4, green: 0.733, blue: 0.416), Color(red: 0.647, green: 0.839, blue: 0.655)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "rps", type: "rps", icon: "hand.raised.fill", name: "Piedra Papel Tijera", desc: "Prueba tu suerte",
        gradient: LinearGradient(colors: [Color(red: 0.259, green: 0.647, blue: 0.961), Color(red: 0.565, green: 0.792, blue: 0.976)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "hangman", type: "hangman", icon: "person.fill.questionmark", name: "Ahorcado", desc: "Adivina palabras de amor",
        gradient: LinearGradient(colors: [Color(red: 0.937, green: 0.325, blue: 0.314), Color(red: 0.937, green: 0.604, blue: 0.604)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "dice", type: "dice", icon: "dice.fill", name: "Dados del Amor", desc: "Acción y parte del cuerpo 🎲",
        gradient: LinearGradient(colors: [Color(red: 0.925, green: 0.282, blue: 0.6), Color(red: 0.957, green: 0.247, blue: 0.369)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "cards", type: "cards", icon: "rectangle.on.rectangle", name: "Carta Mayor", desc: "La carta más alta manda 🃏",
        gradient: LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965), Color(red: 0.851, green: 0.275, blue: 0.937)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "prefer", type: "prefer", icon: "questionmark", name: "¿Qué Prefieres?", desc: "Elige tu dilema amoroso 🤔",
        gradient: LinearGradient(colors: [Color(red: 0.231, green: 0.51, blue: 0.965), Color(red: 0.024, green: 0.714, blue: 0.831)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "roulette", type: "roulette", icon: "arrow.triangle.2.circlepath", name: "Ruleta del Amor", desc: "Gira por un reto o premio 🎡",
        gradient: LinearGradient(colors: [Color(red: 0.063, green: 0.725, blue: 0.506), Color(red: 0.204, green: 0.827, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "never", type: "never", icon: "wineglass", name: "Yo Nunca Nunca", desc: "Revela tus secretos 🍷",
        gradient: LinearGradient(colors: [Color(red: 0.961, green: 0.62, blue: 0.043), Color(red: 0.984, green: 0.749, blue: 0.141)], startPoint: .topLeading, endPoint: .bottomTrailing)),
    GameCard(id: "spicy", type: "spicy", icon: "flame.fill", name: "Picante", desc: "Verdad, reto y más 🔥",
        gradient: LinearGradient(colors: [Color(red: 1.0, green: 0.361, blue: 0.541), Color(red: 1.0, green: 0.541, blue: 0.671)], startPoint: .topLeading, endPoint: .bottomTrailing)),
]

private func gameLabel(for type: String) -> String {
    switch type {
    case "quiz": return "Quiz"
    case "truth_dare": return "Verdad o Reto"
    case "memorama": return "Memorama"
    case "tictactoe": return "Tres en Raya"
    case "rps": return "Piedra Papel Tijera"
    case "hangman": return "Ahorcado"
    case "dice": return "Dados del Amor"
    case "cards": return "Carta Mayor"
    case "prefer": return "Que Prefieres?"
    case "roulette": return "Ruleta del Amor"
    case "never": return "Yo Nunca Nunca"
    default: return type
    }
}

private func gameType(for type: String) -> GameType {
    switch type {
    case "quiz": return .quiz
    case "truth_dare": return .truthOrDare
    case "memorama": return .memorama
    case "tictactoe": return .tictactoe
    case "rps": return .rps
    case "hangman": return .hangman
    case "dice": return .loveDice
    case "cards": return .higherCard
    case "prefer": return .wouldYouRather
    case "roulette": return .loveRoulette
    case "never": return .neverHaveIEver
    case "spicy": return .spicy
    default: return .quiz
    }
}

private func gameTypeString(_ type: GameType) -> String {
    switch type {
    case .quiz: return "quiz"
    case .truthOrDare: return "truth_dare"
    case .memorama: return "memorama"
    case .tictactoe: return "tictactoe"
    case .rps: return "rps"
    case .hangman: return "hangman"
    case .loveDice: return "dice"
    case .higherCard: return "cards"
    case .wouldYouRather: return "prefer"
    case .loveRoulette: return "roulette"
    case .neverHaveIEver: return "never"
    case .spicy: return "spicy"
    }
}

public struct CoupleGamesView: View {
    @State private var activeGames: [ActiveGame] = sampleActiveGames
    @State private var showSheet = false
    @State private var selectedGameCard: GameCard? = nil
    @State private var selectedMode: String? = nil
    @State private var navigateToGame = false
    @State private var snackbarMessage: String? = nil

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerView
                        if !activeGames.isEmpty {
                            activeGamesSection
                        }
                        gameCardsGrid
                    }
                    .padding(.vertical, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigateToHistory = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .sheet(isPresented: $showSheet) {
                if let card = selectedGameCard {
                    gameModeSheet(card: card)
                }
            }
            .background(
                NavigationLink(destination: destinationView, isActive: $navigateToGame) {
                    EmptyView()
                }
                .hidden()
            )
            .background(
                NavigationLink(destination: GameHistoryView(), isActive: $navigateToHistory) {
                    EmptyView()
                }
                .hidden()
            )
            .overlay(alignment: .bottom) {
                if let msg = snackbarMessage {
                    Text(msg)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.black.opacity(0.8)))
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { snackbarMessage = nil }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: snackbarMessage != nil)
        }
    }

    @State private var navigateToHistory = false

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 32))
                .foregroundColor(ThemeManager.shared.primaryPink)

            Text("Juegos de Pareja")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text("Diviértanse juntos online o en el mismo celular")
                .font(.system(size: 13))
                .foregroundColor(ThemeManager.shared.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Active Games Section

    private var activeGamesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeManager.shared.primaryPink)
                Text("Partidas en Tiempo Real")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ThemeManager.shared.primaryPink)
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 8) {
                ForEach(activeGames) { game in
                    activeGameCard(game)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func activeGameCard(_ game: ActiveGame) -> some View {
        if game.status == "pending" {
            if game.isSender {
                HStack {
                    ProgressView()
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Esperando a \(partnerName)...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Invitación para \(game.gameLabel)")
                            .font(.system(size: 12))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                    }

                    Spacer()

                    Button {
                        activeGames.removeAll { $0.id == game.id }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 18))
                        .foregroundColor(ThemeManager.shared.primaryPink)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("¡\(game.sender) te invitó!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Juego: \(game.gameLabel)")
                            .font(.system(size: 12))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Button {
                            // Accept - would update status to active
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        }

                        Button {
                            activeGames.removeAll { $0.id == game.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(12)
                .background(ThemeManager.shared.primaryPink.opacity(0.08))
                .cornerRadius(16)
            }
        } else if game.status == "active" {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(ThemeManager.shared.primaryPink)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Partida de \(game.gameLabel) activa")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Jugando con \(partnerName)")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                }

                Spacer()

                Button {
                    selectedMode = "online"
                    selectedGameCard = gameCards.first { $0.type == game.type }
                    navigateToGame = true
                } label: {
                    Text("Jugar")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(12)
                }

                Button {
                    activeGames.removeAll { $0.id == game.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }

    // MARK: - Game Cards Grid

    private var gameCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(gameCards) { card in
                Button {
                    selectedGameCard = card
                    showSheet = true
                } label: {
                    gameCardView(card)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func gameCardView(_ card: GameCard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(card.gradient)
                .shadow(color: ThemeManager.shared.primaryPink.opacity(0.25), radius: 12, x: 0, y: 6)

            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: card.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                Text(card.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(card.desc)
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .frame(minHeight: 140)
        .aspectRatio(0.9, contentMode: .fit)
    }

    // MARK: - Bottom Sheet

    private func gameModeSheet(card: GameCard) -> some View {
        VStack(spacing: 20) {
            Text("Jugar a \(card.name)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 8)

            VStack(spacing: 0) {
                Button {
                    showSheet = false
                    withAnimation {
                        snackbarMessage = "Invitación enviada a \(partnerName) 🎮"
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wifi")
                            .font(.system(size: 18))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jugar Online con mi pareja")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Envía una invitación en tiempo real a \(partnerName)")
                                .font(.system(size: 11))
                                .foregroundColor(ThemeManager.shared.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                }

                Divider()
                    .padding(.leading, 40)

                Button {
                    showSheet = false
                    selectedMode = "local"
                    navigateToGame = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Jugar en este mismo celular")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Pásense el teléfono por turnos")
                                .font(.system(size: 11))
                                .foregroundColor(ThemeManager.shared.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .presentationDetents([.height(220)])
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    private var destinationView: some View {
        if let mode = selectedMode, let card = selectedGameCard {
            if mode == "local" {
                localGameView(for: card.type)
            } else {
                PlaceholderGameView(gameName: card.name, mode: "online")
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func localGameView(for type: String) -> some View {
        switch type {
        case "quiz":
            QuizGameView()
        case "truth_dare":
            TruthOrDareView()
        case "memorama":
            MemoramaGameView()
        case "tictactoe":
            TicTacToeGameView()
        case "rps":
            RPSGameView()
        case "hangman":
            HangmanGameView()
        case "dice":
            LoveDiceView()
        case "cards":
            HigherCardView()
        case "prefer":
            WouldYouRatherView()
        case "roulette":
            LoveRouletteView()
        case "never":
            NeverHaveIEverView()
        case "spicy":
            SpicyGamesView()
        default:
            PlaceholderGameView(gameName: type, mode: "local")
        }
    }
}
