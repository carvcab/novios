import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var coupleService = CoupleService.shared

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            MessagesView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Nuestro Chat")
                }
                .tag(0)

            LocationView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Nuestro Mapa")
                }
                .tag(1)

            MemoriesAndLettersView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Recuerdos")
                }
                .tag(2)

            DreamsAndGoalsView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Sueños")
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
    }
}
