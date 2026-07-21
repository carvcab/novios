import SwiftUI

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    // MARK: - Pastel Colors
    public let pastelPink = Color(red: 0.96, green: 0.76, blue: 0.82)
    public let pastelRose = Color(red: 0.91, green: 0.63, blue: 0.75)
    public let pastelLavender = Color(red: 0.76, green: 0.69, blue: 0.88)
    public let pastelPeach = Color(red: 1.0, green: 0.85, blue: 0.73)
    public let pastelMint = Color(red: 0.70, green: 0.85, blue: 0.70)
    public let pastelBlue = Color(red: 0.65, green: 0.78, blue: 0.91)
    public let pastelWarmBg = Color(red: 1.0, green: 0.96, blue: 0.97)

    // MARK: - Red Theme Colors
    public let redAccent = Color(red: 0.85, green: 0.18, blue: 0.18)
    public let redSecondary = Color(red: 0.95, green: 0.40, blue: 0.40)
    public let redLight = Color(red: 1.0, green: 0.89, blue: 0.89)
    public let redDark = Color(red: 0.45, green: 0.06, blue: 0.06)

    // MARK: - Dark Theme Colors
    public let darkBg1 = Color(red: 0.04, green: 0.04, blue: 0.04)
    public let darkBg2 = Color(red: 0.08, green: 0.05, blue: 0.09)
    public let darkCard = Color(red: 0.13, green: 0.13, blue: 0.15)
    public let darkSurface = Color(red: 0.18, green: 0.18, blue: 0.20)

    // MARK: - Published Settings
    @Published public var isDarkMode: Bool = false {
        didSet { UserDefaults.standard.set(isDarkMode, forKey: "is_dark_mode") }
    }
    @Published public var isRedMode: Bool = false {
        didSet { UserDefaults.standard.set(isRedMode, forKey: "is_red_mode") }
    }
    @Published public var fontFamily: String = "Inter" {
        didSet { UserDefaults.standard.set(fontFamily, forKey: "font_family") }
    }
    @Published public var enableHaptics: Bool = true
    @Published public var pinLockEnabled: Bool = false
    @Published public var userPinCode: String = ""

    private init() {
        let defaults = UserDefaults.standard
        isDarkMode = defaults.bool(forKey: "is_dark_mode")
        isRedMode = defaults.bool(forKey: "is_red_mode")
        fontFamily = defaults.string(forKey: "font_family") ?? "Inter"
    }

    // MARK: - Accent Colors (adapt to red mode)

    public var primary: Color {
        isRedMode ? redAccent : pastelRose
    }

    public var secondary: Color {
        isRedMode ? redSecondary : pastelLavender
    }

    // MARK: - Background (adapt to dark + red)

    public var cardBackground: Color {
        if isDarkMode { return darkCard }
        if isRedMode { return redLight }
        return .white
    }

    public var surfaceBackground: Color {
        if isDarkMode { return darkSurface }
        if isRedMode { return redLight.opacity(0.5) }
        return pastelWarmBg.opacity(0.5)
    }

    public var textPrimary: Color {
        isDarkMode ? .white : .black.opacity(0.85)
    }

    public var textSecondary: Color {
        isDarkMode ? .white.opacity(0.55) : Color(red: 0.5, green: 0.45, blue: 0.5)
    }

    public var backgroundGradient: LinearGradient {
        if isDarkMode {
            return LinearGradient(
                colors: [darkBg1, darkBg2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        if isRedMode {
            return LinearGradient(
                colors: [redLight, Color(red: 1.0, green: 0.94, blue: 0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [pastelWarmBg, Color(red: 0.98, green: 0.94, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Compatibility
    public var primaryPink: Color { primary }

    public var pastelRoseAccent: Color { primary }
    public var pastelLavenderAccent: Color { secondary }

    // MARK: - Bubble Colors (adapt to themes)

    public var myBubbleBackground: Color {
        if isDarkMode { return surfaceBackground }
        if isRedMode { return redSecondary.opacity(0.25) }
        return Color(red: 0.93, green: 0.65, blue: 0.75)
    }

    public var partnerBubbleBackground: Color {
        if isDarkMode { return Color(red: 0.18, green: 0.18, blue: 0.20) }
        return Color(.systemGray6)
    }

    public var myBubbleText: Color {
        if isDarkMode { return .white.opacity(0.9) }
        return Color(red: 0.35, green: 0.15, blue: 0.2)
    }

    public var myBubbleShadow: Color {
        primary.opacity(isDarkMode ? 0.1 : 0.25)
    }

    public var myBubbleHeart: Color {
        isRedMode ? redSecondary : Color(red: 1, green: 0.85, blue: 0.95)
    }

    // MARK: - Font

    public func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = fontFamily
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size).weight(weight)
        }
        switch name {
        case "Playfair Display": return .custom("Georgia", size: size).weight(weight)
        case "Outfit": return .system(size: size, weight: weight, design: .rounded)
        case "Pacifico": return .custom("MarkerFelt-Thin", size: size).weight(weight)
        case "Poppins": return .custom("Helvetica", size: size).weight(weight)
        default: return .system(size: size, weight: weight)
        }
    }
}

// MARK: - View extension for theme fonts
extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(ThemeManager.shared.font(size: size, weight: weight))
    }
}
