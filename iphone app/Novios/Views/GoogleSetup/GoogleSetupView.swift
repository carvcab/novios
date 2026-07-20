import SwiftUI

private struct GoogleOption: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let binding: Binding<Bool>
}

public struct GoogleSetupView: View {
    @State private var isConnected = false
    @State private var calendarEnabled = false
    @State private var driveEnabled = false
    @State private var photosEnabled = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        if isConnected {
                            connectedOptions
                            disconnectButton
                        } else {
                            connectButton
                        }
                    }
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Google")
            .navigationBarTitleTextColor(.white)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "g.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(ThemeManager.shared.primaryPink)

            Text("Google")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Conecta tu cuenta de Google\npara sincronizar tus servicios")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
    }

    private var connectButton: some View {
        Button(action: connectGoogle) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                Text("Conectar con Google")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(ThemeManager.shared.primaryPink)
            .cornerRadius(14)
            .shadow(color: ThemeManager.shared.primaryPink.opacity(0.4), radius: 8, y: 4)
        }
    }

    private var connectedOptions: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                        optionRow(option)
                        if index < options.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.leading, 44)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var options: [GoogleOption] {
        [
            GoogleOption(icon: "calendar", title: "Sincronizar Calendario",
                         description: "Mantén tus fechas importantes sincronizadas",
                         binding: $calendarEnabled),
            GoogleOption(icon: "drive", title: "Google Drive",
                         description: "Guarda tus recuerdos en la nube",
                         binding: $driveEnabled),
            GoogleOption(icon: "photo.on.rectangle", title: "Google Fotos",
                         description: "Comparte fotos directamente",
                         binding: $photosEnabled),
        ]
    }

    private func optionRow(_ option: GoogleOption) -> some View {
        HStack(spacing: 12) {
            Image(systemName: option.icon)
                .font(.title2)
                .foregroundColor(ThemeManager.shared.primaryPink)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(option.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(option.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: option.binding)
                .tint(ThemeManager.shared.primaryPink)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var disconnectButton: some View {
        Button(action: disconnectGoogle) {
            HStack(spacing: 8) {
                Image(systemName: "link.badge.minus")
                Text("Desconectar Google")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red, lineWidth: 1.5)
            )
        }
        .padding(.top, 8)
    }

    private func connectGoogle() {
        withAnimation(.easeInOut) {
            isConnected = true
        }
    }

    private func disconnectGoogle() {
        withAnimation(.easeInOut) {
            isConnected = false
            calendarEnabled = false
            driveEnabled = false
            photosEnabled = false
        }
    }
}
