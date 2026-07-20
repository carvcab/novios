import SwiftUI

public struct LoveView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Anniversary Hero
                        GlassCard {
                            NavigationLink(destination: AnniversaryView()) {
                                VStack(spacing: 16) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(ThemeManager.shared.neonGlowGradient)
                                                .frame(width: 56, height: 56)
                                                .shadow(color: ThemeManager.shared.primaryPink.opacity(0.3), radius: 16)
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 26))
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(authService.currentUser?.displayName ?? "Tu")  💕  \(userService.partnerUser?.displayName ?? "Pareja")")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                            Text("Juntos desde el \(formattedFirstDate())")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    if let ann = authService.currentUser?.anniversaryDate {
                                        let days = Calendar.current.dateComponents([.day], from: ann, to: Date()).day ?? 0
                                        let years = days / 365
                                        let months = (days % 365) / 30
                                        let remDays = days % 30
                                        VStack(spacing: 4) {
                                            Text("\(years) años  \(months) meses  \(remDays) días")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(ThemeManager.shared.primaryPink)
                                            Text(nextAnniversaryText(ann))
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(ThemeManager.shared.primaryPink.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding(20)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        // Quick Stats
                        if let ann = authService.currentUser?.anniversaryDate {
                            let days = Calendar.current.dateComponents([.day], from: ann, to: Date()).day ?? 0
                            let hours = Calendar.current.dateComponents([.hour], from: ann, to: Date()).hour ?? 0
                            let minutes = Calendar.current.dateComponents([.minute], from: ann, to: Date()).minute ?? 0
                            HStack(spacing: 8) {
                                StatMiniView(icon: "calendar", value: "\(days)", label: "días", color: ThemeManager.shared.primaryPink)
                                StatMiniView(icon: "clock", value: "\(hours)", label: "horas", color: Color(red: 0.49, green: 0.51, blue: 1.0))
                                StatMiniView(icon: "timer", value: "\(minutes)", label: "minutos", color: Color(red: 1.0, green: 0.72, blue: 0.3))
                            }
                            .padding(.horizontal, 16)
                        }

                        // Timeline
                        HStack(spacing: 8) {
                            Image(systemName: "timeline.selection")
                                .foregroundColor(ThemeManager.shared.primaryPink)
                            Text("Nuestra Historia")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        GlassCard {
                            VStack(spacing: 16) {
                                Image(systemName: "timeline.selection")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("Aún no hay momentos en su historia")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                        .padding(.horizontal, 16)

                        // Love Points
                        GlassCard {
                            HStack {
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text("\(Int.random(in: 100...999)) puntos de amor")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, 16)

                        Color.clear.frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func formattedFirstDate() -> String {
        guard let ann = authService.currentUser?.anniversaryDate else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yyyy"
        return formatter.string(from: ann)
    }

    private func nextAnniversaryText(_ ann: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        var next = calendar.date(bySetting: .month, value: calendar.component(.month, from: ann), of: now)!
        next = calendar.date(bySetting: .day, value: calendar.component(.day, from: ann), of: next)!
        if next < now {
            next = calendar.date(byAdding: .year, value: 1, to: next)!
        }
        let diff = calendar.dateComponents([.day], from: now, to: next).day ?? 0
        if diff == 0 { return "🎉 ¡Hoy es su aniversario!" }
        if diff == 1 { return "Mañana es su aniversario 💕" }
        return "Próximo aniversario: \(diff) días"
    }
}

public struct StatMiniView: View {
    public let icon: String
    public let value: String
    public let label: String
    public let color: Color

    public var body: some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
        }
    }
}
