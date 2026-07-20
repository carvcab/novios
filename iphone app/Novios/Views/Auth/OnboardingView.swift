import SwiftUI

public struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showLogin = false
    
    let pages = [
        ("Distancia en Vivo", "location.circle.fill", "Descubre qué tan cerca están en todo momento con nuestro mapa y geolocalizador en vivo."),
        ("Chat y Notas de Voz", "bubble.left.and.bubble.right.fill", "Envía besos virtuales, abrazos, notas de voz y momentos románticos instantáneos."),
        ("Recuerdos e IA", "sparkles", "Álbum de fotos compartido, cápsulas del tiempo y un asistente de IA para citas inolvidables.")
    ]
    
    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Image(systemName: pages[index].1)
                                .font(.system(size: 80))
                                .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                                .shadow(color: ThemeManager.shared.primaryPink.opacity(0.5), radius: 15)
                            
                            Text(pages[index].0)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(pages[index].2)
                                .font(.system(size: 15))
                                .foregroundColor(ThemeManager.shared.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        GradientButton(title: "Crear Cuenta", icon: "arrow.right.circle.fill") {
                            showLogin = true
                        }
                    } else {
                        GradientButton(title: "Siguiente", icon: "arrow.right") {
                            withAnimation { currentPage += 1 }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationDestination(isPresented: $showLogin) {
            LoginView()
        }
    }
}
