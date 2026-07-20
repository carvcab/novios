import SwiftUI

public struct AddPartnerView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared
    
    @State private var searchCode = ""
    @State private var myCode = ""
    @State private var foundUser: [String: Any]?
    @State private var errorMessage: String?
    @State private var isLinking = false
    @State private var copiedNotice = false
    @State private var pulseIcon = false
    
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            FloatingHeartsEffect()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    PulsingHeartView(size: 64)
                    
                    VStack(spacing: 6) {
                        Text("Vincular Pareja")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Conéctate con tu pareja usando su Código, Usuario o Correo")
                            .font(.system(size: 13))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    
                    // Card Mi Código de Vinculación con animación
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text("TU CÓDIGO DE VINCULACIÓN")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                    .tracking(1.2)
                            }
                            
                            HStack(spacing: 14) {
                                Text(myCode.isEmpty ? "CARGANDO..." : myCode)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                    .tracking(3)
                                
                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    UIPasteboard.general.string = myCode
                                    withAnimation(.spring()) { copiedNotice = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { copiedNotice = false }
                                    }
                                } label: {
                                    Image(systemName: copiedNotice ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                        .foregroundColor(copiedNotice ? .green : ThemeManager.shared.primaryPink)
                                        .font(.system(size: 22))
                                        .scaleEffect(copiedNotice ? 1.2 : 1.0)
                                }
                            }
                            
                            if copiedNotice {
                                Text("¡Código copiado al portapapeles! 📋")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("Pásale este código a tu pareja para que te agregue")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Campo de búsqueda de pareja
                    GlassCard {
                        VStack(spacing: 16) {
                            CustomTextField(
                                placeholder: "Código, Usuario o Correo de tu pareja",
                                text: $searchCode,
                                icon: "magnifyingglass"
                            )
                            .onChange(of: searchCode) { newValue in
                                Task {
                                    if newValue.trimmingCharacters(in: .whitespaces).count >= 3 {
                                        foundUser = await userService.searchUser(query: newValue)
                                    } else {
                                        foundUser = nil
                                    }
                                }
                            }
                            
                            if let found = foundUser {
                                VStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                                            .frame(width: 70, height: 70)
                                        
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                    }
                                    
                                    Text(found["displayName"] as? String ?? "Usuario Encontrado")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    if let uname = found["username"] as? String {
                                        Text("@\(uname)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(ThemeManager.shared.primaryPink.opacity(0.12))
                                            .cornerRadius(8)
                                    }
                                    
                                    GradientButton(title: "Vincular Pareja Ahora 💖", icon: "heart.fill", isLoading: isLinking) {
                                        Task {
                                            isLinking = true
                                            let res = await userService.addPartner(codeOrEmail: searchCode)
                                            isLinking = false
                                            if case .success = res {
                                                // Paired!
                                            } else {
                                                errorMessage = "No se pudo vincular la pareja. Intenta de nuevo."
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            if let err = errorMessage {
                                Text(err)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button {
                        userService.didSkipPartner()
                    } label: {
                        Text("Vincular más tarde")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.bottom, 28)
                }
            }
        }
        .task {
            myCode = await userService.getOrGeneratePairCode()
        }
    }
}
