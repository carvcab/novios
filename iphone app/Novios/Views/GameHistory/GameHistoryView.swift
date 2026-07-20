import SwiftUI

public struct GameHistoryView: View {
    @State private var selectedTab = 0
    @State private var winProgress: CGFloat = 0

    private let tabs = ["Estadísticas", "Partidas"]

    private let sampleData: [GameHistoryEntry] = [
        GameHistoryEntry(id: "1", gameType: "Quiz", icon: "questionmark.circle.fill", color: "#FF6B9D", date: Date().addingTimeInterval(-86400 * 1), myScore: 8, partnerScore: 5, result: .win),
        GameHistoryEntry(id: "2", gameType: "Verdad o Reto", icon: "sparkles", color: "#A78BFA", date: Date().addingTimeInterval(-86400 * 2), myScore: 3, partnerScore: 3, result: .tie),
        GameHistoryEntry(id: "3", gameType: "Memorama", icon: "rectangle.3.group.fill", color: "#FBBF24", date: Date().addingTimeInterval(-86400 * 3), myScore: 12, partnerScore: 15, result: .lose),
        GameHistoryEntry(id: "4", gameType: "TicTacToe", icon: "grid", color: "#34D399", date: Date().addingTimeInterval(-86400 * 5), myScore: 1, partnerScore: 0, result: .win),
        GameHistoryEntry(id: "5", gameType: "Piedra Papel Tijeras", icon: "hand.raised.fill", color: "#F472B6", date: Date().addingTimeInterval(-86400 * 7), myScore: 5, partnerScore: 7, result: .lose),
        GameHistoryEntry(id: "6", gameType: "Ahorcado", icon: "person.fill.questionmark", color: "#60A5FA", date: Date().addingTimeInterval(-86400 * 10), myScore: 6, partnerScore: 6, result: .tie),
        GameHistoryEntry(id: "7", gameType: "Love Dice", icon: "dice.fill", color: "#FB923C", date: Date().addingTimeInterval(-86400 * 14), myScore: 10, partnerScore: 8, result: .win),
        GameHistoryEntry(id: "8", gameType: "Higher or Lower", icon: "arrow.up.arrow.down", color: "#A78BFA", date: Date().addingTimeInterval(-86400 * 20), myScore: 4, partnerScore: 6, result: .lose),
        GameHistoryEntry(id: "9", gameType: "Never Have I Ever", icon: "hand.point.up.fill", color: "#F59E0B", date: Date().addingTimeInterval(-86400 * 30), myScore: 7, partnerScore: 4, result: .win),
        GameHistoryEntry(id: "10", gameType: "¿Qué prefieres?", icon: "questionmark.diamond.fill", color: "#EC4899", date: Date().addingTimeInterval(-86400 * 45), myScore: 2, partnerScore: 2, result: .tie),
    ]

    private var totalGames: Int { sampleData.count }
    private var wins: Int { sampleData.filter { $0.result == .win }.count }
    private var losses: Int { sampleData.filter { $0.result == .lose }.count }
    private var ties: Int { sampleData.filter { $0.result == .tie }.count }
    private var winRate: CGFloat { totalGames > 0 ? CGFloat(wins) / CGFloat(totalGames) : 0 }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        ForEach(0..<tabs.count, id: \.self) { i in
                            Text(tabs[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        if selectedTab == 0 {
                            estadisticasTab
                        } else {
                            partidasTab
                        }
                    }
                }
            }
            .navigationTitle("Historial")
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    winProgress = winRate
                }
            }
        }
    }

    // MARK: - Estadísticas Tab

    private var estadisticasTab: some View {
        VStack(spacing: 16) {
            vsHeaderCard
            statsGrid
            perGameBreakdown
            Color.clear.frame(height: 24)
        }
        .padding(.top, 4)
    }

    private var vsHeaderCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Tú")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(wins) - \(losses)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Pareja")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primary.opacity(0.12))
                            .frame(height: 14)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [ThemeManager.shared.primaryPink, ThemeManager.shared.primaryPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * winProgress, height: 14)
                    }
                }
                .frame(height: 14)

                Text(winRate >= 0.5 ? "¡Vas ganando! 🔥" : winRate == 0.5 ? "Están empatados 🤝" : "Van perdiendo 💪")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(value: "\(totalGames)", label: "Partidas jugadas", icon: "gamecontroller", color: ThemeManager.shared.primaryPurple)
            StatCardView(value: "\(wins)", label: "Victorias", icon: "trophy", color: Color(red: 1.0, green: 0.72, blue: 0.3))
            StatCardView(value: "\(losses)", label: "Derrotas", icon: "hand.thumbsdown", color: Color(red: 1.0, green: 0.32, blue: 0.32))
            StatCardView(value: "\(ties)", label: "Empates", icon: "hand.raised", color: Color(red: 0.49, green: 0.51, blue: 1.0))
        }
        .padding(.horizontal, 20)
    }

    private var perGameBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Por juego")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gameTypeStats, id: \.name) { stat in
                        GameTypeMiniCard(stat: stat)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var gameTypeStats: [(name: String, icon: String, color: Color, wins: Int, losses: Int)] {
        let grouped = Dictionary(grouping: sampleData) { $0.gameType }
        return grouped.map { name, entries in
            let first = entries.first!
            let w = entries.filter { $0.result == .win }.count
            let l = entries.filter { $0.result == .lose }.count
            return (name: name, icon: first.icon, color: colorFromHex(first.color), wins: w, losses: l)
        }
        .sorted { $0.wins + $0.losses > $1.wins + $1.losses }
    }

    // MARK: - Partidas Tab

    private var partidasTab: some View {
        LazyVStack(spacing: 12) {
            ForEach(sampleData) { entry in
                GlassCard {
                    HStack(spacing: 14) {
                        Image(systemName: entry.icon)
                            .font(.system(size: 28))
                            .foregroundColor(colorFromHex(entry.color))
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.gameType)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(formattedDate(entry.date))
                                .font(.system(size: 12))
                                .foregroundColor(.primary.opacity(0.45))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Tú \(entry.myScore) - \(entry.partnerScore) Pareja")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Text(entry.winner)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(resultColor(entry.result))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Color.clear.frame(height: 24)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: date)
    }

    private func resultColor(_ result: GameResult) -> Color {
        switch result {
        case .win: return Color(red: 0.3, green: 0.85, blue: 0.39)
        case .lose: return Color(red: 1.0, green: 0.32, blue: 0.32)
        case .tie: return Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }

    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Subviews

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

public struct GameTypeMiniCard: View {
    public let stat: (name: String, icon: String, color: Color, wins: Int, losses: Int)

    public var body: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: stat.icon)
                    .font(.system(size: 22))
                    .foregroundColor(stat.color)

                Text(stat.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Text("\(stat.wins)G")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.3, green: 0.85, blue: 0.39))
                    }
                    HStack(spacing: 3) {
                        Text("\(stat.losses)P")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.32, blue: 0.32))
                    }
                }
            }
            .frame(width: 90)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
        }
    }
}
