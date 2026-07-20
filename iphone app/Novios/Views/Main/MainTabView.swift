import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab = 0
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "heart.fill")
                }
                .tag(0)
            
            MessagesView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)
            
            LiveStatusView()
                .tabItem {
                    Label("En Vivo", systemImage: "tv.fill")
                }
                .tag(2)
            
            MemoriesView()
                .tabItem {
                    Label("Recuerdos", systemImage: "photo.stack.fill")
                }
                .tag(3)
            
            MoreView()
                .tabItem {
                    Label("Más", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .tint(ThemeManager.shared.primaryPink)
    }
}

public struct MoreView: View {
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                ScrollView {
                    VStack(spacing: 16) {
                        NavigationLink(destination: CoupleGamesView()) {
                            MoreOptionCard(title: "Juegos de Pareja Online 🎲", subtitle: "Verdad o Reto en vivo, Ruleta e Historias", icon: "gamecontroller.fill", color: .purple)
                        }
                        
                        NavigationLink(destination: AICoupleAssistantView()) {
                            MoreOptionCard(title: "Asistente de IA Gemini 🤖", subtitle: "Consejos, poemas e ideas para citas", icon: "sparkles", color: .pink)
                        }
                        
                        NavigationLink(destination: LoveLettersView()) {
                            MoreOptionCard(title: "Cartas de Amor 💌", subtitle: "Sobres especiales 'Abrir cuando...'", icon: "envelope.fill", color: .red)
                        }
                        
                        NavigationLink(destination: WishlistView()) {
                            MoreOptionCard(title: "Lista de Deseos ⭐", subtitle: "Metas y sueños para cumplir juntos", icon: "star.fill", color: .orange)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            MoreOptionCard(title: "Ajustes y Seguridad ⚙️", subtitle: "Bloqueo PIN/FaceID, Notificaciones y Perfil", icon: "gearshape.fill", color: .gray)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Más Opciones")
        }
    }
}
