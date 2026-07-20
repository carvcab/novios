import SwiftUI

public struct GameHistoryView: View {
    @State private var filter: FilterOption = .all

    public enum FilterOption: String, CaseIterable {
        case all = "Todos"
        case won = "Ganados"
        case lost = "Perdidos"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Stats summary
                        HStack(spacing: 10) {
                            StatCardView(value: "\(games.count)", label: "Jugados", icon: "gamecontroller.fill", color: ThemeManager.shared.primaryPink)
                            StatCardView(value: "\(games.filter { $0.winner == "Ganó: Tú" }.count)", label: "Ganados", icon: "trophy.fill", color: Color(red: 1.0, green: 0.72, blue: 0.3))
                            StatCardView(value: "\(games.filter { $0.winner == "Empate" }.count)", label: "Empates", icon: "hand.raised.fill", color: Color(red: 0.49, green: 0.51, blue: 1.0))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Filter buttons
                        HStack(spacing: 10) {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Button(action: { filter = option }) {
                                    Text(option.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(filter == option ? .white : .primary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(filter == option ? ThemeManager.shared.primaryPink : Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Game list
                        ForEach(filteredGames, id: \.title) { game in
                            GlassCard {
                                HStack(spacing: 14) {
                                    Text(game.emoji)
                                        .font(.system(size: 32))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(game.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(game.date)
                                            .font(.system(size: 12))
                                            .foregroundColor(.primary.opacity(0.4))
                                        HStack(spacing: 4) {
                                            Image(systemName: game.winner == "Ganó: Tú" ? "trophy.fill" : game.winner == "Empate" ? "hand.raised.fill" : "hand.thumbsdown.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(game.winner == "Ganó: Tú" ? Color(red: 1.0, green: 0.72, blue: 0.3) : game.winner == "Empate" ? Color(red: 0.49, green: 0.51, blue: 1.0) : .primary.opacity(0.4))
                                            Text(game.winner)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(game.winner == "Ganó: Tú" ? Color(red: 1.0, green: 0.72, blue: 0.3) : game.winner == "Empate" ? Color(red: 0.49, green: 0.51, blue: 1.0) : .primary.opacity(0.5))
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 16)
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Historial")
        }
    }

    private var filteredGames: [(emoji: String, title: String, date: String, winner: String)] {
        switch filter {
        case .all: return games
        case .won: return games.filter { $0.winner == "Ganó: Tú" }
        case .lost: return games.filter { $0.winner == "Ganó: Pareja" }
        }
    }

    private let games: [(emoji: String, title: String, date: String, winner: String)] = [
        ("🎯", "Verdad o Reto", "15 Jul 2026", "Ganó: Tú"),
        ("🧩", "Preguntas", "10 Jul 2026", "Ganó: Pareja"),
        ("🎲", "Dados", "05 Jul 2026", "Empate")
    ]
}

public struct StatCardView: View {
    public let value: String
    public let label: String
    public let icon: String
    public let color: Color

    public var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.primary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
        }
    }
}
