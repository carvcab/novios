import SwiftUI

public struct LoveLettersView: View {
    let letters = [
        ("Abrir cuando estés triste 🌧️", "Recuerda que no estás solo/a. Te amo incondicionalmente y siempre estaré a tu lado para sostener tu mano."),
        ("Abrir cuando me extrañes 💔", "Cierra los ojos e imagina un abrazo fuerte. Cada segundo sin ti me hace valorar más nuestro amor."),
        ("Abrir en tu cumpleaños 🎂", "¡Feliz cumpleaños al amor de mi vida! Gracias por llenar mis días de felicidad."),
        ("Abrir cuando no puedas dormir 🌙", "Piensa en todos nuestros momentos mágicos. Descansa bien mi vida.")
    ]
    
    @State private var openLetterTitle: String?
    @State private var openLetterContent: String?
    
    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(letters, id: \.0) { item in
                        Button {
                            openLetterTitle = item.0
                            openLetterContent = item.1
                        } label: {
                            GlassCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "envelope.badge.shield.halffilled.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    
                                    Text(item.0)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 120)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .sheet(item: Binding(get: {
            openLetterTitle != nil ? IdentifiableString(value: openLetterTitle!) : nil
        }, set: { _ in openLetterTitle = nil })) { item in
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                    
                    Text(item.value)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(openLetterContent ?? "")
                        .font(.system(size: 16))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding()
            }
        }
        .navigationTitle("Cartas de Amor")
    }
}

public struct IdentifiableString: Identifiable {
    public var id: String { value }
    public let value: String
}
