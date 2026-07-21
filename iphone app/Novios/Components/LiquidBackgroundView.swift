import SwiftUI

public struct LiquidBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animate1 = false
    @State private var animate2 = false
    @State private var animate3 = false

    public init() {}

    public var body: some View {
        ZStack {
            ThemeManager.shared.pastelWarmBg.ignoresSafeArea()

            Circle()
                .fill(ThemeManager.shared.pastelPink.opacity(0.25))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: animate1 ? -90 : 110, y: animate1 ? -140 : -60)
                .scaleEffect(animate1 ? 1.1 : 0.9)

            Circle()
                .fill(ThemeManager.shared.pastelLavender.opacity(0.2))
                .frame(width: 380, height: 380)
                .blur(radius: 110)
                .offset(x: animate2 ? 130 : -80, y: animate2 ? 180 : 80)
                .scaleEffect(animate2 ? 0.85 : 1.05)

            Circle()
                .fill(ThemeManager.shared.pastelPeach.opacity(0.2))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: animate3 ? -40 : 70, y: animate3 ? 90 : -110)
                .scaleEffect(animate3 ? 1.0 : 0.92)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) { animate1.toggle() }
            withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) { animate2.toggle() }
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) { animate3.toggle() }
        }
    }
}
