import SwiftUI
import FirebaseFirestore

public struct GiftsScreen: View {
    @State private var tab = 0
    @State private var gifts: [[String: Any]] = []
    @State private var lovePoints = 0
    @State private var heartbeatCount = 0
    @State private var lastHeartDate = ""
    @State private var snapshotListener: ListenerRegistration?
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard

    private let giftCatalog: [(id: String, name: String, cost: Int, emoji: String)] = [
        ("rose", "Rosa", 5, "🌹"), ("chocolate", "Chocolate", 10, "🍫"),
        ("teddy", "Osito", 20, "🧸"), ("ring", "Anillo", 50, "💍"),
        ("heart", "Corazón", 15, "💖"), ("kiss", "Beso", 8, "💋"),
        ("cake", "Pastel", 12, "🧁"), ("letter", "Carta", 3, "💌"),
        ("stars", "Estrellas", 25, "✨"),
    ]

    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }
    private var giftsRef: CollectionReference { db.collection("couples").document(coupleId).collection("gifts") }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "heart.fill").foregroundColor(.red)
                    Text("\(lovePoints) pts").appFont(size: 16, weight: .bold).foregroundColor(theme.textPrimary)
                    Spacer()
                }.padding(.horizontal, 16).padding(.vertical, 8)
                    .background(.ultraThinMaterial)

                Picker("", selection: $tab) {
                    Text("Tienda").tag(0)
                    Text("Recibidos").tag(1)
                }.pickerStyle(.segmented).padding(.horizontal, 16).padding(.vertical, 8)

                if tab == 0 { shopView } else { inboxView }
            }
        }
        .navigationTitle("Regalos Virtuales")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadPoints(); startListening() }
        .onDisappear { snapshotListener?.remove() }
    }

    private var shopView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(giftCatalog, id: \.id) { gift in
                    Button {
                        sendGift(gift)
                    } label: {
                        VStack(spacing: 6) {
                            Text(gift.emoji).font(.system(size: 40))
                            Text(gift.name).appFont(size: 11, weight: .bold).foregroundColor(theme.textPrimary)
                            Text("\(gift.cost) pts").appFont(size: 10).foregroundColor(theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(theme.surfaceBackground).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1)))
                        .opacity(lovePoints >= gift.cost ? 1 : 0.4)
                    }
                    .disabled(lovePoints < gift.cost)
                }
            }.padding(16)

            GlassCard(cornerRadius: 16) {
                VStack(spacing: 8) {
                    Text("Gana puntos 💕").appFont(size: 14, weight: .bold).foregroundColor(theme.textPrimary)
                    Text("Toca el corazón para ganar puntos (máx 50/día)")
                        .appFont(size: 11).foregroundColor(theme.textSecondary)
                    Button {
                        earnPoints()
                    } label: {
                        Image(systemName: "heart.fill").font(.system(size: 36))
                            .foregroundColor(.red).scaleEffect(heartbeatCount > 0 ? 1.3 : 1)
                            .animation(.spring(response: 0.3), value: heartbeatCount)
                    }
                    Text("Hoy: \(heartbeatCount)/50").appFont(size: 11).foregroundColor(theme.textSecondary)
                }.padding(16)
            }.padding(.horizontal, 16)
        }
    }

    private var inboxView: some View {
        Group {
            if gifts.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "gift").font(.system(size: 48)).foregroundColor(theme.primary.opacity(0.5))
                    Text("Sin regalos aún").appFont(size: 18, weight: .semibold)
                    Spacer()
                }
            } else {
                List {
                    ForEach(gifts.indices, id: \.self) { i in
                        let g = gifts[i]
                        HStack(spacing: 12) {
                            Text(g["emoji"] as? String ?? "🎁").font(.system(size: 32))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g["giftName"] as? String ?? "").appFont(size: 14, weight: .semibold).foregroundColor(theme.textPrimary)
                                Text("De: \(g["senderName"] as? String ?? "")").appFont(size: 11).foregroundColor(theme.textSecondary)
                            }
                            Spacer()
                            if g["status"] as? String == "unread" {
                                Circle().fill(Color.red).frame(width: 10, height: 10)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            markOpened(i)
                        }
                    }
                }.listStyle(.plain)
            }
        }
    }

    private func loadPoints() {
        lovePoints = defaults.integer(forKey: "love_points")
        heartbeatCount = defaults.integer(forKey: "heartbeat_count")
        lastHeartDate = defaults.string(forKey: "last_heart_date") ?? ""
        let today = dateStr()
        if lastHeartDate != today { heartbeatCount = 0 }
    }

    private func earnPoints() {
        let today = dateStr()
        if lastHeartDate != today { heartbeatCount = 0; lastHeartDate = today }
        guard heartbeatCount < 50 else { return }
        heartbeatCount += 1
        lovePoints = min(lovePoints + 1, 9999)
        defaults.set(lovePoints, forKey: "love_points")
        defaults.set(heartbeatCount, forKey: "heartbeat_count")
        defaults.set(lastHeartDate, forKey: "last_heart_date")
    }

    private func sendGift(_ gift: (id: String, name: String, cost: Int, emoji: String)) {
        guard lovePoints >= gift.cost else { return }
        lovePoints -= gift.cost
        defaults.set(lovePoints, forKey: "love_points")
        let data: [String: Any] = [
            "id": UUID().uuidString,
            "senderId": CoupleService.shared.currentUid,
            "senderName": CoupleService.shared.currentName,
            "giftType": gift.id,
            "giftName": gift.name,
            "emoji": gift.emoji,
            "cost": gift.cost,
            "message": "",
            "timestamp": FieldValue.serverTimestamp(),
            "status": "unread",
        ]
        try? giftsRef.addDocument(data: data)
    }

    private func markOpened(_ i: Int) {
        guard i < gifts.count, let id = gifts[i]["id"] as? String else { return }
        gifts[i]["status"] = "opened"
        try? giftsRef.document(id).updateData(["status": "opened"])
    }

    private func startListening() {
        snapshotListener = giftsRef.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            gifts = docs.map { d in
                var data = d.data()
                data["id"] = d.documentID
                return data
            }
        }
    }

    private func dateStr() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }
}
