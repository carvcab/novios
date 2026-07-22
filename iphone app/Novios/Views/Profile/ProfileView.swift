import SwiftUI
import PhotosUI

public struct ProfileView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var couple = CoupleService.shared

    @State private var streak = 0
    @State private var importantDates: [ImportantDate] = []
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var profileImageUrl: String = ""

    @State private var showAddDate = false
    @State private var showEditDate: ImportantDate?
    @State private var showCalendar = false
    @State private var activeSheet: ActiveSheet?

    enum ActiveSheet: Identifiable {
        case settings
        case music
        case letters
        case games
        case map
        case dreams

        var id: Int {
            switch self {
            case .settings: return 1
            case .music: return 2
            case .letters: return 3
            case .games: return 4
            case .map: return 5
            case .dreams: return 6
            }
        }
    }

    private let defaults = UserDefaults.standard

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    streakSection
                    importantDatesSection
                    actionGridSection
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .appFont(size: 18)
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .onAppear {
                loadStreak()
                loadImportantDates()
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .settings: SettingsView()
                case .music: MusicView()
                case .letters: LettersView()
                case .games: GamesView()
                case .map: LocationView()
                case .dreams: GoalsView()
                }
            }
            .sheet(isPresented: $showAddDate) {
                addDateSheet
            }
            .sheet(item: $showEditDate) { date in
                editDateSheet(date)
            }
            .sheet(isPresented: $showCalendar) {
                calendarSheet
            }
            .onChange(of: photoPickerItem) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                    profileImageData = data
                    await uploadProfilePhoto(data: data)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                let myName = auth.currentUser?.nombre ?? couple.currentName
                let partnerName = couple.partnerName
                let myInitial = String(myName.prefix(1)).uppercased()
                let partnerInitial = String(partnerName.prefix(1)).uppercased()

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    ZStack {
                        if let data = profileImageData, let img = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 86, height: 86).clipShape(Circle())
                        } else if !profileImageUrl.isEmpty, let data = Data(base64Encoded: profileImageUrl), let img = UIImage(data: data) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 86, height: 86).clipShape(Circle())
                        } else {
                            Circle().fill(theme.primary.opacity(0.2)).frame(width: 86, height: 86)
                                .overlay(Text(myInitial).appFont(size: 34, weight: .bold).foregroundColor(theme.primary))
                        }
                        Circle().stroke(.white, lineWidth: 3).frame(width: 86, height: 86)
                    }
                }
                .offset(x: -30, y: 5)

                Circle().fill(theme.secondary.opacity(0.2)).frame(width: 76, height: 76)
                    .overlay(Text(partnerInitial).appFont(size: 28, weight: .bold).foregroundColor(theme.secondary))
                    .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 2))
                    .offset(x: 35, y: -15)

                Text("\u{1F49E}")
                    .font(.system(size: 16))
                    .padding(4)
                    .background(Color.white.clipShape(Circle()))
                    .shadow(color: .black.opacity(0.1), radius: 4)
                    .offset(x: 5, y: -30)
            }
            .frame(height: 110)

            HStack(spacing: 6) {
                Text(auth.currentUser?.nombre ?? couple.currentName)
                    .appFont(size: 22, weight: .bold)
                Text("\u{1F49E}")
                    .font(.system(size: 16))
                Text(couple.partnerName)
                    .appFont(size: 22, weight: .bold)
            }
            .foregroundColor(.primary)
        }
    }

    // MARK: - Streak

    private var streakSection: some View {
        Button {
            showCalendar = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .appFont(size: 24)
                    .foregroundColor(.orange)
                Text("Racha: \(streak) días seguidos \u{1F525}")
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.primary.opacity(0.1)))
        }
    }

    // MARK: - Important Dates

    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .appFont(size: 16)
                    .foregroundColor(theme.primary)
                Text("Fechas Importantes")
                    .appFont(size: 16, weight: .semibold)
                Spacer()
                Button {
                    showAddDate = true
                } label: {
                    Image(systemName: "plus")
                        .appFont(size: 14, weight: .bold)
                        .foregroundColor(theme.primary)
                        .padding(8)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            if importantDates.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .appFont(size: 32)
                        .foregroundColor(.primary.opacity(0.15))
                    Text("No hay fechas importantes aún")
                        .appFont(size: 13)
                        .foregroundColor(.primary.opacity(0.4))
                    Button {
                        showAddDate = true
                    } label: {
                        Text("Agregar fecha")
                            .appFont(size: 13)
                            .foregroundColor(theme.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            } else {
                ForEach(importantDates) { date in
                    Button {
                        showEditDate = date
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .appFont(size: 14)
                                .foregroundColor(theme.primary)
                                .padding(10)
                                .background(theme.primary.opacity(0.1))
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(date.title)
                                    .appFont(size: 14, weight: .semibold)
                                    .foregroundColor(.primary)
                                Text(formatDateCounter(date))
                                    .appFont(size: 11)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                withAnimation {
                                    importantDates.removeAll { $0.id == date.id }
                                    saveImportantDates()
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .appFont(size: 12)
                                    .foregroundColor(.red.opacity(0.5))
                                    .padding(8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                    }
                }
            }
        }
    }

    // MARK: - Action Grid

    private var actionGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .appFont(size: 16)
                    .foregroundColor(theme.primary)
                Text("Accesos rápidos")
                    .appFont(size: 16, weight: .semibold)
            }
            .padding(.leading, 4)

            VStack(spacing: 8) {
                actionRow(icon: "music.note.list", title: "Música", color: theme.pastelPeach) {
                    activeSheet = .music
                }
                actionRow(icon: "envelope.fill", title: "Cartas", color: theme.primary) {
                    activeSheet = .letters
                }
                actionRow(icon: "sportscourt.fill", title: "Juegos", color: .purple) {
                    activeSheet = .games
                }
                actionRow(icon: "location.fill", title: "Mapa", color: .green) {
                    activeSheet = .map
                }
                actionRow(icon: "star.fill", title: "Sueños", color: .orange) {
                    activeSheet = .dreams
                }
                actionRow(icon: "calendar", title: "Fechas Importantes", color: theme.pastelBlue) {
                    showCalendar = true
                }
            }
        }
    }

    private func actionRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .appFont(size: 16)
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)

                Text(title)
                    .appFont(size: 14, weight: .semibold)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .appFont(size: 12, weight: .semibold)
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.1)))
        }
    }

    // MARK: - Add Date Sheet

    private var addDateSheet: some View {
        DateFormView(
            title: "Nueva fecha",
            icon: "heart.fill",
            onSave: { title, date, repeats in
                let newDate = ImportantDate(title: title, date: date, repeats: repeats)
                importantDates.append(newDate)
                saveImportantDates()
                showAddDate = false
            }
        )
    }

    private func editDateSheet(_ date: ImportantDate) -> some View {
        DateFormView(
            title: "Editar fecha",
            icon: "pencil",
            initialTitle: date.title,
            initialDate: date.date,
            initialRepeats: date.repeats,
            onSave: { newTitle, newDate, newRepeats in
                if let idx = importantDates.firstIndex(where: { $0.id == date.id }) {
                    importantDates[idx].title = newTitle
                    importantDates[idx].date = newDate
                    importantDates[idx].repeats = newRepeats
                    saveImportantDates()
                }
                showEditDate = nil
            },
            onDelete: {
                withAnimation {
                    importantDates.removeAll { $0.id == date.id }
                    saveImportantDates()
                }
                showEditDate = nil
            }
        )
    }

    // MARK: - Calendar Sheet

    private var calendarSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Capsule()
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                Text("Fechas Importantes")
                    .appFont(size: 20, weight: .bold)

                if importantDates.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .appFont(size: 40)
                            .foregroundColor(.secondary.opacity(0.2))
                        Text("Agrega fechas desde la sección de arriba")
                            .appFont(size: 13)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    List {
                        ForEach(importantDates) { date in
                            HStack(spacing: 12) {
                                Image(systemName: date.repeats ? "arrow.triangle.2.circlepath" : "heart.fill")
                                    .appFont(size: 14)
                                    .foregroundColor(theme.primary)
                                    .padding(10)
                                    .background(theme.primary.opacity(0.1))
                                    .cornerRadius(10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(date.title)
                                        .appFont(size: 14, weight: .semibold)
                                    Text("\(date.date.formatted(date: .numeric, time: .omitted)) - \(formatDateCounter(date))")
                                        .appFont(size: 11)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()

                Button("Cerrar") {
                    showCalendar = false
                }
                .appFont(size: 15)
                .foregroundColor(theme.primary)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Streak Logic

    private func loadStreak() {
        let partnerUid = couple.partnerUid
        guard !partnerUid.isEmpty else { streak = 0; return }

        let lastDate = defaults.string(forKey: "last_streak_date") ?? ""
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: Date())

        if lastDate != todayStr {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let yesterdayStr = df.string(from: yesterday)

            if lastDate != yesterdayStr {
                streak = 1
            } else {
                streak = min(defaults.integer(forKey: "streak_count") + 1, 999)
            }
            defaults.set(streak, forKey: "streak_count")
            defaults.set(todayStr, forKey: "last_streak_date")
            saveStreakToFirestore()
        } else {
            streak = max(defaults.integer(forKey: "streak_count"), 1)
        }
    }

    private func saveStreakToFirestore() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: Date())
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "parejas/\(CoupleService.parejaId)/datos/streak",
                fields: [
                    "count": streak,
                    "lastDate": todayStr
                ]
            )
        }
    }

    // MARK: - Important Dates Persistence

    private func loadImportantDates() {
        if let data = defaults.data(forKey: "important_dates"),
           let decoded = try? JSONDecoder().decode([ImportantDate].self, from: data) {
            importantDates = decoded
        }
        Task { await loadImportantDatesFromFirestore() }
    }

    private func saveImportantDates() {
        if let data = try? JSONEncoder().encode(importantDates) {
            defaults.set(data, forKey: "important_dates")
        }
        Task { await saveImportantDatesToFirestore() }
    }

    private func saveImportantDatesToFirestore() async {
        let dicts = importantDates.map { date -> [String: Any] in
            let df = ISO8601DateFormatter()
            return [
                "title": date.title,
                "date": df.string(from: date.date),
                "repeats": date.repeats
            ]
        }
        try? await FirebaseRESTService.shared.firestoreSet(
            path: "parejas/\(CoupleService.parejaId)/datos/fechas",
            fields: ["lista": dicts]
        )
    }

    private func loadImportantDatesFromFirestore() async {
        guard let doc = try? await FirebaseRESTService.shared.firestoreGet(
            path: "parejas/\(CoupleService.parejaId)/datos/fechas"
        ),
        let fields = doc["fields"] as? [String: Any],
        let arrayVal = fields["lista"] as? [String: Any],
        let values = arrayVal["arrayValue"] as? [String: Any],
        let entries = values["values"] as? [[String: Any]] else { return }

        let df = ISO8601DateFormatter()
        var loaded: [ImportantDate] = []
        for entry in entries {
            guard let mapVal = entry["mapValue"] as? [String: Any],
                  let mapFields = mapVal["fields"] as? [String: Any] else { continue }
            let s = { (k: String) -> String in
                ((mapFields[k] as? [String: Any])?["stringValue"] as? String) ?? ""
            }
            let b = { (k: String) -> Bool in
                ((mapFields[k] as? [String: Any])?["booleanValue"] as? Bool) ?? false
            }
            if let date = df.date(from: s("date")) {
                loaded.append(ImportantDate(title: s("title"), date: date, repeats: b("repeats")))
            }
        }
        if !loaded.isEmpty {
            await MainActor.run {
                importantDates = loaded
                if let data = try? JSONEncoder().encode(loaded) {
                    defaults.set(data, forKey: "important_dates")
                }
            }
        }
    }

    private func formatDateCounter(_ date: ImportantDate) -> String {
        let target: Date
        if date.repeats {
            let now = Date()
            let cal = Calendar.current
            let comps = cal.dateComponents([.month, .day], from: date.date)
            let thisYearOccurrence = cal.date(from: DateComponents(year: cal.component(.year, from: now), month: comps.month, day: comps.day))!
            let nowStart = cal.startOfDay(for: now)
            if thisYearOccurrence < nowStart || thisYearOccurrence == nowStart {
                target = cal.date(byAdding: .year, value: 1, to: thisYearOccurrence)!
            } else {
                target = thisYearOccurrence
            }
        } else {
            target = date.date
        }
        let diff = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: target
        ).day ?? 0
        if diff > 0 { return "Faltan \(diff) días" }
        if diff == 0 { return "Hoy!" }
        let past = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: date.date),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        return "\(past) días desde entonces"
    }

    // MARK: - Photo Upload

    private func uploadProfilePhoto(data: Data) async {
        let base64 = data.base64EncodedString()
        guard let uid = auth.currentUser?.id else { return }
        try? await FirebaseRESTService.shared.firestoreSet(
            path: "usuarios/\(uid)",
            fields: ["foto": base64]
        )
        await MainActor.run {
            profileImageUrl = base64
        }
    }
}

