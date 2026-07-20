import SwiftUI

public struct MoreListView: View {
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView {
                    VStack(spacing: 16) {
                        MoreOptionCard(title: "Juegos de Pareja Online 🎲", subtitle: "Verdad o Reto en vivo, Ruleta e Historias", icon: "gamecontroller.fill", color: .purple)
                            .overlay(NavigationLink(destination: CoupleGamesView()) { Color.clear })
                        MoreOptionCard(title: "Asistente de IA Gemini 🤖", subtitle: "Consejos, poemas e ideas para citas", icon: "sparkles", color: .pink)
                            .overlay(NavigationLink(destination: AICoupleAssistantView()) { Color.clear })
                        MoreOptionCard(title: "Cartas de Amor 💌", subtitle: "Sobres especiales 'Abrir cuando...'", icon: "envelope.fill", color: .red)
                            .overlay(NavigationLink(destination: LoveLettersView()) { Color.clear })
                        MoreOptionCard(title: "Lista de Deseos ⭐", subtitle: "Metas y sueños para cumplir juntos", icon: "star.fill", color: .orange)
                            .overlay(NavigationLink(destination: WishlistView()) { Color.clear })
                        MoreOptionCard(title: "Ajustes y Seguridad ⚙️", subtitle: "Bloqueo PIN/FaceID, Notificaciones y Perfil", icon: "gearshape.fill", color: .gray)
                            .overlay(NavigationLink(destination: SettingsView()) { Color.clear })
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Más")
        }
    }
}
