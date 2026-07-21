import SwiftUI

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    public let pastelPink = Color(red: 0.96, green: 0.76, blue: 0.82)
    public let pastelRose = Color(red: 0.91, green: 0.63, blue: 0.75)
    public let pastelLavender = Color(red: 0.76, green: 0.69, blue: 0.88)
    public let pastelPeach = Color(red: 1.0, green: 0.85, blue: 0.73)
    public let pastelMint = Color(red: 0.70, green: 0.85, blue: 0.70)
    public let pastelBlue = Color(red: 0.65, green: 0.78, blue: 0.91)
    public let pastelWarmBg = Color(red: 1.0, green: 0.96, blue: 0.97)

    @Published public var isDarkMode: Bool = false
    @Published public var enableHaptics: Bool = true
    @Published public var pinLockEnabled: Bool = false
    @Published public var userPinCode: String = ""

    public var primaryPink: Color { pastelRose }

    public var cardBackground: Color {
        isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : .white
    }

    public var textSecondary: Color {
        isDarkMode ? Color.white.opacity(0.6) : Color(red: 0.5, green: 0.45, blue: 0.5)
    }

    public var backgroundGradient: LinearGradient {
        if isDarkMode {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.04), Color(red: 0.08, green: 0.05, blue: 0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [pastelWarmBg, Color(red: 0.98, green: 0.94, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public var neonGlowGradient: LinearGradient {
        LinearGradient(
            colors: [pastelRose, pastelLavender],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
