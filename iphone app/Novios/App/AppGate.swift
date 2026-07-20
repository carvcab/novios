import SwiftUI

public struct AppGate: View {
    @EnvironmentObject var authService: AuthService
    @State private var showOnboarding = false
    @State private var showAddPartner = false

    public var body: some View {
        Group {
            if !authService.isLoggedIn {
                WelcomeView()
            } else if showOnboarding {
                OnboardingView(onComplete: {
                    showOnboarding = false
                    authService.checkProfileAndPartner()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if !authService.hasPartner && !authService.partnerSkipped {
                            showAddPartner = true
                        }
                    }
                })
            } else if showAddPartner {
                AddPartnerView(onComplete: {
                    showAddPartner = false
                    authService.checkProfileAndPartner()
                })
            } else if !authService.hasProfile {
                OnboardingView(onComplete: {
                    authService.checkProfileAndPartner()
                })
            } else if !authService.hasPartner && !authService.partnerSkipped {
                AddPartnerView(onComplete: {
                    authService.checkProfileAndPartner()
                })
            } else {
                MainTabView()
            }
        }
        .environmentObject(authService)
        .onAppear {
            authService.checkProfileAndPartner()
            if !authService.hasProfile { showOnboarding = true }
            else if !authService.hasPartner && !authService.partnerSkipped { showAddPartner = true }
        }
    }
}
