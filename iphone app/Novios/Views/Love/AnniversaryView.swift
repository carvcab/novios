import SwiftUI

public struct AnniversaryView: View {
    @State private var daysSince = 0
    @State private var nextAnniversary = 0
    @State private var totalDays = 0

    private var anniversaryDate: Date {
        if let saved = UserDefaults.standard.string(forKey: "anniversary_date") {
            let f = ISO8601DateFormatter()
            if let date = f.date(from: saved) { return date }
            let f2 = DateFormatter()
            f2.dateFormat = "yyyy-MM-dd"
            if let date = f2.date(from: saved) { return date }
        }
        return Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 10)) ?? Date()
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        Image(systemName: "heart.fill").font(.system(size: 64)).foregroundColor(ThemeManager.shared.primaryPink)
                            .padding(30).background(Circle().fill(ThemeManager.shared.primaryPink.opacity(0.12)))

                        Text("Aniversario").font(.system(size: 28, weight: .bold)).foregroundColor(.primary)

                        GlassCard {
                            VStack(spacing: 12) {
                                Text("\(totalDays) días juntos").font(.system(size: 22, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                                Text("Desde el \(formatDate(anniversaryDate))").font(.system(size: 14)).foregroundColor(.primary.opacity(0.6))
                                Divider()
                                if nextAnniversary == 0 {
                                    Text("🎉 ¡Hoy es nuestro aniversario!").font(.system(size: 16, weight: .bold)).foregroundColor(.green)
                                } else {
                                    Text("Próximo aniversario: \(nextAnniversary) días").font(.system(size: 14)).foregroundColor(.primary.opacity(0.6))
                                }
                            }.padding(20)
                        }.padding(.horizontal, 20)

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            statCard(value: "\(totalDays)", label: "Días", icon: "calendar")
                            statCard(value: "\(totalDays / 365)", label: "Años", icon: "star.fill")
                            statCard(value: "\((totalDays % 365) / 30)", label: "Meses", icon: "moon.fill")
                            statCard(value: "\(totalDays % 30)", label: "Días extra", icon: "sparkles")
                        }.padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Aniversario")
        }
        .onAppear { calculate() }
    }

    private func calculate() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let start = cal.startOfDay(for: anniversaryDate)
        totalDays = cal.dateComponents([.day], from: start, to: today).day ?? 0

        var next = cal.date(bySetting: .month, value: cal.component(.month, from: anniversaryDate), of: today)!
        next = cal.date(bySetting: .day, value: cal.component(.day, from: anniversaryDate), of: next)!
        if next < today { next = cal.date(byAdding: .year, value: 1, to: next)! }
        nextAnniversary = cal.dateComponents([.day], from: today, to: next).day ?? 0
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(ThemeManager.shared.primaryPink)
                Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(.primary)
                Text(label).font(.system(size: 11)).foregroundColor(.primary.opacity(0.5))
            }.padding(.vertical, 12).frame(maxWidth: .infinity)
        }
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long; f.locale = Locale(identifier: "es_MX")
        return f.string(from: d)
    }
}
