import SwiftUI

public struct LiquidBackgroundView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var animate1 = false
    @State private var animate2 = false
    @State private var animate3 = false

    private var bgColor: Color {
        if theme.isDarkMode { return Color(red: 0.04, green: 0.04, blue: 0.04) }
        if theme.isRedMode { return Color(red: 1.0, green: 0.94, blue: 0.94) }
        return theme.pastelWarmBg
    }

    private var orb1: Color {
        if theme.isDarkMode { return theme.pastelRose.opacity(0.15) }
        if theme.isRedMode { return theme.redAccent.opacity(0.12) }
        return theme.pastelPink.opacity(0.25)
    }

    private var orb2: Color {
        if theme.isDarkMode { return theme.pastelLavender.opacity(0.10) }
        if theme.isRedMode { return theme.redSecondary.opacity(0.10) }
        return theme.pastelLavender.opacity(0.2)
    }

    private var orb3: Color {
        if theme.isDarkMode { return theme.pastelBlue.opacity(0.10) }
        if theme.isRedMode { return theme.redAccent.opacity(0.08) }
        return theme.pastelPeach.opacity(0.2)
    }

    public init() {}

    public var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            Circle()
                .fill(orb1)
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: animate1 ? -90 : 110, y: animate1 ? -140 : -60)
                .scaleEffect(animate1 ? 1.1 : 0.9)

            Circle()
                .fill(orb2)
                .frame(width: 380, height: 380)
                .blur(radius: 110)
                .offset(x: animate2 ? 130 : -80, y: animate2 ? 180 : 80)
                .scaleEffect(animate2 ? 0.85 : 1.05)

            Circle()
                .fill(orb3)
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
