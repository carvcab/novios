import SwiftUI

public struct ImportantDatesView: View {
    @State private var dates: [(title: String, date: Date, icon: String, color: Color, repeats: Bool)] = []
    @State private var showAdd = false
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var newIcon = "heart.fill"

    private let defaults = UserDefaults.standard

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if dates.isEmpty {
                            emptyState
                        } else {
                            ForEach(dates.indices, id: \.self) { i in
                                dateCard(dates[i])
                            }
                        }

                        Button {
                            showAdd = true
                        } label: {
                            GlassCard {
                                HStack {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Agregar fecha importante").font(.system(size: 14, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Fechas Importantes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus").foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
            }
            .alert("Nueva fecha", isPresented: $showAdd) {
                TextField("Título", text: $newTitle)
                DatePicker("Fecha", selection: $newDate, displayedComponents: .date)
                Button("Cancelar", role: .cancel) { newTitle = "" }
                Button("Guardar") {
                    if !newTitle.isEmpty {
                        addDate(title: newTitle, date: newDate, icon: newIcon, color: ThemeManager.shared.primaryPink)
                        newTitle = ""
                    }
                }
            }
        }
        .onAppear { loadDates() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock").font(.system(size: 56)).foregroundColor(.primary.opacity(0.2))
            Text("No hay fechas importantes").font(.title3.weight(.semibold)).foregroundColor(.secondary)
            Text("Agrega aniversarios, cumpleaños y más").font(.subheadline).foregroundColor(ThemeManager.shared.textSecondary)
        }
    }

    private func dateCard(_ item: (title: String, date: Date, icon: String, color: Color, repeats: Bool)) -> some View {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let start = Calendar.current.startOfDay(for: item.date)

        let elapsed = elapsedText(from: start)
        let nextAnnual = nextAnnualDate(from: start)
        let daysToAnnual = Calendar.current.dateComponents([.day], from: today, to: nextAnnual).day ?? 0
        let nextMonthly = nextMonthlyDate(from: start)
        let daysToMonthly = Calendar.current.dateComponents([.day], from: today, to: nextMonthly).day ?? 0

        return GlassCard {
            HStack(spacing: 14) {
                Image(systemName: item.icon).font(.system(size: 22)).foregroundColor(item.color)
                    .padding(10).background(item.color.opacity(0.12)).cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                    Text("\(formatDate(start)) · \(elapsed)").font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))

                    if item.repeats {
                        HStack(spacing: 8) {
                            if daysToAnnual == 0 {
                                Text("🎉 ¡Hoy es el aniversario anual!").font(.system(size: 11, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                            } else {
                                Text("Faltan \(daysToAnnual) días para el aniversario").font(.system(size: 11)).foregroundColor(.primary.opacity(0.6))
                            }
                            if daysToMonthly == 0 {
                                Text("💕 ¡Hoy es el mesiversario!").font(.system(size: 11, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                            } else {
                                Text("Faltan \(daysToMonthly) días para el mesiversario").font(.system(size: 11)).foregroundColor(.primary.opacity(0.6))
                            }
                        }
                    } else {
                        let daysLeft = Calendar.current.dateComponents([.day], from: today, to: start).day ?? 0
                        if daysLeft > 0 {
                            Text("Faltan \(daysLeft) días").font(.system(size: 11)).foregroundColor(.primary.opacity(0.6))
                        } else {
                            Text("\(-daysLeft) días desde entonces").font(.system(size: 11)).foregroundColor(.primary.opacity(0.6))
                        }
                    }
                }

                Spacer()

                Button { deleteDate(item.title) } label: {
                    Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.red.opacity(0.6))
                        .padding(8).background(.ultraThinMaterial).clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Data

    private func loadDates() {
        var items: [(title: String, date: Date, icon: String, color: Color, repeats: Bool)] = []

        // Default dates from settings
        if let annStr = defaults.string(forKey: "anniversary_date"), let d = ISO8601DateFormatter().date(from: annStr) ?? dateFromString(annStr) {
            items.append(("Aniversario de novios 💖", d, "heart.fill", ThemeManager.shared.primaryPink, true))
        }
        if let metStr = defaults.string(forKey: "met_date"), let d = ISO8601DateFormatter().date(from: metStr) ?? dateFromString(metStr) {
            items.append(("Día que nos conocimos 🧑‍🤝‍🧑", d, "person.2.fill", Color(red: 0.49, green: 0.51, blue: 1.0), true))
        }
        if let datingStr = defaults.string(forKey: "dating_date"), let d = ISO8601DateFormatter().date(from: datingStr) ?? dateFromString(datingStr) {
            items.append(("Primera cita ☕", d, "cup.and.saucer.fill", Color(red: 1.0, green: 0.72, blue: 0.3), true))
        }
        if let weddingStr = defaults.string(forKey: "wedding_date"), let d = ISO8601DateFormatter().date(from: weddingStr) ?? dateFromString(weddingStr) {
            items.append(("Boda 💒", d, "sparkles", Color(red: 0.67, green: 0.28, blue: 0.74), true))
        }

        // Custom dates
        if let data = defaults.data(forKey: "important_dates"),
           let decoded = try? JSONDecoder().decode([CustomDate].self, from: data) {
            for cd in decoded {
                items.append((cd.title, cd.date, "star.fill", ThemeManager.shared.primaryPurple, cd.repeats))
            }
        }

        dates = items.sorted { $0.date < $1.date }
    }

    private func addDate(title: String, date: Date, icon: String, color: Color) {
        var custom = loadCustomDates()
        custom.append(CustomDate(title: title, date: date, icon: icon, repeats: true))
        saveCustomDates(custom)
        loadDates()
    }

    private func deleteDate(_ title: String) {
        var custom = loadCustomDates()
        custom.removeAll { $0.title == title }
        saveCustomDates(custom)

        // Also check default dates
        let keys = ["anniversary_date", "met_date", "dating_date", "wedding_date"]
        for key in keys {
            if let stored = defaults.string(forKey: key) {
                if let d = ISO8601DateFormatter().date(from: stored) ?? dateFromString(stored) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if formatter.string(from: d) == formatter.string(from: dates.first(where: { $0.title.contains(title) })?.date ?? Date()) {
                        defaults.removeObject(forKey: key)
                    }
                }
            }
        }
        loadDates()
    }

    private func loadCustomDates() -> [CustomDate] {
        guard let data = defaults.data(forKey: "important_dates"),
              let decoded = try? JSONDecoder().decode([CustomDate].self, from: data) else { return [] }
        return decoded
    }

    private func saveCustomDates(_ items: [CustomDate]) {
        if let encoded = try? JSONEncoder().encode(items) {
            defaults.set(encoded, forKey: "important_dates")
        }
    }

    // MARK: - Helpers

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long; f.locale = Locale(identifier: "es_MX")
        return f.string(from: d)
    }

    private func elapsedText(from start: Date) -> String {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        let s = Calendar.current.startOfDay(for: start)
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: s, to: today)
        var parts: [String] = []
        if let y = comps.year, y > 0 { parts.append("\(y) año\(y != 1 ? "s" : "")") }
        if let m = comps.month, m > 0 { parts.append("\(m) mes\(m != 1 ? "es" : "")") }
        if let d = comps.day, d > 0 { parts.append("\(d) día\(d != 1 ? "s" : "")") }
        return parts.isEmpty ? "Hoy" : parts.joined(separator: ", ")
    }

    private func nextAnnualDate(from start: Date) -> Date {
        let today = Date()
        let comps = Calendar.current.dateComponents([.month, .day], from: start)
        var next = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: today)!
        next = Calendar.current.date(bySetting: .month, value: comps.month ?? 1, of: next)!
        next = Calendar.current.date(bySetting: .day, value: comps.day ?? 1, of: next)!
        if next < Calendar.current.startOfDay(for: today) {
            next = Calendar.current.date(byAdding: .year, value: 1, to: next)!
        }
        return next
    }

    private func nextMonthlyDate(from start: Date) -> Date {
        let today = Date()
        let comps = Calendar.current.dateComponents([.day], from: start)
        var next = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: today)!
        let day = min(comps.day ?? 1, 28)
        next = Calendar.current.date(bySetting: .day, value: day, of: next)!
        if next <= Calendar.current.startOfDay(for: today) {
            next = Calendar.current.date(byAdding: .month, value: 1, to: next)!
            let maxDay = Calendar.current.range(of: .day, in: .month, for: next)?.count ?? 28
            next = Calendar.current.date(bySetting: .day, value: min(day, maxDay), of: next)!
        }
        return next
    }

    private func dateFromString(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
}

private struct CustomDate: Identifiable, Codable {
    let id = UUID()
    let title: String
    let date: Date
    let icon: String
    let repeats: Bool
}
