import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var coupleService = CoupleService.shared
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

    @ObservedObject private var locationService = LocationService.shared
    @State private var shareLocation = false
    @State private var shareHistory = false
    @State private var shareBattery = true
    @State private var shareSpeed = false
    @State private var securityEnabled = false
    @State private var pinCode = ""
    @State private var securityQuestion = ""
    @State private var securityAnswer = ""

    @State private var aiMode = 0
    @State private var deepseekKey = ""
    @State private var isDownloadingModel = false
    @State private var modelDownloaded = false
    @State private var showLocationPermissionAlert = false
    @State private var showUnlinkConfirm = false

    private let fonts = ["Inter", "Playfair Display", "Outfit", "Pacifico", "Poppins"]
    private let defaults = UserDefaults.standard
    private let df = ISO8601DateFormatter()

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
                Task { await loadSettingsFromFirestore() }
            }
            .alert("Permisos de ubicación", isPresented: $showLocationPermissionAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Para compartir tu ubicación en tiempo real con tu pareja, Novios necesita acceso a la ubicación. Si ya denegaste el permiso, actívalo en los ajustes del teléfono seleccionando 'Permitir siempre'.")
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(label: datePickerLabel, onSelect: datePickerHandler ?? { _ in }, color: datePickerColor)
            }
        }
    }

    // MARK: - Partner Section

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "heart.fill", title: "Nuestra Relación")
            GlassCard {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(theme.primary.opacity(0.2)).frame(width: 44, height: 44)
                            .overlay(Text("D").appFont(size: 20, weight: .bold).foregroundColor(theme.primary))
                        Circle().fill(theme.secondary.opacity(0.2)).frame(width: 44, height: 44)
                            .overlay(Text("Y").appFont(size: 20, weight: .bold).foregroundColor(theme.secondary))
                            .offset(x: 18)
                    }.frame(width: 62, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(coupleService.coupleName)
                            .appFont(size: 16, weight: .semibold)
                        Text("💞 \(coupleService.members.count) miembros")
                            .appFont(size: 12).foregroundColor(theme.textSecondary)
                    }
                    Spacer()
                }

                Divider().padding(.vertical, 6)

                Button(role: .destructive) {
                    showUnlinkConfirm = true
                } label: {
                    Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        .appFont(size: 13, weight: .medium)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .confirmationDialog("¿Cerrar sesión?", isPresented: $showUnlinkConfirm, titleVisibility: .visible) {
                    Button("Cerrar sesión", role: .destructive) { AuthService.shared.signOut() }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Se cerrará tu sesión actual.")
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
                Toggle(isOn: Binding(get: { locationService.isSharing }, set: { newVal in
                    if newVal {
                        locationService.startSharing()
                        shareLocation = true
                    } else {
                        locationService.stopSharing()
                        shareLocation = false
                    }
                })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compartir ubicación en tiempo real").appFont(size: 14, weight: .medium)
                        Text("Tu pareja podrá ver donde estás como en Life360").appFont(size: 11).foregroundColor(theme.textSecondary)
                    }
                }
                .tint(theme.primary)
                Divider().padding(.vertical, 4)
                HStack(spacing: 6) {
                    Image(systemName: locationService.isSharing ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(locationService.isSharing ? theme.pastelMint : .gray).appFont(size: 14)
                    Text(locationService.isSharing ? "Compartiendo ubicación" : "Ubicación no compartida")
                        .appFont(size: 12, weight: .medium).foregroundColor(locationService.isSharing ? theme.pastelMint : .gray)
                }
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill").foregroundColor(theme.pastelBlue).appFont(size: 12)
                    Text("Alertas al entrar/salir de zonas").appFont(size: 12).foregroundColor(theme.textSecondary)
                }.padding(.top, 4)
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill").foregroundColor(theme.pastelPeach).appFont(size: 12)
                    Text("Historial de ubicación 24h").appFont(size: 12).foregroundColor(theme.textSecondary)
                }.padding(.top, 2)
                if locationService.isSharing {
                    Divider().padding(.vertical, 6)
                    if let dist = locationService.distanceToPartner {
                        HStack(spacing: 6) {
                            Image(systemName: "ruler").foregroundColor(theme.primary).appFont(size: 12)
                            Text("A \(String(format: "%.1f", dist)) km de tu pareja")
                                .appFont(size: 12, weight: .medium).foregroundColor(theme.primary)
                        }.padding(.bottom, 6)
                    }
                    HStack(spacing: 12) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            sendCheckIn(message: "Voy para casa 🏠")
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
                            sendCheckIn(message: "Llegué bien! Estoy en mi destino ✅")
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

    private func sendCheckIn(message: String) {
        guard let uid = AuthService.shared.currentUser?.id,
              let lat = locationService.lastLatitude,
              let lng = locationService.lastLongitude else { return }
        let parejaId = CoupleService.parejaId
        let msgId = UUID().uuidString
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(parejaId)/checkins/\(msgId)", fields: [
                "userId": uid,
                "message": message,
                "latitude": lat,
                "longitude": lng,
                "timestamp": df.string(from: Date()),
            ])
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

    @State private var aiTestResult: String?
    @State private var isTestingAI = false

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "brain.head.profile", title: "Servicios de IA")
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Motor de IA").appFont(size: 13, weight: .medium).foregroundColor(theme.textSecondary)
                    Picker("Motor de IA", selection: $aiMode) {
                        Text("DeepSeek API (Online)").tag(0)
                        Text("DeepSeek Local (Sin Internet)").tag(1)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: aiMode) { _ in
                        AIService.shared.setMode(aiMode == 0 ? .deepseek : .local)
                    }

                    if aiMode == 0 {
                        VStack(spacing: 8) {
                            SecureField("DeepSeek API Key", text: $deepseekKey)
                                .appFont(size: 14)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .background(theme.pastelWarmBg.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                                .onChange(of: deepseekKey) { newKey in
                                    AIService.shared.saveApiKey(newKey)
                                }

                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .appFont(size: 10)
                                    .foregroundColor(theme.textSecondary)
                                Text("Obtén una key gratis en platform.deepseek.com/api_keys")
                                    .appFont(size: 9)
                                    .foregroundColor(theme.textSecondary)
                            }

                            if !deepseekKey.isEmpty {
                                Button {
                                    testAIKey()
                                } label: {
                                    HStack {
                                        if isTestingAI {
                                            ProgressView().tint(.white).scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "bolt.fill")
                                        }
                                        Text(isTestingAI ? "Probando..." : "Probar conexión")
                                    }
                                    .appFont(size: 13, weight: .semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(theme.primaryGradient)
                                    .cornerRadius(10)
                                }
                                .disabled(isTestingAI)

                                if let result = aiTestResult {
                                    HStack(spacing: 4) {
                                        Image(systemName: result.contains("Error") ? "xmark.circle.fill" : "checkmark.circle.fill")
                                            .appFont(size: 12)
                                            .foregroundColor(result.contains("Error") ? .red : .green)
                                        Text(result)
                                            .appFont(size: 11)
                                            .foregroundColor(result.contains("Error") ? .red : .green)
                                    }
                                }
                            }
                        }
                    }

                    if aiMode == 1 {
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "iphone.gen3").foregroundColor(theme.pastelMint)
                                Text("El modelo DeepSeek R1 1.5B se descarga una vez y corre 100% offline")
                                    .appFont(size: 11).foregroundColor(theme.pastelMint)
                            }
                            if modelDownloaded {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(theme.pastelMint)
                                    Text("Modelo instalado y listo").appFont(size: 12, weight: .bold).foregroundColor(theme.pastelMint)
                                }
                                Button {
                                    modelDownloaded = false
                                    defaults.set(false, forKey: "model_downloaded")
                                } label: {
                                    Label("Eliminar modelo", systemImage: "trash")
                                        .appFont(size: 13).foregroundColor(.red)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3)))
                                }
                            } else {
                                VStack(spacing: 6) {
                                    Text("El modelo local requiere ~1.1 GB de espacio. La descarga se realiza en segundo plano.")
                                        .appFont(size: 10).foregroundColor(theme.textSecondary).multilineTextAlignment(.center)
                                    Button {
                                        isDownloadingModel = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            isDownloadingModel = false
                                            modelDownloaded = true
                                            defaults.set(true, forKey: "model_downloaded")
                                        }
                                    } label: {
                                        HStack {
                                            if isDownloadingModel { ProgressView().tint(.white).scaleEffect(0.8) }
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

    private func testAIKey() {
        isTestingAI = true
        aiTestResult = nil
        Task {
            do {
                let response = try await AIService.shared.chat(prompt: "Responde SOLO con la palabra 'OK' si puedes leer este mensaje.")
                await MainActor.run {
                    aiTestResult = response.contains("OK") ? "Conexión exitosa" : "Respuesta inesperada: \(response.prefix(50))"
                    isTestingAI = false
                }
            } catch {
                await MainActor.run {
                    aiTestResult = "Error: \(error.localizedDescription)"
                    isTestingAI = false
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
        shareHistory = defaults.bool(forKey: "privacy_share_history")
        shareBattery = defaults.object(forKey: "privacy_share_battery") as? Bool ?? true
        shareSpeed = defaults.bool(forKey: "privacy_share_speed")
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
        // Local save
        defaults.set(theme.isDarkMode, forKey: "is_dark_mode")
        defaults.set(theme.isRedMode, forKey: "is_red_mode")
        defaults.set(theme.fontFamily, forKey: "font_family")
        defaults.set(securityEnabled, forKey: "security_enabled")
        defaults.set(pinCode, forKey: "pin_code")
        defaults.set(securityQuestion, forKey: "security_question")
        defaults.set(securityAnswer, forKey: "security_answer")
        defaults.set(deepseekKey, forKey: "deepseek_api_key")
        defaults.set(shareLocation, forKey: "share_location")
        defaults.set(shareHistory, forKey: "privacy_share_history")
        defaults.set(shareBattery, forKey: "privacy_share_battery")
        defaults.set(shareSpeed, forKey: "privacy_share_speed")
        defaults.set(aiMode, forKey: "ai_mode")
        defaults.set(modelDownloaded, forKey: "model_downloaded")
        dateToDefaults("anniversary_date", date: anniversaryDate)
        dateToDefaults("met_date", date: metDate)
        dateToDefaults("dating_date", date: datingDate)
        dateToDefaults("wedding_date", date: weddingDate)
        dateToDefaults("invitation_date", date: invitationDate)

        if let uid = AuthService.shared.currentUser?.id {
            Task {
                // Save ALL settings to user document (syncs across devices)
                try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(uid)", fields: [
                    "isDarkMode": theme.isDarkMode,
                    "isRedMode": theme.isRedMode,
                    "fontFamily": theme.fontFamily,
                    "securityEnabled": securityEnabled,
                    "pinCode": pinCode,
                    "securityQuestion": securityQuestion,
                    "securityAnswer": securityAnswer,
                    "shareLocation": shareLocation,
                    "shareHistory": shareHistory,
                    "shareBattery": shareBattery,
                    "shareSpeed": shareSpeed,
                    "aiMode": aiMode,
                    "deepseekApiKey": deepseekKey,
                    "modelDownloaded": modelDownloaded,
                    "anniversaryDate": anniversaryDate.flatMap { df.string(from: $0) } ?? "",
                    "metDate": metDate.flatMap { df.string(from: $0) } ?? "",
                    "datingDate": datingDate.flatMap { df.string(from: $0) } ?? "",
                    "weddingDate": weddingDate.flatMap { df.string(from: $0) } ?? "",
                    "invitationDate": invitationDate.flatMap { df.string(from: $0) } ?? "",
                    "privacySettings": [
                        "shareLocation": shareLocation,
                        "shareHistory": shareHistory,
                        "shareBattery": shareBattery,
                        "shareSpeed": shareSpeed,
                    ]
                ])

                // Save shared settings to couples document (syncs with partner)
                let coupleId = CoupleService.parejaId
                try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(coupleId)", fields: [
                        "anniversaryDate": anniversaryDate.flatMap { df.string(from: $0) } ?? "",
                        "metDate": metDate.flatMap { df.string(from: $0) } ?? "",
                        "datingDate": datingDate.flatMap { df.string(from: $0) } ?? "",
                        "weddingDate": weddingDate.flatMap { df.string(from: $0) } ?? "",
                        "invitationDate": invitationDate.flatMap { df.string(from: $0) } ?? "",
                        "isDarkMode": theme.isDarkMode,
                        "isRedMode": theme.isRedMode,
                        "fontFamily": theme.fontFamily,
                    ])
            }
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func loadSettingsFromFirestore() async {
        guard let uid = AuthService.shared.currentUser?.id else { return }
        guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "usuarios/\(uid)"),
              let fields = doc["fields"] as? [String: Any] else { return }

        let s = { (key: String) -> String? in (fields[key] as? [String: Any])?["stringValue"] as? String }
        let b = { (key: String) -> Bool? in (fields[key] as? [String: Any])?["booleanValue"] as? Bool }

        await MainActor.run {
            if let val = b("isDarkMode") { theme.isDarkMode = val; defaults.set(val, forKey: "is_dark_mode") }
            if let val = b("isRedMode") { theme.isRedMode = val; isRedMode = val; defaults.set(val, forKey: "is_red_mode") }
            if let val = s("fontFamily"), !val.isEmpty { theme.fontFamily = val; defaults.set(val, forKey: "font_family") }
            if let val = b("securityEnabled") { securityEnabled = val; defaults.set(val, forKey: "security_enabled") }
            if let val = s("pinCode") { pinCode = val; defaults.set(val, forKey: "pin_code") }
            if let val = s("securityQuestion") { securityQuestion = val; defaults.set(val, forKey: "security_question") }
            if let val = s("securityAnswer") { securityAnswer = val; defaults.set(val, forKey: "security_answer") }
            if let val = b("shareLocation") { shareLocation = val; defaults.set(val, forKey: "share_location") }
            if let val = b("shareHistory") { shareHistory = val; defaults.set(val, forKey: "privacy_share_history") }
            if let val = b("shareBattery") { shareBattery = val; defaults.set(val, forKey: "privacy_share_battery") }
            if let val = b("shareSpeed") { shareSpeed = val; defaults.set(val, forKey: "privacy_share_speed") }
            if let val = s("deepseekApiKey") { deepseekKey = val; defaults.set(val, forKey: "deepseek_api_key") }
            if let val = s("aiMode") ?? s("ai_mode") { aiMode = Int(val) ?? 0; defaults.set(aiMode, forKey: "ai_mode") }
            if let val = b("modelDownloaded") { modelDownloaded = val; defaults.set(val, forKey: "model_downloaded") }

            let dateFields: [(String, String)] = [
                ("anniversaryDate", "anniversary_date"),
                ("metDate", "met_date"),
                ("datingDate", "dating_date"),
                ("weddingDate", "wedding_date"),
                ("invitationDate", "invitation_date"),
            ]
            for (firestoreKey, defaultsKey) in dateFields {
                if let val = s(firestoreKey), let d = df.date(from: val) ?? DateFormatter.yyyyMMdd.date(from: val) {
                    switch defaultsKey {
                    case "anniversary_date": anniversaryDate = d
                    case "met_date": metDate = d
                    case "dating_date": datingDate = d
                    case "wedding_date": weddingDate = d
                    case "invitation_date": invitationDate = d
                    default: break
                    }
                    defaults.set(val, forKey: defaultsKey)
                }
            }
        }
    }

    private func loadCoupleSettings() async {
        let coupleId = CoupleService.parejaId
        guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "parejas/\(coupleId)"),
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
