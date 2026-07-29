import SwiftUI
import FirebaseFirestore

struct CollectionsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var collections: [String] = []
    @State private var showCreateSheet = false
    @State private var newName = ""
    
    private let defaultCollections = ["Romantico", "Divertido", "Picante", "Viajes", "Personal", "Universidad"]
    
    private func collectionIcon(_ name: String) -> String {
        switch name {
        case "Romantico": return "heart.fill"
        case "Divertido": return "face.smiling.fill"
        case "Picante": return "flame.fill"
        case "Viajes": return "airplane.departure"
        case "Personal": return "person.fill"
        case "Universidad": return "book.fill"
        default: return "folder.fill"
        }
    }
    
    private func collectionColor(_ name: String) -> Color {
        switch name {
        case "Romantico": return .pink
        case "Divertido": return .orange
        case "Picante": return .red
        case "Viajes": return .blue
        case "Personal": return .purple
        case "Universidad": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(collections, id: \.self) { name in
                            NavigationLink(destination: CollectionDetailView(collectionName: name)) {
                                VStack(spacing: 12) {
                                    Image(systemName: collectionIcon(name))
                                        .font(.system(size: 36))
                                        .foregroundColor(collectionColor(name))
                                    Text(name)
                                        .appFont(size: 14, weight: .bold)
                                        .foregroundColor(theme.textPrimary)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(collectionColor(name).opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Colecciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus").foregroundColor(theme.primary)
                    }
                }
            }
            .onAppear { loadCollections() }
            .sheet(isPresented: $showCreateSheet) {
                NavigationStack {
                    Form {
                        TextField("Nombre", text: $newName)
                    }
                    .navigationTitle("Nueva coleccion")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showCreateSheet = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") {
                                let name = newName.trimmingCharacters(in: .whitespaces)
                                guard !name.isEmpty else { return }
                                GameService.shared.saveCollection(["name": name])
                                newName = ""
                                showCreateSheet = false
                                loadCollections()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadCollections() {
        let defaultSet = Set(defaultCollections)
        GameService.shared.streamCollections().getDocuments { snapshot, _ in
            let custom = snapshot?.documents.compactMap { $0.data()["name"] as? String } ?? []
            let all = defaultSet.union(custom).sorted()
            DispatchQueue.main.async { collections = all }
        }
    }
}

struct CollectionDetailView: View {
    let collectionName: String
    @ObservedObject private var theme = ThemeManager.shared
    
    private let gameTypes: [(String, String, String)] = [
        ("verdad_reto", "Verdad o Reto", "heart.fill"),
        ("yo_nunca", "Yo Nunca Nunca", "wineglass.fill"),
        ("que_prefieres", "Que Prefieres", "questionmark.bubble.fill"),
        ("ahorcados", "Ahorcado", "person.fill.questionmark"),
        ("amor", "Love Game", "heart.square.fill"),
        ("quizzes", "Quizzes", "questionmark.square.fill"),
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()
            List {
                ForEach(gameTypes, id: \.0) { (gameType, gameName, icon) in
                    Section {
                        GameCollectionItemsView(gameType: gameType, gameName: gameName, icon: icon, collectionName: collectionName)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(collectionName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GameCollectionItemsView: View {
    let gameType: String
    let gameName: String
    let icon: String
    let collectionName: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        let _ = FirebaseFirestore.Firestore.firestore()
        Text("Items en \(collectionName)")
            .appFont(size: 12)
            .foregroundColor(theme.textSecondary)
    }
}
