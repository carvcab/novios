import SwiftUI

public struct StatsView: View {
    @State private var daysTogether: Int = 587
    @State private var messageCount: Int = 847
    @State private var photoCount: Int = 234
    @State private var letterCount: Int = 56
    @State private var lovePoints: Int = 720
    @State private var totalLovePoints: Int = 1000
    @State private var currentLevel: Int = 7
    @State private var currentStreak: Int = 12
    @State private var bestStreak: Int = 45
    @State private var compatibilityScore: Int = 87
    @State private var activities: [(icon: String, text: String, date: String)] = [
        ("message.fill", "Enviaron 847 mensajes", "Hasta hoy"),
        ("photo.fill", "Subieron 234 fotos juntos", "Hasta hoy"),
        ("envelope.fill", "Escribieron 56 cartas", "Hasta hoy"),
        ("heart.fill", "Nivel 7 alcanzado", "Hace 3 d\u{00ED}as"),
        ("flame.fill", "Racha de 12 d\u{00ED}as", "Hace 1 d\u{00ED}a"),
        ("star.fill", "87% de compatibilidad", "Hace 1 semana")
    ]

    private let anniversaryDate: Date = {
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 10
        return Calendar.current.date(from: components) ?? Date()
    }()

    private var totalDays: Int {
        Calendar.current.dateComponents([.day], from: anniversaryDate, to: Date()).day ?? daysTogether
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    statsGrid
                    lovePointsSection
                    streakSection
                    activityTimeline
                    compatibilitySection
                    Color.clear.frame(height: 24)
                }
                .padding(.top, 8)
            }
            .background(ThemeManager.shared.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Estad\u{00ED}sticas")
        }
    }

    private var headerSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundColor(ThemeManager.shared.primaryPink)
                    .shadow(color: ThemeManager.shared.primaryPink.opacity(0.4), radius: 12)

                Text("Estad\u{00ED}sticas de la Relaci\u{00F3}n")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("Todo sobre nuestro amor en n\u{00FA}meros")
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.6))
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(value: "\(totalDays)", label: "D\u{00ED}as juntos", icon: "calendar", color: ThemeManager.shared.primaryPink)
            StatCardView(value: "\(messageCount)", label: "Mensajes", icon: "message.fill", color: Color(red: 0.49, green: 0.51, blue: 1.0))
            StatCardView(value: "\(photoCount)", label: "Fotos", icon: "photo.fill", color: Color(red: 1.0, green: 0.72, blue: 0.3))
            StatCardView(value: "\(letterCount)", label: "Cartas", icon: "envelope.fill", color: Color(red: 0.61, green: 0.78, blue: 0.42))
        }
        .padding(.horizontal, 16)
    }

    private var lovePointsSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Puntos de Amor")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                ZStack {
                    Circle()
                        .stroke(ThemeManager.shared.primaryPink.opacity(0.15), lineWidth: 12)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: CGFloat(lovePoints) / CGFloat(totalLovePoints))
                        .stroke(ThemeManager.shared.neonGlowGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: lovePoints)

                    VStack(spacing: 2) {
                        Text("\(lovePoints)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Nivel \(currentLevel)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }

                Text("\(lovePoints) / \(totalLovePoints) puntos para el siguiente nivel")
                    .font(.system(size: 12))
                    .foregroundColor(.primary.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
    }

    private var streakSection: some View {
        GlassCard {
            HStack(spacing: 24) {
                VStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                    Text("\(currentStreak)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Racha actual")
                        .font(.system(size: 11))
                        .foregroundColor(.primary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)
                    Text("\(bestStreak)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Mejor racha")
                        .font(.system(size: 11))
                        .foregroundColor(.primary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
    }

    private var activityTimeline: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(ThemeManager.shared.primaryPink)
                Text("Actividad Reciente")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)

            GlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(activities.enumerated()), id: \.offset) { index, activity in
                        HStack(spacing: 14) {
                            Image(systemName: activity.icon)
                                .font(.system(size: 16))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                                .frame(width: 32, height: 32)
                                .background(ThemeManager.shared.primaryPink.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.text)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(activity.date)
                                    .font(.system(size: 11))
                                    .foregroundColor(.primary.opacity(0.5))
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                        if index < activities.count - 1 {
                            Divider()
                                .background(ThemeManager.shared.primaryPink.opacity(0.1))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var compatibilitySection: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Compatibilidad")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                ZStack {
                    Circle()
                        .stroke(ThemeManager.shared.primaryPink.opacity(0.15), lineWidth: 10)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(compatibilityScore) / 100)
                        .stroke(ThemeManager.shared.neonGlowGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: compatibilityScore)

                    Text("\(compatibilityScore)%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                }

                Text("Resultado del test de compatibilidad")
                    .font(.system(size: 12))
                    .foregroundColor(.primary.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
    }
}
