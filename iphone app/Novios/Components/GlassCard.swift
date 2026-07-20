import SwiftUI

public struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    public let content: Content
    public var cornerRadius: CGFloat
    public var opacity: Double
    public var borderColor: Color
    public var padding: CGFloat

    @State private var isAppeared = false

    public init(
        cornerRadius: CGFloat = 16,
        opacity: Double = 0.15,
        borderColor: Color = Color.white.opacity(0.18),
        padding: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.borderColor = borderColor
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.5), ThemeManager.shared.primaryPink.opacity(0.1), .clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.8
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            .scaleEffect(isAppeared ? 1 : 0.97)
            .opacity(isAppeared ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.9).delay(0.03), value: isAppeared)
            .onAppear { isAppeared = true }
    }
}
