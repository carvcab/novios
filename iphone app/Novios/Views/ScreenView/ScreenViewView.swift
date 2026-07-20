import SwiftUI

public struct ScreenViewView: View {
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 48))
                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                Text("Ver Pantalla")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("La pantalla de tu pareja aparecerá aquí")
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.6))
            }
        }
        .navigationTitle("Pantalla")
    }
}
