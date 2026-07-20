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
            Color(red: 0.035, green: 0.035, blue: 0.043).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)

                    Image(systemName: "heart.fill").font(.system(size: 56)).foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.54))
                    Text("Novios").font(.system(size: 32, weight: .medium)).foregroundColor(.white).tracking(6)
                    Text("Solo para nosotros dos").font(.system(size: 14)).foregroundColor(.white.opacity(0.5)).tracking(2)

                    Spacer().frame(height: 20)

                    if let err = errorMessage {
                        Text(err).font(.system(size: 13)).foregroundColor(.red).padding(12)
                            .frame(maxWidth: .infinity).background(.red.opacity(0.15)).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.3)))
                    }

                    VStack(spacing: 12) {
                        if isSignUp {
                            TextField("", text: $name, prompt: Text("Tu Nombre").foregroundColor(.white.opacity(0.3)))
                                .foregroundColor(.white).padding(14)
                                .background(.white.opacity(0.08)).cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
                        }
                        TextField("", text: $email, prompt: Text("Correo Electrónico").foregroundColor(.white.opacity(0.3)))
                            .foregroundColor(.white).keyboardType(.emailAddress).padding(14)
                            .background(.white.opacity(0.08)).cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
                        SecureField("", text: $password, prompt: Text("Contraseña").foregroundColor(.white.opacity(0.3)))
                            .foregroundColor(.white).padding(14)
                            .background(.white.opacity(0.08)).cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
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
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(14)
                        } else {
                            Text(isSignUp ? "Registrarse" : "Ingresar")
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(14)
                        }
                    }
                    .disabled(authService.isLoading)

                    Button {
                        withAnimation { isSignUp.toggle(); errorMessage = nil }
                    } label: {
                        Text(isSignUp ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.54))
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
