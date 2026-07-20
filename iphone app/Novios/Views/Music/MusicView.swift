import SwiftUI

public struct MusicView: View {
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                Text("Nuestra Música")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("Tu música compartida aparecerá aquí")
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.6))
            }
        }
        .navigationTitle("Música")
    }
}
