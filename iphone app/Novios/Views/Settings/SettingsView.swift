import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userService = UserService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var showingAddPartner = false

    @State private var isRedMode = false

    @State private var showDatePicker = false
    @State private var datePickerLabel = ""
    @State private var datePickerHandler: ((Date) -> Void)?
    @State private var datePickerColor = Color.primary

    @State private var anniversaryDate: Date?
    @State private var metDate: Date?
    @State private var datingDate: Date?
    @State private var weddingDate: Date?
    @State private var invitationDate: Date?

    @State private var shareLocation = false
    @State private var securityEnabled = false
    @State private var pinCode = ""
    @State private var securityQuestion = ""
    @State private var securityAnswer = ""

    @State private var aiMode = 0
    @State private var deepseekKey = ""
    @State private var isDownloadingModel = false
    @State private var modelDownloaded = false

    private let fonts = ["Inter", "Playfair Display", "Outfit", "Pacifico", "Poppins"]
    private let defaults = UserDefaults.standard

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    partnerSection
                    personalizationSection
                    importantDatesSection
                    locationSection
                    securitySection
                    aiSection
                    saveButton
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .appFont(size: 22)
                            .foregroundColor(theme.primary.opacity(0.5))
                    }
                }
            }
            .onAppear {
                loadSettings()
                userService.loadPartnerFromDefaults()
                Task { await userService.fetchPartnerFromFirestore() }
            }
            .sheet(isPresented: $showingAddPartner) {
                AddPartnerView()
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(label: datePickerLabel, onSelect: datePickerHandler ?? { _ in }, color: datePickerColor)
            }
        }
    }

    // MARK: - Partner Section

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "heart.fill", title: "Mi Pareja")
            GlassCard {
                if userService.partnerUser != nil {
                    HStack(spacing: 12) {
                        Circle().fill(theme.primary.opacity(0.25)).frame(width: 48, height: 48)
                            .overlay(Image(systemName: "person.fill").appFont(size: 20).foregroundColor(theme.primary))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(userService.partnerUser?.displayName ?? "Pareja")
                                .appFont(size: 16, weight: .semibold)
                            let uname = userService.partnerUser?.username ?? ""
                            let email = userService.partnerUser?.email ?? ""
                            let subtitle = !uname.isEmpty ? "@\(uname)" : (!email.isEmpty ? email : "Conectado")
                            Text(subtitle)
                                .appFont(size: 13).foregroundColor(theme.textSecondary)
                        }
                        Spacer()
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus").appFont(size: 24).foregroundColor(theme.primary)
                        Text("Aún no has agregado a tu pareja")
                            .appFont(size: 14).foregroundColor(theme.textSecondary)
                        Spacer()
                    }
                    Button {
                        showingAddPartner = true
                    } label: {
                        Text("Buscar y agregar pareja")
                            .appFont(size: 14, weight: .semibold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(theme.primaryGradient).cornerRadius(14)
                    }
                }
            }
        }
    }

    // MARK: - Personalization

    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "paintpalette.fill", title: "Personalización")
            GlassCard {
                Toggle(isOn: Binding(get: { theme.isDarkMode }, set: { theme.isDarkMode = $0 })) {
                    HStack(spacing: 8) {
                        Image(systemName: theme.isDarkMode ? "moon.fill" : "moon").foregroundColor(theme.primary)
                            .appFont(size: 14)
                        Text("Modo oscuro").appFont(size: 14, weight: .medium)
                    }
                }
                .tint(theme.primary)
                Divider().padding(.vertical, 4)
                Toggle(isOn: Binding(get: { theme.isRedMode }, set: { theme.isRedMode = $0 })) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill").foregroundColor(theme.redAccent).appFont(size: 14)
                        Text("Modo rojo").appFont(size: 14, weight: .medium)
                    }
                }
                .tint(theme.redAccent)
                Divider().padding(.vertical, 4)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "textformat").foregroundColor(theme.primary).appFont(size: 13)
                        Text("Fuente / Tipografía")
                            .appFont(size: 13, weight: .medium)
                            .foregroundColor(theme.textSecondary)
                    }
                    Picker("Fuente", selection: Binding(get: { theme.fontFamily }, set: { theme.fontFamily = $0 })) {
                        ForEach(fonts, id: \.self) { font in
                            HStack {
                                Text(font).appFont(size: 16, weight: .regular)
                            }.tag(font)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    // MARK: - Important Dates

    private var importantDatesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "calendar", title: "Fechas Importantes")
            GlassCard {
                dateRow(icon: "heart.fill", label: "Aniversario de novios",
                    subtitle: "Cuando se hicieron novios", date: $anniversaryDate, color: theme.primary)
                Divider().padding(.vertical, 6)
                dateRow(icon: "person.2.fill", label: "Día que nos conocimos",
                    subtitle: "El día que se conocieron", date: $metDate, color: theme.pastelBlue)
                Divider().padding(.vertical, 6)
                dateRow(icon: "cup.and.saucer.fill", label: "Primera cita",
                    subtitle: "Su primera cita juntos", date: $datingDate, color: theme.pastelPeach)
                Divider().padding(.vertical, 6)
                dateRow(icon: "person.fill", label: "Boda",
                    subtitle: "Cuando se casaron", date: $weddingDate, color: theme.pastelMint)
                Divider().padding(.vertical, 6)
                dateRow(icon: "envelope.badge.fill", label: "Invitación en Vivo",
                    subtitle: "Invitación a la boda", date: $invitationDate, color: theme.secondary)
            }
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "location.fill", title: "Ubicación en Vivo")
            GlassCard {
                Toggle(isOn: $shareLocation) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compartir ubicación en tiempo real").appFont(size: 14, weight: .medium)
                        Text("Tu pareja podrá ver donde estás").appFont(size: 11).foregroundColor(theme.textSecondary)
                    }
                }
                .tint(theme.primary)
                Divider().padding(.vertical, 4)
                HStack(spacing: 6) {
                    Image(systemName: shareLocation ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(shareLocation ? theme.pastelMint : .gray).appFont(size: 14)
                    Text(shareLocation ? "Compartiendo ubicación" : "Ubicación no compartida")
                        .appFont(size: 12, weight: .medium).foregroundColor(shareLocation ? theme.pastelMint : .gray)
                }
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill").foregroundColor(theme.pastelBlue).appFont(size: 12)
                    Text("Alertas al entrar/salir de zonas").appFont(size: 12).foregroundColor(theme.textSecondary)
                }.padding(.top, 4)
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill").foregroundColor(theme.pastelPeach).appFont(size: 12)
                    Text("Historial de ubicación 24h").appFont(size: 12).foregroundColor(theme.textSecondary)
                }.padding(.top, 2)
                if shareLocation {
                    Divider().padding(.vertical, 6)
                    HStack(spacing: 12) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Voy a casa", systemImage: "house.fill")
                                .appFont(size: 12, weight: .semibold).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(
                                    LinearGradient(colors: [theme.pastelMint, Color(red: 0.5, green: 0.8, blue: 0.5)],
                                        startPoint: .leading, endPoint: .trailing)
                                ).cornerRadius(12)
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Llegué bien", systemImage: "checkmark.circle.fill")
                                .appFont(size: 12, weight: .semibold).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(
                                    LinearGradient(colors: [theme.pastelBlue, Color(red: 0.5, green: 0.6, blue: 0.9)],
                                        startPoint: .leading, endPoint: .trailing)
                                ).cornerRadius(12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "lock.fill", title: "Seguridad")
            GlassCard {
                Toggle(isOn: $securityEnabled) {
                    Text("Bloquear con PIN al abrir").appFont(size: 14, weight: .medium)
                }
                .tint(theme.primary)
                if securityEnabled {
                    VStack(spacing: 10) {
                        SecureField("Código PIN (4 dígitos)", text: $pinCode)
                            .appFont(size: 14).keyboardType(.numberPad)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .background(theme.pastelWarmBg.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        TextField("Pregunta Secreta de Recuperación", text: $securityQuestion)
                            .appFont(size: 14)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .background(theme.pastelWarmBg.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        SecureField("Respuesta Secreta", text: $securityAnswer)
                            .appFont(size: 14)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .background(theme.pastelWarmBg.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    }
                    .padding(.top, 6)
                }
            }
        }
    }

    // MARK: - AI Services

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "brain.head.profile", title: "Servicios de IA")
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Motor de IA").appFont(size: 13, weight: .medium).foregroundColor(theme.textSecondary)
                    Picker("Motor de IA", selection: $aiMode) {
                        Text("DeepSeek API (Online)").tag(0)
                        Text("DeepSeek Local (Sin Internet)").tag(1)
                    }
                    .pickerStyle(.menu)
                    if aiMode == 0 {
                        SecureField("DeepSeek API Key", text: $deepseekKey)
                            .appFont(size: 14)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .background(theme.pastelWarmBg.opacity(0.2))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        Text("Obtén una key en platform.deepseek.com/api_keys")
                            .appFont(size: 10).foregroundColor(theme.textSecondary)
                    }
                    if aiMode == 1 {
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "iphone.gen3").foregroundColor(theme.pastelMint)
                                Text("El modelo DeepSeek R1 1.5B se descarga una vez (~1.1 GB) y corre 100% offline")
                                    .appFont(size: 11).foregroundColor(theme.pastelMint)
                            }
                            if modelDownloaded {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(theme.pastelMint)
                                    Text("Modelo instalado y listo").appFont(size: 12, weight: .bold).foregroundColor(theme.pastelMint)
                                }
                                Button {
                                    modelDownloaded = false
                                } label: {
                                    Label("Eliminar modelo", systemImage: "trash")
                                        .appFont(size: 13).foregroundColor(.red)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3)))
                                }
                            } else {
                                Button {
                                    isDownloadingModel = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        isDownloadingModel = false
                                        modelDownloaded = true
                                    }
                                } label: {
                                    HStack {
                                        if isDownloadingModel { ProgressView().tint(.white) }
                                        else { Image(systemName: "arrow.down.circle.fill") }
                                        Text(isDownloadingModel ? "Descargando..." : "Descargar Modelo Local")
                                    }
                                    .appFont(size: 13, weight: .semibold).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(
                                        LinearGradient(colors: [theme.pastelMint, Color(red: 0.5, green: 0.8, blue: 0.5)],
                                            startPoint: .leading, endPoint: .trailing)
                                    ).cornerRadius(10)
                                }
                                .disabled(isDownloadingModel)
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .background(theme.pastelMint.opacity(0.06))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.pastelMint.opacity(0.2), lineWidth: 0.5))
                    }
                }
            }
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveSettings()
        } label: {
            Text("Guardar Todas las Configuraciones")
                .appFont(size: 16, weight: .bold).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(theme.primaryGradient).cornerRadius(16)
                .shadow(color: theme.primary.opacity(0.2), radius: 8, y: 3)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).appFont(size: 14).foregroundColor(theme.primary)
            Text(title).appFont(size: 16, weight: .semibold)
        }
        .padding(.leading, 4).padding(.bottom, 2)
    }

    private func dateRow(icon: String, label: String, subtitle: String, date: Binding<Date?>, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).appFont(size: 16).foregroundColor(color)
                .padding(8).background(color.opacity(0.1)).cornerRadius(10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).appFont(size: 14, weight: .semibold)
                if let d = date.wrappedValue {
                    Text(d.formatted(date: .long, time: .omitted))
                        .appFont(size: 12, weight: .bold).foregroundColor(theme.primary)
                } else {
                    Text(subtitle).appFont(size: 11).foregroundColor(theme.textSecondary)
                }
            }
            Spacer()
            Button(date.wrappedValue != nil ? "Cambiar" : "Elegir") {
                showDatePicker(for: label, binding: date, color: color)
            }
            .appFont(size: 12, weight: .medium)
            .foregroundColor(theme.primary)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.primary.opacity(0.3)))
        }
    }

    private func showDatePicker(for label: String, binding: Binding<Date?>, color: Color) {
        datePickerLabel = label
        datePickerHandler = { date in binding.wrappedValue = date }
        datePickerColor = color
        showDatePicker = true
    }

    private func loadSettings() {
        theme.isDarkMode = defaults.bool(forKey: "is_dark_mode")
        theme.isRedMode = defaults.bool(forKey: "is_red_mode")
        theme.fontFamily = defaults.string(forKey: "font_family") ?? "Inter"
        isRedMode = theme.isRedMode
        securityEnabled = defaults.bool(forKey: "security_enabled")
        pinCode = defaults.string(forKey: "pin_code") ?? ""
        securityQuestion = defaults.string(forKey: "security_question") ?? ""
        securityAnswer = defaults.string(forKey: "security_answer") ?? ""
        deepseekKey = defaults.string(forKey: "deepseek_api_key") ?? ""
        shareLocation = defaults.bool(forKey: "share_location")
        anniversaryDate = dateFromDefaults("anniversary_date")
        metDate = dateFromDefaults("met_date")
        datingDate = dateFromDefaults("dating_date")
        weddingDate = dateFromDefaults("wedding_date")
        invitationDate = dateFromDefaults("invitation_date")
        aiMode = defaults.integer(forKey: "ai_mode")
        modelDownloaded = defaults.bool(forKey: "model_downloaded")

        Task { await loadCoupleSettings() }
    }

    private func saveSettings() {
        defaults.set(theme.isDarkMode, forKey: "is_dark_mode")
        defaults.set(theme.isRedMode, forKey: "is_red_mode")
        defaults.set(theme.fontFamily, forKey: "font_family")
        defaults.set(securityEnabled, forKey: "security_enabled")
        defaults.set(pinCode, forKey: "pin_code")
        defaults.set(securityQuestion, forKey: "security_question")
        defaults.set(securityAnswer, forKey: "security_answer")
        defaults.set(deepseekKey, forKey: "deepseek_api_key")
        defaults.set(shareLocation, forKey: "share_location")
        defaults.set(aiMode, forKey: "ai_mode")
        dateToDefaults("anniversary_date", date: anniversaryDate)
        dateToDefaults("met_date", date: metDate)
        dateToDefaults("dating_date", date: datingDate)
        dateToDefaults("wedding_date", date: weddingDate)
        dateToDefaults("invitation_date", date: invitationDate)

        if let uid = AuthService.shared.currentUser?.id {
            Task {
                try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(uid)", fields: [
                    "isDarkMode": theme.isDarkMode,
                    "isRedMode": theme.isRedMode,
                    "fontFamily": theme.fontFamily,
                    "anniversaryDate": anniversaryDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "metDate": metDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "datingDate": datingDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "weddingDate": weddingDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "invitationDate": invitationDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                ])

                if let coupleId = defaults.string(forKey: "couple_id"), !coupleId.isEmpty {
                    try? await FirebaseRESTService.shared.firestoreSet(path: "couples/\(coupleId)", fields: [
                        "anniversaryDate": anniversaryDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                        "metDate": metDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                        "datingDate": datingDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                        "weddingDate": weddingDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                        "invitationDate": invitationDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                        "isDarkMode": theme.isDarkMode,
                        "isRedMode": theme.isRedMode,
                        "fontFamily": theme.fontFamily,
                    ])
                }
            }
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func loadCoupleSettings() async {
        guard let coupleId = defaults.string(forKey: "couple_id"), !coupleId.isEmpty,
              let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "couples/\(coupleId)"),
              let fields = doc["fields"] as? [String: Any] else { return }

        let s = { (key: String) -> String? in (fields[key] as? [String: Any])?["stringValue"] as? String }
        let b = { (key: String) -> Bool? in (fields[key] as? [String: Any])?["booleanValue"] as? Bool }
        let formatter = ISO8601DateFormatter()

        if let val = s("anniversaryDate"), let d = formatter.date(from: val) {
            anniversaryDate = d; dateToDefaults("anniversary_date", date: d)
        }
        if let val = s("metDate"), let d = formatter.date(from: val) {
            metDate = d; dateToDefaults("met_date", date: d)
        }
        if let val = s("datingDate"), let d = formatter.date(from: val) {
            datingDate = d; dateToDefaults("dating_date", date: d)
        }
        if let val = s("weddingDate"), let d = formatter.date(from: val) {
            weddingDate = d; dateToDefaults("wedding_date", date: d)
        }
        if let val = s("invitationDate"), let d = formatter.date(from: val) {
            invitationDate = d; dateToDefaults("invitation_date", date: d)
        }

        if let val = b("isDarkMode") { theme.isDarkMode = val; defaults.set(val, forKey: "is_dark_mode") }
        if let val = b("isRedMode") { theme.isRedMode = val; isRedMode = val; defaults.set(val, forKey: "is_red_mode") }
        if let val = s("fontFamily"), !val.isEmpty { theme.fontFamily = val; defaults.set(val, forKey: "font_family") }
    }

    private func dateFromDefaults(_ key: String) -> Date? {
        guard let s = defaults.string(forKey: key) else { return nil }
        return ISO8601DateFormatter().date(from: s) ?? DateFormatter.yyyyMMdd.date(from: s)
    }

    private func dateToDefaults(_ key: String, date: Date?) {
        if let d = date { defaults.set(ISO8601DateFormatter().string(from: d), forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }
}

// MARK: - Date Picker Helper

private struct DatePickerView: View {
    let label: String
    let onSelect: (Date) -> Void
    let color: Color
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(label).appFont(size: 18, weight: .semibold)
                DatePicker("Selecciona fecha", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical).tint(color)
                Button {
                    onSelect(selectedDate)
                    dismiss()
                } label: {
                    Text("Guardar").appFont(size: 16, weight: .bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(ThemeManager.shared.primaryGradient).cornerRadius(14)
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

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
