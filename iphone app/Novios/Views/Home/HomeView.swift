import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared
    
    @State private var appearAnimation = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Animated Background
                LiquidBackgroundView()
                
                // Floating Heart Particles Layer
                FloatingHeartsEffect()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Hola, \(authService.currentUser?.displayName ?? "Amor")")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "sparkles")
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                }
                                
                                Text("Su historia de amor está conectada ✨")
                                    .font(.system(size: 13))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                            }
                            Spacer()
                            
                            // Glowing Heart Avatar Icon
                            ZStack {
                                Circle()
                                    .fill(ThemeManager.shared.primaryPink.opacity(0.25))
                                    .frame(width: 48, height: 48)
                                    .blur(radius: 4)
                                
                                Circle()
                                    .fill(ThemeManager.shared.cardBackground)
                                    .frame(width: 46, height: 46)
                                    .overlay(
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : -20)
                        
                        // Tarjeta de estado de pareja
                        PartnerStatusCard(partner: userService.partnerUser)
                            .padding(.horizontal, 20)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.94)
                        
                        // Widget de Distancia
                        DistanceWidgetView(partnerCoordinate: userService.partnerUser?.coordinate)
                            .padding(.horizontal, 20)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 20)
                        
                        // Widget Contador de Amor
                        LoveCounterWidgetView(anniversaryDate: authService.currentUser?.anniversaryDate)
                            .padding(.horizontal, 20)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.95)
                        
                        // Sección de Momentos Destacados
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Acceso Rápido")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    QuickFeatureTile(title: "Notas de Voz", icon: "mic.fill", color: .purple)
                                    QuickFeatureTile(title: "Cápsula Tiempo", icon: "hourglass", color: .orange)
                                    QuickFeatureTile(title: "Verdad o Reto", icon: "dice.fill", color: .pink)
                                    QuickFeatureTile(title: "Cita Romántica", icon: "sparkles", color: .blue)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                    appearAnimation = true
                }
            }
        }
    }
}
