import SwiftUI
import PhotosUI
import UIKit

public struct ProfileView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var couple = CoupleService.shared

    @State private var showSettings = false
    @State private var showPhotoPicker = false
    @State private var profileImage: UIImage?

    @State private var activeSheet: ActiveSheet?

    enum ActiveSheet: Identifiable {
        case memories
        case dreams
        case settings

        var id: Int {
            switch self {
            case .memories: return 1
            case .dreams: return 2
            case .settings: return 3
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Couple Header
                    VStack(spacing: 8) {
                        Text(couple.coupleName)
                            .appFont(size: 26, weight: .bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("Diego 💞 Yosmari (Sincronizado)")
                                .appFont(size: 13, weight: .medium)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)

                    // Photos Avatar Stack
                    HStack(spacing: -12) {
                        profileCircle(for: "Diego", color: theme.primary)
                        profileCircle(for: "Yosmari", color: theme.secondary)
                    }
                    .padding(.bottom, 8)

                    // Exclusive Couple Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        navCard(icon: "heart.fill", title: "Nuestra Historia", color: .red) {
                            activeSheet = .memories
                        }
                        navCard(icon: "photo.stack.fill", title: "Nuestros Recuerdos", color: theme.pastelPeach) {
                            activeSheet = .memories
                        }
                        navCard(icon: "star.fill", title: "Nuestros Sueños", color: .purple) {
                            activeSheet = .dreams
                        }
                        navCard(icon: "calendar", title: "Nuestros Eventos", color: theme.pastelMint) {
                            activeSheet = .dreams
                        }
                        navCard(icon: "envelope.fill", title: "Nuestras Cartas", color: theme.primary) {
                            activeSheet = .memories
                        }
                        navCard(icon: "book.fill", title: "Nuestro Diario", color: theme.pastelLavender) {
                            activeSheet = .memories
                        }
                    }
                    .padding(.horizontal, 4)

                    // Relationship Stats Box
                    VStack(spacing: 12) {
                        Text("Nuestra Relación Privada")
                            .appFont(size: 16, weight: .bold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            statItem(number: "\(couple.cartas.count)", label: "Cartas")
                            statItem(number: "\(couple.recuerdos.count)", label: "Recuerdos")
                            statItem(number: "\(couple.logros.count)", label: "Metas")
                            statItem(number: "\(couple.eventos.count)", label: "Eventos")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.primary.opacity(0.15)))

                    // Settings Button
                    Button {
                        activeSheet = .settings
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Configuración de Pareja")
                        }
                        .appFont(size: 15, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.primaryGradient)
                        .cornerRadius(16)
                        .shadow(color: theme.primary.opacity(0.25), radius: 8, y: 3)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .memories:
                MemoriesAndLettersView()
            case .dreams:
                DreamsAndGoalsView()
            case .settings:
                SettingsView()
            }
        }

    }

    private func profileCircle(for name: String, color: Color) -> some View {
        Button { showPhotoPicker = true } label: {
            ZStack {
                if let img = profileImage, name == (couple.currentUid == CoupleService.diegoUid ? "Diego" : "Yosmari") {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 80, height: 80).clipShape(Circle())
                } else {
                    Circle().fill(color.opacity(0.2)).frame(width: 80, height: 80)
                        .overlay(Text(name.prefix(1)).appFont(size: 32, weight: .bold).foregroundColor(color))
                }
                Circle().stroke(.white, lineWidth: 3).frame(width: 80, height: 80)
            }
        }
    }

    private func statItem(number: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(number)
                .appFont(size: 18, weight: .bold)
                .foregroundColor(theme.primary)
            Text(label)
                .appFont(size: 11)
                .foregroundColor(theme.textSecondary)
        }
    }

    private func navCard(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).appFont(size: 24).foregroundColor(color)
                Text(title).appFont(size: 12, weight: .semibold).foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .background(color.opacity(0.05))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.15)))
        }
    }
}
