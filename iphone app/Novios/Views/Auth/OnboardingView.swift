import SwiftUI

public struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var name = ""
    @State private var username = ""
    @State private var birthday = Date()
    @State private var showBirthdayPicker = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isComplete = false

    public var onComplete: (() -> Void)?

    public var body: some View {
        ZStack {
            LinearGradient(colors: [ThemeManager.shared.primaryPink.opacity(0.9), ThemeManager.shared.primaryPurple.opacity(0.7), Color(red: 0.05, green: 0.05, blue: 0.05)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                Image(systemName: "heart.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.9))

                if isComplete {
                    completeStep
                } else {
                    profileSetupStep
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            if name.isEmpty { name = authService.currentUser?.displayName ?? "" }
        }
    }

    private var profileSetupStep: some View {
        VStack(spacing: 20) {
            Text("Tu Perfil").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            Text("Crea tu perfil para empezar").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))

            TextField("", text: $name, prompt: Text("Tu nombre").foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white).padding(14).background(.white.opacity(0.08)).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))

            TextField("", text: $username, prompt: Text("@usuario").foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white).autocapitalization(.none).padding(14).background(.white.opacity(0.08)).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))

            Button { showBirthdayPicker = true } label: {
                HStack {
                    Image(systemName: "calendar").foregroundColor(.white.opacity(0.5))
                    Text("Fecha de nacimiento").foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text(formatDate(birthday)).foregroundColor(.white)
                }.padding(14).background(.white.opacity(0.08)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
            }

            if let err = errorMessage {
                Text(err).font(.system(size: 13)).foregroundColor(.red)
            }

            Button {
                if name.trimmingCharacters(in: .whitespaces).isEmpty {
                    errorMessage = "Por favor ingresa tu nombre"; return
                }
                if username.trimmingCharacters(in: .whitespaces).isEmpty {
                    errorMessage = "Por favor ingresa un nombre de usuario"; return
                }
                authService.saveProfile(dob: birthday, username: username.lowercased().replacingOccurrences(of: " ", with: "_"), partnerName: nil)
                withAnimation { isComplete = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete?()
                }
            } label: {
                Text("Guardar Perfil").font(.system(size: 16, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(.white).cornerRadius(16)
            }
        }
        .sheet(isPresented: $showBirthdayPicker) {
            VStack(spacing: 20) {
                Text("Fecha de nacimiento").font(.headline)
                DatePicker("", selection: $birthday, in: ...Date(), displayedComponents: .date).datePickerStyle(.graphical)
                Button("Seleccionar") { showBirthdayPicker = false }
                    .font(.system(size: 16, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
            }.padding()
        }
    }

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(.green)
            Text("¡Todo listo!").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
            Text("Bienvenido a Novios").font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
        }
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"; f.locale = Locale(identifier: "es_MX")
        return f.string(from: d)
    }
}
