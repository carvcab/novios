import SwiftUI

public struct LiveStatusView: View {
    @StateObject private var statusService = StatusService.shared
    @State private var screenHistory: [(String, Date)] = []

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Avatar
                        let isOnline = statusService.isOnline
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: isOnline ? [.green, Color.green.opacity(0.7)] : [.gray.opacity(0.2), .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                                .shadow(color: isOnline ? .green.opacity(0.3) : .clear, radius: 24)
                            Image(systemName: isOnline ? "heart.fill" : "heart")
                                .font(.system(size: 46)).foregroundColor(.white)
                        }

                        let partnerName = UserDefaults.standard.string(forKey: "partner_name") ?? "Pareja"
                        Text(partnerName).font(.system(size: 22, weight: .bold)).foregroundColor(.primary)

                        // Online badge
                        HStack(spacing: 8) {
                            Circle().fill(isOnline ? Color.green : Color.gray.opacity(0.3)).frame(width: 8, height: 8)
                            Text(isOnline ? "En línea ahora" : "Desconectado")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isOnline ? .green : .primary.opacity(0.4))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(isOnline ? Color.green.opacity(0.12) : .primary.opacity(0.06))
                        .cornerRadius(20)

                        // Current app card (from Firestore)
                        GlassCard { appCardContent }
                        // Battery card
                        GlassCard { detailCard(icon: isCharging ? "battery.100.bolt" : "battery.100", label: "Batería", value: batteryValue, color: batteryColor, isActive: batteryLevel >= 0) }
                        // Last seen card
                        GlassCard { detailCard(icon: "clock", label: "Última vez activo", value: lastSeenText, color: .orange, isActive: lastSeen != nil) }
                        // Phone state card
                        GlassCard { phoneStateCard }
                        // Last notification card
                        if let notif = lastNotification {
                            GlassCard { lastNotificationCard(notif) }
                        }

                        // Screen share button
                        GlassCard {
                            NavigationLink(destination: ScreenShareView()) {
                                HStack(spacing: 14) {
                                    Image(systemName: "tv").font(.system(size: 22)).foregroundColor(ThemeManager.shared.primaryPink)
                                        .padding(10).background(ThemeManager.shared.primaryPink.opacity(0.12)).cornerRadius(12)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Compartir pantalla").font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                                        Text("Ver la pantalla de tu pareja en tiempo real").font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.primary.opacity(0.3))
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Screen history
                        if !screenHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath").foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Historial de pantallas").font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                                }
                                ForEach(screenHistory.prefix(15).indices, id: \.self) { i in
                                    let entry = screenHistory[i]
                                    GlassCard {
                                        HStack(spacing: 12) {
                                            Circle().fill(i == 0 ? Color.green : .primary.opacity(0.2)).frame(width: 6, height: 6)
                                            Text(entry.0).font(.system(size: 13, weight: .medium)).foregroundColor(.primary)
                                            Spacer()
                                            Text(timeString(entry.1)).font(.system(size: 11)).foregroundColor(.primary.opacity(0.4))
                                        }
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("💞 \(partnerName)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Data from StatusService

    private var status: [String: Any] { statusService.partnerStatus }
    private var partnerName: String { UserDefaults.standard.string(forKey: "partner_name") ?? "Pareja" }

    private var currentApp: String { status["currentApp"] as? String ?? status["currentScreen"] as? String ?? "" }
    private var currentAppLabel: String {
        let a = currentApp.lowercased()
        if a.contains("whatsapp") { return "WhatsApp" }
        if a.contains("instagram") { return "Instagram" }
        if a.contains("tiktok") { return "TikTok" }
        if a.contains("facebook") || a.contains("messenger") { return a.contains("messenger") ? "Messenger" : "Facebook" }
        if a.contains("twitter") || a.contains("x") { return "Twitter / X" }
        if a.contains("youtube") { return "YouTube" }
        if a.contains("telegram") { return "Telegram" }
        if a.contains("snapchat") { return "Snapchat" }
        if a.contains("gmail") || a.contains("mail") { return "Correo" }
        if a.contains("maps") { return "Google Maps" }
        if a.contains("spotify") || a.contains("music") { return "Música" }
        if a.contains("chrome") || a.contains("safari") { return "Navegador" }
        return currentApp.isEmpty ? "Ninguna" : currentApp
    }
    private var batteryLevel: Int { status["batteryLevel"] as? Int ?? -1 }
    private var isCharging: Bool { status["isCharging"] as? Bool ?? false }
    private var phoneState: String { status["phoneState"] as? String ?? "activo" }
    private var lastSeen: Date? { status["lastSeenDate"] as? Date }
    private var lastNotification: (app: String, title: String, text: String)? {
        guard let app = status["lastNotificationApp"] as? String, !app.isEmpty else { return nil }
        let title = status["lastNotificationTitle"] as? String ?? ""
        let text = status["lastNotificationText"] as? String ?? ""
        return (app, title, text)
    }

    private var batteryValue: String {
        batteryLevel >= 0 ? "\(batteryLevel)%\(isCharging ? "  Cargando" : "")" : "Desconocido"
    }
    private var batteryColor: Color {
        isCharging ? .green : (batteryLevel > 20 ? .green : (batteryLevel >= 0 ? .red : .gray))
    }

    private var lastSeenText: String {
        guard let ls = lastSeen else { return "Desconocido" }
        let f = DateFormatter()
        f.dateStyle = .short; f.timeStyle = .short
        return f.string(from: ls)
    }

    // MARK: - App Card

    private var appCardContent: some View {
        let hasApp = !currentApp.isEmpty && statusService.isOnline
        let color: Color
        let icon: String
        let label = currentAppLabel
        let a = currentApp.lowercased()

        if !hasApp {
            icon = "iphone"; color = .gray.opacity(0.4); label = statusService.isOnline ? "Sin datos de apps" : "Desconectado"
        } else if a.contains("whatsapp") { icon = "message.fill"; color = Color(red: 0.15, green: 0.83, blue: 0.4) }
        else if a.contains("instagram") { icon = "camera.fill"; color = Color(red: 0.89, green: 0.25, blue: 0.37) }
        else if a.contains("tiktok") { icon = "music.note"; color = .black }
        else if a.contains("facebook") || a.contains("messenger") { icon = "f.circle.fill"; color = Color(red: 0.09, green: 0.47, blue: 0.95) }
        else if a.contains("twitter") || a.contains("x") { icon = "bolt.fill"; color = Color(red: 0.11, green: 0.69, blue: 0.96) }
        else if a.contains("youtube") { icon = "play.rectangle.fill"; color = .red }
        else if a.contains("telegram") { icon = "paperplane.fill"; color = Color(red: 0, green: 0.53, blue: 0.8) }
        else if a.contains("snapchat") { icon = "ghost.fill"; color = .yellow }
        else if a.contains("gmail") || a.contains("mail") { icon = "envelope.fill"; color = Color(red: 0.92, green: 0.26, blue: 0.21) }
        else if a.contains("maps") { icon = "map.fill"; color = Color(red: 0.2, green: 0.66, blue: 0.33) }
        else if a.contains("spotify") || a.contains("music") { icon = "headphones"; color = Color(red: 0.11, green: 0.72, blue: 0.33) }
        else if a.contains("chrome") || a.contains("safari") { icon = "globe"; color = Color(red: 0.26, green: 0.52, blue: 0.96) }
        else { icon = "app.gift"; color = .blue }

        return AnyView(HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
                .padding(10).background(color.opacity(0.12)).cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Text(phoneState == "suspendido" ? "Última app (pantalla apagada)" : "Usando app")
                    .font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                Text(label).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
            }
            Spacer()
            Circle().fill(hasApp ? (phoneState == "suspendido" ? Color.orange : Color.green) : .gray.opacity(0.2))
                .frame(width: 10, height: 10)
        })
    }

    // MARK: - Detail Card

    private func detailCard(icon: String, label: String, value: String, color: Color, isActive: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
                .padding(10).background(color.opacity(0.12)).cornerRadius(12)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                Text(value).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
            }
            Spacer()
            Circle().fill(isActive ? Color.green : .gray.opacity(0.2)).frame(width: 10, height: 10)
        }
    }

