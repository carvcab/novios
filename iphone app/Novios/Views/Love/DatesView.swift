import SwiftUI
import FirebaseFirestore

// MARK: - Important Date Model

struct ImportantDateItem: Identifiable {
    let id: String
    var title: String
    var dateStr: String
    var repeats: Bool
}

// MARK: - Milestone Config

private struct MilestoneDates {
    var met: Date?
    var dating: Date?
    var anniversary: Date?
    var wedding: Date?
}

// MARK: - Main View

public struct DatesView: View {
    @ObservedObject private var theme = ThemeManager.shared

    // Milestone dates from couples/{coupleId}
    @State private var milestones = MilestoneDates()

    // Important dates from couples/{coupleId}/lists/important_dates
    @State private var importantDates: [ImportantDateItem] = []

    @State private var now = Date()
    @State private var showConfig = false
    @State private var showAddDate = false
    @State private var editingDate: ImportantDateItem?

    private let db = Firestore.firestore()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var coupleListener: ListenerRegistration?
    private var datesListener: ListenerRegistration?

    private var coupleId: String { CoupleService.coupleId }

    private var coupleDocRef: DocumentReference {
        db.collection("couples").document(coupleId)
    }

    private var importantDatesRef: DocumentReference {
        db.collection("couples").document(coupleId).collection("lists").document("important_dates")
    }

