import SwiftUI

public struct LiveStatusScreen: View {
    @ObservedObject private var status = StatusService.shared
    @ObservedObject private var location = LocationService.shared
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var partnerName: String {
        status.partnerStatus["nombre"] as? String ?? CoupleService.shared.partnerName
    }

    private var isOnline: Bool {
        status.partnerStatus["isOnline"] as? Bool ?? false
    }

    private var currentScreen: String {
        status.partnerStatus["currentScreen"] as? String ?? (isOnline ? "En línea" : "Offline")
    }

    private var currentAppLabel: String {
        status.partnerStatus["currentAppLabel"] as? String ?? ""
    }

    private var currentApp: String {
        status.partnerStatus["currentApp"] as? String ?? ""
    }

    private var phoneState: String {
        status.partnerStatus["phoneState"] as? String ?? ""
    }

    private var batteryLevel: Int {
        status.partnerStatus["batteryLevel"] as? Int ?? location.partnerBattery ?? -1
    }

    private var isCharging: Bool {
        status.partnerStatus["isCharging"] as? Bool ?? false
    }

    private var lastSeenDate: Date? {
        status.partnerStatus["lastSeenDate"] as? Date
    }

    private var lastNotification: String {
        status.partnerStatus["lastNotification"] as? String ?? ""
    }

    private var lastNotificationTitle: String {
        status.partnerStatus["lastNotificationTitle"] as? String ?? ""
    }

    private var lastNotificationText: String {
        status.partnerStatus["lastNotificationText"] as? String ?? ""
    }

