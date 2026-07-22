import SwiftUI
import Firebase

@main
struct NoviosApp: App {
    @StateObject private var authService: AuthService
    @StateObject private var themeManager: ThemeManager

    init() {
        FirebaseApp.configure()
        _authService = StateObject(wrappedValue: AuthService.shared)
        _themeManager = StateObject(wrappedValue: ThemeManager.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            AppGate()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
