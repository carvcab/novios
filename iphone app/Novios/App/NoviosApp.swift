import SwiftUI

@main
struct NoviosApp: App {
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            AppGate()
                .environmentObject(authService)
                .preferredColorScheme(.light)
        }
    }
}
