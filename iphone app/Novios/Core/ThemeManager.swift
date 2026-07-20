import SwiftUI

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    // Primary Colors
    public let primaryPink = Color(red: 1.0, green: 0.36, blue: 0.54) // #FF5C8A
    public let primaryPurple = Color(red: 0.65, green: 0.35, blue: 0.95) // #A65BF5
    public let backgroundDark = Color(red: 0.04, green: 0.04, blue: 0.04) // #09090B
    public let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
    public let textPrimary = Color.white
    public let textSecondary = Color.white.opacity(0.6)
    
    @Published public var isDarkMode: Bool = true
    @Published public var enableHaptics: Bool = true
    @Published public var pinLockEnabled: Bool = false
    @Published public var userPinCode: String = ""

    public var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundDark, Color(red: 0.08, green: 0.05, blue: 0.09)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var neonGlowGradient: LinearGradient {
        LinearGradient(
            colors: [primaryPink, primaryPurple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
