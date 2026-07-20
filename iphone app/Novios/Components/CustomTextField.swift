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
                .foregroundColor(.primary.opacity(0.4))
                .font(.system(size: 18))
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.primary.opacity(0.4)))
                    .foregroundColor(.primary)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.primary.opacity(0.4)))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(ThemeManager.shared.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
