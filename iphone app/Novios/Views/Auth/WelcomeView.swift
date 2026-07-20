import SwiftUI

public struct WelcomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showEmailForm = false
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    public var body: some View {
        ZStack {
            LinearGradient(colors: [ThemeManager.shared.primaryPink.opacity(0.9), ThemeManager.shared.primaryPurple.opacity(0.6), Color(red: 0.04, green: 0.04, blue: 0.07).opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "heart.fill").font(.system(size: 48)).foregroundColor(.white.opacity(0.8))
                    .padding(24).background(Circle().stroke(.white.opacity(0.2), lineWidth: 1.5))

                Text("Novios").font(.system(size: 34, weight: .semibold)).foregroundColor(.white).tracking(4)
                Text("Solo para nosotros dos").font(.system(size: 14, weight: .light)).foregroundColor(.white.opacity(0.6)).tracking(0.5)

                Spacer().frame(height: 20)

                if let err = errorMessage {
                    Text(err).font(.system(size: 13)).foregroundColor(.red).padding(12)
                        .frame(maxWidth: .infinity).background(.red.opacity(0.15)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.3)))
                }

                if !showEmailForm {
                    googleButton
                    emailOptionButton
                } else {
                    emailForm
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("Política de Privacidad").font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                    Text("•").font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
                    Text("Términos de Servicio").font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var googleButton: some View {
        Button {
            Task {
                isLoading = true; errorMessage = nil
                _ = await authService.signInWithGoogle()
                isLoading = false
            }
        } label: {
            HStack {
                Image(systemName: "g.circle.fill").font(.system(size: 20)).foregroundColor(Color(red: 0.25, green: 0.49, blue: 0.96))
                Text("Continuar con Google").font(.system(size: 15, weight: .medium))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(.white).cornerRadius(28).foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.55))
        }
        .disabled(isLoading)
    }

    private var emailOptionButton: some View {
        Button {
            withAnimation { showEmailForm = true }
        } label: {
            HStack {
                Image(systemName: "envelope.fill").font(.system(size: 16)).foregroundColor(.white)
                Text("Entrar con Correo").font(.system(size: 15)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.3), lineWidth: 1.5))
        }
    }

    private var emailForm: some View {
        VStack(spacing: 16) {
            Text(isSignUp ? "Crear Cuenta" : "Iniciar Sesión").font(.system(size: 20, weight: .bold)).foregroundColor(.white)

            if isSignUp {
                TextField("", text: $name, prompt: Text("Tu Nombre").foregroundColor(.white.opacity(0.3)))
                    .foregroundColor(.white).padding(14).background(.white.opacity(0.05))
                    .cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
            }

            TextField("", text: $email, prompt: Text("Correo Electrónico").foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white).keyboardType(.emailAddress).padding(14).background(.white.opacity(0.05))
                .cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))

            SecureField("", text: $password, prompt: Text("Contraseña").foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white).padding(14).background(.white.opacity(0.05))
                .cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))

            Button {
                Task {
                    isLoading = true; errorMessage = nil
                    do {
                        if isSignUp {
                            try await authService.signUpWithEmail(email: email, password: password, name: name)
                        } else {
                            try await authService.signInWithEmail(email: email, password: password)
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            } label: {
                Text(isSignUp ? "Registrarse" : "Ingresar").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(ThemeManager.shared.primaryPink).cornerRadius(16)
            }
            .disabled(isLoading)

            Button {
                withAnimation { isSignUp.toggle(); errorMessage = nil }
            } label: {
                Text(isSignUp ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
            }

            Divider().background(.white.opacity(0.15))

            Button {
                withAnimation { showEmailForm = false }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    Text("Volver a opciones").font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(24)
        .background(.white.opacity(0.08)).cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.15)))
    }
}
