import SwiftUI

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    public let primaryPink = Color(red: 0.91, green: 0.27, blue: 0.49)
    public let primaryPurple = Color(red: 0.61, green: 0.44, blue: 0.91)

    @Published public var isDarkMode: Bool = false
    @Published public var enableHaptics: Bool = true
    @Published public var pinLockEnabled: Bool = false
    @Published public var userPinCode: String = ""

    public var cardBackground: Color {
        isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : .white
    }

    public var textSecondary: Color {
        isDarkMode ? Color.white.opacity(0.6) : Color(red: 0.35, green: 0.35, blue: 0.35)
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
                colors: [Color(red: 1.0, green: 0.96, blue: 0.97), Color(red: 1.0, green: 0.94, blue: 0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public var neonGlowGradient: LinearGradient {
        LinearGradient(
            colors: [primaryPink, primaryPurple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
