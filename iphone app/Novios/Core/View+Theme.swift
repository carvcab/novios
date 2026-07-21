import SwiftUI

extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(ThemeManager.shared.font(size: size, weight: weight))
    }

    func appBodyFont() -> some View {
        appFont(size: 14)
    }

    func appHeadlineFont() -> some View {
        appFont(size: 16, weight: .semibold)
    }

    func appTitleFont() -> some View {
        appFont(size: 20, weight: .bold)
    }

    func appCaptionFont() -> some View {
        appFont(size: 12)
    }

    var accentColor: Color { ThemeManager.shared.primary }
    var accentSecondary: Color { ThemeManager.shared.secondary }
    var themeBackgroundGradient: LinearGradient { ThemeManager.shared.backgroundGradient }
}
