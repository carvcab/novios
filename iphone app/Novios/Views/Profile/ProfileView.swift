import SwiftUI

public struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile avatars
                        ProfileHeaderView(
                            name: authService.currentUser?.displayName ?? "Tu",
                            partnerName: userService.partnerUser?.displayName ?? ""
                        )

                        // Streak card
                        GlassCard {
                            HStack {
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.orange)
                                Text("Racha: \(Int.random(in: 1...30)) días seguidos 🔥")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 16)

                        // Important dates
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text("Fechas Importantes")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            GlassCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white.opacity(0.15))
                                    Text("No hay fechas importantes aún")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                    Button("Agregar fecha") {
                                        // TODO: Add date dialog
                                    }
                                    .font(.system(size: 13))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Quick access grid
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text("Accesos rápidos")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            VStack(spacing: 8) {
                                QuickAccessRowView(icon: "rectangle.on.rectangle", title: "Pantalla Compartida", destination: ScreenViewView())
                                QuickAccessRowView(icon: "note.text", title: "Notas", destination: NotesView())
                                QuickAccessRowView(icon: "wand.and.stars", title: "Lista de Deseos", destination: WishlistView())
                                QuickAccessRowView(icon: "moon.stars", title: "Sueños", destination: DreamsView())
                                QuickAccessRowView(icon: "list.clipboard", title: "Planificador", destination: PlannerView())
                                QuickAccessRowView(icon: "music.note", title: "Música", destination: MusicView())
                                QuickAccessRowView(icon: "envelope.open", title: "Cartas", destination: LoveLettersView())
                                QuickAccessRowView(icon: "gamecontroller", title: "Juegos", destination: CoupleGamesView())
                                QuickAccessRowView(icon: "location", title: "Mapa", destination: LocationView())
                            }
                        }
                        .padding(.horizontal, 16)

                        Color.clear.frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

public struct ProfileHeaderView: View {
    public let name: String
    public let partnerName: String

    public var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ThemeManager.shared.primaryPurple.opacity(0.2))
                    .frame(width: 76, height: 76)
                    .overlay(
                        Text(partnerName.prefix(1).uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(ThemeManager.shared.primaryPurple)
                    )
                    .position(x: 120, y: 35)

                Circle()
                    .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                    .frame(width: 86, height: 86)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .overlay(
                        Text(name.prefix(1).uppercased())
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                    )
                    .shadow(color: ThemeManager.shared.primaryPink.opacity(0.25), radius: 15)
                    .position(x: 70, y: 50)

                Text("💞")
                    .font(.system(size: 16))
                    .position(x: 95, y: 70)
            }
            .frame(height: 110)

            Text(name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            if !partnerName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                    Text(partnerName)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

public struct QuickAccessRowView<Destination: View>: View {
    public let icon: String
    public let title: String
    public let destination: Destination

    public var body: some View {
        NavigationLink(destination: destination) {
            GlassCard {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .padding(10)
                        .background(ThemeManager.shared.primaryPink.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
    }
}
