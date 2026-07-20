import SwiftUI

public struct ProfileSetupView: View {
    @EnvironmentObject var authService: AuthService
    @State private var username = ""
    @State private var birthday = Date()
    
    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer().frame(height: 20)
                
                Image(systemName: "person.crop.circle.badge.sparkles")
                    .font(.system(size: 70))
                    .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                
                VStack(spacing: 6) {
                    Text("Configura tu Perfil")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Tu pareja te identificará con estos datos en la app")
                        .font(.system(size: 14))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                }
                
                GlassCard {
                    VStack(spacing: 16) {
                        CustomTextField(placeholder: "Nombre de Usuario (ej: diego123)", text: $username, icon: "at")
                        
                        DatePicker("Fecha de Cumpleaños", selection: $birthday, displayedComponents: .date)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                        
                        GradientButton(title: "Guardar y Continuar", icon: "checkmark.circle.fill") {
                            let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            authService.saveProfile(dob: birthday, username: cleanUsername.isEmpty ? "usuario" : cleanUsername, partnerName: nil)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}
