import SwiftUI

public struct MemoriesView: View {
    @State private var selectedTab = 0
    
    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()
                
                VStack {
                    Picker("", selection: $selectedTab) {
                        Text("Galería").tag(0)
                        Text("Diario").tag(1)
                        Text("Cápsulas").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    if selectedTab == 0 {
                        PhotoGalleryView()
                    } else if selectedTab == 1 {
                        JournalView()
                    } else {
                        CapsuleView()
                    }
                }
            }
            .navigationTitle("Recuerdos & Diario")
        }
    }
}

public struct PhotoGalleryView: View {
    let samplePhotos = [
        ("Cita en la playa", "photo.fill", "14 Feb 2026"),
        ("Nuestro Aniversario", "heart.fill", "10 Dic 2025"),
        ("Viaje juntos", "airplane", "05 Ago 2025")
    ]
    
    public var body: some View {
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
}
