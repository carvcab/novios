import SwiftUI

public struct LoveView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var status = StatusService.shared
    @StateObject private var vm = LoveViewModel()
    @State private var showAddEvent = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    anniversaryHeroSection
                    quickStatsSection
                    timelineSection
                    lovePointsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Nuestro Amor 💖")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddEvent) {
                AddEventView { title, description, category, color, date in
                    vm.addEvent(title: title, description: description, category: category, color: color, date: date)
                }
            }
            .onAppear { vm.onAppear() }
            .onDisappear { vm.onDisappear() }
        }
    }

    // MARK: - Anniversary Hero
    private var anniversaryHeroSection: some View {
        GlassCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [theme.primary, theme.secondary],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: theme.primary.opacity(0.3), radius: 16)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(vm.myName)  💕  \(vm.partnerName)")
                            .appFont(size: 16, weight: .bold)
                            .foregroundColor(theme.textPrimary)
                        Text(vm.sinceText)
                            .appFont(size: 12)
                            .foregroundColor(theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary.opacity(0.3))
                }
                if vm.hasAnniversaryDate {
                    VStack(spacing: 4) {
                        Text(vm.timeTogether)
                            .appFont(size: 20, weight: .bold)
                            .foregroundColor(theme.primary)
                        Text(vm.nextAnniversaryText)
                            .appFont(size: 12)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.primary.opacity(0.08))
                    .cornerRadius(12)
                }
            }
        }
        .onTapGesture { vm.showComingSoon("Pantalla de Aniversario") }
        .padding(.bottom, 20)
    }

    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        HStack(spacing: 10) {
            quickStatCard(icon: "calendar", value: vm.totalDays, label: "días", color: theme.primary)
            quickStatCard(icon: "clock", value: vm.totalHours, label: "horas", color: Color(red: 0.49, green: 0.51, blue: 1.0))
            quickStatCard(icon: "timer", value: vm.totalMinutes, label: "minutos", color: Color(red: 1.0, green: 0.72, blue: 0.30))
        }
        .padding(.bottom, 20)
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        GlassCard(cornerRadius: 14) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(value)
                    .appFont(size: 18, weight: .bold)
                    .foregroundColor(theme.textPrimary)
                Text(label)
                    .appFont(size: 11)
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Timeline (Nuestra Historia)
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "timeline.selection")
                    .font(.system(size: 16))
                    .foregroundColor(theme.primary)
                Text("Nuestra Historia")
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
            }

            if vm.isLoadingTimeline {
                HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 20)
            } else if vm.timelineEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "timeline.selection")
                        .font(.system(size: 40))
                        .foregroundColor(theme.textSecondary.opacity(0.2))
                    Text("Aún no hay momentos en su historia")
                        .appFont(size: 13)
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(Array(vm.timelineEvents.enumerated()), id: \.element.id) { index, event in
                    timelineItem(event: event, isLast: index == vm.timelineEvents.count - 1)
                }
            }

            HStack {
                Spacer()
                Button(action: { showAddEvent = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Agregar recuerdo")
                            .appFont(size: 13, weight: .medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(theme.primary.opacity(0.1))
                    .cornerRadius(20)
                    .foregroundColor(theme.primary)
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(.bottom, 20)
    }

    private func timelineItem(event: TimelineEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(event.color, lineWidth: 2))
                        .shadow(color: event.color.opacity(0.2), radius: 6)
                    Image(systemName: event.icon)
                        .font(.system(size: 13))
                        .foregroundColor(event.color)
                }
                if !isLast {
                    Rectangle()
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 42)

            GlassCard(cornerRadius: 14) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(theme.textPrimary)
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(theme.textSecondary.opacity(0.5))
                            Text(event.date)
                                .appFont(size: 11)
                                .foregroundColor(theme.textSecondary.opacity(0.6))
                        }
                        if !event.description.isEmpty {
                            Text(event.description)
                                .appFont(size: 12)
                                .foregroundColor(theme.textSecondary)
                                .lineSpacing(3)
                        }
                    }
                    Spacer()
                    Button(action: { vm.deleteEvent(event) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Love Points
    private var lovePointsSection: some View {
        GlassCard(cornerRadius: 18) {
            HStack {
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundColor(theme.primary)
                Text("\(vm.lovePoints) puntos de amor")
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
                Spacer()
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Timeline Event Model
struct TimelineEvent: Identifiable {
    let id: String
    let docName: String
    let icon: String
    let title: String
    let description: String
    let date: String
    let dateISO: String
    let color: Color
    let createdBy: String
}

// MARK: - Categories
struct TimelineCategory {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let hex: String

    static let all: [TimelineCategory] = [
        .init(id: "favorite", name: "Amor", icon: "heart.fill", color: Color(red: 1, green: 0.5, blue: 0.5), hex: "FFFF7F7F"),
        .init(id: "flight", name: "Viaje", icon: "airplane.departure", color: Color(red: 0.4, green: 0.73, blue: 0.42), hex: "FF66BB6A"),
        .init(id: "cake", name: "Cumple", icon: "birthday.cake.fill", color: Color(red: 0.49, green: 0.51, blue: 1.0), hex: "FF7C83FF"),
        .init(id: "star", name: "Especial", icon: "star.fill", color: Color(red: 1, green: 0.72, blue: 0.30), hex: "FFFFB74D"),
        .init(id: "movie", name: "Cine", icon: "film.fill", color: Color(red: 0.56, green: 0.14, blue: 0.67), hex: "FF8E24AA"),
        .init(id: "restaurant", name: "Cena", icon: "fork.knife", color: Color(red: 0.85, green: 0.11, blue: 0.38), hex: "FFD81B60"),
        .init(id: "gift", name: "Regalo", icon: "gift.fill", color: Color(red: 0, green: 0.69, blue: 0.76), hex: "FF00ACC1"),
        .init(id: "music", name: "Música", icon: "music.note", color: Color(red: 0.22, green: 0.29, blue: 0.67), hex: "FF3949AB"),
    ]
}

// MARK: - ViewModel
@MainActor
class LoveViewModel: ObservableObject {
    @Published var timelineEvents: [TimelineEvent] = []
    @Published var isLoadingTimeline = false
    @Published var lovePoints: Int = 0
    @Published var totalDays: String = "0"
    @Published var totalHours: String = "0"
    @Published var totalMinutes: String = "0"
    @Published var timeTogether: String = ""
    @Published var nextAnniversaryText: String = ""
    @Published var sinceText: String = "Configura tus fechas"
    @Published var hasAnniversaryDate = false

    let myName: String
    let partnerName: String

    private var pollingTimer: Timer?
    private var timelinePath: String { "parejas/\(CoupleService.parejaId)/timeline" }

    init() {
        let isDiego = AuthService.shared.currentUser?.id == CoupleService.diegoUid
        myName = isDiego ? "Diego" : "Yosmari"
        partnerName = isDiego ? "Yosmari" : "Diego"
    }

    func onAppear() {
        refreshData()
        startPolling()
    }

    func onDisappear() {
        pollingTimer?.invalidate()
    }

    func refreshData() {
        updateAnniversaryStats()
        fetchTimelineEvents()
        fetchLovePoints()
    }

    // MARK: - Anniversary Stats

    private func updateAnniversaryStats() {
        guard let ann = anniversaryDate else {
            hasAnniversaryDate = false
            timeTogether = ""
            nextAnniversaryText = ""
            sinceText = "Configura tus fechas"
            totalDays = "0"; totalHours = "0"; totalMinutes = "0"
            return
        }
        hasAnniversaryDate = true
        let now = Date()
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: ann, to: now)
        let y = comps.year ?? 0; let m = comps.month ?? 0; let d = comps.day ?? 0
        var parts: [String] = []
        if y > 0 { parts.append("\(y) años") }
        if m > 0 { parts.append("\(m) meses") }
        if d > 0 { parts.append("\(d) días") }
        timeTogether = parts.isEmpty ? "0 días" : parts.joined(separator: "  ")

        let daysSince = Calendar.current.dateComponents([.day], from: ann, to: now).day ?? 0
        totalDays = "\(daysSince)"
        totalHours = "\(Calendar.current.dateComponents([.hour], from: ann, to: now).hour ?? 0)"
        totalMinutes = "\(Calendar.current.dateComponents([.minute], from: ann, to: now).minute ?? 0)"

        let df = DateFormatter(); df.dateFormat = "d 'de' MMMM 'de' yyyy"; df.locale = Locale(identifier: "es")
        sinceText = "Juntos desde el \(df.string(from: ann))"

        nextAnniversaryText = calcNextAnniversary(ann)
    }

    private func calcNextAnniversary(_ ann: Date) -> String {
        let now = Date()
        let today = Calendar.current.startOfDay(for: now)
        var next = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: now), month: Calendar.current.component(.month, from: ann), day: Calendar.current.component(.day, from: ann)))!
        if next < today {
            next = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: now) + 1, month: Calendar.current.component(.month, from: ann), day: Calendar.current.component(.day, from: ann)))!
        }
        let diff = Calendar.current.dateComponents([.day], from: today, to: next).day ?? 0
        if diff == 0 { return "🎉 ¡Hoy es su aniversario!" }
        if diff == 1 { return "Mañana es su aniversario 💕" }
        return "Próximo aniversario: \(diff) días"
    }

    private var anniversaryDate: Date? {
        guard let fields = CoupleService.shared.data?["fields"] as? [String: Any],
              let fecha = fields["fechaRelacion"] as? [String: Any],
              let str = fecha["stringValue"] as? String ?? fecha["timestampValue"] as? String else {
            return UserDefaults.standard.string(forKey: "anniversary_date").flatMap { ISO8601DateFormatter().date(from: $0) ?? DateFormatter.yyyyMMdd.date(from: $0) }
        }
        return ISO8601DateFormatter().date(from: str) ?? DateFormatter.yyyyMMdd.date(from: str)
    }

    // MARK: - Timeline Events

    func fetchTimelineEvents() {
        isLoadingTimeline = true
        Task {
            defer { isLoadingTimeline = false }
            let docs = (try? await FirebaseRESTService.shared.firestoreList(path: timelinePath)) ?? []
            var events: [TimelineEvent] = []
            for doc in docs {
                guard let name = doc["name"] as? String,
                      let fields = doc["fields"] as? [String: Any] else { continue }
                let docName = name.split(separator: "/").last.map(String.init) ?? UUID().uuidString
                let icon = parseString(from: fields, key: "icon") ?? "favorite"
                let title = parseString(from: fields, key: "title") ?? ""
                let description = parseString(from: fields, key: "description") ?? ""
                let date = parseString(from: fields, key: "date") ?? ""
                let dateISO = parseString(from: fields, key: "dateISO") ?? ""
                let hex = parseString(from: fields, key: "color") ?? "FFFF7F7F"
                let createdBy = parseString(from: fields, key: "createdBy") ?? ""
                let color = parseColor(hex)
                events.append(TimelineEvent(id: docName, docName: docName, icon: icon, title: title, description: description, date: date, dateISO: dateISO, color: color, createdBy: createdBy))
            }
            events.sort { (a, b) -> Bool in
                let aDate = ISO8601DateFormatter().date(from: a.dateISO) ?? Date.distantPast
                let bDate = ISO8601DateFormatter().date(from: b.dateISO) ?? Date.distantPast
                return aDate > bDate
            }
            timelineEvents = events
        }
    }

    func addEvent(title: String, description: String, category: String, color: String, date: Date) {
        let df = DateFormatter()
        df.dateFormat = "d 'de' MMMM 'de' yyyy"
        df.locale = Locale(identifier: "es")
        let dateStr = df.string(from: date)
        let dateISO = ISO8601DateFormatter().string(from: date)
        let docId = UUID().uuidString
        let uid = AuthService.shared.currentUser?.id ?? FirebaseRESTService.shared.localId ?? ""

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "\(timelinePath)/\(docId)", fields: [
                "icon": category,
                "title": title,
                "description": description,
                "date": dateStr,
                "dateISO": dateISO,
                "color": color,
                "createdBy": uid,
            ])
            fetchTimelineEvents()
        }
    }

    func deleteEvent(_ event: TimelineEvent) {
        Task {
            try? await FirebaseRESTService.shared.firestoreDelete(path: "\(timelinePath)/\(event.docName)")
            fetchTimelineEvents()
        }
    }

    // MARK: - Love Points

    func fetchLovePoints() {
        let uid = AuthService.shared.currentUser?.id ?? FirebaseRESTService.shared.localId ?? ""
        Task {
            let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "usuarios/\(uid)")
            if let fields = doc?["fields"] as? [String: Any] {
                lovePoints = parseInt(from: fields, key: "lovePoints") ?? 0
            }
        }
    }

    // MARK: - Polling

    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchTimelineEvents()
                self?.updateAnniversaryStats()
            }
        }
    }

    // MARK: - Helpers

    func showComingSoon(_ name: String) {
        let alert = UIAlertController(title: name, message: "Próximamente disponible", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topVC()?.present(alert, animated: true)
    }

    private func parseString(from fields: [String: Any], key: String) -> String? {
        (fields[key] as? [String: Any])?["stringValue"] as? String
    }

    private func parseInt(from fields: [String: Any], key: String) -> Int? {
        if let s = (fields[key] as? [String: Any])?["integerValue"] as? String { return Int(s) }
        return nil
    }

    private func parseColor(_ hex: String) -> Color {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 { clean = "FF" + clean }
        guard let val = UInt64(clean, radix: 16) else { return Color(red: 1, green: 0.5, blue: 0.5) }
        return Color(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255
        )
    }

    private func topVC() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let window = scenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        var vc = window?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }
}

