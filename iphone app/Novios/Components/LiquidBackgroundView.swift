import SwiftUI

public struct LiquidBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animate1 = false
    @State private var animate2 = false
    @State private var animate3 = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.white.opacity(0.97).ignoresSafeArea()

            // Large soft pink orb
            Circle()
                .fill(Color(red: 1.0, green: 0.36, blue: 0.54).opacity(0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: animate1 ? -100 : 120, y: animate1 ? -160 : -50)
                .scaleEffect(animate1 ? 1.15 : 0.85)

            // Purple orb
            Circle()
                .fill(Color(red: 0.65, green: 0.35, blue: 0.95).opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: animate2 ? 140 : -90, y: animate2 ? 200 : 70)
                .scaleEffect(animate2 ? 0.8 : 1.1)

            // Small pink accent
            Circle()
                .fill(Color(red: 0.9, green: 0.1, blue: 0.4).opacity(0.04))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: animate3 ? -50 : 80, y: animate3 ? 100 : -130)
                .scaleEffect(animate3 ? 1.05 : 0.9)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) { animate1.toggle() }
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) { animate2.toggle() }
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) { animate3.toggle() }
        }
    }
}
