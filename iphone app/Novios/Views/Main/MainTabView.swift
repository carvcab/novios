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

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Perfil")
                }
                .tag(1)
        }
        .tint(ThemeManager.shared.primary)
    }
}
