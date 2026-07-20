import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userService = UserService.shared

    @State private var timeTogether = ""
    @State private var dailyQuote = ""
    @State private var partnerOnline = false
    @State private var partnerScreen = ""
    @State private var heartParticles: [HeartParticle] = []
    @State private var particleCounter = 0

    private let quotes = [
        "El mejor lugar del mundo eres tú.",
        "Te amo no solo por lo que eres, sino por lo que soy cuando estoy contigo.",
        "Eres mi momento favorito del día.",
        "En un beso, sabrás todo lo que he callado.",
        "Si sé lo que es el amor, es por ti.",
        "Eres la casualidad más hermosa de mi vida.",
        "Juntos es mi lugar favorito para estar.",
        "Te elegiría a ti cien veces, en cien mundos.",
        "Amar no es mirarse el uno al otro; es mirar juntos en la misma dirección.",
        "Eres la canción que hace latir mi corazón.",
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                    .ignoresSafeArea()
                FloatingHeartsEffect()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // EverUs branding
                        Text("EverUs")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ThemeManager.shared.primaryPink)
                            .tracking(3)
                            .padding(.top, 16)

                        // Interactive Heart
                        Button(action: tapHeart) {
                            ZStack {
                                ForEach(heartParticles) { p in
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: p.size))
                                        .foregroundColor(ThemeManager.shared.primaryPink.opacity(p.opacity))
                                        .offset(x: p.dx, y: p.dy)
                                }
                                ZStack {
                                    Circle()
                                        .fill(ThemeManager.shared.primaryPink.opacity(0.15))
                                        .frame(width: 100, height: 100)
                                    Circle()
                                        .fill(ThemeManager.shared.primaryPink.opacity(0.03))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 42))
                                        .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                                }
                            }
                            .frame(width: 100, height: 100)
                        }

                        // Couple name
                        Text("\(authService.currentUser?.displayName ?? "Tu")  &  \(userService.partnerUser?.displayName ?? "Pareja")")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(timeTogether)
                            .font(.system(size: 26, weight: .light))
                            .foregroundColor(ThemeManager.shared.primaryPink)

                        // Status cards row
                        HStack(spacing: 12) {
                            NavigationLink(destination: NotificationsView()) {
                                GlassCard {
                                    VStack(spacing: 8) {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(ThemeManager.shared.primaryPink)
                                            .padding(10)
                                            .background(ThemeManager.shared.primaryPink.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text("Noti")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("Actividad")
                                            .font(.system(size: 10))
                                            .foregroundColor(.primary.opacity(0.5))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                }
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: LiveStatusView()) {
                                GlassCard {
                                    VStack(spacing: 8) {
                                        Image(systemName: partnerOnline ? "heart.fill" : "heart")
                                            .font(.system(size: 22))
                                            .foregroundColor(partnerOnline ? .green : .white.opacity(0.4))
                                            .padding(10)
                                            .background(partnerOnline ? Color.green.opacity(0.12) : Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text("En Vivo")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(partnerOnline ? (partnerScreen.isEmpty ? "En línea" : partnerScreen) : "Offline")
                                            .font(.system(size: 10))
                                            .foregroundColor(partnerOnline ? .green : .white.opacity(0.4))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)

                        // Quote card
                        GlassCard {
                            HStack(spacing: 10) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 18))
                                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.3))
                                Text("\"\(dailyQuote)\"")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.primary.opacity(0.9))
                                    .italic()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 18)
                        }
                        .padding(.horizontal, 20)

                        // Cover photo placeholder
                        GlassCard {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                                Text("Toca para poner tu foto aquí")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary.opacity(0.45))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .background(
                                LinearGradient(colors: [ThemeManager.shared.primaryPink.opacity(0.15), ThemeManager.shared.primaryPurple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                        .padding(.horizontal, 20)

                        // Distance + Countdown strip
                        HStack(spacing: 10) {
                            NavigationLink(destination: LocationView()) {
                                GlassCard {
                                    HStack(spacing: 10) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(red: 0.49, green: 0.51, blue: 1.0))
                                            .padding(8)
                                            .background(Color(red: 0.49, green: 0.51, blue: 1.0).opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Sin datos")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.primary)
                                            Text("Distancia")
                                                .font(.system(size: 10))
                                                .foregroundColor(.primary.opacity(0.5))
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 12)
                                }
                            }
                            .buttonStyle(.plain)

                            GlassCard {
                                HStack(spacing: 10) {
                                    Image(systemName: "hourglass.bottomhalf.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(red: 0.94, green: 0.33, blue: 0.31))
                                        .padding(8)
                                        .background(Color(red: 0.94, green: 0.33, blue: 0.31).opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Configura")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text("Tu fecha")
                                            .font(.system(size: 10))
                                            .foregroundColor(.primary.opacity(0.5))
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Feature Grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            FeatureGridItem(icon: "rectangle.on.rectangle", label: "Pantalla", color: Color(red: 0, green: 0.75, blue: 0.65), destination: AnyView(ScreenViewView()))
                            FeatureGridItem(icon: "envelope.open", label: "Cartas", color: Color(red: 1.0, green: 0.5, blue: 0.5), destination: AnyView(LoveLettersView()))
                            FeatureGridItem(icon: "note.text", label: "Notas", color: Color(red: 0.91, green: 0.27, blue: 0.49), destination: AnyView(NotesView()))
                            FeatureGridItem(icon: "brain.head.profile", label: "Amor IA", color: Color(red: 0.31, green: 0.76, blue: 0.97), destination: AnyView(AICoupleAssistantView()))
                            FeatureGridItem(icon: "photo.on.rectangle.angled", label: "Recuerdos", color: Color(red: 0.49, green: 0.51, blue: 1.0), destination: AnyView(MemoriesView()))
                            FeatureGridItem(icon: "gamecontroller", label: "Juegos", color: Color(red: 1.0, green: 0.72, blue: 0.3), destination: AnyView(CoupleGamesView()))
                            FeatureGridItem(icon: "wand.and.stars", label: "Deseos", color: Color(red: 0.67, green: 0.28, blue: 0.74), destination: AnyView(WishlistView()))
                            FeatureGridItem(icon: "moon.stars", label: "Sueños", color: Color(red: 0.36, green: 0.42, blue: 0.75), destination: AnyView(DreamsView()))
                            FeatureGridItem(icon: "list.clipboard", label: "Planner", color: Color(red: 0.4, green: 0.73, blue: 0.42), destination: AnyView(PlannerView()))
                            FeatureGridItem(icon: "music.note", label: "Música", color: Color(red: 0.15, green: 0.65, blue: 0.6), destination: AnyView(MusicView()))
                            FeatureGridItem(icon: "calendar", label: "Fechas", color: Color(red: 0.94, green: 0.33, blue: 0.31), destination: AnyView(AnniversaryView()))
                            FeatureGridItem(icon: "square.grid.2x2", label: "Más", color: Color(red: 0.47, green: 0.56, blue: 0.61), destination: AnyView(MoreListView()))
                        }
                        .padding(.horizontal, 20)

                        // Mood + Weather
                        HStack(spacing: 10) {
                            GlassCard {
                                VStack(spacing: 6) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Feliz")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("Hoy")
                                        .font(.system(size: 11))
                                        .foregroundColor(.primary.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 12)
                            }
                            GlassCard {
                                VStack(spacing: 6) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(ThemeManager.shared.primaryPink)
                                    Text("Soleado")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("Relación")
                                        .font(.system(size: 11))
                                        .foregroundColor(.primary.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.horizontal, 20)

                        Color.clear.frame(height: 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                dailyQuote = quotes[Calendar.current.component(.day, from: Date()) % quotes.count]
                updateTimeTogether()
                Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                    updateTimeTogether()
                }
            }
        }
    }

    private func tapHeart() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation {
            for _ in 0..<6 {
                let p = HeartParticle(
                    id: particleCounter,
                    dx: CGFloat.random(in: -60...60),
                    dy: CGFloat.random(in: -80...(-40)),
                    size: CGFloat.random(in: 6...16),
                    opacity: Double.random(in: 0.3...0.7)
                )
                particleCounter += 1
                heartParticles.append(p)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            heartParticles.removeAll()
        }
    }

    private func updateTimeTogether() {
        guard let ann = authService.currentUser?.anniversaryDate else {
            timeTogether = "0 días"
            return
        }
        let days = Calendar.current.dateComponents([.day], from: ann, to: Date()).day ?? 0
        let years = days / 365
        let months = (days % 365) / 30
        let remDays = days % 30
        var parts: [String] = []
        if years > 0 { parts.append("\(years) a") }
        if months > 0 { parts.append("\(months) m") }
        if remDays > 0 { parts.append("\(remDays)d") }
        timeTogether = parts.isEmpty ? "0 días" : parts.joined(separator: " ")
    }
}

struct HeartParticle: Identifiable {
    let id: Int
    let dx: CGFloat
    let dy: CGFloat
    let size: CGFloat
    let opacity: Double
}

public struct FeatureGridItem: View {
    public let icon: String
    public let label: String
    public let color: Color
    public let destination: AnyView

    public var body: some View {
        NavigationLink(destination: destination) {
            GlassCard {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                        .padding(12)
                        .background(color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }
}
