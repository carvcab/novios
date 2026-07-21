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
                    Text("Chat")
                }
                .tag(0)

            LocationView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Mapa")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Nosotros")
                }
                .tag(2)
        }
        .tint(ThemeManager.shared.primary)
    }
}
