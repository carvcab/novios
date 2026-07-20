import SwiftUI

public struct CoupleGamesView: View {
    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        NavigationLink(destination: TruthOrDareView()) {
                            GameCategoryCard(title: "Verdad o Reto 🌶️", description: "Preguntas picantes y retos divertidos para jugar en pareja", color: .purple)
                        }
                        
                        NavigationLink(destination: DateWheelView()) {
                            GameCategoryCard(title: "Ruleta de Citas 🎡", description: "Gira la ruleta y dejen que el azar decida qué harán hoy", color: .pink)
                        }
                        
                        NavigationLink(destination: HowWellDoYouKnowMeView()) {
                            GameCategoryCard(title: "¿Qué tanto me conoces? 🧠", description: "Pongan a prueba sus conocimientos sobre el otro", color: .blue)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Juegos de Pareja")
        }
    }
}

public struct GameCategoryCard: View {
    public let title: String
    public let description: String
    public let color: Color
    
    public var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary.opacity(0.3))
            }
        }
    }
}

public struct DateWheelView: View {
    let options = ["Cine en Casa 🍿", "Masaje con Aceite 💆‍♂️", "Cocinar Juntos 🍝", "Paseo Nocturno 🌙", "Noche de Juegos 🎮"]
    @State private var selectedOption = "¡Gira para elegir!"
    @State private var isSpinning = false
    
    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text(selectedOption)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                ZStack {
                    Circle()
                        .fill(ThemeManager.shared.primaryPink.opacity(0.15))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))
                }
                
                GradientButton(title: "Girar Ruleta", icon: "arrow.triangle.2.circlepath") {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        isSpinning = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isSpinning = false
                        selectedOption = options.randomElement()!
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .navigationTitle("Ruleta de Citas")
    }
}

public struct HowWellDoYouKnowMeView: View {
    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                GlassCard {
                    VStack(spacing: 12) {
                        Text("Pregunta #1")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                        
                        Text("¿Cuál es la comida favorita de tu pareja?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("¿Qué tanto me conoces?")
    }
}
