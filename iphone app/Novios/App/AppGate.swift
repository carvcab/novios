import SwiftUI

public struct AppGate: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared
    
    public var body: some View {
        Group {
            if !authService.isAuthenticated {
                WelcomeView()
            } else if let user = authService.currentUser {
                if user.username.isEmpty {
                    ProfileSetupView()
                } else if !user.isPaired && !user.skippedPartner {
                    AddPartnerView()
                } else {
                    MainTabView()
                }
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}
