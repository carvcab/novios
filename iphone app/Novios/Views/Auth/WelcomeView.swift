import SwiftUI

public struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showOnboarding = false
    @State private var animateHero = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                FloatingHeartsEffect()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        PulsingHeartView(size: 76)
                            .scaleEffect(animateHero ? 1 : 0.7)
                            .opacity(animateHero ? 1 : 0)
                        
                        VStack(spacing: 12) {
                            Text("Novios")
                                .font(.system(size: 46, weight: .bold))
                                .foregroundColor(.primary)
                                .shadow(color: ThemeManager.shared.primaryPink.opacity(0.6), radius: 15)
                            
                            Text("El espacio privado e íntimo para ti y tu pareja. Conéctense en tiempo real sin importar la distancia.")
                                .font(.system(size: 15))
                                .foregroundColor(ThemeManager.shared.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                        }
                        .opacity(animateHero ? 1 : 0)
                        .offset(y: animateHero ? 0 : 25)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        GradientButton(title: "Comenzar Ahora", icon: "heart.circle.fill") {
                            showOnboarding = true
                        }
                        
                        Button {
                            showLogin = true
                        } label: {
                            Text("Ya tengo una cuenta")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                    .opacity(animateHero ? 1 : 0)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateHero = true
                }
            }
            .navigationDestination(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
        }
    }
}
