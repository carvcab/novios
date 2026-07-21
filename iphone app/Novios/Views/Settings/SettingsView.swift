import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userService = UserService.shared
    @State private var showingAddPartner = false

    @State private var isDarkMode = false
    @State private var selectedFont = "Inter"

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
            .background(ThemeManager.shared.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22)).foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear(perform: loadSettings)
            .sheet(isPresented: $showingAddPartner) {
                AddPartnerView()
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
                        Circle().fill(ThemeManager.shared.primaryPink.opacity(0.15)).frame(width: 48, height: 48)
                            .overlay(Image(systemName: "person.fill").font(.system(size: 20)).foregroundColor(ThemeManager.shared.primaryPink))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("@\(userService.partnerUser?.username ?? "")")
                                .font(.system(size: 16, weight: .semibold))
                            Text(userService.partnerUser?.displayName ?? "Sin nombre")
                                .font(.system(size: 13)).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus").font(.system(size: 28)).foregroundColor(ThemeManager.shared.primaryPink)
                        Text("Aún no has agregado a tu pareja")
                            .font(.system(size: 14)).foregroundColor(.secondary)
                        Spacer()
                    }
                    Button {
                        showingAddPartner = true
                    } label: {
                        Text("Buscar y agregar pareja")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(ThemeManager.shared.primaryPink).cornerRadius(14)
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
                Toggle(isOn: $isDarkMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Modo oscuro").font(.system(size: 14, weight: .medium))
                    }
                }
                .tint(ThemeManager.shared.primaryPink)
                Divider().padding(.vertical, 4)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fuente / Tipografía").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                    Picker("Fuente", selection: $selectedFont) {
                        ForEach(fonts, id: \.self) { font in
                            Text(font).tag(font)
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
                    subtitle: "Cuando se hicieron novios", date: $anniversaryDate, color: ThemeManager.shared.primaryPink)
                Divider().padding(.vertical, 6)
                dateRow(icon: "person.2.fill", label: "Día que nos conocimos",
                    subtitle: "El día que se conocieron", date: $metDate, color: Color(red: 0.49, green: 0.51, blue: 1.0))
                Divider().padding(.vertical, 6)
                dateRow(icon: "cup.and.saucer.fill", label: "Primera cita",
                    subtitle: "Su primera cita juntos", date: $datingDate, color: Color(red: 1.0, green: 0.72, blue: 0.3))
                Divider().padding(.vertical, 6)
                dateRow(icon: "person.fill", label: "Boda",
                    subtitle: "Cuando se casaron", date: $weddingDate, color: Color(red: 0.4, green: 0.73, blue: 0.42))
                Divider().padding(.vertical, 6)
                dateRow(icon: "envelope.badge.fill", label: "Invitación en Vivo",
                    subtitle: "Invitación a la boda", date: $invitationDate, color: Color(red: 0.85, green: 0.4, blue: 0.65))
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
                        Text("Compartir ubicación en tiempo real").font(.system(size: 14, weight: .medium))
                        Text("Tu pareja podrá ver donde estás").font(.system(size: 11)).foregroundColor(.secondary)
                    }
                }
                .tint(ThemeManager.shared.primaryPink)
                Divider().padding(.vertical, 4)
                HStack(spacing: 6) {
                    Image(systemName: shareLocation ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(shareLocation ? .green : .gray).font(.system(size: 14))
                    Text(shareLocation ? "Compartiendo ubicación" : "Ubicación no compartida")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(shareLocation ? .green : .gray)
                }
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill").foregroundColor(.blue).font(.system(size: 12))
                    Text("Alertas al entrar/salir de zonas").font(.system(size: 12)).foregroundColor(.secondary)
                }.padding(.top, 4)
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill").foregroundColor(.orange).font(.system(size: 12))
                    Text("Historial de ubicación 24h").font(.system(size: 12)).foregroundColor(.secondary)
                }.padding(.top, 2)
                if shareLocation {
                    Divider().padding(.vertical, 6)
                    HStack(spacing: 12) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Voy a casa", systemImage: "house.fill")
                                .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(Color.green).cornerRadius(12)
                        }
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Llegué bien", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(Color.blue).cornerRadius(12)
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
                    Text("Bloquear con PIN al abrir").font(.system(size: 14, weight: .medium))
                }
                .tint(ThemeManager.shared.primaryPink)
                if securityEnabled {
                    VStack(spacing: 10) {
                        SecureField("Código PIN (4 dígitos)", text: $pinCode)
                            .font(.system(size: 14)).keyboardType(.numberPad)
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                        TextField("Pregunta Secreta de Recuperación", text: $securityQuestion)
                            .font(.system(size: 14))
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                        SecureField("Respuesta Secreta", text: $securityAnswer)
                            .font(.system(size: 14))
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)
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
                    Text("Motor de IA").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                    Picker("Motor de IA", selection: $aiMode) {
                        Text("DeepSeek API (Online)").tag(0)
                        Text("DeepSeek Local (Sin Internet)").tag(1)
                    }
                    .pickerStyle(.menu)
                    if aiMode == 0 {
                        SecureField("DeepSeek API Key", text: $deepseekKey)
                            .font(.system(size: 14))
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                        Text("Obtén una key en platform.deepseek.com/api_keys")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    if aiMode == 1 {
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "iphone.gen3").foregroundColor(.green)
                                Text("El modelo DeepSeek R1 1.5B se descarga una vez (~1.1 GB) y corre 100% offline")
                                    .font(.system(size: 11)).foregroundColor(.green).opacity(0.8)
                            }
                            if modelDownloaded {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                    Text("Modelo instalado y listo").font(.system(size: 12, weight: .bold)).foregroundColor(.green)
                                }
                                Button {
                                    modelDownloaded = false
                                } label: {
                                    Label("Eliminar modelo", systemImage: "trash")
                                        .font(.system(size: 13)).foregroundColor(.red)
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
                                        if isDownloadingModel {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "arrow.down.circle.fill")
                                        }
                                        Text(isDownloadingModel ? "Descargando..." : "Descargar Modelo Local")
                                    }
                                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Color.green).cornerRadius(10)
                                }
                                .disabled(isDownloadingModel)
                            }
                        }
                        .padding(10)
                        .background(Color.green.opacity(0.06)).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.15)))
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
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(ThemeManager.shared.neonGlowGradient).cornerRadius(16)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(ThemeManager.shared.primaryPink)
            Text(title).font(.system(size: 16, weight: .semibold))
        }
        .padding(.leading, 4).padding(.bottom, 2)
    }

    private func dateRow(icon: String, label: String, subtitle: String, date: Binding<Date?>, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                .padding(8).background(color.opacity(0.1)).cornerRadius(10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 14, weight: .semibold))
                if let d = date.wrappedValue {
                    Text(d.formatted(date: .long, time: .omitted))
                        .font(.system(size: 12, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                } else {
                    Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(date.wrappedValue != nil ? "Cambiar" : "Elegir") {
                showDatePicker(for: label, binding: date, color: color)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(ThemeManager.shared.primaryPink)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ThemeManager.shared.primaryPink.opacity(0.3)))
        }
    }

    private func showDatePicker(for label: String, binding: Binding<Date?>, color: Color) {
        let store = DateStore(binding: binding)
        let host = UIHostingController(
            rootView: DatePickerView(label: label, store: store, color: color)
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(host, animated: true)
        }
    }

    private func loadSettings() {
        isDarkMode = defaults.bool(forKey: "is_dark_mode")
        selectedFont = defaults.string(forKey: "font_family") ?? "Inter"
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
        let savedMode = defaults.integer(forKey: "ai_mode")
        aiMode = savedMode
        modelDownloaded = defaults.bool(forKey: "model_downloaded")
    }

    private func saveSettings() {
        defaults.set(isDarkMode, forKey: "is_dark_mode")
        defaults.set(selectedFont, forKey: "font_family")
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
                    "isDarkMode": isDarkMode,
                    "fontFamily": selectedFont,
                    "anniversaryDate": anniversaryDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "metDate": metDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "datingDate": datingDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "weddingDate": weddingDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                    "invitationDate": invitationDate.flatMap { ISO8601DateFormatter().string(from: $0) } ?? "",
                ])
            }
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func dateFromDefaults(_ key: String) -> Date? {
        guard let s = defaults.string(forKey: key) else { return nil }
        return ISO8601DateFormatter().date(from: s) ?? DateFormatter.yyyyMMdd.date(from: s)
    }

    private func dateToDefaults(_ key: String, date: Date?) {
        if let d = date {
            defaults.set(ISO8601DateFormatter().string(from: d), forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

// MARK: - Date Picker Helper

private class DateStore: ObservableObject {
    @Binding var date: Date?
    init(binding: Binding<Date?>) { _date = binding }
}

private struct DatePickerView: View {
    let label: String
    @StateObject var store: DateStore
    let color: Color
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(label).font(.system(size: 18, weight: .semibold))
                DatePicker("Selecciona fecha", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical).tint(color)
                Button {
                    store.date = selectedDate
                    UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.windows.first?.rootViewController }
                        .first?.dismiss(animated: true)
                } label: {
                    Text("Guardar").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(color).cornerRadius(14)
                }
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        UIApplication.shared.connectedScenes
                            .compactMap { ($0 as? UIWindowScene)?.windows.first?.rootViewController }
                            .first?.dismiss(animated: true)
                    }
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
