import SwiftUI

public struct AppGate: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var coupleService = CoupleService.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var didLockOnBackground = false
    @State private var isLoadingCouple = false

    public var body: some View {
        Group {
            if authService.isRestoringSession || isLoadingCouple {
                ZStack {
                    LiquidBackgroundView()
                    VStack(spacing: 16) {
                        ProgressView().tint(theme.primary)
                        Text("Cargando...")
                            .appFont(size: 14, weight: .medium)
                            .foregroundColor(theme.textSecondary)
                        Text(coupleService.coupleName)
                            .appFont(size: 12)
                            .foregroundColor(theme.textSecondary.opacity(0.5))
                    }
                }
            } else if authService.isLocked {
                LockScreenView()
            } else if !authService.isLoggedIn {
                WelcomeView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(authService)
        .onAppear {
            if authService.isLoggedIn {
                loadCoupleData()
            }
        }
        .onChange(of: authService.isLoggedIn) { loggedIn in
            if loggedIn { loadCoupleData() }
        }
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

    private func loadCoupleData() {
        isLoadingCouple = true
        Task {
            await CoupleService.shared.loadCouple()
            await MainActor.run {
                isLoadingCouple = false
            }
        }
    }
}
