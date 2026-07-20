import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var userService = UserService.shared
    
    @State private var enablePin = false
    @State private var pinCode = ""
    
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Perfil Card
                    GlassCard {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(authService.currentUser?.displayName ?? "Mi Nombre")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("@\(authService.currentUser?.username ?? "usuario")")
                                    .font(.system(size: 13))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Notificaciones de Pareja en Vivo
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text("NOTIFICACIONES DE TU PAREJA")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(spacing: 10) {
                                Button {
                                    userService.simulatePartnerEvent(event: .lowBattery(15))
                                } label: {
                                    TestNotificationRow(title: "Simular Batería Baja (15%) 🔋", color: .orange)
                                }
                                
                                Button {
                                    userService.simulatePartnerEvent(event: .startedCharging)
                                } label: {
                                    TestNotificationRow(title: "Simular Celular Cargando ⚡", color: .green)
                                }
                                
                                Button {
                                    userService.simulatePartnerEvent(event: .moodChanged("🥰", "Pensando en ti cada segundo"))
                                } label: {
                                    TestNotificationRow(title: "Simular Cambio de Estado de Ánimo 🥰", color: .pink)
                                }
                                
                                Button {
                                    userService.simulatePartnerEvent(event: .proximityAlert("A solo 250 metros de ti"))
                                } label: {
                                    TestNotificationRow(title: "Simular Alerta de Cercanía (250m) 📍", color: .purple)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Firebase Status
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("ESTADO DE FIREBASE DUAL")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("Proyecto Activo:")
                                    .font(.system(size: 13))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                                Spacer()
                                Text(firebaseService.activeProjectID)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                            }
                            
                            Button {
                                firebaseService.switchToBackupIfNeeded()
                            } label: {
                                Text("Cambiar a Servidor Respaldo (novios-49289)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Seguridad & Ajustes
                    GlassCard {
                        VStack(spacing: 16) {
                            Toggle(isOn: $themeManager.pinLockEnabled) {
                                Label("Bloqueo de App con PIN / Face ID", systemImage: "lock.shield.fill")
                                    .foregroundColor(.primary)
                            }
                            .tint(ThemeManager.shared.primaryPink)
                            
                            Toggle(isOn: $themeManager.enableHaptics) {
                                Label("Vibración Háptica en Besos/Toques", systemImage: "waveform")
                                    .foregroundColor(.primary)
                            }
                            .tint(ThemeManager.shared.primaryPink)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Cerrar Sesión
                    Button {
                        authService.signOut()
                    } label: {
                        Text("Cerrar Sesión")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Ajustes & Configuración")
    }
}

public struct TestNotificationRow: View {
    public let title: String
    public let color: Color
    
    public var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "paperplane.fill")
                .font(.system(size: 12))
                .foregroundColor(color)
        }
        .padding(10)
        .background(color.opacity(0.15))
        .cornerRadius(10)
    }
}
