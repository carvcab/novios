import SwiftUI

public struct AIDownloadView: View {
    @ObservedObject private var manager = AIModelManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var installing = false
    @State private var errorMsg: String?
    let showSkip: Bool

    public init(showSkip: Bool = true) {
        self.showSkip = showSkip
    }

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: manager.state == .ready ? "checkmark.circle.fill" : "sparkles")
                .font(.system(size: 64))
                .foregroundColor(.white)

            Text(manager.state == .ready ? "IA instalada correctamente" : "Descargar IA")
                .appFont(size: 26, weight: .bold)
                .foregroundColor(.white)

            if let model = manager.currentModel {
                VStack(spacing: 6) {
                    infoRow("Modelo", model.name)
                    infoRow("Version", model.version)
                    infoRow("Tamano", "\(model.sizeMB) MB")
                    infoRow("Espacio requerido", "\(model.requiredSpaceMB) MB")
                }
                .padding(.horizontal, 40)
            }

            // Progress
            if installing || manager.state == .downloading || manager.state == .verifying || manager.state == .installing {
                ProgressView(value: manager.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .padding(.horizontal, 48)
                    .scaleEffect(1.2)

                Text(manager.progressText)
                    .appFont(size: 14, weight: .semibold)
                    .foregroundColor(.white)

                if manager.totalBytes > 0 {
                    Text("\(manager.downloadedBytes / (1024*1024)) MB / \(manager.totalBytes / (1024*1024)) MB")
                        .appFont(size: 12)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Error
            if let error = errorMsg {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Error")
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(.white)
                    }
                    Text(error)
                        .appFont(size: 12)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    Button(action: { startDownload() }) {
                        Text("Reintentar")
                            .appFont(size: 14, weight: .bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
                .background(Color.red.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 40)
            }

            // Actions
            if !installing && errorMsg == nil && manager.state != .downloading {
                if manager.state == .ready {
                    Button("Comenzar") {
                        // Dismiss to main app
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(rootView: MainTabView())
                            window.makeKeyAndVisible()
                        }
                    }
                    .buttonStyle(PrimaryButton())
                } else {
                    Button(action: { startDownload() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("Descargar")
                        }
                    }
                    .buttonStyle(PrimaryButton())

                    if showSkip {
                        Button("Mas tarde") {}
                            .appFont(size: 14)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [theme.primary, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .onAppear {
            manager.initModel()
        }
        .onReceive(manager.$state) { state in
            installing = state == .downloading || state == .verifying || state == .installing
            if state == .error {
                errorMsg = manager.errorMessage
            } else if state == .ready {
                errorMsg = nil
                installing = false
            }
        }
    }

    private func startDownload() {
        errorMsg = nil
        installing = true
        manager.downloadModel()
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .appFont(size: 13)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .appFont(size: 13, weight: .bold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Button Style

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appFont(size: 16, weight: .bold)
            .foregroundColor(ThemeManager.shared.primary)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
