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

    private let debounceQueue = DispatchQueue(label: "search.debounce")

    public var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.035, blue: 0.043).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 52))
                        .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.54))

                    Text("Vincular Pareja")
                        .font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                    Text("Busca a tu pareja por su nombre de usuario o correo")
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13)).foregroundColor(.red)
                            .padding(12).frame(maxWidth: .infinity)
                            .background(.red.opacity(0.15)).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.red.opacity(0.3)))
                    }

                    // Search field
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("", text: $searchText, prompt: Text("Nombre de usuario o correo de tu pareja").foregroundColor(.white.opacity(0.4)))
                            .foregroundColor(.white).autocapitalization(.none).disableAutocorrection(true)
                        if isSearching {
                            ProgressView().tint(Color(red: 1.0, green: 0.36, blue: 0.54))
                        } else if foundUser != nil {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(Color(red: 0.11, green: 0.11, blue: 0.12))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                        foundUser != nil ? Color(red: 1.0, green: 0.36, blue: 0.54).opacity(0.6) : .white.opacity(0.1)
                    ))
                    .onChange(of: searchText) { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                        if trimmed.count >= 3 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if self.searchText == newValue {
                                    performSearch()
                                }
                            }
                        } else {
                            foundUser = nil; errorMessage = nil
                        }
                    }

                    // Found user card
                    if let found = foundUser {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.36, blue: 0.54).opacity(0.15))
                                .frame(width: 72, height: 72)
                                .overlay(Image(systemName: "person.fill").font(.system(size: 32))
                                    .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.54)))

                            Text(found["displayName"] as? String ?? "Usuario Encontrado")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)

                            if let uname = found["username"] as? String, !uname.isEmpty {
                                Text("@\(uname)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 1.0, green: 0.36, blue: 0.54))
                                    .padding(.horizontal, 10).padding(.vertical, 3)
                                    .background(Color(red: 1.0, green: 0.36, blue: 0.54).opacity(0.1)).cornerRadius(8)
                            }

                            Button {
                                Task {
                                    isAdding = true; errorMessage = nil
                                    let result = await userService.addPartner(query: searchText)
                                    isAdding = false
                                    switch result {
                                    case .success:
                                        authService.savePartner(uid: found["uid"] as? String ?? "", name: found["displayName"] as? String ?? "Pareja")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            onComplete?()
                                        }
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
                                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                                        .background(Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(14)
                                } else {
                                    HStack(spacing: 8) {
                                        Image(systemName: "heart.fill").font(.system(size: 16))
                                        Text("Vincular Pareja Ahora")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                                    .background(Color(red: 1.0, green: 0.36, blue: 0.54)).cornerRadius(14)
                                }
                            }
                            .disabled(isAdding)
                        }
                        .padding(20)
                        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 1.0, green: 0.36, blue: 0.54).opacity(0.4)))
                    }

                    Spacer()

                    Button {
                        authService.didSkipPartner()
                        onComplete?()
                    } label: {
                        Text("Vincular más tarde")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.5))
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
                if let user = user {
                    self.foundUser = user
                } else {
                    self.errorMessage = "No se encontró ningún usuario con ese nombre o correo."
                }
            }
        }
    }
}
