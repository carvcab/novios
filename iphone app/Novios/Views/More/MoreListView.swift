import SwiftUI

public struct MoreListView: View {
    private let sections: [(String, [(String, String, String, Color, AnyView)])] = [
        ("JUEGOS", [
            ("🎲 Juegos de Pareja", "Verdad o Reto, Ruleta, Preguntas", "gamecontroller.fill", .purple, AnyView(CoupleGamesView())),
            ("🎯 Historial de Juegos", "Resultados y puntuaciones", "clock.arrow.circlepath", .orange, AnyView(GameHistoryView())),
        ]),
        ("EXPRESIÓN", [
            ("💌 Cartas de Amor", "Sobres especiales 'Abrir cuando...'", "envelope.fill", .red, AnyView(LoveLettersView())),
            ("💬 Cifrado", "Mensajes cifrados de extremo a extremo", "lock.shield.fill", .blue, AnyView(EncryptionView())),
        ]),
        ("RECUERDOS", [
            ("📸 Tal día como hoy", "Recuerdos de esta fecha", "clock.fill", .cyan, AnyView(OnThisDayView())),
            ("📖 Nuestro Libro", "Libro de nuestra relación", "book.closed.fill", .brown, AnyView(RelationshipBookView())),
        ]),
        ("SOCIAL", [
            ("🎁 Regalos Virtuales", "Envía regalos a tu pareja", "gift.fill", .pink, AnyView(GiftsView())),
            ("📱 Compartir Pantalla", "Comparte tu pantalla en vivo", "rectangle.on.rectangle", Color(red: 0, green: 0.75, blue: 0.65), AnyView(ScreenViewView())),
            ("🏆 Compatibilidad", "Test de compatibilidad de pareja", "heart.text.square.fill", .mint, AnyView(CompatibilityView())),
        ]),
        ("EXTRAS", [
            ("🌟 Constelación", "Nuestra constelación de amor", "sparkles", Color(red: 0.67, green: 0.28, blue: 0.74), AnyView(ConstellationView())),
            ("🎤 Buzón de Voz", "Mensajes de voz para el futuro", "mic.fill", Color(red: 0.15, green: 0.65, blue: 0.6), AnyView(VoiceMailboxView())),
            ("🎯 GIFs Favoritos", "Tus GIFs de pareja favoritos", "smiley.fill", .yellow, AnyView(FavoriteGifsView())),
        ]),
        ("CONFIGURACIÓN", [
            ("🔐 Bloqueo de App", "PIN y Face ID", "lock.fill", .gray, AnyView(LockScreenView())),
            ("☁️ Google Setup", "Sincroniza con Google", "g.circle.fill", Color(red: 0.25, green: 0.49, blue: 0.96), AnyView(GoogleSetupView())),
            ("🔔 Notificaciones", "Configura tus notificaciones", "bell.badge.fill", .red, AnyView(NotificationsView())),
            ("🤔 ¿Quién es quién?", "Adivina quién hizo qué", "questionmark.circle.fill", .teal, AnyView(WhoView())),
            ("🔑 Permisos", "Administrar permisos de la app", "hand.raised.fill", Color(red: 0.94, green: 0.33, blue: 0.31), AnyView(PermissionsView())),
            ("⚙️ Ajustes", "Ajustes generales de la app", "gearshape.fill", .gray, AnyView(SettingsView())),
        ])
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(sections, id: \.0) { section in
                            Text(section.0)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                                .tracking(1.5)
                                .padding(.horizontal, 20)
                                .padding(.top, 4)

                            ForEach(section.1, id: \.0) { item in
                                NavigationLink(destination: item.4) {
                                    GlassCard {
                                        HStack(spacing: 14) {
                                            Text(item.2)
                                                .font(.system(size: 20))
                                                .foregroundColor(item.3)
                                                .frame(width: 36, height: 36)
                                                .background(item.3.opacity(0.12))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.0)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                Text(item.1)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(ThemeManager.shared.textSecondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.primary.opacity(0.3))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                            }
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Más")
        }
    }
}
