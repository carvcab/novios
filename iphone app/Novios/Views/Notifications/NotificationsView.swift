import SwiftUI
import FirebaseFirestore

public struct NotificationsView: View {
    @State private var activities: [ActivityItem] = []
    @State private var partnerNotifs: [NotifLog] = []
    @State private var sharedNotifs: [SharedNotif] = []
    @State private var listener: ListenerRegistration?
    @State private var partnerListener: ListenerRegistration?
    @State private var sharedListener: ListenerRegistration?
    @State private var partnerUid: String = ""

    @State private var quickShareText = ""
    @State private var showQuickShare = false
    @State private var clipboardText: String?
    @State private var showClipboardAlert = false
    @State private var showSendSheet = false
    @State private var selectedApp = ""

    private let db = Firestore.firestore()
    private let theme = ThemeManager.shared
    private let notifService = SharedNotificationService.shared

    private var coupleId: String { CoupleService.coupleId }

    private let apps = [
        ("WhatsApp", "message.fill", Color(red: 0.18, green: 0.80, blue: 0.44)),
        ("Instagram", "camera.viewfinder", Color(red: 0.88, green: 0.39, blue: 0.59)),
        ("TikTok", "music.note.tv.fill", .black),
        ("Telegram", "paperplane.fill", Color(red: 0.22, green: 0.60, blue: 0.94)),
        ("Messenger", "bubble.left.fill", Color(red: 0.0, green: 0.62, blue: 1.0)),
        ("Snapchat", "ghost.fill", Color(red: 1.0, green: 0.92, blue: 0.0)),
        ("Twitter/X", "bird.fill", Color(red: 0.11, green: 0.63, blue: 0.95)),
        ("Gmail", "envelope.fill", Color(red: 0.85, green: 0.33, blue: 0.31)),
        ("YouTube", "play.rectangle.fill", .red),
        ("Spotify", "music.note.list", Color(red: 0.12, green: 0.78, blue: 0.34)),
        ("Facebook", "f.square.fill", Color(red: 0.23, green: 0.35, blue: 0.60)),
        ("SMS", "text.bubble.fill", .green),
        ("WhatsApp Llama", "phone.fill", Color(red: 0.18, green: 0.80, blue: 0.44)),
    ]

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 0) {
                quickShareBar
                Divider().opacity(0.3)
                if mergedList.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if showClipboardAlert, let clip = clipboardText {
                                clipboardBanner(clip)
                            }
                            ForEach(mergedList) { item in
                                notificationCard(item)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSendSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(theme.primary)
                }
            }
        }
        .onAppear {
            partnerUid = CoupleService.shared.partnerUid
            startListening()
            checkClipboardAfterDelay()
        }
        .onDisappear { stopListening() }
        .sheet(isPresented: $showSendSheet) {
            sendToPartnerSheet
        }
    }

    private var quickShareBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.pencil")
                .foregroundColor(theme.primary)
                .font(.system(size: 14))
            TextField("Escribe o pega algo para compartir...", text: $quickShareText)
                .appFont(size: 13)
                .textFieldStyle(.plain)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Button {
                let text = quickShareText.trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { return }
                notifService.saveSharedNotification(text: text, app: "Novios")
                quickShareText = ""
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(quickShareText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray.opacity(0.4) : theme.primary)
            }
            .disabled(quickShareText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func clipboardBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard.fill")
                .foregroundColor(theme.primary)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text("Texto copiado detectado")
                    .appFont(size: 11, weight: .semibold)
                    .foregroundColor(theme.textSecondary)
                Text(text.prefix(80) + (text.count > 80 ? "..." : ""))
                    .appFont(size: 12)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Button("Compartir") {
                notifService.saveSharedNotification(text: text, app: "Clipboard")
                clipboardText = nil
                showClipboardAlert = false
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .appFont(size: 12, weight: .semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.primary)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.primary.opacity(0.2), lineWidth: 1))
    }

    private var sendToPartnerSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Compartir con \(CoupleService.shared.partnerName)")
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(theme.textPrimary)
                TextField("Escribe algo para compartir...", text: $quickShareText, axis: .vertical)
                    .appFont(size: 14)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(apps, id: \.0) { name, icon, color in
                            Button {
                                selectedApp = name
                                let text = quickShareText.trimmingCharacters(in: .whitespaces)
                                guard !text.isEmpty else { return }
                                notifService.saveSharedNotification(text: text, app: name)
                                quickShareText = ""
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(color)
                                        .frame(width: 44, height: 44)
                                        .background(color.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(name)
                                        .appFont(size: 9)
                                        .foregroundColor(theme.textSecondary)
                                }
                                .frame(width: 64)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 80)
                List {
                    Section("Compartidos recientemente") {
                        ForEach(sharedNotifs.prefix(10)) { n in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(n.text).appFont(size: 13).foregroundColor(theme.textPrimary)
                                HStack {
                                    Text(n.app).appFont(size: 10).foregroundColor(theme.textSecondary)
                                    Text(formatDate(n.timestamp)).appFont(size: 10).foregroundColor(theme.textSecondary)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Enviar a pareja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { showSendSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.textSecondary.opacity(0.3))
            Text("Sin actividad aún")
                .appFont(size: 18, weight: .semibold)
            Text("Aquí verás las notificaciones que compartas con \(CoupleService.shared.partnerName)")
                .appFont(size: 13)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func notificationCard(_ item: ActivityItem) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(appColor(item.app).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: appIcon(item.app))
                    .foregroundColor(appColor(item.app))
                    .font(.system(size: 14))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if !item.app.isEmpty {
                        Text(item.app)
                            .appFont(size: 10, weight: .semibold)
                            .foregroundColor(appColor(item.app).opacity(0.7))
                    }
                    Text(formatDate(item.timestamp))
                        .appFont(size: 10)
                        .foregroundColor(theme.textSecondary.opacity(0.6))
                }
                if !item.title.isEmpty {
                    Text(item.title)
                        .appFont(size: 12, weight: .semibold)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                }
                Text(item.text)
                    .appFont(size: 11)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
            if item.isShared {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.5))
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08)))
    }

    private func startListening() {
        let actRef = db.collection("couples").document(coupleId).collection("activities")
        listener = actRef
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { doc -> ActivityItem? in
                    let d = doc.data()
                    guard let text = d["text"] as? String else { return nil }
                    let ts = (d["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    return ActivityItem(
                        id: "act_\(doc.documentID)", title: d["title"] as? String ?? "",
                        text: text, app: "", type: d["type"] as? String ?? "",
                        icon: d["icon"] as? String ?? "bell.fill", timestamp: ts, isShared: false
                    )
                }
                DispatchQueue.main.async { self.activities = items }
            }

        guard !partnerUid.isEmpty else { return }
        let notifRef = db.collection("users").document(partnerUid).collection("notification_logs")
        partnerListener = notifRef
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { doc -> NotifLog? in
                    let d = doc.data()
                    guard let app = d["app"] as? String, let text = d["text"] as? String else { return nil }
                    let ts = (d["timestamp"] as? Timestamp)?.dateValue()
                        ?? ISO8601DateFormatter().date(from: d["createdAt"] as? String ?? "")
                        ?? Date()
                    return NotifLog(id: doc.documentID, app: app, title: d["title"] as? String ?? "",
                                    text: text, packageName: d["packageName"] as? String ?? "", timestamp: ts)
                }
                DispatchQueue.main.async { self.partnerNotifs = items }
            }

        let sharedRef = notifService.streamSharedNotifications()
        sharedListener = sharedRef.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { doc -> SharedNotif? in
                let d = doc.data()
                guard let text = d["text"] as? String else { return nil }
                let ts = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                return SharedNotif(id: doc.documentID, text: text, app: d["app"] as? String ?? "Novios",
                                    title: d["title"] as? String ?? "",
                                    sender: d["sender"] as? String ?? "Alguien",
                                    timestamp: ts)
            }
            DispatchQueue.main.async { self.sharedNotifs = items }
        }
    }

    private func stopListening() {
        listener?.remove(); listener = nil
        partnerListener?.remove(); partnerListener = nil
        sharedListener?.remove(); sharedListener = nil
    }

    private var mergedList: [ActivityItem] {
        let acts = activities
        let notifs = partnerNotifs.map { n in
            ActivityItem(id: "notif_\(n.id)", title: n.title, text: n.text,
                         app: n.app, type: "", icon: appIcon(n.app), timestamp: n.timestamp, isShared: false)
        }
        let shared = sharedNotifs.map { s in
            ActivityItem(id: "shared_\(s.id)", title: "\(s.sender) compartio", text: s.text,
                         app: s.app, type: "shared", icon: "heart.fill", timestamp: s.timestamp, isShared: true)
        }
        return (acts + notifs + shared).sorted { $0.timestamp > $1.timestamp }
    }

    private func checkClipboardAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let text = notifService.checkClipboard() {
                clipboardText = text
                withAnimation { showClipboardAlert = true }
            }
        }
    }

    private func appColor(_ app: String) -> Color {
        switch app.lowercased() {
        case "whatsapp", "whatsapp llama": return Color(red: 0.18, green: 0.80, blue: 0.44)
        case "instagram": return Color(red: 0.88, green: 0.39, blue: 0.59)
        case "tiktok": return .black
        case "telegram": return Color(red: 0.22, green: 0.60, blue: 0.94)
        case "messenger": return Color(red: 0.0, green: 0.62, blue: 1.0)
        case "snapchat": return Color(red: 1.0, green: 0.92, blue: 0.0)
        case "twitter", "x": return Color(red: 0.11, green: 0.63, blue: 0.95)
        case "gmail", "mail": return Color(red: 0.85, green: 0.33, blue: 0.31)
        case "youtube": return Color(red: 1.0, green: 0.0, blue: 0.0)
        case "spotify": return Color(red: 0.12, green: 0.78, blue: 0.34)
        case "facebook": return Color(red: 0.23, green: 0.35, blue: 0.60)
        case "clipboard": return theme.primary
        default: return theme.primary
        }
    }

    private func appIcon(_ app: String) -> String {
        switch app.lowercased() {
        case "whatsapp", "whatsapp llama": return "message.fill"
        case "instagram": return "camera.viewfinder"
        case "tiktok": return "music.note.tv.fill"
        case "telegram": return "paperplane.fill"
        case "messenger": return "bubble.left.fill"
        case "snapchat": return "ghost.fill"
        case "twitter", "x": return "bird.fill"
        case "gmail", "mail": return "envelope.fill"
        case "youtube": return "play.rectangle.fill"
        case "spotify": return "music.note.list"
        case "facebook": return "f.square.fill"
        case "phone", "llamada": return "phone.fill"
        case "sms", "messages": return "text.bubble.fill"
        case "calendar": return "calendar"
        case "clipboard": return "doc.on.clipboard.fill"
        default: return "bell.fill"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
        }
        if cal.isDateInYesterday(date) {
            let f = DateFormatter(); f.dateFormat = "'Ayer' HH:mm"; return f.string(from: date)
        }
        let f = DateFormatter(); f.dateFormat = "d MMM HH:mm"; f.locale = Locale(identifier: "es")
        return f.string(from: date)
    }
}

private struct NotifLog {
    let id: String; let app: String; let title: String
    let text: String; let packageName: String; let timestamp: Date
}

private struct SharedNotif: Identifiable {
    let id: String; let text: String; let app: String
    let title: String; let sender: String; let timestamp: Date
}

private struct ActivityItem: Identifiable {
    let id: String; let title: String; let text: String
    let app: String; let type: String; let icon: String
    let timestamp: Date; let isShared: Bool
}
