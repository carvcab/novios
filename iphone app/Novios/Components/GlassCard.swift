import SwiftUI

public struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    public let content: Content
    public var cornerRadius: CGFloat

    @State private var isAppeared = false

    public init(
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial)
            .background(ThemeManager.shared.cardBackground.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(colors: [
                            .white.opacity(0.7),
                            ThemeManager.shared.primary.opacity(0.2),
                            .white.opacity(0.3)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.8
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: ThemeManager.shared.primary.opacity(0.08), radius: 12, x: 0, y: 4)
            .scaleEffect(isAppeared ? 1 : 0.97)
            .opacity(isAppeared ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.9).delay(0.03), value: isAppeared)
            .onAppear { isAppeared = true }
    }
}
