import SwiftUI

@main
struct NoviosApp: App {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            AppGate()
                .environmentObject(firebaseService)
                .environmentObject(authService)
                .environmentObject(themeManager)
                .preferredColorScheme(.light)
        }
    }
}