    private var hasAnyMilestone: Bool {
        milestones.met != nil || milestones.dating != nil || milestones.anniversary != nil || milestones.wedding != nil
    }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            ScrollView {
                VStack(spacing: 20) {
                    if hasAnyMilestone {
                        heroCarousel
                        milestonesTimeline
                        countdownSection
                    } else {
                        emptyMilestones
                    }
                    importantDatesSection
                }
                .padding(16)
            }
        }
        .navigationTitle("Fechas Importantes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startListening() }
        .onDisappear { stopListening() }
        .onReceive(timer) { t in now = t }
        .sheet(isPresented: $showConfig) {
            MilestoneConfigSheet(
                met: $milestones.met, dating: $milestones.dating,
                anniversary: $milestones.anniversary, wedding: $milestones.wedding,
                coupleRef: coupleDocRef
            )
        }
        .sheet(isPresented: $showAddDate) {
            DateFormSheet(title: "Nueva fecha", onSave: addImportantDate)
        }
        .sheet(item: $editingDate) { item in
            DateFormSheet(
                title: "Editar fecha",
                initialTitle: item.title,
                initialDate: yyyyMMdd.date(from: item.dateStr) ?? Date(),
                initialRepeats: item.repeats,
                onSave: { name, date, rep in updateImportantDate(id: item.id, name: name, date: date, repeats: rep) },
                onDelete: { deleteImportantDate(id: item.id) }
            )
        }
    }

    // MARK: - Hero Carousel

    private var heroCarousel: some View {
        let cards = milestoneCards
        return GlassCard(cornerRadius: 20) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                        Image(systemName: "heart.fill").font(.system(size: 22)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(AuthService.shared.currentUser?.nombre ?? "Tú")  💕  \(CoupleService.shared.partnerName)")
                            .appFont(size: 15, weight: .bold)
                        if let d = milestones.anniversary {
                            Text("Juntos desde el \(d.formatted(.dateTime.day().month(.wide).year()))")
                                .appFont(size: 11).foregroundColor(theme.textSecondary)
                        } else {
                            Text("Configura tus fechas").appFont(size: 11).foregroundColor(theme.textSecondary)
                        }
                    }
                    Spacer()
                }

                if let d = milestones.anniversary {
                    let e = elapsed(from: d, to: now)
                    VStack(spacing: 4) {
                        Text("\(e.y) años  \(e.m) meses  \(e.d) días")
                            .appFont(size: 20, weight: .bold).foregroundColor(theme.primary)
                        Text("\(e.h)h : \(e.mi)m : \(e.s)s")
                            .appFont(size: 16, weight: .bold).foregroundColor(theme.primary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(theme.primary.opacity(0.08)).cornerRadius(12)
                }

                if !cards.isEmpty {
                    TabView {
                        ForEach(cards, id: \.label) { card in
                            HStack(spacing: 10) {
                                Image(systemName: card.icon).foregroundColor(card.color)
                                Text(card.label).appFont(size: 13, weight: .semibold)
                                Spacer()
                                if let d = card.date {
                                    Text(elapsedShort(from: d, to: now))
                                        .appFont(size: 13, weight: .bold).foregroundColor(card.color)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .tabViewStyle(.page(interactive: true))
                    .frame(height: 50)
                }

                Button { showConfig = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                        Text("Configurar fechas").appFont(size: 12, weight: .medium)
                    }
                    .foregroundColor(theme.primary).padding(.vertical, 6)
                }
            }
            .padding(16)
        }
    }

    private var milestoneCards: [(icon: String, label: String, date: Date?, color: Color)] {
        var cards: [(String, String, Date?, Color)] = []
        if let d = milestones.met { cards.append(("person.2.fill", "Nos conocimos", d, Color(red: 0.49, green: 0.51, blue: 1.0))) }
        if let d = milestones.dating { cards.append(("cup.and.saucer.fill", "Primera cita", d, Color(red: 1.0, green: 0.72, blue: 0.30))) }
        if let d = milestones.anniversary { cards.append(("heart.fill", "Aniversario", d, theme.primary)) }
        if let d = milestones.wedding { cards.append(("ring", "Boda", d, Color(red: 0.7, green: 0.3, blue: 0.7))) }
        return cards
    }

    // MARK: - Empty State

    private var emptyMilestones: some View {
        GlassCard(cornerRadius: 20) {
            VStack(spacing: 12) {
                Image(systemName: "calendar").font(.system(size: 48)).foregroundColor(theme.primary.opacity(0.4))
                Text("Configura tus fechas importantes").appFont(size: 16, weight: .semibold)
                Text("Agrega cuándo se conocieron, su primera cita, aniversario o boda")
                    .appFont(size: 12).foregroundColor(.secondary).multilineTextAlignment(.center)
                Button { showConfig = true } label: {
                    Text("Configurar").appFont(size: 14, weight: .medium).foregroundColor(theme.primary)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(theme.primary.opacity(0.1)).cornerRadius(12)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Milestones Timeline

    private var milestonesTimeline: some View {
        let cards = milestoneCards
        guard !cards.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(icon: "timeline.selection", title: "Nuestra Línea del Tiempo")
                ForEach(cards, id: \.label) { card in
                    let e = card.date.map { elapsed(from: $0, to: now) }
                    let next = card.date.map { nextYearly($0) }
                    let daysUntil = next.map { Calendar.current.dateComponents([.day], from: now, to: $0).day ?? 0 } ?? 365
                    let progress = min(max(Double(365 - abs(daysUntil)) / 365.0, 0), 1)

                    GlassCard(cornerRadius: 14) {
                        HStack(spacing: 12) {
                            Circle().fill(card.color.opacity(0.15)).frame(width: 42, height: 42)
                                .overlay(Image(systemName: card.icon).foregroundColor(card.color).font(.system(size: 16)))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(card.label).appFont(size: 14, weight: .semibold)
                                if let d = card.date {
                                    Text("\(d.formatted(.dateTime.day().month(.wide).year()))")
                                        .appFont(size: 10).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                if let e = e {
                                    Text("\(e.y)a \(e.m)m \(e.d)d").appFont(size: 12, weight: .bold).foregroundColor(card.color)
                                }
                                ProgressView(value: progress).tint(card.color)
                                    .frame(width: 60)
                            }
                        }
                        .padding(12)
                    }
                }
            }
        )
    }

    // MARK: - Countdowns

    private var countdownSection: some View {
        var items: [(title: String, date: Date, icon: String, color: Color)] = []
        let addYearly = { (label: String, date: Date?, icon: String, color: Color) in
            guard let d = date else { return }
            let target = nextYearly(d)
            let title = "\(label) #\(target.year - d.year)"
            items.append((title, target, icon, color))
        }
        let addMonthly = { (label: String, date: Date?, icon: String, color: Color) in
            guard let d = date else { return }
            let target = nextMonthly(d, now: now)
            let monthsNo = (target.year - d.year) * 12 + (target.month - d.month)
            items.append(("\(label) #\(monthsNo)", target, icon, color))
        }

        addYearly("Aniversario", milestones.anniversary, "heart.fill", theme.primary)
        addMonthly("Mesiversario", milestones.anniversary, "heart", theme.secondary)
        addYearly("Boda", milestones.wedding, "ring", Color(red: 0.7, green: 0.3, blue: 0.7))
        addYearly("Nos conocimos", milestones.met, "person.2.fill", Color(red: 0.49, green: 0.51, blue: 1.0))

        guard !items.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(icon: "hourglass.bottomhalf.filled", title: "Cuenta Regresiva (En Vivo)")
                ForEach(items, id: \.title) { item in
                    let diff = item.date.timeIntervalSince(now)
                    let days = Int(diff) / 86400
                    let hours = (Int(diff) % 86400) / 3600
                    let minutes = (Int(diff) % 3600) / 60
                    let seconds = Int(diff) % 60

                    GlassCard(cornerRadius: 14) {
                        HStack(spacing: 12) {
                            Circle().fill(item.color.opacity(0.12)).frame(width: 40, height: 40)
                                .overlay(Image(systemName: item.icon).foregroundColor(item.color).font(.system(size: 16)))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).appFont(size: 13, weight: .bold)
                                Text(item.date.formatted(.dateTime.day().month(.wide).year()))
                                    .appFont(size: 10).foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Faltan:").appFont(size: 9).foregroundColor(.secondary)
                                if days > 0 || hours > 0 || minutes > 0 || seconds > 0 {
                                    Text("\(days)d \(hours)h \(minutes)m \(seconds)s")
                                        .appFont(size: 13, weight: .bold).foregroundColor(days == 0 && hours == 0 ? .green : item.color)
                                } else {
                                    Text("¡Hoy! 🎉").appFont(size: 13, weight: .bold).foregroundColor(.green)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
            }
        )
    }

    // MARK: - Important Dates

    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader(icon: "calendar.badge.clock", title: "Fechas Importantes")
                Spacer()
                Button { showAddDate = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(theme.primary)
                }
            }

            if importantDates.isEmpty {
                GlassCard(cornerRadius: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus").font(.system(size: 32)).foregroundColor(theme.textSecondary.opacity(0.2))
                        Text("No hay fechas agregadas aún").appFont(size: 13).foregroundColor(.secondary)
                        Button { showAddDate = true } label: {
                            Text("Agregar fecha").appFont(size: 13).foregroundColor(theme.primary)
                        }
                    }
                    .padding(24).frame(maxWidth: .infinity)
                }
            } else {
                ForEach(importantDates) { item in
                    GlassCard(cornerRadius: 14) {
                        Button {
                            editingDate = item
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "heart.fill").font(.system(size: 14)).foregroundColor(theme.primary)
                                    .padding(10).background(theme.primary.opacity(0.1)).cornerRadius(10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).appFont(size: 14, weight: .semibold)
                                    HStack(spacing: 4) {
                                        if let d = yyyyMMdd.date(from: item.dateStr) {
                                            Text(d.formatted(.dateTime.day().month(.wide).year()))
                                                .appFont(size: 10).foregroundColor(.secondary)
                                            Text("·").appFont(size: 10).foregroundColor(.secondary)
                                            Text(formatDateCounter(date: d, repeats: item.repeats))
                                                .appFont(size: 10).foregroundColor(theme.primary)
                                        }
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.3))
                            }
                            .padding(12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(theme.primary)
            Text(title).appFont(size: 15, weight: .bold)
        }
    }

    private func elapsed(from: Date, to: Date) -> (y: Int, m: Int, d: Int, h: Int, mi: Int, s: Int) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: from, to: to)
        let diff = to.timeIntervalSince(from)
        let totalSec = Int(diff)
        return (
            comps.year ?? 0,
            comps.month ?? 0,
            comps.day ?? 0,
            (totalSec % 86400) / 3600,
            (totalSec % 3600) / 60,
            totalSec % 60
        )
    }

    private func elapsedShort(from: Date, to: Date) -> String {
        let e = elapsed(from: from, to: to)
        return "\(e.y)a \(e.m)m \(e.d)d"
    }

    private func nextYearly(_ date: Date) -> Date {
        let cal = Calendar.current
        let nowDate = cal.startOfDay(for: now)
        var next = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: cal.component(.month, from: date), day: cal.component(.day, from: date))) ?? now
        if next < nowDate {
            next = cal.date(from: DateComponents(year: cal.component(.year, from: now) + 1, month: cal.component(.month, from: date), day: cal.component(.day, from: date))) ?? now
        }
        return next
    }

    private func nextMonthly(_ date: Date, now: Date) -> Date {
        let cal = Calendar.current
        var targetYear = cal.component(.year, from: now)
        var targetMonth = cal.component(.month, from: now)
        if cal.component(.day, from: now) >= cal.component(.day, from: date) {
            targetMonth += 1
            if targetMonth > 12 { targetMonth = 1; targetYear += 1 }
        }
        let day = cal.component(.day, from: date)
        let lastDay = cal.range(of: .day, in: .month, for: DateComponents(calendar: cal, year: targetYear, month: targetMonth).date ?? now)?.count ?? 30
        return DateComponents(calendar: cal, year: targetYear, month: targetMonth, day: min(day, lastDay)).date ?? now
    }

    private func formatDateCounter(date: Date, repeats: Bool) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let target: Date
        if repeats {
            let next = nextYearly(date)
            target = cal.startOfDay(for: next)
        } else {
            target = cal.startOfDay(for: date)
        }
        let diff = cal.dateComponents([.day], from: today, to: target).day ?? 0
        if diff > 0 { return "Faltan \(diff) días" }
        if diff == 0 { return "¡Hoy!" }
        let past = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: today).day ?? 0
        return "\(past) días desde entonces"
    }

    // MARK: - Firestore

    private func startListening() {
        coupleDocRef.addSnapshotListener { snapshot, _ in
            guard let d = snapshot?.data() else { return }
            let p = { (k: String) -> Date? in
                if let ts = d[k] as? Timestamp { return ts.dateValue() }
                if let s = d[k] as? String { return yyyyMMdd.date(from: s) ?? ISO8601DateFormatter().date(from: s) }
                return nil
            }
            withAnimation {
                milestones.met = p("metDate")
                milestones.dating = p("datingDate")
                milestones.anniversary = p("anniversaryDate")
                milestones.wedding = p("weddingDate")
            }
        }

        importantDatesRef.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data(),
                  let items = data["items"] as? [[String: Any]] else { return }
            withAnimation {
                importantDates = items.compactMap { dict in
                    guard let id = dict["id"] as? String,
                          let title = dict["title"] as? String,
                          let dateStr = dict["date"] as? String else { return nil }
                    return ImportantDateItem(id: id, title: title, dateStr: dateStr, repeats: dict["repeats"] as? Bool ?? false)
                }
            }
        }
    }

    private func stopListening() {
        // snapshot listeners auto-remove when view disappears
    }

    private func syncImportantDates() {
        let dicts = importantDates.map { item -> [String: Any] in
            ["id": item.id, "title": item.title, "date": item.dateStr, "repeats": item.repeats]
        }
        try? importantDatesRef.setData(["items": dicts, "updatedAt": FieldValue.serverTimestamp()])
    }

    private func addImportantDate(name: String, date: Date, repeats: Bool) {
        let item = ImportantDateItem(
            id: "\(Int(Date().timeIntervalSince1970 * 1000))",
            title: name,
            dateStr: yyyyMMdd.string(from: date),
            repeats: repeats
        )
        importantDates.append(item)
        syncImportantDates()
    }

    private func updateImportantDate(id: String, name: String, date: Date, repeats: Bool) {
        guard let idx = importantDates.firstIndex(where: { $0.id == id }) else { return }
        importantDates[idx].title = name
        importantDates[idx].dateStr = yyyyMMdd.string(from: date)
        importantDates[idx].repeats = repeats
        syncImportantDates()
    }

    private func deleteImportantDate(id: String) {
        importantDates.removeAll { $0.id == id }
        syncImportantDates()
    }
}

