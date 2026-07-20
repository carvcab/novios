import SwiftUI

public struct MoreOptionCard: View {
    public let title: String
    public let subtitle: String
    public let icon: String
    public let color: Color

    public init(title: String, subtitle: String, icon: String, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.2))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(ThemeManager.shared.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}
