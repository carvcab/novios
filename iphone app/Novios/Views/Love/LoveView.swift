import SwiftUI
import FirebaseFirestore

public struct LoveView: View {
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
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(ThemeManager.shared.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Nuestro Amor 💖")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddEvent) {
                AddEventView { title, description, category, color, date in
                    vm.addEvent(title: title, description: description, category: category, color: color, date: date)
                }
            }
            .onAppear { vm.startListening() }
            .onDisappear { vm.stopListening() }
        }
    }

    private var anniversaryHeroSection: some View {
        GlassCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [ThemeManager.shared.primary, ThemeManager.shared.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 56, height: 56)
                            .shadow(color: ThemeManager.shared.primary.opacity(0.3), radius: 16)
                        Image(systemName: "heart.fill").font(.system(size: 24)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(vm.myName)  💕  \(vm.partnerName)").appFont(size: 16, weight: .bold).foregroundColor(ThemeManager.shared.textPrimary)
                        Text(vm.sinceText).appFont(size: 12).foregroundColor(ThemeManager.shared.textSecondary)
                    }
                    Spacer()
                    NavigationLink(destination: AnniversaryScreen()) {
                        Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.3))
                    }
                }
                if vm.hasAnniversaryDate {
                    VStack(spacing: 4) {
                        Text(vm.timeTogether).appFont(size: 20, weight: .bold).foregroundColor(ThemeManager.shared.primary)
                        Text(vm.nextAnniversaryText).appFont(size: 12).foregroundColor(ThemeManager.shared.textSecondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(ThemeManager.shared.primary.opacity(0.08)).cornerRadius(12)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var quickStatsSection: some View {
        HStack(spacing: 10) {
            quickStatCard(icon: "calendar", value: vm.totalDays, label: "días", color: ThemeManager.shared.primary)
            quickStatCard(icon: "clock", value: vm.totalHours, label: "horas", color: Color(red: 0.49, green: 0.51, blue: 1.0))
            quickStatCard(icon: "timer", value: vm.totalMinutes, label: "minutos", color: Color(red: 1.0, green: 0.72, blue: 0.30))
        }
        .padding(.bottom, 20)
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        GlassCard(cornerRadius: 14) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
                Text(value).appFont(size: 20, weight: .bold).foregroundColor(ThemeManager.shared.textPrimary)
                Text(label).appFont(size: 11).foregroundColor(ThemeManager.shared.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath").foregroundColor(ThemeManager.shared.primary)
                Text("Nuestra Historia").appFont(size: 16, weight: .bold).foregroundColor(ThemeManager.shared.textPrimary)
                Spacer()
                Button { showAddEvent = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(ThemeManager.shared.primary).font(.system(size: 22))
                }
            }
            .padding(.bottom, 4)

            if vm.timelineEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 36)).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.2))
                    Text("Aún no hay momentos").appFont(size: 13).foregroundColor(.secondary)
                    Text("Agrega los momentos especiales de su historia 💕").appFont(size: 11).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(vm.timelineEvents.enumerated()), id: \.offset) { _, event in
                        timelineRow(event)
                    }
                }
            }
        }
    }

    private func timelineRow(_ event: TimelineEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(parseColor(event.color).opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: iconName(event.icon)).foregroundColor(parseColor(event.color)).font(.system(size: 16))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).appFont(size: 14, weight: .semibold).foregroundColor(ThemeManager.shared.textPrimary)
                if !event.description.isEmpty {
                    Text(event.description).appFont(size: 12).foregroundColor(ThemeManager.shared.textSecondary).lineLimit(2)
                }
                Text(event.date).appFont(size: 11).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.6))
            }
            Spacer()
            Button {
                vm.deleteEvent(event)
            } label: {
                Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(12).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1)))
    }

    private func iconName(_ icon: String) -> String {
        switch icon {
        case "flight": return "airplane"
        case "cake": return "birthday.cake"
        case "star": return "star.fill"
        case "movie": return "film.fill"
        case "restaurant": return "fork.knife"
        case "gift": return "gift.fill"
        case "music": return "music.note"
        default: return "heart.fill"
        }
    }

    private func parseColor(_ hex: String) -> Color {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 { clean = "FF" + clean }
        guard let val = UInt64(clean, radix: 16) else { return Color(red: 1, green: 0.5, blue: 0.5) }
        return Color(red: Double((val >> 16) & 0xFF) / 255, green: Double((val >> 8) & 0xFF) / 255, blue: Double(val & 0xFF) / 255)
    }
}

