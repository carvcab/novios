import SwiftUI

public struct NotificationsView: View {
    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                Text("Notificaciones")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("No hay notificaciones nuevas")
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.6))
            }
        }
        .navigationTitle("Notificaciones")
    }
}
