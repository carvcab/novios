import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            MessagesView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Mensajes")
                }
                .tag(0)

            LocationView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Ubicación")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Perfil")
                }
                .tag(2)
        }
        .tint(ThemeManager.shared.primary)
    }
}
