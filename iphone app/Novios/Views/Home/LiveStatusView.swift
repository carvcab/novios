import SwiftUI

private struct StatusData {
    var isOnline = false
    var currentScreen = ""
    var lastSeen: Date?
    var batteryLevel = -1
    var isCharging = false
    var currentApp = ""
    var currentAppLabel = ""
    var phoneState = "activo"
    var lastNotification: (app: String, title: String, text: String)?
    var lastNotificationTime: Date?
}

private let partnerName = "Valentina"

public struct LiveStatusView: View {
    @State private var status = StatusData()
    @State private var screenHistory: [(String, Date)] = []

    private let statusTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: status.isOnline ? [.green, Color.green.opacity(0.7)] : [.gray.opacity(0.2), .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                                .shadow(color: status.isOnline ? .green.opacity(0.3) : .clear, radius: 24)
                            Image(systemName: status.isOnline ? "heart.fill" : "heart")
                                .font(.system(size: 46)).foregroundColor(.white)
                        }

                        Text(partnerName).font(.system(size: 22, weight: .bold)).foregroundColor(.primary)

                        // Online badge
                        HStack(spacing: 8) {
                            Circle().fill(status.isOnline ? Color.green : Color.gray.opacity(0.3)).frame(width: 8, height: 8)
                            Text(status.isOnline ? "En línea ahora" : "Desconectado")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(status.isOnline ? .green : .primary.opacity(0.4))
                        }
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(status.isOnline ? Color.green.opacity(0.12) : .primary.opacity(0.06))
                        .cornerRadius(20)

