import SwiftUI
import FirebaseFirestore

public struct RelationshipBookScreen: View {
    @State private var memories: [[String: Any]] = []
    @State private var goals: [[String: Any]] = []
    @State private var capsules: [[String: Any]] = []
    @State private var page = 0
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }
    private var memoriesRef: CollectionReference { db.collection("couples").document(coupleId).collection("memories") }
    private var goalsRef: CollectionReference { db.collection("couples").document(coupleId).collection("goals") }
    private var capsulesRef: CollectionReference { db.collection("couples").document(coupleId).collection("capsules") }
    private let pages = ["Portada", "Prólogo", "Recuerdos", "Metas", "Cápsulas", "Epílogo"]

    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.06, blue: 0.08).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                        Text("\(i+1)").appFont(size: 10, weight: .bold)
                            .foregroundColor(page == i ? .white : .gold.opacity(0.4))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(page == i ? Color.burgundy : Color.clear))
                            .onTapGesture { page = i }
                    }
                }.padding(.vertical, 8).background(Color.burgundy.opacity(0.3))

                TabView(selection: $page) {
                    coverPage.tag(0)
                    prologuePage.tag(1)
                    memoriesPage.tag(2)
                    goalsPage.tag(3)
                    capsulesPage.tag(4)
                    epiloguePage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle("Libro Relación")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadData() }
    }

    private var coverPage: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("💞").font(.system(size: 60))
            Text("Nuestra Historia").appFont(size: 28, weight: .bold).foregroundColor(.gold)
            Text("\(CoupleService.shared.currentName) & \(CoupleService.shared.partnerName)")
                .appFont(size: 18, weight: .medium).foregroundColor(.gold.opacity(0.8))
            Spacer()
            Text("Toca para continuar ▶").appFont(size: 12).foregroundColor(.gold.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.12, green: 0.06, blue: 0.08))
    }

    private var prologuePage: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Prólogo").appFont(size: 24, weight: .bold).foregroundColor(.gold)
            Image(systemName: "heart.fill").font(.system(size: 40)).foregroundColor(.burgundy)
            Text("Cada día juntos es una página nueva en esta historia de amor.")
                .appFont(size: 14).foregroundColor(.gold.opacity(0.7)).multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.12, green: 0.06, blue: 0.08))
    }

    private var memoriesPage: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Recuerdos").appFont(size: 22, weight: .bold).foregroundColor(.gold).padding(.top)
                if memories.isEmpty {
                    Text("Sin recuerdos aún").foregroundColor(.gold.opacity(0.5)).padding(.top, 40)
                }
                ForEach(Array(memories.enumerated()), id: \.offset) { _, mem in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mem["title"] as? String ?? "").appFont(size: 14, weight: .bold).foregroundColor(.gold)
                        Text(mem["description"] as? String ?? "").appFont(size: 12).foregroundColor(.gold.opacity(0.6))
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.burgundy.opacity(0.2)).cornerRadius(8)
                }
            }.padding(16)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.12, green: 0.06, blue: 0.08))
    }

    private var goalsPage: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Metas y Sueños").appFont(size: 22, weight: .bold).foregroundColor(.gold).padding(.top)
                if goals.isEmpty {
                    Text("Sin metas aún").foregroundColor(.gold.opacity(0.5)).padding(.top, 40)
                }
                ForEach(Array(goals.enumerated()), id: \.offset) { _, g in
                    let done = g["isCompleted"] as? Bool ?? false
                    HStack {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle").foregroundColor(done ? .green : .gold.opacity(0.4))
                        Text(g["title"] as? String ?? "").appFont(size: 13, weight: .medium).foregroundColor(.gold)
                        Spacer()
                    }.padding(12).background(Color.burgundy.opacity(0.2)).cornerRadius(8)
                }
            }.padding(16)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.12, green: 0.06, blue: 0.08))
    }

    private var capsulesPage: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Cápsulas del Tiempo").appFont(size: 22, weight: .bold).foregroundColor(.gold).padding(.top)
                if capsules.isEmpty {
                    Text("Sin cápsulas aún").foregroundColor(.gold.opacity(0.5)).padding(.top, 40)
                }
                ForEach(Array(capsules.enumerated()), id: \.offset) { _, c in
                    let opened = c["isOpened"] as? Bool ?? false
                    HStack {
                        Image(systemName: opened ? "envelope.open.fill" : "envelope.fill").foregroundColor(opened ? .green : .gold)
                        Text(c["title"] as? String ?? "").appFont(size: 13, weight: .medium).foregroundColor(.gold)
                        Spacer()
                    }.padding(12).background(Color.burgundy.opacity(0.2)).cornerRadius(8)
                }
            }.padding(16)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.12, green: 0.06, blue: 0.08))
    }

    private var epiloguePage: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Epílogo").appFont(size: 24, weight: .bold).foregroundColor(.gold)
            Text("Esta historia continúa...").appFont(size: 16).foregroundColor(.gold.opacity(0.7))
            HStack(spacing: 24) {
                Text(CoupleService.shared.currentName).appFont(size: 14, weight: .semibold).foregroundColor(.gold)
                Text("💞").font(.system(size: 24))
                Text(CoupleService.shared.partnerName).appFont(size: 14, weight: .semibold).foregroundColor(.gold)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.12, green: 0.06, blue: 0.08))
    }

    private func loadData() {
        memoriesRef.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            memories = docs.map { $0.data() }
        }
        goalsRef.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            goals = docs.map { $0.data() }
        }
        capsulesRef.addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            capsules = docs.map { $0.data() }
        }
    }
}

private extension Color {
    static let gold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let burgundy = Color(red: 0.5, green: 0.0, blue: 0.13)
}
