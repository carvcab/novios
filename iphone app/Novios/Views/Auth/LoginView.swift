import SwiftUI

public struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    
    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)
                    
                    Image(systemName: "heart.square.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                    
                    VStack(spacing: 8) {
                        Text(isSignUp ? "Crear Cuenta" : "Iniciar Sesión")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(isSignUp ? "Únete con tu correo para vincularte" : "Bienvenido de nuevo a tu espacio romántico")
                            .font(.system(size: 14))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                    }
                    
                    GlassCard {
                        VStack(spacing: 16) {
                            if isSignUp {
                                CustomTextField(placeholder: "Tu Nombre Completo", text: $name, icon: "person.fill")
                            }
                            
                            CustomTextField(placeholder: "Correo Electrónico", text: $email, icon: "envelope.fill")
                            
                            CustomTextField(placeholder: "Contraseña", text: $password, icon: "lock.fill", isSecure: true)
                            
                            if let error = authService.authError {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                            }
                            
                            GradientButton(
                                title: isSignUp ? "Registrarme" : "Entrar",
                                icon: isSignUp ? "person.badge.plus" : "lock.open.fill",
                                isLoading: authService.isLoading
                            ) {
                                Task {
                                    if isSignUp {
                                        _ = await authService.signUp(email: email, pass: password, name: name)
                                    } else {
                                        _ = await authService.signIn(email: email, pass: password)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button {
                        withAnimation { isSignUp.toggle() }
                    } label: {
                        Text(isSignUp ? "¿Ya tienes cuenta? Inicia Sesión" : "¿No tienes cuenta? Regístrate aquí")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
            }
        }
    }
}
