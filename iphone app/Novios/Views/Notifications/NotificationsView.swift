import SwiftUI

public struct NotificationsView: View {
    @State private var mensajesOn = true
    @State private var recordatoriosOn = true
    @State private var aniversariosOn = true
    @State private var juegosOn = false
    @State private var ubicacionOn = true
    @State private var musicaOn = false
    @State private var quietHoursOn = false
    @State private var fromHour = Date()
    @State private var toHour = Date()

    private let notifications: [(String, String, String, Binding<Bool>)] = []

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard(cornerRadius: 28) {
                            VStack(spacing: 12) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(ThemeManager.shared.primaryPink)

                                Text("Notificaciones")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)

                                Text("Personaliza cómo y cuándo recibir notificaciones")
                                    .font(.system(size: 13))
                                    .foregroundColor(ThemeManager.shared.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        VStack(spacing: 0) {
                            ToggleItem(icon: "message.fill", title: "Mensajes", description: "Nuevos mensajes de tu pareja", isOn: $mensajesOn)
                            ToggleItem(icon: "bell.fill", title: "Recordatorios", description: "Recordatorios de eventos y tareas", isOn: $recordatoriosOn)
                            ToggleItem(icon: "heart.fill", title: "Aniversarios", description: "Fechas especiales y aniversarios", isOn: $aniversariosOn)
                            ToggleItem(icon: "gamecontroller.fill", title: "Juegos", description: "Invitaciones y resultados de juegos", isOn: $juegosOn)
                            ToggleItem(icon: "location.fill", title: "Ubicación", description: "Alertas de ubicación compartida", isOn: $ubicacionOn)
                            ToggleItem(icon: "music.note.fill", title: "Música", description: "Nuevas canciones y listas compartidas", isOn: $musicaOn)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Horario Silencioso")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.primary)

                                        Text("No recibir notificaciones durante este período")
                                            .font(.system(size: 12))
                                            .foregroundColor(ThemeManager.shared.textSecondary)
                                    }

                                    Spacer()

                                    Toggle("", isOn: $quietHoursOn)
                                        .tint(ThemeManager.shared.primaryPink)
                                }

                                if quietHoursOn {
                                    Divider()
                                        .background(ThemeManager.shared.textSecondary.opacity(0.3))

                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Desde")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(ThemeManager.shared.textSecondary)

                                            DatePicker("", selection: $fromHour, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .accentColor(ThemeManager.shared.primaryPink)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Hasta")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(ThemeManager.shared.textSecondary)

                                            DatePicker("", selection: $toHour, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .accentColor(ThemeManager.shared.primaryPink)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Notificaciones")
        }
    }
}

private struct ToggleItem: View {
    public let icon: String
    public let title: String
    public let description: String
    @Binding public var isOn: Bool

    public var body: some View {
        GlassCard(cornerRadius: 16, opacity: 0.1) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(ThemeManager.shared.primaryPink)
                    .frame(width: 32, height: 32)
                    .background(ThemeManager.shared.primaryPink.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .tint(ThemeManager.shared.primaryPink)
                    .labelsHidden()
            }
        }
    }
}
