import SwiftUI
import FirebaseFirestore

public struct FavoriteGIFsScreen: View {
    @State private var gifs: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var showAdd = false
    @State private var newUrl = ""
    @State private var newName = ""
    @ObservedObject private var theme = ThemeManager.shared
    private let db = Firestore.firestore()

    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }
    private var listsDoc: DocumentReference { db.collection("couples").document(coupleId).collection("lists").document("favorite_gifs") }

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            if gifs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "giftcard").font(.system(size: 48)).foregroundColor(theme.primary.opacity(0.5))
                    Text("Sin GIFs").appFont(size: 18, weight: .semibold)
                    Text("Agreguen sus GIFs favoritos 💕").appFont(size: 13).foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(gifs.enumerated()), id: \.offset) { i, gif in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: gif["url"] as? String ?? "")) { img in
                                    img.resizable().scaledToFit().cornerRadius(10)
                                } placeholder: {
                                    Color.gray.opacity(0.2).cornerRadius(10)
                                }
                                Button {
                                    deleteGIF(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill").font(.system(size: 22))
                                        .foregroundColor(.red.opacity(0.8)).background(Color.white.clipShape(Circle()))
                                }.offset(x: 6, y: -6)
                            }
                        }
                    }.padding(12)
                }
            }
        }
        .navigationTitle("GIFs Favoritos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").foregroundColor(theme.primary) }
            }
        }
        .onAppear { startListening() }
        .onDisappear { snapshotListener?.remove() }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    TextField("URL del GIF", text: $newUrl)
                    TextField("Nombre (opcional)", text: $newName)
                }
                .navigationTitle("Agregar GIF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            gifs.append(["url": newUrl.trimmingCharacters(in: .whitespaces), "name": newName])
                            save()
                            showAdd = false; newUrl = ""; newName = ""
                        }.disabled(newUrl.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }.presentationDetents([.medium])
        }
    }

    private func startListening() {
        snapshotListener = listsDoc.addSnapshotListener { snap, _ in
            guard let data = snap?.data(), let items = data["items"] as? [[String: Any]] else { return }
            gifs = items
        }
    }

    private func save() { try? listsDoc.setData(["items": gifs, "updatedAt": FieldValue.serverTimestamp()]) }
    private func deleteGIF(at i: Int) { gifs.remove(at: i); save() }
}
