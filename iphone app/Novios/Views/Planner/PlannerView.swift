import SwiftUI

private struct Idea: Identifiable {
    let id: String
    let emoji: String
    let title: String
}

private struct WatchItem: Identifiable {
    let id: String
    let emoji: String
    let title: String
    var isWatched: Bool
}

private struct RestaurantItem: Identifiable {
    let id: String
    let emoji: String
    let name: String
    var visited: Bool
}

private struct Plan: Identifiable {
    let id = UUID()
    let date: String
    let title: String
    let emoji: String
}

public struct PlannerView: View {
    @State private var dateIdeas: [Idea] = []
    @State private var watchList: [WatchItem] = []
    @State private var restaurants: [RestaurantItem] = []
    @State private var upcomingPlans: [Plan] = []

    @State private var newWatchText = ""
    @State private var showNewIdeaAlert = false
    @State private var newIdeaText = ""
    @State private var showNewRestaurantAlert = false
    @State private var newRestaurantText = ""

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        dateIdeasSection
                        watchListSection
                        restaurantSection
                        upcomingPlansSection
                        wishlistLink
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Planner")
            .alert("Nueva idea", isPresented: $showNewIdeaAlert) {
                TextField("Idea...", text: $newIdeaText)
                Button("Cancelar", role: .cancel) { newIdeaText = "" }
                Button("Agregar") {
                    let trimmed = newIdeaText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let idea = Idea(id: UUID().uuidString, emoji: "💡", title: trimmed)
                        dateIdeas.append(idea)
                        Task {
                            await FirestoreSyncService.shared.savePlannerItem(title: trimmed, type: "idea", emoji: "💡")
                        }
                        newIdeaText = ""
                    }
                }
            }
            .alert("Recomendar restaurante", isPresented: $showNewRestaurantAlert) {
                TextField("Nombre...", text: $newRestaurantText)
                Button("Cancelar", role: .cancel) { newRestaurantText = "" }
                Button("Agregar") {
                    let trimmed = newRestaurantText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let item = RestaurantItem(id: UUID().uuidString, emoji: "🍽️", name: trimmed, visited: false)
                        restaurants.append(item)
                        Task {
                            await FirestoreSyncService.shared.savePlannerItem(title: trimmed, type: "restaurant", emoji: "🍽️")
                        }
                        newRestaurantText = ""
                    }
                }
            }
            .task {
                let items = await FirestoreSyncService.shared.loadPlannerItems()
                dateIdeas = items.filter { $0["type"] as? String == "idea" }.map {
                    Idea(id: $0["id"] as? String ?? UUID().uuidString,
                         emoji: $0["emoji"] as? String ?? "💡",
                         title: $0["title"] as? String ?? "")
                }
                watchList = items.filter { $0["type"] as? String == "movie" }.map {
                    WatchItem(id: $0["id"] as? String ?? UUID().uuidString,
                              emoji: $0["emoji"] as? String ?? "🎬",
                              title: $0["title"] as? String ?? "",
                              isWatched: $0["isDone"] as? Bool ?? false)
                }
                restaurants = items.filter { $0["type"] as? String == "restaurant" }.map {
                    RestaurantItem(id: $0["id"] as? String ?? UUID().uuidString,
                                   emoji: $0["emoji"] as? String ?? "🍽️",
                                   name: $0["title"] as? String ?? "",
                                   visited: $0["isDone"] as? Bool ?? false)
                }
            }
        }
    }

    // MARK: - Date Ideas Section
    private var dateIdeasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ideas para salir")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dateIdeas) { idea in
                        GlassCard {
                            VStack(spacing: 8) {
                                Text(idea.emoji)
                                    .font(.system(size: 36))
                                Text(idea.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                Button {
                                    upcomingPlans.append(Plan(date: "Próximamente", title: idea.title, emoji: idea.emoji))
                                } label: {
                                    Text("Programar")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(ThemeManager.shared.primaryPink)
                                        .cornerRadius(12)
                                }
                            }
                            .frame(width: 120)
                        }
                    }

                    GlassCard {
                        Button {
                            showNewIdeaAlert = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text("Agregar idea")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 80)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Watch List Section
    private var watchListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lista de pendientes")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach($watchList) { $item in
                    GlassCard {
                        HStack(spacing: 12) {
                            Button {
                                item.isWatched.toggle()
                            } label: {
                                Image(systemName: item.isWatched ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(item.isWatched ? .green : .gray)
                            }

                            Text("\(item.emoji) \(item.title)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                                .strikethrough(item.isWatched)

                            Spacer()

                            Button {
                                watchList.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                GlassCard {
                    HStack {
                        TextField("Película o serie...", text: $newWatchText)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Button {
                            let trimmed = newWatchText.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                let emoji = trimmed.contains("(") ? "📺" : "🎬"
                                let item = WatchItem(id: UUID().uuidString, emoji: emoji, title: trimmed, isWatched: false)
                                watchList.append(item)
                                Task {
                                    await FirestoreSyncService.shared.savePlannerItem(title: trimmed, type: "movie", emoji: emoji)
                                }
                                newWatchText = ""
                            }
                        } label: {
                            Text("Agregar a la lista")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ThemeManager.shared.primaryPink)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Restaurant Section
    private var restaurantSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Restaurantes para probar")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach($restaurants) { $restaurant in
                    GlassCard {
                        HStack(spacing: 12) {
                            Text(restaurant.emoji)
                                .font(.system(size: 28))

                            Text(restaurant.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()

                            Button {
                                restaurant.visited.toggle()
                            } label: {
                                Text(restaurant.visited ? "✅ Visitado" : "⬜ Visitar")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(restaurant.visited ? .green : ThemeManager.shared.primaryPink)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        (restaurant.visited ? Color.green : ThemeManager.shared.primaryPink).opacity(0.15)
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                GlassCard {
                    Button {
                        showNewRestaurantAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(ThemeManager.shared.primaryPink)
                            Text("Recomendar restaurante")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Upcoming Plans Section
    private var upcomingPlansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Próximos planes")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(upcomingPlans.prefix(3)) { plan in
                    GlassCard {
                        HStack(spacing: 14) {
                            Text(plan.emoji)
                                .font(.system(size: 28))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plan.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(plan.date)
                                    .font(.system(size: 12))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Wishlist Link
    private var wishlistLink: some View {
        NavigationLink {
            WishlistView()
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 22))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                    Text("Lista de Deseos")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(ThemeManager.shared.textSecondary)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