// MARK: - Add Event View

struct AddEventView: View {
    let onSave: (String, String, String, String, Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var selectedCategory = "favorite"
    @State private var selectedColor = "FFFF7F7F"

    private let categories = [
        ("favorite", "Amor", "FFFF7F7F"), ("flight", "Viaje", "FF7FB2"), ("cake", "Cumpleaños", "FFB37F"),
        ("star", "Logro", "FFD700"), ("movie", "Cine", "7FB2FF"), ("restaurant", "Cena", "7FFF7F"),
        ("gift", "Regalo", "FF7FFF"), ("music", "Música", "B27FFF"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Título") { TextField("¿Qué pasó?", text: $title) }
                Section("Descripción") { TextField("Cuenta los detalles...", text: $description) }
                Section("Fecha") { DatePicker("", selection: $selectedDate, displayedComponents: .date).datePickerStyle(.graphical) }
                Section("Categoría") {
                    categoryPicker
                }
            }
            .navigationTitle("Nuevo Momento ✨")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(title.trimmingCharacters(in: .whitespaces), description.trimmingCharacters(in: .whitespaces), selectedCategory, selectedColor, selectedDate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.0) { cat in
                    let isSel = selectedCategory == cat.0
                    let col = parseColor(cat.2)
                    VStack(spacing: 4) {
                        Image(systemName: iconName(cat.0))
                            .font(.system(size: 20))
                            .foregroundColor(isSel ? col : .secondary)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                            .background(isSel ? col.opacity(0.15) : Color.clear)
                        Text(cat.1).appFont(size: 9).foregroundColor(isSel ? .primary : .secondary)
                    }
                    .onTapGesture { selectedCategory = cat.0; selectedColor = cat.2 }
                }
            }
        }
    }

    private func parseColor(_ hex: String) -> Color {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 { clean = "FF" + clean }
        guard let val = UInt64(clean, radix: 16) else { return .pink }
        return Color(red: Double((val >> 16) & 0xFF) / 255, green: Double((val >> 8) & 0xFF) / 255, blue: Double(val & 0xFF) / 255)
    }

    private func iconName(_ i: String) -> String {
        switch i { case "flight": "airplane"; case "movie": "film"; case "restaurant": "fork.knife"; case "gift": "gift"; case "music": "music.note"; case "cake": "birthday.cake"; case "star": "star.fill"; default: "heart.fill" }
    }
}

// MARK: - Anniversary Detail Screen

struct AnniversaryScreen: View {
    @StateObject private var vm = LoveViewModel()
    @State private var showConfig = false
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    milestoneCard(icon: "person.line.dotted.person", label: "Nos conocimos", date: vm.metDate, color: Color(red: 0.49, green: 0.51, blue: 1.0))
                    milestoneCard(icon: "fork.knife", label: "Primera cita", date: vm.datingDate, color: Color(red: 1.0, green: 0.72, blue: 0.30))
                    milestoneCard(icon: "heart.fill", label: "Aniversario (Novios)", date: vm.anniversaryDate, color: ThemeManager.shared.primary)
                    milestoneCard(icon: "ring", label: "Boda (Esposos)", date: vm.weddingDate, color: Color(red: 0.7, green: 0.3, blue: 0.7))

                    Button { showConfig = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Configurar Fechas")
                                .appFont(size: 14, weight: .medium)
                        }
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(ThemeManager.shared.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundColor(ThemeManager.shared.primary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Aniversario 💕")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(timer) { t in now = t }
        .onAppear { vm.startListening() }
        .onDisappear { vm.stopListening() }
        .sheet(isPresented: $showConfig) { dateConfigSheet }
    }

    private func milestoneCard(icon: String, label: String, date: Date?, color: Color) -> some View {
        GlassCard(cornerRadius: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: icon).foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).appFont(size: 13, weight: .semibold).foregroundColor(ThemeManager.shared.textPrimary)
                    if let d = date {
                        Text(vm.formatDate(d)).appFont(size: 11).foregroundColor(ThemeManager.shared.textSecondary)
                        Text(elapsedString(from: d)).appFont(size: 13, weight: .bold).foregroundColor(color)
                        Text(countdownString(from: d)).appFont(size: 10).foregroundColor(ThemeManager.shared.textSecondary)
                    } else {
                        Text("No configurado").appFont(size: 11).foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(14)
        }
    }

