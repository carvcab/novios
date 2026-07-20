import SwiftUI

public struct LiveStatusView: View {
    @StateObject private var screenService = ScreenShareService.shared
    @StateObject private var userService = UserService.shared
    
    @State private var isPulseAnimating = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                FloatingHeartsEffect()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Tarjeta Transmisión de Pantalla en Vivo
                        GlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Circle()
                                        .fill(screenService.status == .streaming ? Color.green : Color.orange)
                                        .frame(width: 10, height: 10)
                                        .scaleEffect(isPulseAnimating ? 1.4 : 1.0)
                                    
                                    Text("TRANSMISIÓN DE PANTALLA EN VIVO")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .tracking(1.0)
                                    
                                    Spacer()
                                    
                                    Text(screenService.status == .streaming ? "EN VIVO" : "INACTIVO")
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(screenService.status == .streaming ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                        .foregroundColor(screenService.status == .streaming ? .green : .gray)
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.black.opacity(0.4))
                                        .frame(height: 180)
                                    
                                    if screenService.status == .streaming {
                                        VStack(spacing: 10) {
                                            Image(systemName: "tv.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(ThemeManager.shared.primaryPink)
                                            Text("Compartiendo pantalla con tu pareja...")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    } else {
                                        VStack(spacing: 10) {
                                            Image(systemName: "rectangle.inset.filled.and.cursorarrow")
                                                .font(.system(size: 40))
                                                .foregroundColor(Color.white.opacity(0.4))
                                            Text("Comienza a transmitir tu pantalla en tiempo real")
                                                .font(.system(size: 13))
                                                .foregroundColor(ThemeManager.shared.textSecondary)
                                        }
                                    }
                                }
                                
                                GradientButton(
                                    title: screenService.status == .streaming ? "Detener Transmisión" : "Compartir Mi Pantalla",
                                    icon: screenService.status == .streaming ? "stop.fill" : "play.fill"
                                ) {
                                    if screenService.status == .streaming {
                                        screenService.stopScreenShare()
                                    } else {
                                        screenService.requestScreenShare()
                                        ChatNotificationService.shared.notifyScreenShareStarted(from: AuthService.shared.currentUser?.displayName ?? "Tu pareja")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Tarjeta Latidos del Corazón en Vivo
                        GlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "waveform.path.ecg")
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("SINCRONIZACIÓN DE LATIDOS")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Spacer()
                                }
                                
                                HStack(spacing: 20) {
                                    PulsingHeartView(size: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(screenService.currentBpm) BPM")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(screenService.isHeartbeatSynced ? "Latidos sincronizados con tu pareja ❤️" : "Presiona para sintonizar ritmos")
                                            .font(.system(size: 12))
                                            .foregroundColor(ThemeManager.shared.textSecondary)
                                    }
                                    Spacer()
                                }
                                
                                Button {
                                    screenService.toggleHeartbeatSync()
                                } label: {
                                    Text(screenService.isHeartbeatSynced ? "Desconectar Sincronización" : "Sincronizar Latidos en Vivo")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("En Vivo & Pantalla")
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulseAnimating = true
                }
            }
        }
    }
}