// MARK: - Important Date Model

public struct ImportantDate: Identifiable, Codable, Equatable {
    public var id = UUID()
    public var title: String
    public var date: Date
    public var repeats: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, date, repeats
    }
}

// MARK: - Date Form View

private struct DateFormView: View {
    let title: String
    let icon: String
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

    init(
        title: String,
        icon: String,
        initialTitle: String = "",
        initialDate: Date = Date(),
        initialRepeats: Bool = false,
        onSave: @escaping (String, Date, Bool) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.initialTitle = initialTitle
        self.initialDate = initialDate
        self.initialRepeats = initialRepeats
        self.onSave = onSave
        self.onDelete = onDelete
        _nameText = State(initialValue: initialTitle)
        _selectedDate = State(initialValue: initialDate)
        _repeats = State(initialValue: initialRepeats)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .appFont(size: 16)
                        .foregroundColor(ThemeManager.shared.primary)
                    Text(title)
                        .appFont(size: 18, weight: .semibold)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nombre de la fecha")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.secondary)
                    TextField("Ej: Aniversario, Primera cita...", text: $nameText)
                        .appFont(size: 15)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Fecha")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.secondary)
                    Button {
                        showDatePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .appFont(size: 14)
                                .foregroundColor(ThemeManager.shared.primary)
                            Text(selectedDate.formatted(date: .long, time: .omitted))
                                .appFont(size: 14, weight: .semibold)
                                .foregroundColor(ThemeManager.shared.primary)
                            Spacer()
                        }
                        .padding(14)
                        .background(ThemeManager.shared.primary.opacity(0.08))
                        .cornerRadius(12)
                    }
                }

                Toggle(isOn: $repeats) {
                    Text("Se repite cada año")
                        .appFont(size: 14)
                }
                .tint(ThemeManager.shared.primary)

                Spacer()

                HStack(spacing: 12) {
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Text("Eliminar")
                                .appFont(size: 14, weight: .medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3)))
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancelar")
                            .appFont(size: 14, weight: .medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15)))
                    }

                    Button {
                        guard !nameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(nameText.trimmingCharacters(in: .whitespaces), selectedDate, repeats)
                    } label: {
                        Text("Guardar")
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ThemeManager.shared.primaryGradient)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    VStack(spacing: 16) {
                        DatePicker(
                            "Selecciona fecha",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(ThemeManager.shared.primary)
                        .padding()
                        Button {
                            showDatePicker = false
                        } label: {
                            Text("Listo")
                                .appFont(size: 16, weight: .bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ThemeManager.shared.primaryGradient)
                                .cornerRadius(14)
                                .padding(.horizontal, 20)
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
