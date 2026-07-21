import SwiftUI

public struct AddPartnerView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isAdding = false
    @State private var foundUser: [String: Any]?
    @State private var errorMessage: String?

    public var onComplete: (() -> Void)?

    public var body: some View {
        ZStack {
            LiquidBackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundColor(ThemeManager.shared.pastelRose)

                    Text("Vincular Pareja")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Busca a tu pareja por su nombre de usuario o correo")
                        .font(.system(size: 13))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                        .multilineTextAlignment(.center)

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13)).foregroundColor(.red)
                            .padding(12).frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial).background(Color.red.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2)))
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ThemeManager.shared.textSecondary)
                        TextField("", text: $searchText, prompt: Text("Nombre de usuario o correo de tu pareja").foregroundColor(ThemeManager.shared.textSecondary.opacity(0.5)))
                            .foregroundColor(.primary).autocapitalization(.none).disableAutocorrection(true)
                        if isSearching {
                            ProgressView().tint(ThemeManager.shared.pastelRose)
                        } else if foundUser != nil {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .background(ThemeManager.shared.pastelWarmBg.opacity(0.3))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                        foundUser != nil ? ThemeManager.shared.pastelRose.opacity(0.6) : .white.opacity(0.3),
                        lineWidth: 0.8
                    ))
                    .onChange(of: searchText) { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                        if trimmed.count >= 3 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if self.searchText == newValue { performSearch() }
                            }
                        } else {
                            foundUser = nil; errorMessage = nil
                        }
                    }

                    if let found = foundUser {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(ThemeManager.shared.pastelPink.opacity(0.2))
                                .frame(width: 68, height: 68)
                                .overlay(Image(systemName: "person.fill").font(.system(size: 28))
                                    .foregroundColor(ThemeManager.shared.pastelRose))

                            Text(found["displayName"] as? String ?? "Usuario Encontrado")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.primary)

                            if let uname = found["username"] as? String, !uname.isEmpty {
                                Text("@\(uname)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ThemeManager.shared.pastelRose)
                                    .padding(.horizontal, 10).padding(.vertical, 3)
                                    .background(ThemeManager.shared.pastelPink.opacity(0.15)).cornerRadius(8)
                            }

                            Button {
                                Task {
                                    isAdding = true; errorMessage = nil
                                    let result = await userService.addPartner(query: searchText)
                                    isAdding = false
                                    switch result {
                                    case .success:
                                        authService.savePartner(uid: found["uid"] as? String ?? "", name: found["displayName"] as? String ?? "Pareja")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete?() }
                                    case .alreadyHasPartner:
                                        errorMessage = "Ya tienes una pareja vinculada."
                                    case .targetHasPartner:
                                        errorMessage = "Esta persona ya está vinculada con otra pareja."
                                    case .notFound:
                                        errorMessage = "No se encontró ningún usuario con ese nombre o correo."
                                    default:
                                        errorMessage = "Ocurrió un error al vincular. Intenta de nuevo."
                                    }
                                }
                            } label: {
                                if isAdding {
                                    ProgressView().tint(.white)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(
                                            LinearGradient(colors: [ThemeManager.shared.pastelRose, ThemeManager.shared.pastelLavender],
                                                startPoint: .leading, endPoint: .trailing)
                                        )
                                        .cornerRadius(14)
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "heart.fill").font(.system(size: 16))
                                        Text("Vincular Pareja Ahora")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(
                                        LinearGradient(colors: [ThemeManager.shared.pastelRose, ThemeManager.shared.pastelLavender],
                                            startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: ThemeManager.shared.pastelRose.opacity(0.2), radius: 8, y: 3)
                                }
                            }
                            .disabled(isAdding)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .background(ThemeManager.shared.pastelWarmBg.opacity(0.3))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(
                            LinearGradient(colors: [.white.opacity(0.6), ThemeManager.shared.pastelPink.opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 0.8
                        ))
                    }

                    Spacer()

                    Button {
                        authService.didSkipPartner()
                        onComplete?()
                    } label: {
                        Text("Vincular más tarde")
                            .font(.system(size: 14))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                    }
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }
        isSearching = true
        errorMessage = nil
        foundUser = nil
        Task {
            let user = await userService.searchUser(query: trimmed)
            await MainActor.run {
                self.isSearching = false
                if let user = user { self.foundUser = user }
                else { self.errorMessage = "No se encontró ningún usuario con ese nombre o correo." }
            }
        }
    }
}