                        // Current app card
                        GlassCard { appCardContent }
                        // Battery card
                        GlassCard { detailCard(icon: status.isCharging ? "battery.100.bolt" : "battery.100", label: "Batería", value: status.batteryLevel >= 0 ? "\(status.batteryLevel)%\(status.isCharging ? "  Cargando" : "")" : "Desconocido", color: status.isCharging ? .green : (status.batteryLevel > 20 ? .green : (status.batteryLevel >= 0 ? .red : .gray)), isActive: status.batteryLevel >= 0) }
                        // Last seen card
                        GlassCard { detailCard(icon: "clock", label: "Última vez activo", value: status.lastSeen != nil ? formatDateTime(status.lastSeen!) : "Desconocido", color: .orange, isActive: status.lastSeen != nil, trailing: status.lastSeen != nil ? Text(timeAgo(status.lastSeen!)).font(.system(size: 11)).foregroundColor(.primary.opacity(0.4)) : nil) }
                        // Phone state card
                        GlassCard { phoneStateCard }
                        // Last notification card
                        if let notif = status.lastNotification {
                            GlassCard { lastNotificationCard(app: notif.app, title: notif.title, text: notif.text, time: status.lastNotificationTime) }
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
                                            Text("\(Calendar.current.component(.hour, from: entry.1)):\(String(format: "%02d", Calendar.current.component(.minute, from: entry.1))):\(String(format: "%02d", Calendar.current.component(.second, from: entry.1)))")
                                                .font(.system(size: 11)).foregroundColor(.primary.opacity(0.4))
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
            .onReceive(statusTimer) { _ in updateMockStatus() }
            .onAppear { updateMockStatus() }
        }
    }

    private var appCardContent: some View {
        let hasApp = status.currentApp.isEmpty == false && status.isOnline
        let color: Color
        let icon: String
        let label: String
        let appLabel = status.currentAppLabel

        if !hasApp {
            icon = "iphone"
            color = .gray.opacity(0.4)
            label = status.isOnline ? "Sin datos de apps" : "Desconectado"
        } else {
            let a = status.currentApp.lowercased()
            if a.contains("whatsapp") { icon = "message.fill"; color = Color(red: 0.15, green: 0.83, blue: 0.4); label = appLabel.isEmpty ? "WhatsApp" : appLabel }
            else if a.contains("instagram") { icon = "camera.fill"; color = Color(red: 0.89, green: 0.25, blue: 0.37); label = "Instagram" }
            else if a.contains("tiktok") { icon = "music.note"; color = .black; label = "TikTok" }
            else if a.contains("facebook") || a.contains("messenger") { icon = "f.circle.fill"; color = Color(red: 0.09, green: 0.47, blue: 0.95); label = a.contains("messenger") ? "Messenger" : "Facebook" }
            else if a.contains("twitter") || a.contains("x") { icon = "bolt.fill"; color = Color(red: 0.11, green: 0.69, blue: 0.96); label = "Twitter / X" }
            else if a.contains("youtube") { icon = "play.rectangle.fill"; color = .red; label = "YouTube" }
            else if a.contains("telegram") { icon = "paperplane.fill"; color = Color(red: 0, green: 0.53, blue: 0.8); label = "Telegram" }
            else if a.contains("snapchat") { icon = "ghost.fill"; color = .yellow; label = "Snapchat" }
            else if a.contains("gmail") || a.contains("mail") { icon = "envelope.fill"; color = Color(red: 0.92, green: 0.26, blue: 0.21); label = "Correo" }
            else if a.contains("maps") { icon = "map.fill"; color = Color(red: 0.2, green: 0.66, blue: 0.33); label = "Google Maps" }
            else if a.contains("spotify") || a.contains("music") { icon = "headphones"; color = Color(red: 0.11, green: 0.72, blue: 0.33); label = "Música" }
            else if a.contains("chrome") || a.contains("browser") || a.contains("safari") { icon = "globe"; color = Color(red: 0.26, green: 0.52, blue: 0.96); label = "Navegador" }
            else if a.contains("phone") || a.contains("teléfono") { icon = "phone.fill"; color = .green; label = "Teléfono" }
            else { icon = "app.gift"; color = .blue; label = appLabel.isEmpty ? status.currentApp : appLabel }
        }

        return AnyView(HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
                .padding(10).background(color.opacity(0.12)).cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Text(status.phoneState == "suspendido" ? "Última app (pantalla apagada)" : "Usando app")
                    .font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                Text(label).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
            }
            Spacer()
            if hasApp {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(status.phoneState == "suspendido" ? "Suspendido" : "Activo")
                        .font(.system(size: 10)).foregroundColor(status.phoneState == "suspendido" ? .orange : .green)
                    Text("ahora").font(.system(size: 11)).foregroundColor(.primary.opacity(0.4))
                }
            }
            Circle().fill(hasApp ? (status.phoneState == "suspendido" ? Color.orange : Color.green) : .gray.opacity(0.2))
                .frame(width: 10, height: 10)
        })
    }

    private func detailCard(icon: String, label: String, value: String, color: Color, isActive: Bool, trailing: Text? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
                .padding(10).background(color.opacity(0.12)).cornerRadius(12)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                Text(value).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
            }
            Spacer()
            if let t = trailing { t }
            Circle().fill(isActive ? Color.green : .gray.opacity(0.2)).frame(width: 10, height: 10)
        }
    }

    private var phoneStateCard: some View {
        let ls = status.lastSeen
        let recentlySeen = ls != nil && Date().timeIntervalSince(ls!) < 130
        let effectiveState = status.isOnline ? status.phoneState : "apagado"
        let (label, stateColor, stateIcon): (String, Color, String)

        if status.isOnline || recentlySeen {
            switch effectiveState {
            case "suspendido": (label, stateColor, stateIcon) = ("suspendido (pantalla apagada)", .orange, "lock.rectangle")
            case "bloqueado": (label, stateColor, stateIcon) = ("bloqueado (pantalla bloqueada)", .orange, "lock.fill")
            case "apagado": (label, stateColor, stateIcon) = ("apagado (sin conexión)", .red, "poweroff")
            default: (label, stateColor, stateIcon) = ("encendido (activo)", .green, "iphone")
            }
        } else {
            (label, stateColor, stateIcon) = ("apagado o sin conexión", .gray.opacity(0.4), "wifi.slash")
        }

        return AnyView(detailCard(icon: stateIcon, label: "Estado del teléfono", value: label, color: stateColor, isActive: label != "apagado o sin conexión"))
    }

    private func lastNotificationCard(app: String, title: String, text: String, time: Date?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.badge.fill").font(.system(size: 22)).foregroundColor(ThemeManager.shared.primaryPink)
                .padding(10).background(ThemeManager.shared.primaryPink.opacity(0.12)).cornerRadius(12)
            VStack(alignment: .leading, spacing: 2) {
                Text("Última notificación").font(.system(size: 12)).foregroundColor(.primary.opacity(0.5))
                if !app.isEmpty { Text(app).font(.system(size: 12, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink) }
                if !title.isEmpty { Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary).lineLimit(1) }
                if !text.isEmpty { Text(text).font(.system(size: 12)).foregroundColor(.primary.opacity(0.6)).lineLimit(2) }
            }
            Spacer()
            if let t = time { Text("\(Calendar.current.component(.hour, from: t)):\(String(format: "%02d", Calendar.current.component(.minute, from: t)))").font(.system(size: 11)).foregroundColor(.primary.opacity(0.4)) }
        }
    }

    private func updateMockStatus() {
        let apps = ["WhatsApp", "Instagram", "TikTok", "YouTube", "Spotify", "Telegram", "Chrome", "Gmail", "Twitter"]
        let appIds = ["com.whatsapp", "com.instagram", "com.zhiliao", "com.google.ios.youtube", "com.spotify", "org.telegram", "com.google.chrome.ios", "com.google.gmail", "com.twitter"]
        let idx = Int(Date().timeIntervalSince1970) % apps.count
        status.isOnline = true
        status.currentApp = appIds[idx]
        status.currentAppLabel = apps[idx]
        status.batteryLevel = [15, 23, 45, 67, 88, 95].randomElement() ?? 50
        status.isCharging = Bool.random()
        status.lastSeen = Date()
        status.phoneState = ["activo", "suspendido", "bloqueado"].randomElement() ?? "activo"
        if Int(Date().timeIntervalSince1970) % 5 == 0 {
            status.lastNotification = ("WhatsApp", "Mensaje de amor 💕", "¡Te extraño mucho! ¿Cuándo nos vemos?")
            status.lastNotificationTime = Date()
        }
        let newScreen = apps.randomElement() ?? "WhatsApp"
        if screenHistory.isEmpty || screenHistory.first?.0 != newScreen {
            screenHistory.insert((newScreen, Date()), at: 0)
            if screenHistory.count > 30 { screenHistory = Array(screenHistory.prefix(30)) }
        }
    }

    private func formatDateTime(_ dt: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(dt) { return "Hoy \(cal.component(.hour, from: dt)):\(String(format: "%02d", cal.component(.minute, from: dt)))" }
        if cal.isDateInYesterday(dt) { return "Ayer \(cal.component(.hour, from: dt)):\(String(format: "%02d", cal.component(.minute, from: dt)))" }
        return "\(cal.component(.day, from: dt))/\(cal.component(.month, from: dt)) \(cal.component(.hour, from: dt)):\(String(format: "%02d", cal.component(.minute, from: dt)))"
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s/60)m" }
        return "\(s/3600)h"
    }
}

