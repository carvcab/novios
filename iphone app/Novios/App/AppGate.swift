import SwiftUI

public struct AppGate: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var didLockOnBackground = false

    public var body: some View {
        Group {
            if authService.isRestoringSession {
                ZStack {
                    LiquidBackgroundView()
                    VStack(spacing: 16) {
                        ProgressView().tint(theme.primary)
                        Text("Cargando tu cuenta...")
                            .appFont(size: 14, weight: .medium)
                            .foregroundColor(theme.textSecondary)
                    }
                }
            } else if authService.isLocked {
                LockScreenView()
            } else if !authService.isLoggedIn {
                WelcomeView()
            } else if !authService.hasPartner && !authService.partnerSkipped {
                AddPartnerView(onComplete: { authService.checkProfileAndPartner() })
            } else {
                MainTabView()
            }
        }
        .environmentObject(authService)
        .onChange(of: scenePhase) { phase in
            let securityEnabled = UserDefaults.standard.bool(forKey: "security_enabled")
            if phase == .active {
                LocationService.shared.appDidBecomeActive()
                if securityEnabled && didLockOnBackground {
                    authService.isLocked = true
                    didLockOnBackground = false
                }
            }
            if phase == .background || phase == .inactive {
                LocationService.shared.appDidEnterBackground()
                if securityEnabled {
                    didLockOnBackground = true
                }
            }
        }
    }
}
