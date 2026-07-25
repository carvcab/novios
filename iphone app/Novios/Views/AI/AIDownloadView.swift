import SwiftUI

public struct AIDownloadView: View {
    @ObservedObject private var ai = LocalAIService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var done = false
    @State private var downloading = false
    let showSkip: Bool

    public init(showSkip: Bool = true) {
        self.showSkip = showSkip
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundColor(.white)
            Text("IA de EverUs")
                .appFont(size: 26, weight: .bold)
                .foregroundColor(.white)
            Text(done ? "IA instalada correctamente" : "Descarga el modelo de IA para obtener respuestas inteligentes, romanticas y offline")
                .appFont(size: 14)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Text("Tamano: 1.1 GB")
                .appFont(size: 12)
                .foregroundColor(.white.opacity(0.6))

            if downloading {
                ProgressView(value: ai.downloadProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .padding(.horizontal, 48)
                    .scaleEffect(1.2)
                Text("\(Int(ai.downloadProgress * 100))%")
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(.white)
                Text(ai.statusText)
                    .appFont(size: 12)
                    .foregroundColor(.white.opacity(0.7))
            } else if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
            } else {
                Button(action: startDownload) {
                    HStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.down")
                        Text("Descargar")
                    }
                    .appFont(size: 16, weight: .bold)
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                if showSkip {
                    Button("Mas tarde") {
                        done = true
                    }
                    .appFont(size: 14)
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [theme.primary, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .onAppear {
            done = ai.isInitialized
        }
    }

    private func startDownload() {
        downloading = true
        ai.startDownload()
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { t in
            if ai.isInitialized || !ai.isLoading {
                DispatchQueue.main.async {
                    downloading = false
                    done = ai.isInitialized
                }
                t.invalidate()
            }
        }
    }
}
