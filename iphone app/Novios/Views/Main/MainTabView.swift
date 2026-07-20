import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab = 0

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            MessagesView()
                .tabItem {
                    Label("Chat", systemImage: selectedTab == 1 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                }
                .tag(1)

            LoveView()
                .tabItem {
                    Label("Amor", systemImage: selectedTab == 2 ? "heart.fill" : "heart")
                }
                .tag(2)

            LocationView()
                .tabItem {
                    Label("Ubicación", systemImage: selectedTab == 3 ? "location.fill" : "location")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .tint(ThemeManager.shared.primaryPink)
    }
}
