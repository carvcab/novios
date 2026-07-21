import SwiftUI

public struct WelcomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage: String?

    public var body: some View {
        ZStack {
            LiquidBackgroundView()

            ScrollView {
                VStack(spacing: 22) {
                    Spacer().frame(height: 50)

                    Image(systemName: "heart.fill")
                        .appFont(size: 50)
                        .foregroundColor(ThemeManager.shared.primary)

                    Text("Novios")
                        .appFont(size: 30, weight: .medium)
                        .foregroundColor(ThemeManager.shared.primary)
                        .tracking(6)

                    Text("Solo para nosotros dos")
                        .appFont(size: 14)
                        .foregroundColor(ThemeManager.shared.textSecondary)
                        .tracking(2)

                    Spacer().frame(height: 10)

                    if let err = errorMessage {
                        Text(err)
                            .appFont(size: 13)
                            .foregroundColor(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .background(Color.red.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2)))
                    }

                    VStack(spacing: 12) {
                        if isSignUp {
                            glassField(placeholder: "Tu Nombre", text: $name, icon: "person.fill")
                        }
                        glassField(placeholder: "Correo Electrónico", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                        glassField(placeholder: "Contraseña", text: $password, icon: "lock.fill", isSecure: true)
                    }

                    Button {
                        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

                        if trimmedEmail.isEmpty || trimmedPassword.isEmpty || (isSignUp && trimmedName.isEmpty) {
                            errorMessage = "Por favor completa todos los campos"
                            return
                        }

                        Task {
                            errorMessage = nil
                            do {
                                if isSignUp {
                                    try await authService.signUpWithEmail(email: trimmedEmail, password: trimmedPassword, name: trimmedName)
                                } else {
                                    try await authService.signInWithEmail(email: trimmedEmail, password: trimmedPassword)
                                }
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        if authService.isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(ThemeManager.shared.primaryGradient)
                                .cornerRadius(16)
                        } else {
                            Text(isSignUp ? "Registrarse" : "Ingresar")
                                .appFont(size: 16, weight: .semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(ThemeManager.shared.primaryGradient)
                                .cornerRadius(16)
                                .shadow(color: ThemeManager.shared.primary.opacity(0.25), radius: 8, y: 3)
                        }
                    }
                    .disabled(authService.isLoading)

                    Button {
                        withAnimation { isSignUp.toggle(); errorMessage = nil }
                    } label: {
                        Text(isSignUp ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                            .appFont(size: 13, weight: .semibold)
                            .foregroundColor(ThemeManager.shared.primary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
    }

    private func glassField(placeholder: String, text: Binding<String>, icon: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(ThemeManager.shared.primary)
                .appFont(size: 16)
            if isSecure {
                SecureField("", text: text, prompt: Text(placeholder).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.5)))
                    .foregroundColor(.primary)
            } else {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.5)))
                    .foregroundColor(.primary)
                    .keyboardType(keyboardType)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .background(ThemeManager.shared.pastelWarmBg.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.6), ThemeManager.shared.pastelPink.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
        )
    }
}
