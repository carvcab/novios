import SwiftUI

public struct AppGate: View {
    @EnvironmentObject var authService: AuthService

    public var body: some View {
        Group {
            if authService.isRestoringSession {
                ZStack {
                    LiquidBackgroundView()
                    VStack(spacing: 16) {
                        ProgressView().tint(ThemeManager.shared.pastelRose)
                        Text("Cargando tu cuenta...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                    }
                }
            } else if !authService.isLoggedIn {
                WelcomeView()
            } else if !authService.hasPartner && !authService.partnerSkipped {
                AddPartnerView(onComplete: { authService.checkProfileAndPartner() })
            } else {
                MainTabView()
            }
        }
        .environmentObject(authService)
    }
}
