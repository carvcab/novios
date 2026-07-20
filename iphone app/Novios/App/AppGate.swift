import SwiftUI

public struct AppGate: View {
    @EnvironmentObject var authService: AuthService
    @State private var permissionsDone = UserDefaults.standard.bool(forKey: "permissions_granted")

    public var body: some View {
        Group {
            if authService.isRestoringSession {
                ZStack {
                    ThemeManager.shared.backgroundGradient.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView().tint(ThemeManager.shared.primaryPink)
                        Text("Cargando tu cuenta...").font(.system(size: 14, weight: .medium)).foregroundColor(.primary.opacity(0.7))
                    }
                }
            } else if !authService.isLoggedIn {
                WelcomeView()
            } else if !authService.hasProfile {
                OnboardingView(onComplete: { authService.checkProfileAndPartner() })
            } else if !authService.hasPartner && !authService.partnerSkipped {
                AddPartnerView(onComplete: { authService.checkProfileAndPartner() })
            } else if !permissionsDone {
                PermissionsView(onComplete: {
                    permissionsDone = true
                    UserDefaults.standard.set(true, forKey: "permissions_granted")
                })
            } else {
                MainTabView()
            }
        }
        .environmentObject(authService)
    }
}
