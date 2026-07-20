import SwiftUI

public struct TruthOrDareView: View {
    @StateObject private var gameService = OnlineGameService.shared
    @EnvironmentObject var authService: AuthService
    
    let truths = [
        "¿Qué fue lo primero que pensaste cuando me viste por primera vez?",
        "¿Cuál es tu recuerdo favorito conmigo?",
        "¿Qué canción te recuerda a mí?",
        "¿Qué detalle mío te enamoró por completo?"
    ]
    let dares = [
        "Dale un beso apasionado de 10 segundos a tu pareja.",
        "Dile 3 cosas que amas de ella mirándola a los ojos.",
        "Baila tu canción favorita con tu pareja en este momento.",
        "Escríbele un mensaje de amor secreto en su teléfono."
    ]
    
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            FloatingHeartsEffect()
            
            VStack(spacing: 24) {
                // Indicador Turno en Vivo
                HStack(spacing: 8) {
                    Circle()
                        .fill(gameService.isMyTurn ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)
                    
                    Text(gameService.isMyTurn ? "¡ES TU TURNO DE JUGAR!" : "TURNO DE TU PAREJA ⏳")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1.0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                GlassCard {
                    VStack(spacing: 16) {
                        Text(gameService.activeSession?.isTruth == true ? "VERDAD 💭" : "RETO 🔥")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(gameService.activeSession?.isTruth == true ? .blue : ThemeManager.shared.primaryPink)
                        
                        Text(gameService.activeSession?.currentQuestion ?? "Presiona 'Verdad' o 'Reto' para enviar tu jugada")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 24)
                
                HStack(spacing: 20) {
                    Button {
                        let text = truths.randomElement()!
                        gameService.nextTurn(questionText: text, isTruth: true)
                        ChatNotificationService.shared.sendLocalNotification(title: "🎲 Verdad o Reto", body: "Tu pareja te ha enviado una pregunta de VERDAD.")
                    } label: {
                        Text("Verdad 💭")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(16)
                    }
                    
                    Button {
                        let text = dares.randomElement()!
                        gameService.nextTurn(questionText: text, isTruth: false)
                        ChatNotificationService.shared.sendLocalNotification(title: "🔥 Verdad o Reto", body: "Tu pareja te ha enviado un RETO.")
                    } label: {
                        Text("Reto 🔥")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(ThemeManager.shared.primaryPink.opacity(0.8))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Verdad o Reto en Vivo")
    }
}
