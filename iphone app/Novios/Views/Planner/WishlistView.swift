import SwiftUI

private struct Wish: Identifiable {
    let id: String
    let emoji: String
    let name: String
    var isPurchased: Bool
}

public struct WishlistView: View {
    @State private var wishes: [Wish] = []

    @State private var showAddAlert = false
    @State private var newWishText = ""

    private var sortedWishes: [Wish] {
        wishes.sorted { !$0.isPurchased && $1.isPurchased }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(sortedWishes) { wish in
                                GlassCard {
                                    VStack(spacing: 10) {
                                        Text(wish.emoji)
                                            .font(.system(size: 40))

                                        Text(wish.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .strikethrough(wish.isPurchased)

                                        Button {
                                            if let idx = wishes.firstIndex(where: { $0.id == wish.id }) {
                                                wishes[idx].isPurchased.toggle()
                                            }
                                        } label: {
                                            Text(wish.isPurchased ? "✅ Comprado" : "⬜ Pendiente")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(wish.isPurchased ? .green : ThemeManager.shared.primaryPink)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(
                                                    (wish.isPurchased ? Color.green : ThemeManager.shared.primaryPink).opacity(0.15)
                                                )
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        GlassCard {
                            Button {
                                showAddAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Agregar deseo")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Lista de Deseos")
            .alert("Nuevo deseo", isPresented: $showAddAlert) {
                TextField("Producto...", text: $newWishText)
                Button("Cancelar", role: .cancel) { newWishText = "" }
                Button("Agregar") {
                    let trimmed = newWishText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let wish = Wish(id: UUID().uuidString, emoji: "🎁", name: trimmed, isPurchased: false)
                        wishes.append(wish)
                        Task {
                            await FirestoreSyncService.shared.saveWish(title: trimmed, emoji: "🎁")
                        }
                        newWishText = ""
                    }
                }
            }
            .task {
                let items = await FirestoreSyncService.shared.loadWishlist()
                wishes = items.map {
                    Wish(id: $0["id"] as? String ?? UUID().uuidString,
                         emoji: $0["emoji"] as? String ?? "🎁",
                         name: $0["title"] as? String ?? "",
                         isPurchased: $0["isPurchased"] as? Bool ?? false)
                }
            }
        }
    }
}
