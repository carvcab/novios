import SwiftUI

private struct PartnerNotification: Identifiable {
    let id = UUID()
    let app: String
    let content: String
    let timestamp: Date
    let isNew: Bool
}

public struct NotificationsView: View {
    private let partnerName = "Carlos"

    @State private var notifications: [PartnerNotification] = [
        PartnerNotification(app: "WhatsApp", content: "¡Buenos días! ¿Vamos a almorzar?", timestamp: Date().addingTimeInterval(-300), isNew: true),
        PartnerNotification(app: "Instagram", content: "A @usuario le gustó tu foto", timestamp: Date().addingTimeInterval(-900), isNew: true),
        PartnerNotification(app: "TikTok", content: "Nuevo video viral 🔥", timestamp: Date().addingTimeInterval(-3600), isNew: true),
        PartnerNotification(app: "Telegram", content: "Mensaje en grupo Familia", timestamp: Date().addingTimeInterval(-7200), isNew: false),
        PartnerNotification(app: "Gmail", content: "Recordatorio: Cita médica mañana", timestamp: Date().addingTimeInterval(-10800), isNew: false),
        PartnerNotification(app: "Facebook", content: "Tienes una solicitud de amistad", timestamp: Date().addingTimeInterval(-18000), isNew: false),
        PartnerNotification(app: "Twitter", content: "Nueva mención de @usuario", timestamp: Date().addingTimeInterval(-25200), isNew: false),
        PartnerNotification(app: "Snapchat", content: "¡Snap streak en riesgo! 🔥", timestamp: Date().addingTimeInterval(-32400), isNew: false),
        PartnerNotification(app: "YouTube", content: "Nuevo video de tu suscripción", timestamp: Date().addingTimeInterval(-43200), isNew: false),
        PartnerNotification(app: "Chrome", content: "Artículo recomendado para ti", timestamp: Date().addingTimeInterval(-86400), isNew: false),
        PartnerNotification(app: "WhatsApp", content: "Llamada perdida de Juan", timestamp: Date().addingTimeInterval(-120), isNew: true),
        PartnerNotification(app: "Instagram", content: "Nuevo story de @amigo", timestamp: Date().addingTimeInterval(-600), isNew: true),
    ]

    @State private var selectedFilter = "Todas"
    @State private var showPartnerNotifications = true
    @State private var soundEnabled = true
    @State private var vibrationEnabled = true

    private let filters = ["Todas", "WhatsApp", "Instagram", "Otras"]

    private var filteredNotifications: [PartnerNotification] {
        switch selectedFilter {
        case "WhatsApp":
            return notifications.filter { $0.app == "WhatsApp" }
        case "Instagram":
            return notifications.filter { $0.app == "Instagram" }
        case "Otras":
            return notifications.filter { $0.app != "WhatsApp" && $0.app != "Instagram" }
        default:
            return notifications
        }
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    @ViewBuilder
    private func appIcon(for app: String) -> some View {
        Group {
            switch app {
            case "WhatsApp":
                ZStack {
                    Circle().fill(Color.green)
                    Text("W").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "Instagram":
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [Color.purple, Color.pink, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    Text("I").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "TikTok":
                ZStack {
                    Circle().fill(Color.black)
                    Text("T").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "Facebook":
                ZStack {
                    Circle().fill(Color.blue)
                    Text("F").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "Twitter":
                ZStack {
                    Circle().fill(Color.black)
                    Text("X").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "Telegram":
                ZStack {
                    Circle().fill(Color.blue)
                    Text("T").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "Snapchat":
                ZStack {
                    Circle().fill(Color.yellow)
                    Text("S").font(.system(size: 16, weight: .bold)).foregroundColor(.black)
                }
            case "Gmail":
                ZStack {
                    Circle().fill(Color.red)
                    Text("G").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "YouTube":
                ZStack {
                    Circle().fill(Color.red)
                    Text("Y").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            case "Chrome":
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [Color.green, Color.yellow], startPoint: .top, endPoint: .bottom)
                    )
                    Text("C").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            default:
                ZStack {
                    Circle().fill(Color.gray)
                    Image(systemName: "app.badge.fill").font(.system(size: 14)).foregroundColor(.white)
                }
            }
        }
        .frame(width: 40, height: 40)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard(cornerRadius: 28) {
                            VStack(spacing: 8) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 42))
                                    .foregroundColor(ThemeManager.shared.primaryPink)

                                Text("Notificaciones de \(partnerName)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)

                                Text("Actividad reciente de tu pareja")
                                    .font(.system(size: 13))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Text(filter)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selectedFilter == filter ? .white : ThemeManager.shared.textSecondary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? ThemeManager.shared.primaryPink : Color.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        if filteredNotifications.isEmpty {
                            VStack(spacing: 12) {
                                Spacer().frame(height: 30)
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(ThemeManager.shared.textSecondary)

                                Text("Aún no hay notificaciones de tu pareja")
                                    .font(.system(size: 15))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                                    .multilineTextAlignment(.center)
                                Spacer().frame(height: 30)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredNotifications) { notif in
                                    GlassCard(cornerRadius: 18) {
                                        HStack(spacing: 14) {
                                            appIcon(for: notif.app)

                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(notif.app)
                                                        .font(.system(size: 15, weight: .bold))
                                                        .foregroundColor(.primary)

                                                    Spacer()

                                                    Circle()
                                                        .fill(notif.isNew ? ThemeManager.shared.primaryPink : Color.gray.opacity(0.4))
                                                        .frame(width: 8, height: 8)
                                                }

                                                Text(notif.content)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(ThemeManager.shared.textSecondary)
                                                    .lineLimit(2)

                                                Text(relativeTime(from: notif.timestamp))
                                                    .font(.system(size: 11))
                                                    .foregroundColor(ThemeManager.shared.textSecondary.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notificaciones de la app")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.top, 8)

                            GlassCard(cornerRadius: 18) {
                                VStack(spacing: 0) {
                                    ToggleItem(icon: "bell.badge.fill", title: "Mostrar notificaciones de la pareja", isOn: $showPartnerNotifications)
                                    Divider().background(ThemeManager.shared.textSecondary.opacity(0.2))
                                    ToggleItem(icon: "speaker.wave.2.fill", title: "Sonido al recibir notificación", isOn: $soundEnabled)
                                    Divider().background(ThemeManager.shared.textSecondary.opacity(0.2))
                                    ToggleItem(icon: "iphone.radiowaves.left.and.right", title: "Vibración", isOn: $vibrationEnabled)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Notificaciones")
        }
    }
}

private struct ToggleItem: View {
    public let icon: String
    public let title: String
    @Binding public var isOn: Bool

    public var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ThemeManager.shared.primaryPink)
                .frame(width: 30, height: 30)
                .background(ThemeManager.shared.primaryPink.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(ThemeManager.shared.primaryPink)
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }
}
