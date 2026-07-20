import SwiftUI

public struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    public let content: Content
    public var cornerRadius: CGFloat
    public var opacity: Double
    public var borderColor: Color

    @State private var shimmerOffset: CGFloat = -200

    public init(
        cornerRadius: CGFloat = 24,
        opacity: Double = 0.15,
        borderColor: Color = Color.white.opacity(0.18),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.borderColor = borderColor
        self.content = content()
    }

    public var body: some View {
        content
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.75) : Color.white.opacity(0.85))

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (colorScheme == .dark ? Color.white : Color.black).opacity(opacity + 0.05),
                                    (colorScheme == .dark ? Color.white : Color.black).opacity(opacity - 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if colorScheme == .dark {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, Color.white.opacity(0.08), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(x: shimmerOffset)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        colorScheme == .dark
                            ? LinearGradient(
                                colors: [borderColor, ThemeManager.shared.primaryPink.opacity(0.3), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [ThemeManager.shared.primaryPink.opacity(0.15), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                        lineWidth: 1.2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: (colorScheme == .dark ? Color.black : Color.gray).opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 14, x: 0, y: 7)
            .onAppear {
                if colorScheme == .dark {
                    withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 300
                    }
                }
            }
    }
}