    private func elapsedString(from date: Date) -> String {
        let e = elapsed(date, now)
        return "\(e.y)a \(e.m)m \(e.d)d \(e.h)h \(e.min)m \(e.s)s"
    }

    private func countdownString(from date: Date) -> String {
        let next = nextAnniversary(date)
        let days = Calendar.current.dateComponents([.day], from: now, to: next).day ?? 0
        if days == 0 { return "🎉 ¡Hoy!" }
        if days == 1 { return "Mañana 💕" }
        return "Próximo: \(days) días"
    }

    private func nextAnniversary(_ date: Date) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        var next = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: cal.component(.month, from: date), day: cal.component(.day, from: date)))!
        if next < today { next = cal.date(from: DateComponents(year: cal.component(.year, from: now) + 1, month: cal.component(.month, from: date), day: cal.component(.day, from: date)))! }
        return next
    }

    private func elapsed(_ from: Date, _ to: Date) -> (y: Int, m: Int, d: Int, h: Int, min: Int, s: Int) {
        let diff = to.timeIntervalSince(from)
        let totalSec = Int(diff)
        let y = totalSec / (365 * 86400)
        let rem = totalSec % (365 * 86400)
        let m = rem / (30 * 86400)
        let rem2 = rem % (30 * 86400)
        let d = rem2 / 86400
        let h = (rem2 % 86400) / 3600
        let min = (rem2 % 3600) / 60
        let s = rem2 % 60
        return (y, m, d, h, min, s)
    }

    private var dateConfigSheet: some View {
        DateConfigView(
            metDate: vm.metDate, datingDate: vm.datingDate,
            anniversaryDate: vm.anniversaryDate, weddingDate: vm.weddingDate,
            coupleDocRef: vm.coupleDocRef
        )
    }
}

// MARK: - Date Configuration Sheet

struct DateConfigView: View {
    let metDate: Date?; let datingDate: Date?; let anniversaryDate: Date?; let weddingDate: Date?
    let coupleDocRef: DocumentReference
    @Environment(\.dismiss) private var dismiss

    @State private var met: Date; @State private var metEnabled: Bool
    @State private var dating: Date; @State private var datingEnabled: Bool
    @State private var ann: Date; @State private var annEnabled: Bool
    @State private var wedding: Date; @State private var weddingEnabled: Bool

    init(metDate: Date?, datingDate: Date?, anniversaryDate: Date?, weddingDate: Date?, coupleDocRef: DocumentReference) {
        self.metDate = metDate; self.datingDate = datingDate; self.anniversaryDate = anniversaryDate; self.weddingDate = weddingDate
        self.coupleDocRef = coupleDocRef
        _met = State(initialValue: metDate ?? Date())
        _metEnabled = State(initialValue: metDate != nil)
        _dating = State(initialValue: datingDate ?? Date())
        _datingEnabled = State(initialValue: datingDate != nil)
        _ann = State(initialValue: anniversaryDate ?? Date())
        _annEnabled = State(initialValue: anniversaryDate != nil)
        _wedding = State(initialValue: weddingDate ?? Date())
        _weddingEnabled = State(initialValue: weddingDate != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                dateSection(icon: "person.line.dotted.person", label: "Nos conocimos", color: Color(red: 0.49, green: 0.51, blue: 1.0), date: $met, enabled: $metEnabled)
                dateSection(icon: "fork.knife", label: "Primera cita", color: Color(red: 1.0, green: 0.72, blue: 0.30), date: $dating, enabled: $datingEnabled)
                dateSection(icon: "heart.fill", label: "Aniversario (Novios)", color: ThemeManager.shared.primary, date: $ann, enabled: $annEnabled)
                dateSection(icon: "ring", label: "Boda (Esposos)", color: Color(red: 0.7, green: 0.3, blue: 0.7), date: $wedding, enabled: $weddingEnabled)
            }
            .navigationTitle("Fechas importantes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { save() }.disabled(!metEnabled && !datingEnabled && !annEnabled && !weddingEnabled) }
            }
        }
        .presentationDetents([.large])
    }

    private func dateSection(icon: String, label: String, color: Color, date: Binding<Date>, enabled: Binding<Bool>) -> some View {
        Section {
            Toggle(isOn: enabled) { Text(label).appFont(size: 14, weight: .medium).foregroundColor(color) }
            if enabled.wrappedValue {
                DatePicker("Fecha", selection: date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(color)
            }
        }
    }

    private func save() {
        var fields: [String: Any] = [:]
        if metEnabled { fields["metDate"] = Timestamp(date: met) } else { fields["metDate"] = FieldValue.delete() }
        if datingEnabled { fields["datingDate"] = Timestamp(date: dating) } else { fields["datingDate"] = FieldValue.delete() }
        if annEnabled { fields["anniversaryDate"] = Timestamp(date: ann) } else { fields["anniversaryDate"] = FieldValue.delete() }
        if weddingEnabled { fields["weddingDate"] = Timestamp(date: wedding) } else { fields["weddingDate"] = FieldValue.delete() }
        Task { try? await coupleDocRef.setData(fields, merge: true) }
        dismiss()
    }
}

