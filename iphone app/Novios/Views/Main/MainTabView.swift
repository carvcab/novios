import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var coupleService = CoupleService.shared
    @ObservedObject private var chatService = ChatService.shared

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Inicio")
                }
                .tag(0)

            MessagesView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Nuestro Chat")
                }
                .badge(chatService.unreadCount > 0 ? chatService.unreadCount : 0)
                .tag(1)

            LoveView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Nuestro Amor")
                }
                .tag(2)

            LocationView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Nuestro Mapa")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Nosotros")
                }
                .tag(4)
        }
        .tint(ThemeManager.shared.primary)
        .task {
            await CoupleService.shared.refreshSubcollections()
        }
        .onChange(of: selectedTab) { tab in
            if tab == 1 { chatService.unreadCount = 0 }
        }
    }
}
