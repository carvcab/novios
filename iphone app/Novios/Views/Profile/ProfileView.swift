import SwiftUI
import PhotosUI

public struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var theme = ThemeManager.shared

    @State private var isLoading = true
    @State private var displayName = ""
    @State private var username = ""
    @State private var birthdayDate: Date?
    @State private var profilePhotoBase64: String?
    @State private var partnerName = ""
    @State private var partnerUid = ""

    @State private var streakCount = 0
    @State private var importantDates: [[String: Any]] = []

    @State private var showPhotoPicker = false
    @State private var showEditUsername = false
    @State private var showEditBirthday = false
    @State private var usernameText = ""
    @State private var showAddDate = false
    @State private var editingDateIndex: Int?
    @State private var editingDate: [String: Any]?
    @State private var showSettings = false

    private let defaults = UserDefaults.standard

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let df = ISO8601DateFormatter()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 60)
                            ProgressView().tint(theme.primary)
                            Text("Cargando perfil...")
                                .appFont(size: 14)
                                .foregroundColor(theme.textSecondary)
                        }
                    } else {
                        profileHeader
                        if !partnerUid.isEmpty {
                            partnerInfo
                        }
                        streakCard
                        importantDatesSection
                        quickActionsSection
                    }
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadUserData()
            loadStreak()
            loadImportantDates()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { image in
                if let data = image.jpegData(compressionQuality: 0.6) {
                    let base64 = data.base64EncodedString()
                    profilePhotoBase64 = base64
                    saveField("profilePhotoUrl", value: "data:image/jpeg;base64,\(base64)")
                }
            }
        }
        .alert("Editar usuario", isPresented: $showEditUsername) {
            TextField("Nombre de usuario", text: $usernameText)
            Button("Cancelar", role: .cancel) {}
            Button("Guardar") { saveUsername() }
        } message: {
            Text("Ingresa tu nombre de usuario")
        }
        .sheet(isPresented: $showEditBirthday) {
            BirthdayPickerView(selectedDate: birthdayDate ?? Date()) { date in
                birthdayDate = date
                let str = dateFormatter.string(from: date)
                saveField("birthdayDate", value: str)
                saveField("dob", value: str)
                defaults.set(str, forKey: "profile_dob")
            }
        }
        .sheet(isPresented: $showAddDate) {
            AddDateView(editingDate: editingDate) { title, dateStr, repeats in
                if title == "__delete__" {
                    if let idx = editingDateIndex, idx < importantDates.count {
                        importantDates.remove(at: idx)
                    }
                } else if let idx = editingDateIndex {
                    importantDates[idx] = ["title": title, "date": dateStr, "repeats": repeats]
                } else {
                    importantDates.append(["title": title, "date": dateStr, "repeats": repeats])
                }
                editingDateIndex = nil
                editingDate = nil
                saveImportantDates()
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Button {
                showPhotoPicker = true
            } label: {
                ZStack {
                    Group {
                        if let base64 = profilePhotoBase64,
                           let data = Data(base64Encoded: base64),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(theme.primary.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(displayName.prefix(1).uppercased())
                                        .appFont(size: 40, weight: .bold)
                                        .foregroundColor(theme.primary)
                                )
                        }
                    }
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 100, height: 100)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .appFont(size: 12)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(theme.primary)
                                .clipShape(Circle())
                                .offset(x: 2, y: 2)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }

            Text(displayName)
                .appFont(size: 22, weight: .bold)
                .foregroundColor(.primary)

            HStack(spacing: 4) {
                Image(systemName: "at")
                    .appFont(size: 13)
                    .foregroundColor(theme.primary.opacity(0.7))
                Text("@\(username)")
                    .appFont(size: 14)
                    .foregroundColor(theme.textSecondary)
                Button { showEditUsername = true } label: {
                    Image(systemName: "pencil")
                        .appFont(size: 10)
                        .foregroundColor(theme.primary.opacity(0.5))
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "cake.fill")
                    .appFont(size: 13)
                    .foregroundColor(theme.primary.opacity(0.7))
                if let bd = birthdayDate {
                    Text(bd.formatted(date: .long, time: .omitted))
                        .appFont(size: 14)
                        .foregroundColor(theme.textSecondary)
                    Button { showEditBirthday = true } label: {
                        Image(systemName: "pencil")
                            .appFont(size: 10)
                            .foregroundColor(theme.primary.opacity(0.5))
                    }
                } else {
                    Button { showEditBirthday = true } label: {
                        Text("Agregar cumpleaños")
                            .appFont(size: 13)
                            .foregroundColor(theme.primary)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .background(theme.cardBackground.opacity(0.3))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.6), theme.primary.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
        )
    }

    // MARK: - Partner Info

    private var partnerInfo: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(theme.secondary.opacity(0.25))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "heart.fill")
                        .appFont(size: 18)
                        .foregroundColor(theme.primary)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Vinculado con")
                    .appFont(size: 12)
                    .foregroundColor(theme.textSecondary)
                Text(partnerName)
                    .appFont(size: 15, weight: .semibold)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .background(theme.cardBackground.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primary.opacity(0.2), lineWidth: 0.8)
        )
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 10) {
            Image(systemName: partnerUid.isEmpty ? "link.ring" : "flame.fill")
                .appFont(size: 24)
                .foregroundColor(partnerUid.isEmpty ? theme.primary : .orange)
            Text(partnerUid.isEmpty
                ? "Vincula tu cuenta en Ajustes para iniciar tu racha!"
                : "Racha: \(streakCount) días seguidos"
            )
            .appFont(size: partnerUid.isEmpty ? 13 : 16, weight: .semibold)
            .foregroundColor(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .background(theme.cardBackground.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primary.opacity(0.15), lineWidth: 0.8)
        )
    }

    // MARK: - Important Dates

    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .appFont(size: 14)
                    .foregroundColor(theme.primary)
                Text("Fechas Importantes")
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    editingDateIndex = nil
                    editingDate = nil
                    showAddDate = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .appFont(size: 20)
                        .foregroundColor(theme.primary)
                }
            }
            .padding(.leading, 4)

            if importantDates.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .appFont(size: 32)
                        .foregroundColor(theme.textSecondary.opacity(0.3))
                    Text("No hay fechas importantes aún")
                        .appFont(size: 13)
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                    Button {
                        editingDateIndex = nil
                        editingDate = nil
                        showAddDate = true
                    } label: {
                        Text("Agregar fecha")
                            .appFont(size: 13, weight: .medium)
                            .foregroundColor(theme.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.ultraThinMaterial)
                .background(theme.cardBackground.opacity(0.3))
                .cornerRadius(16)
            } else {
                ForEach(importantDates.indices, id: \.self) { i in
                    let d = importantDates[i]
                    let title = d["title"] as? String ?? ""
                    let dateStr = d["date"] as? String ?? ""
                    let repeats = d["repeats"] as? Bool ?? false
                    let date = dateFormatter.date(from: dateStr)
                    let counter = date.map { formatDateCounter($0, repeats: repeats) } ?? ""

                    HStack(spacing: 12) {
                        Image(systemName: repeats ? "repeat" : "heart.fill")
                            .appFont(size: 14)
                            .foregroundColor(theme.primary)
                            .padding(10)
                            .background(theme.primary.opacity(0.1))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .appFont(size: 14, weight: .semibold)
                                .foregroundColor(.primary)
                            Text(counter)
                                .appFont(size: 11)
                                .foregroundColor(theme.textSecondary)
                        }

                        Spacer()

                        Button {
                            editingDateIndex = i
                            editingDate = d
                            showAddDate = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .appFont(size: 18)
                                .foregroundColor(theme.textSecondary.opacity(0.4))
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .background(theme.cardBackground.opacity(0.3))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    private func formatDateCounter(_ date: Date, repeats: Bool) -> String {
        let target: Date
        if repeats {
            let now = Date()
            let cal = Calendar.current
            let thisYear = cal.date(bySettingHour: 0, minute: 0, second: 0, of: cal.date(from: DateComponents(year: cal.component(.year, from: now), month: cal.component(.month, from: date), day: cal.component(.day, from: date)))!)!
            if thisYear < now {
                target = cal.date(byAdding: .year, value: 1, to: thisYear)!
            } else {
                target = thisYear
            }
        } else {
            target = date
        }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
        if diff > 0 { return "Faltan \(diff) días" }
        if diff == 0 { return "Hoy!" }
        let past = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(past) días desde entonces"
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2")
                    .appFont(size: 14)
                    .foregroundColor(theme.primary)
                Text("Accesos rápidos")
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 4)

            VStack(spacing: 8) {
                quickActionRow(icon: "gearshape.fill", title: "Ajustes", color: theme.primary) {
                    showSettings = true
                }
                quickActionRow(icon: "music.note", title: "Música", color: theme.pastelPeach) {
                    // Placeholder
                }
                quickActionRow(icon: "note.text", title: "Notas", color: theme.pastelMint) {
                    // Placeholder
                }
                quickActionRow(icon: "calendar", title: "Calendario", color: theme.pastelBlue) {
                    // Placeholder
                }
            }
        }
    }

    private func quickActionRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .appFont(size: 16)
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.15))
                    .cornerRadius(10)
                Text(title)
                    .appFont(size: 14, weight: .semibold)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .appFont(size: 12)
                    .foregroundColor(theme.textSecondary.opacity(0.4))
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .background(theme.cardBackground.opacity(0.3))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Firestore Data Loading

    private func loadUserData() {
        guard let uid = authService.currentUser?.id ?? FirebaseRESTService.shared.localId else {
            isLoading = false
            return
        }

        Task {
            if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "users/\(uid)"),
               let fields = doc["fields"] as? [String: Any] {
                await MainActor.run {
                    displayName = extractString(fields, key: "displayName")
                        ?? extractString(fields, key: "name")
                        ?? authService.currentUser?.displayName ?? "Usuario"
                    username = extractString(fields, key: "username")
                        ?? defaults.string(forKey: "profile_username") ?? ""
                    partnerName = extractString(fields, key: "partnerName")
                        ?? defaults.string(forKey: "partner_name") ?? ""
                    partnerUid = extractString(fields, key: "partnerUid") ?? ""

                    if let photoVal = extractString(fields, key: "profilePhotoUrl"), !photoVal.isEmpty {
                        if photoVal.hasPrefix("data:image") {
                            let base64 = photoVal.replacingOccurrences(of: "data:image/.*?;base64,", with: "", options: .regularExpression)
                            profilePhotoBase64 = base64
                        } else {
                            // Could be a URL - convert to base64 if needed
                        }
                    }

                    if let bdStr = extractString(fields, key: "birthdayDate")
                        ?? extractString(fields, key: "dob")
                        ?? defaults.string(forKey: "profile_dob") {
                        birthdayDate = dateFormatter.date(from: bdStr)
                            ?? df.date(from: bdStr)
                    }

                    isLoading = false
                }
                loadImportantDatesFromFirestore(fields: fields)
            } else {
                await MainActor.run {
                    displayName = authService.currentUser?.displayName ?? "Usuario"
                    username = defaults.string(forKey: "profile_username") ?? ""
                    partnerName = defaults.string(forKey: "partner_name") ?? ""
                    partnerUid = defaults.string(forKey: "partner_uid") ?? ""
                    if let bdStr = defaults.string(forKey: "profile_dob") {
                        birthdayDate = dateFormatter.date(from: bdStr)
                    }
                    isLoading = false
                }
            }
        }
    }

    private func loadImportantDatesFromFirestore(fields: [String: Any]) {
        if let datesJson = extractString(fields, key: "importantDatesJson"),
           let data = datesJson.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            importantDates = arr
            saveImportantDatesLocally()
        }
    }

    private func loadImportantDates() {
        if let data = defaults.data(forKey: "important_dates"),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            importantDates = arr
        }
    }

    private func saveImportantDates() {
        saveImportantDatesLocally()
        guard let uid = authService.currentUser?.id ?? FirebaseRESTService.shared.localId else { return }
        if let data = try? JSONSerialization.data(withJSONObject: importantDates),
           let json = String(data: data, encoding: .utf8) {
            Task {
                try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
                    "importantDatesJson": json
                ])
            }
        }
    }

    private func saveImportantDatesLocally() {
        if let data = try? JSONSerialization.data(withJSONObject: importantDates) {
            defaults.set(data, forKey: "important_dates")
        }
    }

    // MARK: - Streak

    private func loadStreak() {
        guard !partnerUid.isEmpty else {
            streakCount = 0
            return
        }
        let today = Date()
        let todayStr = dateFormatter.string(from: today)
        let lastDate = defaults.string(forKey: "last_streak_date") ?? ""

        if lastDate != todayStr {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            let yesterdayStr = dateFormatter.string(from: yesterday)

            if lastDate != yesterdayStr {
                streakCount = 1
            } else {
                streakCount = min(defaults.integer(forKey: "streak_count") + 1, 999)
            }
            defaults.set(streakCount, forKey: "streak_count")
            defaults.set(todayStr, forKey: "last_streak_date")
        } else {
            streakCount = max(defaults.integer(forKey: "streak_count"), 1)
        }
    }

    // MARK: - Save Helpers

    private func saveField(_ key: String, value: String) {
        guard let uid = authService.currentUser?.id ?? FirebaseRESTService.shared.localId else { return }
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [key: value])
        }
    }

    private func saveUsername() {
        let val = usernameText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !val.isEmpty else { return }
        username = val
        defaults.set(val, forKey: "profile_username")
        guard let uid = authService.currentUser?.id ?? FirebaseRESTService.shared.localId else { return }
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: ["username": val])
            try? await FirebaseRESTService.shared.firestoreSet(path: "usernames/\(val)", fields: [
                "uid": uid,
                "email": authService.currentUser?.email ?? ""
            ])
        }
    }

    // MARK: - Field Extractor

    private func extractString(_ fields: [String: Any], key: String) -> String? {
        guard let map = fields[key] as? [String: Any] else { return nil }
        return map["stringValue"] as? String ?? map["timestampValue"] as? String
    }
}

