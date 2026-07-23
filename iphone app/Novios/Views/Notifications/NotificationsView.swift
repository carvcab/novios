import SwiftUI
import FirebaseFirestore

public struct NotificationsView: View {
    @State private var activities: [ActivityItem] = []
    @State private var listener: ListenerRegistration?

    private let db = Firestore.firestore()
    private let theme = ThemeManager.shared

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var activitiesRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("activities")
    }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            if activities.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(activities) { item in
                            activityCard(item)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.textSecondary.opacity(0.3))
            Text("Sin actividad aún")
                .appFont(size: 18, weight: .semibold)
            Text("Aquí verás la actividad de tu pareja 💕")
                .appFont(size: 13)
                .foregroundColor(.secondary)
        }
    }

    private func activityCard(_ item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor(item.icon).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName(item.icon))
                    .foregroundColor(iconColor(item.icon))
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .appFont(size: 13, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
                Text(item.text)
                    .appFont(size: 12)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
                Text(formatDate(item.timestamp))
                    .appFont(size: 10)
                    .foregroundColor(theme.textSecondary.opacity(0.6))
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
    }

    private func startListening() {
        listener = activitiesRef
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { doc -> ActivityItem? in
                    let d = doc.data()
                    guard let text = d["text"] as? String else { return nil }
                    let ts = (d["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    return ActivityItem(
                        id: doc.documentID,
                        title: d["title"] as? String ?? "",
                        text: text,
                        type: d["type"] as? String ?? "",
                        icon: d["icon"] as? String ?? "info",
                        timestamp: ts
                    )
                }
                DispatchQueue.main.async { self.activities = items }
            }
    }

    private func stopListening() {
        listener?.remove()
        listener = nil
    }

    private func iconName(_ icon: String) -> String {
        switch icon {
        case "music": return "music.note"
        case "photo": return "photo.fill"
        case "map", "zone", "place": return "location.fill"
        case "letter", "mail": return "envelope.fill"
        case "gift": return "gift.fill"
        case "game": return "gamecontroller.fill"
        default: return "bell.fill"
        }
    }

    private func iconColor(_ icon: String) -> Color {
        switch icon {
        case "music": return .pink
        case "photo": return .orange
        case "map", "zone", "place": return .blue
        case "letter", "mail": return .purple
        case "gift": return .red
        case "game": return .green
        default: return theme.primary
        }
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; return "Hoy \(f.string(from: date))"
        }
        if cal.isDateInYesterday(date) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; return "Ayer \(f.string(from: date))"
        }
        let f = DateFormatter(); f.dateFormat = "d MMM HH:mm"; f.locale = Locale(identifier: "es")
        return f.string(from: date)
    }
}

private struct ActivityItem: Identifiable {
    let id: String
    let title: String
    let text: String
    let type: String
    let icon: String
    let timestamp: Date
}