// MARK: - Milestone Config Sheet

private struct MilestoneConfigSheet: View {
    @Binding var met: Date?
    @Binding var dating: Date?
    @Binding var anniversary: Date?
    @Binding var wedding: Date?
    let coupleRef: DocumentReference
    @Environment(\.dismiss) private var dismiss

    @State private var metEnabled: Bool
    @State private var datingEnabled: Bool
    @State private var annEnabled: Bool
    @State private var weddingEnabled: Bool
    @State private var metDate: Date
    @State private var datingDate: Date
    @State private var annDate: Date
    @State private var weddingDate: Date

    init(met: Binding<Date?>, dating: Binding<Date?>, anniversary: Binding<Date?>, wedding: Binding<Date?>, coupleRef: DocumentReference) {
        _met = met; _dating = dating; _anniversary = anniversary; _wedding = wedding
        self.coupleRef = coupleRef
        _metEnabled = State(initialValue: met.wrappedValue != nil)
        _datingEnabled = State(initialValue: dating.wrappedValue != nil)
        _annEnabled = State(initialValue: anniversary.wrappedValue != nil)
        _weddingEnabled = State(initialValue: wedding.wrappedValue != nil)
        _metDate = State(initialValue: met.wrappedValue ?? Date())
        _datingDate = State(initialValue: dating.wrappedValue ?? Date())
        _annDate = State(initialValue: anniversary.wrappedValue ?? Date())
        _weddingDate = State(initialValue: wedding.wrappedValue ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                dateToggle(icon: "person.2.fill", label: "Nos conocimos", color: Color(red: 0.49, green: 0.51, blue: 1.0),
                    enabled: $metEnabled, date: $metDate)
                dateToggle(icon: "cup.and.saucer.fill", label: "Primera cita", color: Color(red: 1.0, green: 0.72, blue: 0.30),
                    enabled: $datingEnabled, date: $datingDate)
                dateToggle(icon: "heart.fill", label: "Aniversario (Novios)", color: ThemeManager.shared.primary,
                    enabled: $annEnabled, date: $annDate)
                dateToggle(icon: "ring", label: "Boda (Esposos)", color: Color(red: 0.7, green: 0.3, blue: 0.7),
                    enabled: $weddingEnabled, date: $weddingDate)
            }
            .navigationTitle("Fechas importantes").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { save() } }
            }
        }
        .presentationDetents([.large])
    }

    private func dateToggle(icon: String, label: String, color: Color, enabled: Binding<Bool>, date: Binding<Date>) -> some View {
        Section {
            Toggle(isOn: enabled) {
                HStack(spacing: 8) {
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 14))
                    Text(label).appFont(size: 14, weight: .medium)
                }
            }
            if enabled.wrappedValue {
                DatePicker("Fecha", selection: date, displayedComponents: .date)
                    .datePickerStyle(.graphical).tint(color)
            }
        }
    }

    private func save() {
        var fields: [String: Any] = [:]
        if metEnabled { fields["metDate"] = Timestamp(date: metDate) } else { fields["metDate"] = FieldValue.delete() }
        if datingEnabled { fields["datingDate"] = Timestamp(date: datingDate) } else { fields["datingDate"] = FieldValue.delete() }
        if annEnabled { fields["anniversaryDate"] = Timestamp(date: annDate) } else { fields["anniversaryDate"] = FieldValue.delete() }
        if weddingEnabled { fields["weddingDate"] = Timestamp(date: weddingDate) } else { fields["weddingDate"] = FieldValue.delete() }
        Task {
            try? await coupleRef.setData(fields, merge: true)
            // Also sync to user document for cross-device
            if let uid = AuthService.shared.currentUser?.id {
                let df = ISO8601DateFormatter()
                var userFields: [String: Any] = [:]
                if metEnabled { userFields["metDate"] = df.string(from: metDate) } else { userFields["metDate"] = "" }
                if datingEnabled { userFields["datingDate"] = df.string(from: datingDate) } else { userFields["datingDate"] = "" }
                if annEnabled { userFields["anniversaryDate"] = df.string(from: annDate) } else { userFields["anniversaryDate"] = "" }
                if weddingEnabled { userFields["weddingDate"] = df.string(from: weddingDate) } else { userFields["weddingDate"] = "" }
                try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: userFields)
            }
        }
        dismiss()
    }
}

