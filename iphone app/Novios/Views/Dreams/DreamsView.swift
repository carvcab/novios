import SwiftUI

public struct DreamsView: View {
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 48))
                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                Text("Sueños y Metas")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Tus sueños compartidos aparecerán aquí")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .navigationTitle("Sueños")
    }
}
