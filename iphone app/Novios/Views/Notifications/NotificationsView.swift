import SwiftUI

public struct NotificationsView: View {
    @State private var notifications: [[String: Any]] = []
    @State private var selectedFilter = "Todas"
    @State private var isLoading = true
    @State private var partnerName = ""

    private let filters = ["Todas", "WhatsApp", "Instagram", "Otras"]
    private let colors: [String: Color] = [
        "whatsapp": Color(red: 0.15, green: 0.83, blue: 0.4),
        "instagram": Color(red: 0.89, green: 0.25, blue: 0.37),
        "tiktok": .black,
        "facebook": Color(red: 0.09, green: 0.47, blue: 0.95),
        "messenger": Color(red: 0.09, green: 0.47, blue: 0.95),
        "twitter": Color(red: 0.11, green: 0.69, blue: 0.96),
        "telegram": Color(red: 0, green: 0.53, blue: 0.8),
        "snapchat": .yellow,
        "gmail": Color(red: 0.92, green: 0.26, blue: 0.21),
        "youtube": .red,
        "chrome": Color(red: 0.26, green: 0.52, blue: 0.96),
    ]

    private var pollingTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(ThemeManager.shared.primaryPink)
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filters, id: \.self) { filter in
                                    Button {
                                        selectedFilter = filter
                                    } label: {
                                        Text(filter)
                                            .font(.system(size: 13, weight: selectedFilter == filter ? .bold : .regular))
                                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                                            .padding(.horizontal, 16).padding(.vertical, 6)
                                            .background(selectedFilter == filter ? ThemeManager.shared.primaryPink : Color.primary.opacity(0.08))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                        }

                        if filteredNotifications.isEmpty {
                            emptyState
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(filteredNotifications.indices, id: \.self) { i in
                                        notificationCard(filteredNotifications[i])
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notificaciones de \(partnerName)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onReceive(pollingTimer) { _ in
            Task { await fetchNotifications() }
        }
        .task {
            partnerName = UserDefaults.standard.string(forKey: "partner_name") ?? "tu pareja"
            await fetchNotifications()
            isLoading = false
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash").font(.system(size: 48)).foregroundColor(.primary.opacity(0.2))
            Text("Aún no hay notificaciones de \(partnerName)")
                .font(.system(size: 16, weight: .medium)).foregroundColor(.primary.opacity(0.5))
            Text("Las notificaciones aparecerán aquí en tiempo real")
                .font(.system(size: 13)).foregroundColor(.primary.opacity(0.3))
            Spacer()
        }
    }

    private func notificationCard(_ notif: [String: Any]) -> some View {
        let app = (notif["app"] as? String) ?? ""
        let title = (notif["title"] as? String) ?? ""
        let text = (notif["text"] as? String) ?? ""
        let time = notif["timestamp"] as? Date ?? Date()
        let appLower = app.lowercased()
        let color = colors.first { appLower.contains($0.key) }?.value ?? .gray

        return GlassCard {
            HStack(spacing: 12) {
                Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40)
                    .overlay(Text(app.prefix(2).uppercased()).font(.system(size: 14, weight: .bold)).foregroundColor(color))

                VStack(alignment: .leading, spacing: 2) {
                    Text(app).font(.system(size: 13, weight: .semibold)).foregroundColor(.primary)
                    if !title.isEmpty {
                        Text(title).font(.system(size: 13)).foregroundColor(.primary).lineLimit(1)
                    }
                    if !text.isEmpty {
                        Text(text).font(.system(size: 12)).foregroundColor(.primary.opacity(0.6)).lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Circle().fill(ThemeManager.shared.primaryPink).frame(width: 8, height: 8)
                    Text(timeAgo(time)).font(.system(size: 10)).foregroundColor(.primary.opacity(0.4))
                }
            }
        }
    }

    private var filteredNotifications: [[String: Any]] {
        let result = notifications.sorted { (a, b) -> Bool in
            let t1 = a["timestamp"] as? Date ?? Date(timeIntervalSince1970: 0)
            let t2 = b["timestamp"] as? Date ?? Date(timeIntervalSince1970: 0)
            return t1 > t2
        }
        if selectedFilter == "Todas" { return result }
        let filterLower = selectedFilter.lowercased()
        return result.filter {
            let app = ($0["app"] as? String ?? "").lowercased()
            return app.contains(filterLower)
        }
    }

    private func fetchNotifications() async {
        guard let partnerUid = UserDefaults.standard.string(forKey: "partner_uid"),
              !partnerUid.isEmpty else { return }
        let docs = try? await FirebaseRESTService.shared.firestoreGet(
            path: "users/\(partnerUid)/activities?orderBy=timestamp&pageSize=50")
        guard let documents = (docs?["documents"] as? [[String: Any]]) else { return }

        var items: [[String: Any]] = []
        for doc in documents {
            guard let fields = doc["fields"] as? [String: Any] else { continue }
            var item: [String: Any] = [:]
            for (key, val) in fields {
                if let map = val as? [String: Any] {
                    if let s = map["stringValue"] as? String { item[key] = s }
                    else if let ts = map["timestampValue"] as? String {
                        item[key] = ISO8601DateFormatter().date(from: ts) ?? Date()
                    }
                }
            }
            if let name = doc["name"] as? String {
                item["id"] = name.split(separator: "/").last.map(String.init)
            }
            items.append(item)
        }
        await MainActor.run { self.notifications = items }
    }

    private var timeAgo: (Date) -> String {
        { date in
            let s = Int(-date.timeIntervalSinceNow)
            if s < 60 { return "\(s)s" }
            if s < 3600 { return "\(s/60)m" }
            if s < 86400 { return "\(s/3600)h" }
            return "\(s/86400)d"
        }
    }
}
