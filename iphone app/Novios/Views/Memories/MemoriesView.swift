import SwiftUI

public struct MemoriesView: View {
    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(samplePhotos, id: \.0) { item in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(ThemeManager.shared.primaryPink.opacity(0.15))
                                            .frame(height: 120)
                                        
                                        Image(systemName: item.1)
                                            .font(.system(size: 40))
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                    }
                                    
                                    Text(item.0)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text(item.2)
                                        .font(.system(size: 12))
                                        .foregroundColor(ThemeManager.shared.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Recuerdos")
        }
    }
}

private let samplePhotos: [(String, String, String)] = [
    ("Cita en la playa", "photo.fill", "14 Feb 2026"),
    ("Nuestro Aniversario", "heart.fill", "10 Dic 2025"),
    ("Viaje juntos", "airplane", "05 Ago 2025"),
    ("Primera foto", "camera.fill", "01 Ene 2025")
]
