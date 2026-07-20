import SwiftUI

public struct ChatBubbleView: View {
    public let message: MessageModel
    public var isFromMe: Bool
    public var onReaction: (String) -> Void
    
    public var body: some View {
        HStack {
            if isFromMe { Spacer() }
            
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if message.type == .kiss || message.type == .hug || message.type == .touch {
                        Text(message.text ?? "")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(message.text ?? "")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isFromMe
                    ? ThemeManager.shared.neonGlowGradient
                    : LinearGradient(colors: [ThemeManager.shared.cardBackground, ThemeManager.shared.cardBackground], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(18)
                
                // Reacciones
                if let reactions = message.reactions, !reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(reactions.values), id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 12))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
            }
            
            if !isFromMe { Spacer() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
