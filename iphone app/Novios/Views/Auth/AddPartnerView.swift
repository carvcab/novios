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
            ThemeManager.shared.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "heart.fill").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primaryPink)

                Text("Vincular Pareja").font(.system(size: 26, weight: .bold)).foregroundColor(.primary)
                Text("Busca a tu pareja por su nombre de usuario o correo")
                    .font(.system(size: 13)).foregroundColor(ThemeManager.shared.textSecondary).multilineTextAlignment(.center)

                if let err = errorMessage {
                    Text(err).font(.system(size: 13)).foregroundColor(.red).padding(12)
                        .frame(maxWidth: .infinity).background(.red.opacity(0.15)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.3)))
                }

                // Search field
                GlassCard {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.primary.opacity(0.4))
                        TextField("", text: $searchText, prompt: Text("Nombre de usuario o correo de tu pareja").foregroundColor(.primary.opacity(0.4)))
                            .foregroundColor(.primary).autocapitalization(.none)
                        if isSearching {
                            ProgressView().tint(ThemeManager.shared.primaryPink)
                        } else if foundUser != nil {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                    }
                    .padding(4)
                }
                .onChange(of: searchText) { newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                    if trimmed.count >= 3 {
                        isSearching = true; errorMessage = nil; foundUser = nil
                        Task {
                            foundUser = await userService.searchUser(query: trimmed)
                            isSearching = false
                            if foundUser == nil && trimmed.count >= 3 {
                                errorMessage = "No se encontró ningún usuario con ese nombre o correo."
                            }
                        }
                    } else {
                        foundUser = nil; errorMessage = nil
                    }
                }

                // Found user card
                if let found = foundUser {
                    GlassCard {
                        VStack(spacing: 16) {
                            Circle().fill(ThemeManager.shared.primaryPink.opacity(0.15)).frame(width: 72, height: 72)
                                .overlay(Image(systemName: "person.fill").font(.system(size: 32)).foregroundColor(ThemeManager.shared.primaryPink))

                            Text(found["displayName"] as? String ?? "Usuario Encontrado")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.primary)

                            if let uname = found["username"] as? String {
                                Text("@\(uname)").font(.system(size: 12, weight: .medium))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                    .padding(.horizontal, 10).padding(.vertical, 3)
                                    .background(ThemeManager.shared.primaryPink.opacity(0.1)).cornerRadius(8)
                            }

                            GradientButton(title: "Vincular Pareja Ahora 💖", icon: "heart.fill", isLoading: isAdding) {
                                Task {
                                    isAdding = true; errorMessage = nil
                                    let res = await userService.addPartner(codeOrEmail: searchText, foundUserData: found)
                                    isAdding = false
                                    switch res {
                                    case .success:
                                        authService.savePartner(uid: found["uid"] as? String ?? "", name: found["displayName"] as? String ?? "Pareja")
                                        onComplete?()
                                    case .alreadyHasPartner:
                                        errorMessage = "Ya tienes una pareja vinculada."
                                    case .targetHasPartner:
                                        errorMessage = "Esta persona ya está vinculada con otra pareja."
                                    case .notFound:
                                        errorMessage = "No se pudo encontrar al usuario. Verifica el código o usuario."
                                    default:
                                        errorMessage = "Ocurrió un error al vincular. Intenta de nuevo."
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    authService.didSkipPartner()
                    onComplete?()
                } label: {
                    Text("Vincular más tarde").font(.system(size: 14)).foregroundColor(.primary.opacity(0.5))
                }
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 24)
        }
        .task {
            myPairCode = await userService.getOrGeneratePairCode()
        }
    }
}