// MARK: - Add Event Sheet
struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @State private var titleInput = ""
    @State private var descriptionInput = ""
    @State private var selectedDate = Date()
    @State private var selectedCategory = TimelineCategory.all[0]
    @State private var showDatePicker = false

    let onSave: (String, String, String, String, Date) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("¿Qué pasó?")
                            .appFont(size: 12, weight: .bold)
                            .foregroundColor(theme.textSecondary)
                        TextField("Ej: Nuestro primer beso", text: $titleInput)
                            .appFont(size: 15)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(theme.surfaceBackground)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Descripción / Nota (Opcional)")
                            .appFont(size: 12, weight: .bold)
                            .foregroundColor(theme.textSecondary)
                        TextField("Ej: Fue un día inolvidable...", text: $descriptionInput, axis: .vertical)
                            .appFont(size: 15)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(theme.surfaceBackground)
                            .cornerRadius(12)
                            .lineLimit(3...5)
                    }

                    Button(action: { showDatePicker = true }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(theme.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fecha del momento")
                                    .appFont(size: 11)
                                    .foregroundColor(theme.textSecondary)
                                Text(selectedDate, style: .date)
                                    .appFont(size: 14, weight: .semibold)
                                    .foregroundColor(theme.textPrimary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(12)
                        .background(theme.surfaceBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categoría:")
                            .appFont(size: 12, weight: .bold)
                            .foregroundColor(theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TimelineCategory.all) { cat in
                                    Button(action: { selectedCategory = cat }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 12))
                                            Text(cat.name)
                                                .appFont(size: 12, weight: .medium)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory.id == cat.id ? cat.color : theme.surfaceBackground)
                                        .foregroundColor(selectedCategory.id == cat.id ? .white : theme.textPrimary)
                                        .cornerRadius(20)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Agregar momento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard !titleInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(titleInput.trimmingCharacters(in: .whitespaces),
                               descriptionInput.trimmingCharacters(in: .whitespaces),
                               selectedCategory.id, selectedCategory.hex, selectedDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(titleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(selectedDate: $selectedDate)
            }
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var tempDate: Date

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _tempDate = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            DatePicker("", selection: $tempDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Seleccionar fecha")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("OK") {
                            selectedDate = tempDate
                            dismiss()
                        }
                    }
                }
        }
    }
}

extension TimelineCategory: Identifiable {}

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