// MARK: - Date Form Sheet

private struct DateFormSheet: View {
    let title: String
    var initialTitle: String = ""
    var initialDate: Date = Date()
    var initialRepeats: Bool = false
    let onSave: (String, Date, Bool) -> Void
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var nameText: String
    @State private var selectedDate: Date
    @State private var repeats: Bool
    @State private var showDatePicker = false

    init(title: String, initialTitle: String = "", initialDate: Date = Date(), initialRepeats: Bool = false, onSave: @escaping (String, Date, Bool) -> Void, onDelete: (() -> Void)? = nil) {
        self.title = title; self.initialTitle = initialTitle; self.initialDate = initialDate; self.initialRepeats = initialRepeats
        self.onSave = onSave; self.onDelete = onDelete
        _nameText = State(initialValue: initialTitle)
        _selectedDate = State(initialValue: initialDate)
        _repeats = State(initialValue: initialRepeats)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill").appFont(size: 16).foregroundColor(ThemeManager.shared.primary)
                    Text(title).appFont(size: 18, weight: .semibold)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nombre de la fecha").appFont(size: 12, weight: .medium).foregroundColor(.secondary)
                    TextField("Ej: Aniversario, Primera cita...", text: $nameText)
                        .appFont(size: 15).padding(14).background(.ultraThinMaterial).cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Fecha").appFont(size: 12, weight: .medium).foregroundColor(.secondary)
                    Button { showDatePicker = true } label: {
                        HStack {
                            Image(systemName: "calendar").appFont(size: 14).foregroundColor(ThemeManager.shared.primary)
                            Text(selectedDate.formatted(date: .long, time: .omitted)).appFont(size: 14, weight: .semibold).foregroundColor(ThemeManager.shared.primary)
                            Spacer()
                        }
                        .padding(14).background(ThemeManager.shared.primary.opacity(0.08)).cornerRadius(12)
                    }
                }

                Toggle(isOn: $repeats) {
                    Text("Se repite cada año").appFont(size: 14)
                }.tint(ThemeManager.shared.primary)

                Spacer()

                HStack(spacing: 12) {
                    if let onDelete = onDelete {
                        Button(role: .destructive) { onDelete() } label: {
                            Text("Eliminar").appFont(size: 14, weight: .medium).foregroundColor(.red)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3)))
                        }
                    }
                    Button { dismiss() } label: {
                        Text("Cancelar").appFont(size: 14, weight: .medium).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15)))
                    }
                    Button {
                        guard !nameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(nameText.trimmingCharacters(in: .whitespaces), selectedDate, repeats)
                    } label: {
                        Text("Guardar").appFont(size: 14, weight: .bold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(ThemeManager.shared.primaryGradient).cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    VStack(spacing: 16) {
                        DatePicker("Selecciona fecha", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical).tint(ThemeManager.shared.primary).padding()
                        Button { showDatePicker = false } label: {
                            Text("Listo").appFont(size: 16, weight: .bold).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(ThemeManager.shared.primaryGradient).cornerRadius(14).padding(.horizontal, 20)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancelar") { showDatePicker = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Date Formatter

private let yyyyMMdd: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()
