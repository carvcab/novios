import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab = 0

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Inicio", systemImage: "house.fill") }
                .tag(0)
                .onAppear { StatusService.shared.updateCurrentScreen("Inicio") }

            MessagesView()
                .tabItem { Label("Chat", systemImage: "message.fill") }
                .tag(1)
                .onAppear { StatusService.shared.updateCurrentScreen("Chat") }

            LoveView()
                .tabItem {
                    Label("Amor", systemImage: "heart.fill")
                }
                .tag(2)
                .onAppear { StatusService.shared.updateCurrentScreen("Amor") }

            LocationView()
                .tabItem { Label("Ubicación", systemImage: "location.fill") }
                .tag(3)
                .onAppear { StatusService.shared.updateCurrentScreen("Ubicación") }

            ProfileView()
                .tabItem { Label("Perfil", systemImage: "person.fill") }
                .tag(4)
                .onAppear { StatusService.shared.updateCurrentScreen("Perfil") }
        }
        .tint(ThemeManager.shared.primaryPink)
    }
}
