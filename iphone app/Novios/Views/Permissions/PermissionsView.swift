import SwiftUI
import UserNotifications
import CoreLocation
import AVFoundation
import Photos

public struct PermissionsView: View {
    public var onComplete: (() -> Void)?
    @State private var permissionsGranted = false
    @State private var notificationsGranted = false
    @State private var locationGranted = false
    @State private var microphoneGranted = false
    @State private var photosGranted = false

    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "hand.raised.fill").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primaryPink)

                Text("Permisos").font(.system(size: 28, weight: .bold)).foregroundColor(.primary)
                Text("Concede los permisos para disfrutar de Novios al máximo")
                    .font(.system(size: 14)).foregroundColor(ThemeManager.shared.textSecondary).multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    permissionCard(icon: "bell.badge.fill", title: "Notificaciones", description: "Recibe mensajes y notificaciones de tu pareja", isGranted: $notificationsGranted) {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                            notificationsGranted = granted
                        }
                    }

                    permissionCard(icon: "location.fill", title: "Ubicación", description: "Comparte tu ubicación con tu pareja", isGranted: $locationGranted) {
                        let manager = CLLocationManager()
                        manager.requestWhenInUseAuthorization()
                        locationGranted = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
                    }

                    permissionCard(icon: "mic.fill", title: "Micrófono", description: "Envía notas de voz a tu pareja", isGranted: $microphoneGranted) {
                        AVAudioSession.sharedInstance().requestRecordPermission { granted in
                            microphoneGranted = granted
                        }
                    }

                    permissionCard(icon: "photo.on.rectangle.fill", title: "Fotos", description: "Comparte fotos y recuerdos", isGranted: $photosGranted) {
                        PHPhotoLibrary.requestAuthorization { status in
                            photosGranted = status == .authorized || status == .limited
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Button {
                    permissionsGranted = true
                    onComplete?()
                } label: {
                    Text("Continuar").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(ThemeManager.shared.primaryPink).cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    private func permissionCard(icon: String, title: String, description: String, isGranted: Binding<Bool>, action: @escaping () -> Void) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 22)).foregroundColor(ThemeManager.shared.primaryPink)
                    .padding(10).background(ThemeManager.shared.primaryPink.opacity(0.12)).cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                    Text(description).font(.system(size: 11)).foregroundColor(ThemeManager.shared.textSecondary)
                }

                Spacer()

                if isGranted.wrappedValue {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.system(size: 22))
                } else {
                    Button("Conceder") {
                        action()
                    }
                    .font(.system(size: 13, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(ThemeManager.shared.primaryPink.opacity(0.12)).cornerRadius(12)
                }
            }
        }
    }
}