    // MARK: - Phone State Card

    private var phoneStateCard: some View {
        let recentlySeen = lastSeen != nil && Date().timeIntervalSince(lastSeen!) < 130
        let effectiveState = statusService.isOnline ? phoneState : "apagado"
        let (label, stateColor, stateIcon): (String, Color, String)

        if statusService.isOnline || recentlySeen {
            switch effectiveState {
            case "suspendido": (label, stateColor, stateIcon) = ("suspendido (pantalla apagada)", .orange, "lock.rectangle")
            case "bloqueado": (label, stateColor, stateIcon) = ("bloqueado (pantalla bloqueada)", .orange, "lock.fill")
            case "apagado": (label, stateColor, stateIcon) = ("apagado (sin conexión)", .red, "poweroff")
            default: (label, stateColor, stateIcon) = ("encendido (activo)", .green, "iphone")
            }
        } else {
            (label, stateColor, stateIcon) = ("apagado o sin conexión", .gray.opacity(0.4), "wifi.slash")
        }

        return AnyView(detailCard(icon: stateIcon, label: "Estado del teléfono", value: label, color: stateColor, isActive: !label.contains("apagado")))
    }

    // MARK: - Last Notification Card

    private func lastNotificationCard(_ notif: (app: String, title: String, text: String)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.badge.fill").font(.system(size: 22)).foregroundColor(ThemeManager.shared.primaryPink)
                .padding(10).background(ThemeManager.shared.primaryPink.opacity(0.12)).cornerRadius(12)
            VStack(alignment: .leading, spacing: 2) {
                Text("Última notificación").font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                if !notif.app.isEmpty { Text(notif.app).font(.system(size: 12, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink) }
                if !notif.title.isEmpty { Text(notif.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary).lineLimit(1) }
                if !notif.text.isEmpty { Text(notif.text).font(.system(size: 12)).foregroundColor(.primary.opacity(0.6)).lineLimit(2) }
            }
            Spacer()
        }
    }

    private func timeString(_ d: Date) -> String {
        let c = Calendar.current
        return "\(c.component(.hour, from: d)):\(String(format: "%02d", c.component(.minute, from: d)))"
    }
}
