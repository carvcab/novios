import SwiftUI
import FirebaseFirestore

public struct DatesView: View {
    @State private var events: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var eventTitle = ""
    @State private var eventDate = ""
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var listsDoc: DocumentReference {
        db.collection("couples").document(coupleId).collection("lists").document("calendar_events")
    }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            if events.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .navigationTitle("Fechas Importantes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startListening() }
        .onDisappear { snapshotListener?.remove() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(theme.primary.opacity(0.5))
            Text("Sin eventos")
                .appFont(size: 18, weight: .semibold)
            Text("Agreguen fechas importantes 💕")
                .appFont(size: 13)
                .foregroundColor(.secondary)
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                anniversaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                sectionHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                if events.isEmpty {
                    emptyEventsMessage
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(events.indices, id: \.self) { i in
                            eventRow(events[i], index: i)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                addEventSection
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Color.clear.frame(height: 40)
            }
        }
    }

    private var anniversaryCard: some View {
        let anniversaryStr = UserDefaults.standard.string(forKey: "couple_anniversary_date")
            ?? UserDefaults.standard.string(forKey: "anniversary_date")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let anniversaryDate = anniversaryStr.flatMap { dateFormatter.date(from: $0) }

        let displayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "d 'de' MMMM 'de' yyyy"
            f.locale = Locale(identifier: "es")
            return f
        }()

        return GlassCard(cornerRadius: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aniversario")
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(theme.textPrimary)
                    if let date = anniversaryDate {
                        Text(displayFormatter.string(from: date))
                            .appFont(size: 12)
                            .foregroundColor(theme.textSecondary)
                        Text(anniversaryCountdown(from: date))
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(theme.primary)
                    } else {
                        Text("No configurado")
                            .appFont(size: 12)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16))
                .foregroundColor(theme.primary)
            Text("Fechas Importantes")
                .appFont(size: 16, weight: .bold)
                .foregroundColor(theme.textPrimary)
            Spacer()
        }
    }

    private var emptyEventsMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(theme.textSecondary.opacity(0.3))
            Text("No hay fechas agregadas aún")
                .appFont(size: 13)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func eventRow(_ event: [String: Any], index: Int) -> some View {
        let title = event["title"] as? String ?? ""
        let dateStr = event["date"] as? String ?? ""
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        let eventDate = df.date(from: dateStr)
        let isPast = eventDate.map { $0 < Calendar.current.startOfDay(for: Date()) } ?? false

        return GlassCard(cornerRadius: 16) {
            HStack(spacing: 12) {
                Image(systemName: isPast ? "calendar.badge.checkmark" : "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(isPast ? .gray : theme.primary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .appFont(size: 15, weight: .semibold)
                        .foregroundColor(isPast ? .secondary : theme.textPrimary)
                    Text(formattedDate(dateStr))
                        .appFont(size: 12)
                        .foregroundColor(isPast ? .secondary.opacity(0.6) : theme.textSecondary)
                    if let date = parseDate(dateStr) {
                        Text(eventCountdown(from: date))
                            .appFont(size: 12, weight: .medium)
                            .foregroundColor(isPast ? .secondary.opacity(0.5) : theme.primary)
                    }
                }
                Spacer()
                Button {
                    deleteEvent(event)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var addEventSection: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 12) {
                Text("Agregar Evento")
                    .appFont(size: 14, weight: .bold)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Nombre del evento", text: $eventTitle)
                    .appFont(size: 14)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15)))

                TextField("Fecha (YYYY-MM-DD)", text: $eventDate)
                    .appFont(size: 14)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15)))
                    .keyboardType(.numbersAndPunctuation)

                Button {
                    addEvent()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Agregar")
                            .appFont(size: 14, weight: .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(theme.primary)
                }
                .disabled(eventTitle.trimmingCharacters(in: .whitespaces).isEmpty || eventDate.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(eventTitle.trimmingCharacters(in: .whitespaces).isEmpty || eventDate.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
    }

    private func formattedDate(_ dateStr: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let date = df.date(from: dateStr) else { return dateStr }
        let displayDf = DateFormatter()
        displayDf.dateFormat = "d 'de' MMMM 'de' yyyy"
        displayDf.locale = Locale(identifier: "es")
        return displayDf.string(from: date)
    }

    private func parseDate(_ dateStr: String) -> Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df.date(from: dateStr)
    }

    private func anniversaryCountdown(from date: Date) -> String {
        let now = Date()
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        var next = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: cal.component(.month, from: date), day: cal.component(.day, from: date)))!
        if next < today {
            next = cal.date(from: DateComponents(year: cal.component(.year, from: now) + 1, month: cal.component(.month, from: date), day: cal.component(.day, from: date)))!
        }
        let days = cal.dateComponents([.day], from: today, to: next).day ?? 0
        if days == 0 { return "🎉 ¡Hoy es su aniversario!" }
        if days == 1 { return "Mañana es su aniversario 💕" }
        return "Próximo aniversario: \(days) días"
    }

    private func eventCountdown(from date: Date) -> String {
        let now = Date()
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let target = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: today, to: target).day ?? 0
        if days < 0 {
            let past = abs(days)
            if past == 0 { return "Hoy" }
            if past == 1 { return "Ayer" }
            return "Hace \(past) días"
        }
        if days == 0 { return "¡Hoy!" }
        if days == 1 { return "Mañana" }
        return "Faltan \(days) días"
    }

    private func startListening() {
        snapshotListener = listsDoc.addSnapshotListener { snapshot, _ in
            guard let data = snapshot?.data(),
                  let items = data["items"] as? [[String: Any]] else { return }
            DispatchQueue.main.async {
                self.events = items
            }
        }
    }

    private func saveToFirestore(_ items: [[String: Any]]) {
        try? listsDoc.setData(["items": items, "updatedAt": FieldValue.serverTimestamp()])
    }

    private func addEvent() {
        let trimmedTitle = eventTitle.trimmingCharacters(in: .whitespaces)
        let trimmedDate = eventDate.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty, !trimmedDate.isEmpty else { return }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        guard df.date(from: trimmedDate) != nil else { return }
        let newEvent: [String: Any] = [
            "id": "\(Int(Date().timeIntervalSince1970 * 1000))",
            "title": trimmedTitle,
            "date": trimmedDate,
        ]
        events.append(newEvent)
        saveToFirestore(events)
        eventTitle = ""
        eventDate = ""
    }

    private func deleteEvent(_ event: [String: Any]) {
        guard let idx = events.firstIndex(where: { ($0["id"] as? String) == (event["id"] as? String) }) else { return }
        events.remove(at: idx)
        saveToFirestore(events)
    }
}
