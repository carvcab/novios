import SwiftUI
import Firebase

@main
struct NoviosApp: App {
    @StateObject private var authService = AuthService.shared

    init() {
        FirebaseApp.configure()
    }
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            AppGate()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
