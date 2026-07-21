import SwiftUI

public struct CustomTextField: View {
    public let placeholder: String
    @Binding public var text: String
    public var icon: String
    public var isSecure: Bool

    public init(
        placeholder: String,
        text: Binding<String>,
        icon: String = "envelope.fill",
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(ThemeManager.shared.primary)
                .appFont(size: 18)

            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.5)))
                    .foregroundColor(.primary)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(ThemeManager.shared.textSecondary.opacity(0.5)))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .background(ThemeManager.shared.pastelWarmBg.opacity(0.4))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.5), ThemeManager.shared.pastelPink.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
        )
    }
}