// MARK: - Photo Picker

struct PhotoPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async { self.parent.onImagePicked(uiImage) }
                }
            }
        }
    }
}

// MARK: - Birthday Picker

struct BirthdayPickerView: View {
    @State var selectedDate: Date
    let onSave: (Date) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker("Cumpleaños", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(ThemeManager.shared.primary)
                Button {
                    onSave(selectedDate)
                    dismiss()
                } label: {
                    Text("Guardar")
                        .appFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ThemeManager.shared.primaryGradient)
                        .cornerRadius(14)
                }
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add/Edit Date View

struct AddDateView: View {
    let editingDate: [String: Any]?
    let onSave: (String, String, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var repeats = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(editingDate != nil ? "Editar fecha" : "Nueva fecha")
                    .appFont(size: 18, weight: .semibold)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Nombre").appFont(size: 13, weight: .medium).foregroundColor(ThemeManager.shared.textSecondary)
                    TextField("Ej: Aniversario, Primera cita...", text: $title)
                        .appFont(size: 14)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .background(ThemeManager.shared.pastelWarmBg.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Fecha").appFont(size: 13, weight: .medium).foregroundColor(ThemeManager.shared.textSecondary)
                    DatePicker("Selecciona fecha", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(ThemeManager.shared.primary)
                }

                Toggle("Se repite cada año", isOn: $repeats)
                    .tint(ThemeManager.shared.primary)
                    .padding(.vertical, 4)

                HStack(spacing: 12) {
                    if editingDate != nil {
                        Button(role: .destructive) {
                            onSave("__delete__", "", false)
                            dismiss()
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                                .appFont(size: 14, weight: .medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3)))
                        }
                    }
                    Button {
                        let trimmed = title.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let dateStr = dateFormatter.string(from: date)
                        onSave(trimmed, dateStr, repeats)
                        dismiss()
                    } label: {
                        Text("Guardar")
                            .appFont(size: 15, weight: .bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ThemeManager.shared.primaryGradient)
                            .cornerRadius(14)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                if let ed = editingDate {
                    title = ed["title"] as? String ?? ""
                    repeats = ed["repeats"] as? Bool ?? false
                    if let dateStr = ed["date"] as? String, let d = dateFormatter.date(from: dateStr) {
                        date = d
                    }
                }
            }
        }
    }
}