// MARK: - LoveViewModel

class LoveViewModel: ObservableObject {
    @Published var timelineEvents: [TimelineEvent] = []
    @Published var totalDays: String = "0"
    @Published var totalHours: String = "0"
    @Published var totalMinutes: String = "0"
    @Published var timeTogether: String = ""
    @Published var nextAnniversaryText: String = ""
    @Published var sinceText: String = "Configura tus fechas"
    @Published var hasAnniversaryDate = false
    @Published var anniversaryDate: Date? = nil
    @Published var metDate: Date? = nil
    @Published var datingDate: Date? = nil
    @Published var weddingDate: Date? = nil

    let myName: String
    let partnerName: String

    private var coupleListener: ListenerRegistration?
    private var timelineListener: ListenerRegistration?
    private var timer: Timer?
    private let db = Firestore.firestore()

    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }
    private var coupleDocRef: DocumentReference { db.collection("couples").document(coupleId) }
    private var timelineDocRef: DocumentReference { db.collection("couples").document(coupleId).collection("lists").document("timeline_events") }

    init() {
        let isDiego = AuthService.shared.currentUser?.id == CoupleService.diegoUid
        myName = isDiego ? "Diego" : "Yosmari"
        partnerName = isDiego ? "Yosmari" : "Diego"
    }

    func startListening() {
        coupleListener = coupleDocRef.addSnapshotListener { [weak self] snapshot, _ in
            guard let d = snapshot?.data() else { return }
            self?.parseDates(d)
        }
        timelineListener = timelineDocRef.addSnapshotListener { [weak self] snapshot, _ in
            guard let data = snapshot?.data(), let items = data["items"] as? [[String: Any]] else { return }
            let events = items.compactMap { dict -> TimelineEvent? in
                guard let title = dict["title"] as? String else { return nil }
                return TimelineEvent(
                    id: dict["id"] as? String ?? UUID().uuidString,
                    docName: "",
                    icon: dict["icon"] as? String ?? "favorite",
                    title: title,
                    description: dict["description"] as? String ?? "",
                    date: dict["date"] as? String ?? "",
                    dateISO: dict["dateISO"] as? String ?? "",
                    color: dict["color"] as? String ?? "FFFF7F7F",
                    createdBy: dict["createdBy"] as? String ?? ""
                )
            }.sorted { a, b in
                (ISO8601DateFormatter().date(from: a.dateISO) ?? .distantPast) > (ISO8601DateFormatter().date(from: b.dateISO) ?? .distantPast)
            }
            DispatchQueue.main.async { self?.timelineEvents = events }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateAnniversaryStats()
        }
    }

    func stopListening() {
        coupleListener?.remove(); timelineListener?.remove(); timer?.invalidate()
    }

    private func parseDates(_ data: [String: Any]) {
        anniversaryDate = parseDate(data["anniversaryDate"])
        metDate = parseDate(data["metDate"])
        datingDate = parseDate(data["datingDate"])
        weddingDate = parseDate(data["weddingDate"])
        DispatchQueue.main.async { self.updateAnniversaryStats() }
    }

    private func parseDate(_ val: Any?) -> Date? {
        if let ts = val as? Timestamp { return ts.dateValue() }
        if let s = val as? String {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
            return ISO8601DateFormatter().date(from: s) ?? f.date(from: s)
        }
        return nil
    }

    func updateAnniversaryStats() {
        guard let ann = anniversaryDate else {
            hasAnniversaryDate = false; timeTogether = ""; nextAnniversaryText = ""
            sinceText = "Configura tus fechas"; totalDays = "0"; totalHours = "0"; totalMinutes = "0"
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
        totalDays = "\(Calendar.current.dateComponents([.day], from: ann, to: now).day ?? 0)"
        totalHours = "\(Calendar.current.dateComponents([.hour], from: ann, to: now).hour ?? 0)"
        totalMinutes = "\(Calendar.current.dateComponents([.minute], from: ann, to: now).minute ?? 0)"
        let df = DateFormatter(); df.dateFormat = "d 'de' MMMM 'de' yyyy"; df.locale = Locale(identifier: "es")
        sinceText = "Juntos desde el \(df.string(from: ann))"
        nextAnniversaryText = calcNextAnniversary(ann)
    }

    private func calcNextAnniversary(_ ann: Date) -> String {
        let now = Date(); let today = Calendar.current.startOfDay(for: now)
        var next = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: now), month: Calendar.current.component(.month, from: ann), day: Calendar.current.component(.day, from: ann)))!
        if next < today { next = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: now) + 1, month: Calendar.current.component(.month, from: ann), day: Calendar.current.component(.day, from: ann)))! }
        let diff = Calendar.current.dateComponents([.day], from: today, to: next).day ?? 0
        if diff == 0 { return "🎉 ¡Hoy es su aniversario!" }
        if diff == 1 { return "Mañana es su aniversario 💕" }
        return "Próximo aniversario: \(diff) días"
    }

    func timeSince(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date, to: Date())
        let y = comps.year ?? 0; let m = comps.month ?? 0; let d = comps.day ?? 0
        return "\(y)a \(m)m \(d)d"
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d 'de' MMMM 'de' yyyy"; f.locale = Locale(identifier: "es")
        return f.string(from: date)
    }

    static func formatDateShort(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMM yyyy"; f.locale = Locale(identifier: "es")
        return f.string(from: date)
    }

    func showDateConfig() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }
        let alert = UIAlertController(title: "Configurar Fechas", message: "Fecha de aniversario (YYYY-MM-DD):", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Ej: 2023-06-15"
            if let d = self.anniversaryDate { tf.text = ISO8601DateFormatter().string(from: d).prefix(10).description }
        }
        alert.addAction(UIAlertAction(title: "Guardar", style: .default) { _ in
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
            if let text = alert.textFields?.first?.text, let date = f.date(from: text) {
                Task { try? await self.coupleDocRef.setData(["anniversaryDate": Timestamp(date: date)], merge: true) }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        root.present(alert, animated: true)
    }

    func addEvent(title: String, description: String, category: String, color: String, date: Date) {
        let df = DateFormatter(); df.dateFormat = "d 'de' MMMM 'de' yyyy"; df.locale = Locale(identifier: "es")
        Task {
            var items = (try? await timelineDocRef.getDocument().data().flatMap { $0["items"] as? [[String: Any]] }) ?? []
            items.insert([
                "id": "\(Date().timeIntervalSince1970 * 1000)", "icon": category, "title": title,
                "description": description, "date": df.string(from: date),
                "dateISO": ISO8601DateFormatter().string(from: date), "color": color,
                "createdBy": AuthService.shared.currentUser?.id ?? ""
            ], at: 0)
            try? await timelineDocRef.setData(["items": items, "updatedAt": FieldValue.serverTimestamp()])
        }
    }

    func deleteEvent(_ event: TimelineEvent) {
        Task {
            guard var items = (try? await timelineDocRef.getDocument().data().flatMap { $0["items"] as? [[String: Any]] }) else { return }
            items.removeAll { ($0["id"] as? String) == event.id || ($0["title"] as? String) == event.title }
            try? await timelineDocRef.setData(["items": items, "updatedAt": FieldValue.serverTimestamp()])
        }
    }
}

// MARK: - Types

struct TimelineEvent {
    let id: String; let docName: String; let icon: String; let title: String
    let description: String; let date: String; let dateISO: String; let color: String; let createdBy: String
}