private struct ScreenShareView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.035, blue: 0.043).ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Compartir Pantalla").tag(0)
                    Text("Ver Pantalla").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle()).padding(.horizontal, 16).padding(.top, 8)
                .tint(Color(red: 1.0, green: 0.36, blue: 0.54))

                if selectedTab == 0 {
                    senderPage
                } else {
                    receiverPage
                }
            }
        }
        .navigationTitle("Pantalla en Vivo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var senderPage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 64)).foregroundColor(.white.opacity(0.2))
                    Text("Presiona \"Iniciar\" para compartir tu pantalla")
                        .font(.system(size: 14)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                }
            }
            .frame(maxHeight: .infinity)

            Button {
                // Screen sharing not available on iOS without ReplayKit
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Iniciar Transmisión de Pantalla")
                }
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(16)
            }
            Spacer().frame(height: 20)
        }
        .padding(20)
    }

    private var receiverPage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                VStack(spacing: 12) {
                    Image(systemName: "tv").font(.system(size: 64)).foregroundColor(.white.opacity(0.2))
                    Text("Presiona \"Conectar\" para ver la pantalla de tu pareja")
                        .font(.system(size: 14)).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                }
            }
            .frame(maxHeight: .infinity)

            Button {
                // Screen viewing not available without Firestore
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Conectar y Ver Pantalla")
                }
                .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(16)
            }
            Spacer().frame(height: 20)
        }
        .padding(20)
    }
}
