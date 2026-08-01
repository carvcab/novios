import SwiftUI
import Firebase

@main
struct NoviosApp: App {
    @StateObject private var authService: AuthService
    @StateObject private var themeManager: ThemeManager

    init() {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("[NoviosApp] GoogleService-Info.plist no encontrado en bundle")
        }
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
