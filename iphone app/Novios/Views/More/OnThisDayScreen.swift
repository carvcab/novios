import SwiftUI
import FirebaseFirestore

public struct OnThisDayScreen: View {
    @State private var memories: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }
    private var memoriesRef: CollectionReference { db.collection("couples").document(coupleId).collection("memories") }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 0) {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let filtered = memories.filter { mem in
                    guard let ts = mem["date"] as? Timestamp else { return false }
                    let memDate = calendar.startOfDay(for: ts.dateValue())
                    let yearDiff = calendar.dateComponents([.year], from: memDate, to: today).year ?? 0
                    if yearDiff < 1 { return false }
                    let memMD = calendar.dateComponents([.month, .day], from: memDate)
                    let todayMD = calendar.dateComponents([.month, .day], from: today)
                    return memMD.month == todayMD.month && memMD.day == todayMD.day
                }

                if filtered.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 48)).foregroundColor(theme.primary.opacity(0.5))
                        Text("No hay recuerdos de esta fecha").appFont(size: 18, weight: .semibold)
                        Text("Los recuerdos aparecerán aquí en su aniversario").appFont(size: 13).foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(filtered.enumerated()), id: \.offset) { i, mem in
                                let title = mem["title"] as? String ?? ""
                                let desc = mem["description"] as? String ?? ""
                                let date = (mem["date"] as? Timestamp)?.dateValue() ?? Date()
                                let years = calendar.dateComponents([.year], from: date, to: today).year ?? 0
                                GlassCard(cornerRadius: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Hace \(years) año\(years != 1 ? "s" : "")")
                                            .appFont(size: 12, weight: .bold).foregroundColor(theme.primary)
                                        Text(title).appFont(size: 16, weight: .bold).foregroundColor(theme.textPrimary)
                                        if !desc.isEmpty { Text(desc).appFont(size: 13).foregroundColor(theme.textSecondary) }
                                    }.padding(12)
                                }
                            }
                        }.padding(16)
                    }
                }
            }
        }
        .navigationTitle("Hace un Año")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            snapshotListener = memoriesRef.addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                memories = docs.map { $0.data() }
            }
        }
        .onDisappear { snapshotListener?.remove() }
    }
}
