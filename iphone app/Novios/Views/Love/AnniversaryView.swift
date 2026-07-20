import SwiftUI

public struct AnniversaryView: View {
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                Text("Aniversario")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Detalles del aniversario")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .navigationTitle("Aniversario")
    }
}
