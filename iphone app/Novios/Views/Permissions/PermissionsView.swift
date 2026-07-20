import SwiftUI

public struct PermissionsView: View {
    @State private var notificationsGranted = false
    @State private var locationGranted = false
    @State private var microphoneGranted = false
    @State private var photosGranted = false

    private let permissions: [(icon: String, title: String, description: String, binding: Binding<Bool>)] = [
        ("bell.badge.fill", "Notificaciones", "Recibe alertas y mensajes de tu pareja al instante", .init(get: { false }, set: { _, _ in })),
        ("location.fill", "Ubicación", "Comparte tu ubicación en tiempo real con tu ser querido", .init(get: { false }, set: { _, _ in })),
        ("mic.fill", "Micrófono", "Envía notas de voz y mensajes de audio románticos", .init(get: { false }, set: { _, _ in })),
        ("photo.on.rectangle.fill", "Fotos", "Accede a tu álbum compartido de momentos especiales", .init(get: { false }, set: { _, _ in }))
    ]

    private var allGranted: Bool {
        notificationsGranted && locationGranted && microphoneGranted && photosGranted
    }

    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                            .shadow(color: ThemeManager.shared.primaryPink.opacity(0.5), radius: 15)

                        Text("Permisos")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Concede los permisos para disfrutar de Novios al máximo")
                            .font(.system(size: 15))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        PermissionCard(
                            icon: "bell.badge.fill",
                            title: "Notificaciones",
                            description: "Recibe alertas y mensajes de tu pareja al instante",
                            isGranted: $notificationsGranted
                        )
                        PermissionCard(
                            icon: "location.fill",
                            title: "Ubicación",
                            description: "Comparte tu ubicación en tiempo real con tu ser querido",
                            isGranted: $locationGranted
                        )
                        PermissionCard(
                            icon: "mic.fill",
                            title: "Micrófono",
                            description: "Envía notas de voz y mensajes de audio románticos",
                            isGranted: $microphoneGranted
                        )
                        PermissionCard(
                            icon: "photo.on.rectangle.fill",
                            title: "Fotos",
                            description: "Accede a tu álbum compartido de momentos especiales",
                            isGranted: $photosGranted
                        )
                    }
                    .padding(.horizontal, 20)

                    if allGranted {
                        GradientButton(title: "Continuar", icon: "arrow.right.circle.fill") {
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Permisos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ThemeManager.shared.primaryPink.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Button("Conceder") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        isGranted = true
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeManager.shared.neonGlowGradient)
                    .cornerRadius(10)
                }
            }
        }
    }
}
