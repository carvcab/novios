import SwiftUI

public struct QuickFeatureTile: View {
    public let title: String
    public let icon: String
    public let color: Color

    public init(title: String, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.18).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