    private var lastNotificationTime: Date? {
        status.partnerStatus["lastNotificationTime"] as? Date
    }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    partnerHeader
                    if !phoneState.isEmpty || batteryLevel >= 0 {
                        deviceStatusSection
                    }
                    if isOnline {
                        currentAppSection
                    }
                    lastSeenSection
                    if !lastNotification.isEmpty {
                        lastNotificationSection
                    }
                    screenHistorySection
                    shareScreenButton
                }
                .padding(20)
            }
        }
        .navigationTitle("En Vivo")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in currentTime = Date() }
    }

    // MARK: - Partner Header

    private var partnerHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.backgroundGradient)
                    .frame(width: 80, height: 80)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(theme.primary.opacity(0.6))
                Circle()
                    .fill(isOnline ? Color.green : Color.gray)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 28, y: 28)
            }

            Text(partnerName)
                .appFont(size: 22, weight: .bold)
                .foregroundColor(theme.textPrimary)

            HStack(spacing: 6) {
                Circle()
                    .fill(isOnline ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(isOnline ? "En línea" : "Offline")
                    .appFont(size: 14)
                    .foregroundColor(isOnline ? .green : .secondary)
            }
        }
    }

    // MARK: - Device Status

    private var deviceStatusSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 12) {
                Text("Estado del dispositivo")
                    .appFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if batteryLevel >= 0 {
                    HStack {
                        Image(systemName: isCharging ? "battery.100.bolt" : "battery.100")
                            .font(.system(size: 18))
                            .foregroundColor(batteryLevel > 20 ? .green : .red)
                        Text("\(batteryLevel)%")
                            .appFont(size: 14, weight: .medium)
                        if isCharging {
                            Text("Cargando")
                                .appFont(size: 12)
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                }

                if !phoneState.isEmpty {
                    HStack {
                        Image(systemName: phoneIcon)
                            .font(.system(size: 16))
                            .foregroundColor(phoneColor)
                        Text(phoneStateLabel)
                            .appFont(size: 14)
                        Spacer()
                    }
                }
            }
        }
    }

    private var phoneIcon: String {
        switch phoneState {
        case "activo": return "iphone.radiowaves.left.and.right"
        case "bloqueado": return "lock.fill"
        case "suspendido": return "moon.fill"
        case "apagado": return "iphone.slash"
        default: return "iphone"
        }
    }

    private var phoneColor: Color {
        switch phoneState {
        case "activo": return .green
        case "bloqueado": return .orange
        case "suspendido": return .blue
        case "apagado": return .red
        default: return .secondary
        }
    }

    private var phoneStateLabel: String {
        switch phoneState {
        case "activo": return "Activo"
        case "bloqueado": return "Bloqueado"
        case "suspendido": return "Suspendido"
        case "apagado": return "Apagado"
        default: return phoneState
        }
    }

    // MARK: - Current App

    private var currentAppSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 10) {
                Text("Usando ahora")
                    .appFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Image(systemName: appIcon)
                        .font(.system(size: 32))
                        .foregroundColor(appColor)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(appColor.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentAppLabel.isEmpty ? currentApp : currentAppLabel)
                            .appFont(size: 15, weight: .medium)
                            .foregroundColor(theme.textPrimary)
                        Text(currentScreen)
                            .appFont(size: 12)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private var appIcon: String {
        let app = currentApp.lowercased()
        if app.contains("whatsapp") { return "message.fill" }
        if app.contains("instagram") || app.contains("facebook") { return "camera.fill" }
        if app.contains("tiktok") { return "music.note" }
        if app.contains("twitter") || app.contains("x") { return "message" }
        if app.contains("youtube") { return "video.fill" }
        if app.contains("telegram") { return "paperplane.fill" }
        if app.contains("snapchat") { return "ghost.fill" }
        if app.contains("gmail") || app.contains("mail") { return "envelope.fill" }
        if app.contains("chrome") || app.contains("safari") { return "globe" }
        if app.contains("maps") { return "map.fill" }
        if app.contains("spotify") || app.contains("music") { return "music.note.list" }
        if app.contains("phone") || app.contains("teléfono") { return "phone.fill" }
        if app.contains("camera") { return "camera.fill" }
        if app.contains("photos") || app.contains("fotos") || app.contains("gallery") { return "photo.fill" }
        if app.contains("settings") || app.contains("ajustes") { return "gear" }
        return "app.fill"
    }

    private var appColor: Color {
        let app = currentApp.lowercased()
        if app.contains("whatsapp") { return Color(red: 0.18, green: 0.8, blue: 0.44) }
        if app.contains("instagram") { return Color(red: 0.83, green: 0.21, blue: 0.51) }
        if app.contains("facebook") { return Color(red: 0.23, green: 0.35, blue: 0.6) }
        if app.contains("tiktok") { return .black }
        if app.contains("twitter") || app.contains("x") { return Color(red: 0.04, green: 0.05, blue: 0.06) }
        if app.contains("youtube") { return .red }
        if app.contains("telegram") { return Color(red: 0.06, green: 0.53, blue: 0.83) }
        if app.contains("snapchat") { return Color(red: 1, green: 0.96, blue: 0) }
        if app.contains("spotify") { return Color(red: 0.11, green: 0.73, blue: 0.33) }
        return theme.primary
    }

    // MARK: - Last Seen

    private var lastSeenSection: some View {
        GlassCard(cornerRadius: 18) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.secondary)
                Text(isOnline ? "En línea ahora" : "Visto \(lastSeenText)")
                    .appFont(size: 14)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    private var lastSeenText: String {
        guard let date = lastSeenDate else { return "desconocido" }
        let elapsed = Int(-date.timeIntervalSinceNow)
        if elapsed < 60 { return "hace \(elapsed)s" }
        if elapsed < 3600 { return "hace \(elapsed / 60)m" }
        if elapsed < 86400 { return "hace \(elapsed / 3600)h" }
        let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short
        return f.string(from: date)
    }

    // MARK: - Last Notification

    private var lastNotificationSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    Text("Última notificación")
                        .appFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    if let time = lastNotificationTime {
                        Text(time, style: .time)
                            .appFont(size: 11)
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Image(systemName: notificationAppIcon)
                        .font(.system(size: 16))
                        .foregroundColor(theme.primary)
                    Text(lastNotification)
                        .appFont(size: 12)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !lastNotificationTitle.isEmpty {
                    Text(lastNotificationTitle)
                        .appFont(size: 13, weight: .medium)
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !lastNotificationText.isEmpty {
                    Text(lastNotificationText)
                        .appFont(size: 12)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var notificationAppIcon: String {
        let app = lastNotification.lowercased()
        if app.contains("whatsapp") { return "message.fill" }
        if app.contains("instagram") { return "camera.fill" }
        if app.contains("tiktok") { return "music.note" }
        if app.contains("gmail") { return "envelope.fill" }
        if app.contains("telegram") { return "paperplane.fill" }
        return "bell.fill"
    }

    // MARK: - Screen History

    private var screenHistorySection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.secondary)
                    Text("Historial de pantalla")
                        .appFont(size: 14, weight: .semibold)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                screenHistoryContent
            }
        }
    }

    @ViewBuilder
    private var screenHistoryContent: some View {
        let currentInfo = isOnline ? [(screen: currentScreen, app: currentAppLabel.isEmpty ? currentApp : currentAppLabel, time: Date())] : []
        if currentInfo.isEmpty {
            Text("No hay historial disponible")
                .appFont(size: 12).foregroundColor(.secondary)
        } else {
            ForEach(Array(currentInfo.enumerated()), id: \.offset) { _, entry in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.green)
                    Text(entry.app.isEmpty ? entry.screen : entry.app)
                        .appFont(size: 13)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Text(entry.time, style: .time)
                        .appFont(size: 11)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Share Screen Button

    private var shareScreenButton: some View {
        Button {
            let alert = UIAlertController(title: "Compartir Pantalla", message: "Función próximamente disponible", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let vc = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                var top = vc
                while let p = top.presentedViewController { top = p }
                top.present(alert, animated: true)
            }
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Compartir Pantalla")
                    .appFont(size: 15, weight: .medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, 8)
    }
}
