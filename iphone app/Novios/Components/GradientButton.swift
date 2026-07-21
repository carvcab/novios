import SwiftUI

public struct GradientButton: View {
    public let title: String
    public var icon: String?
    public var isLoading: Bool
    public var action: () -> Void

    @State private var isPressed = false

    public init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .bold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [ThemeManager.shared.pastelRose, ThemeManager.shared.pastelLavender],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    Color.white.opacity(0.1)
                }
            )
            .cornerRadius(18)
            .shadow(color: ThemeManager.shared.pastelRose.opacity(0.3), radius: 10, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .disabled(isLoading)
    }
}
