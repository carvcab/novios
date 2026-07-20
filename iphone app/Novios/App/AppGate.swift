import SwiftUI

public struct AppGate: View {
    @EnvironmentObject var authService: AuthService

    public var body: some View {
        Group {
            if !authService.isLoggedIn {
                WelcomeView()
            } else if !authService.hasProfile {
                OnboardingView()
            } else if !authService.hasPartner && !authService.partnerSkipped {
                AddPartnerView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(authService)
    }
}
