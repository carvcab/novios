import SwiftUI

public struct LoveView: View {
    @StateObject private var coupleService = CoupleService.shared
    @State private var activeTab: LoveFeature? = nil

    enum LoveFeature: String, CaseIterable, Identifiable {
        case letters = "Cartas de Amor"
        case memories = "Recuerdos"
        case games = "Juegos"
        case journal = "Diario Compartido"
        case music = "Música"
        case goals = "Metas y Logros"
        case dates = "Ideas de Citas"
        case todo = "Lista de Pendientes"
        case capsule = "Cápsula del Tiempo"
        case stats = "Estadísticas"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .letters: return "envelope.fill"
            case .memories: return "photo.on.rectangle.angled"
            case .games: return "gamecontroller.fill"
            case .journal: return "book.closed.fill"
            case .music: return "music.note.list"
            case .goals: return "star.fill"
            case .dates: return "heart.text.square.fill"
            case .todo: return "checkmark.square.fill"
            case .capsule: return "hourglass"
            case .stats: return "chart.bar.fill"
            }
        }

        var color: Color {
            switch self {
            case .letters: return Color(red: 0.95, green: 0.45, blue: 0.65)
            case .memories: return Color(red: 0.85, green: 0.55, blue: 0.85)
            case .games: return Color(red: 0.98, green: 0.65, blue: 0.45)
            case .journal: return Color(red: 0.45, green: 0.75, blue: 0.95)
            case .music: return Color(red: 0.95, green: 0.75, blue: 0.45)
            case .goals: return Color(red: 0.55, green: 0.85, blue: 0.65)
            case .dates: return Color(red: 0.95, green: 0.50, blue: 0.50)
            case .todo: return Color(red: 0.65, green: 0.65, blue: 0.95)
            case .capsule: return Color(red: 0.85, green: 0.70, blue: 0.95)
            case .stats: return Color(red: 0.95, green: 0.60, blue: 0.75)
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Banner
                        headerBanner

                        // Features Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(LoveFeature.allCases) { feature in
                                Button {
                                    activeTab = feature
                                } label: {
                                    featureCard(feature)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Nuestro Amor 💖")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $activeTab) { feature in
                switch feature {
                case .letters: LettersView()
                case .memories: MemoriesView()
                case .games: GamesView()
                case .journal: JournalView()
                case .music: MusicView()
                case .goals: GoalsView()
                case .dates: DateIdeasView()
                case .todo: TodoView()
                case .capsule: CapsulesView()
                case .stats: StatsView()
                }
            }
            .task {
                await coupleService.refreshSubcollections()
            }
        }
    }

    private var headerBanner: some View {
        VStack(spacing: 6) {
            Text("Diego  💞  Yosmari")
                .appFont(size: 22, weight: .bold)
                .foregroundColor(ThemeManager.shared.primaryPink)
            Text("Nuestro espacio privado de amor")
                .appFont(size: 13, weight: .light)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func featureCard(_ feature: LoveFeature) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .appFont(size: 20, weight: .semibold)
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .appFont(size: 15, weight: .semibold)
                    .foregroundColor(.primary)
                Text(subtitleFor(feature))
                    .appFont(size: 11)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(feature.color.opacity(0.3), lineWidth: 0.8))
        .shadow(color: feature.color.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    private func subtitleFor(_ feature: LoveFeature) -> String {
        switch feature {
        case .letters: return "\(coupleService.cartas.count) cartas"
        case .memories: return "\(coupleService.recuerdos.count) momentos"
        case .games: return "Preguntas y retos"
        case .journal: return "\(coupleService.diarioEntries.count) entradas"
        case .music: return "\(coupleService.musica.count) canciones"
        case .goals: return "\(coupleService.logros.count) logros"
        case .dates: return "\(coupleService.citas.count) planes"
        case .todo: return "\(coupleService.todoItems.count) pendientes"
        case .capsule: return "\(coupleService.capsulas.count) cápsulas"
        case .stats: return "Días e hitos"
        }
    }
}
