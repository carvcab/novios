import SwiftUI

public struct LiquidBackgroundView: View {
    @State private var animate1 = false
    @State private var animate2 = false
    @State private var animate3 = false

    public init() {}

    public var body: some View {
        ZStack {
            // Base dark obsidian background
            Color(red: 0.04, green: 0.04, blue: 0.05)
                .ignoresSafeArea()

            // Floating Orb 1 - Neon Pink (#FF5C8A)
            Circle()
                .fill(Color(red: 1.0, green: 0.36, blue: 0.54).opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: animate1 ? -90 : 100, y: animate1 ? -150 : -60)
                .scaleEffect(animate1 ? 1.2 : 0.9)

            // Floating Orb 2 - Neon Purple (#A65BF5)
            Circle()
                .fill(Color(red: 0.65, green: 0.35, blue: 0.95).opacity(0.3))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: animate2 ? 120 : -80, y: animate2 ? 180 : 80)
                .scaleEffect(animate2 ? 0.85 : 1.15)

            // Floating Orb 3 - Deep Crimson (#FF2A6D)
            Circle()
                .fill(Color(red: 0.9, green: 0.1, blue: 0.4).opacity(0.25))
                .frame(width: 280, height: 280)
                .blur(radius: 65)
                .offset(x: animate3 ? -40 : 90, y: animate3 ? 120 : -140)
                .scaleEffect(animate3 ? 1.1 : 0.95)

            // Subtle dark overlay grid
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                animate1.toggle()
            }
            withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
                animate2.toggle()
            }
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animate3.toggle()
            }
        }
    }
}
