import SwiftUI

public struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var step = 0
    @State private var isCreator = false
    @State private var codeInput = ""
    @State private var generatedCode = ""
    @State private var name = ""
    @State private var birthday = Date()
    @State private var anniversary = Date()
    @State private var showBirthdayPicker = false
    @State private var showAnniversaryPicker = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let userService = UserService.shared

    public var body: some View {
        ZStack {
            LinearGradient(colors: [ThemeManager.shared.primaryPink.opacity(0.9), ThemeManager.shared.primaryPurple.opacity(0.7), Color(red: 0.05, green: 0.05, blue: 0.05)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "heart.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.9))

                if step == 0 { hasPartnerStep }
                else if step == 1 { enterCodeStep }
                else if step == 2 { showCodeStep }
                else if step == 3 { profileSetupStep }
                else if step == 4 { completeStep }
            }
            .padding(.horizontal, 32)
        }
    }

    private var hasPartnerStep: some View {
        VStack(spacing: 20) {
            Text("Bienvenido").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
            Text("¿Ya tienes una pareja?").font(.system(size: 16)).foregroundColor(.white.opacity(0.8))

            Button {
                isCreator = false; step = 1
            } label: {
                Text("Sí, tengo un código").font(.system(size: 16, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(.white).cornerRadius(16)
            }

            Button {
                isCreator = true; generateCode(); step = 2
            } label: {
                Text("No, crear nueva relación").font(.system(size: 16, weight: .medium)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.4)))
            }
        }
    }

    private var enterCodeStep: some View {
        VStack(spacing: 20) {
            Text("Ingresa el código").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            Text("Pídele el código a tu pareja").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))

            TextField("", text: $codeInput, prompt: Text("Ej: A7F9K2").foregroundColor(.gray))
                .font(.system(size: 24, weight: .bold)).tracking(8).multilineTextAlignment(.center)
                .foregroundColor(.black).padding(16).background(.white.opacity(0.95)).cornerRadius(16)
                .textCase(.uppercase)

            if let err = errorMessage {
                Text(err).font(.system(size: 13)).foregroundColor(.red)
            }

            Button {
                Task {
                    isLoading = true; errorMessage = nil
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    let code = codeInput.trimmingCharacters(in: .whitespaces).uppercased()
                    if code.count >= 4 {
                        authService.savePartner(uid: "partner_\(code)", name: "Mi Pareja")
                        step = 3
                    } else {
                        errorMessage = "Código inválido. Intenta de nuevo."
                    }
                    isLoading = false
                }
            } label: {
                Text("Unirse").font(.system(size: 16, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(.white).cornerRadius(16)
            }
            .disabled(isLoading || codeInput.count < 4)
        }
    }

    private var showCodeStep: some View {
        VStack(spacing: 20) {
            Text("Tu código").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            Text("Comparte este código con tu pareja").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))

            Text(generatedCode).font(.system(size: 36, weight: .bold)).tracking(10).foregroundColor(.white)
                .padding(20).background(.white.opacity(0.12)).cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.2)))

            Button {
                UIPasteboard.general.string = generatedCode
            } label: {
                Text("Copiar código 📋").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.3)))
            }

            Button {
                step = 3
            } label: {
                Text("Continuar").font(.system(size: 16, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(.white).cornerRadius(16)
            }
        }
    }

    private var profileSetupStep: some View {
        VStack(spacing: 20) {
            Text("Tu Perfil").font(.system(size: 24, weight: .bold)).foregroundColor(.white)

            TextField("", text: $name, prompt: Text("Tu nombre").foregroundColor(.white.opacity(0.3)))
                .foregroundColor(.white).padding(14).background(.white.opacity(0.08)).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))

            dateButton(title: "Fecha de nacimiento", date: birthday, action: { showBirthdayPicker = true })
            if isCreator {
                dateButton(title: "Fecha de aniversario", date: anniversary, action: { showAnniversaryPicker = true })
            }

            if let err = errorMessage {
                Text(err).font(.system(size: 13)).foregroundColor(.red)
            }

            Button {
                if name.trimmingCharacters(in: .whitespaces).isEmpty {
                    errorMessage = "Por favor ingresa tu nombre"; return
                }
                authService.saveProfile(dob: birthday, username: name.lowercased().replacingOccurrences(of: " ", with: "_"), partnerName: nil)
                step = 4
            } label: {
                Text("Guardar Perfil").font(.system(size: 16, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(.white).cornerRadius(16)
            }
        }
        .sheet(isPresented: $showBirthdayPicker) {
            DatePickerView(title: "Fecha de nacimiento", date: $birthday)
        }
        .sheet(isPresented: $showAnniversaryPicker) {
            DatePickerView(title: "Fecha de aniversario", date: $anniversary)
        }
    }

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundColor(.green)
            Text("¡Todo listo!").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
            Text("Bienvenido a Novios").font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                authService.checkProfileAndPartner()
            }
        }
    }

    private func generateCode() {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        generatedCode = String((0..<6).map { _ in chars.randomElement()! })
    }

    private func dateButton(title: String, date: Date, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "calendar").foregroundColor(.white.opacity(0.5))
                Text(title).foregroundColor(.white.opacity(0.5))
                Spacer()
                Text(formatDate(date)).foregroundColor(.white)
            }.padding(14).background(.white.opacity(0.08)).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
        }
    }

    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "es_MX")
        return f.string(from: d)
    }
}

private struct DatePickerView: View {
    let title: String
    @Binding var date: Date
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(title).font(.headline)
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
            Button("Seleccionar") { dismiss() }
                .font(.system(size: 16, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
        }.padding()
    }
}
