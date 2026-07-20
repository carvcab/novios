import SwiftUI

public struct ChatBubbleView: View {
    public let message: MessageModel
    public var isFromMe: Bool
    public var onReaction: ((String) -> Void)?
    public var onReply: (() -> Void)?
    public var onCopy: (() -> Void)?

    @State private var showContextMenu = false

    private let reactionEmojis = ["❤️", "😘", "😂", "😮", "😢", "🔥", "💖", "👍", "👎"]
    private let theme = ThemeManager.shared

    public var body: some View {
        VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
            if message.isDisappearing {
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Desaparece después de leer")
                        .font(.system(size: 9))
                        .foregroundColor(.orange.opacity(0.7))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)
            }

            HStack(alignment: .bottom, spacing: 6) {
                if isFromMe { Spacer(minLength: 50) }

                VStack(alignment: isFromMe ? .trailing : .leading, spacing: 3) {
                    if hasReply {
                        replyPreview
                    }

                    bubbleContent
                        .background(bubbleBackground)
                        .cornerRadius(18)

                    VStack(spacing: 1) {
                        timestampRow

                        if let reactions = message.reactions, !reactions.isEmpty {
                            reactionsRow(reactions: reactions)
                        }
                    }
                }

                if !isFromMe { Spacer(minLength: 50) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .contextMenu {
            reactionContextMenu
            Divider()
            if message.replyToId == nil {
                Button {
                    onReply?()
                } label: {
                    Label("Responder", systemImage: "arrowshape.turn.up.left")
                }
            }
            if message.type == .text, message.text != nil {
                Button {
                    onCopy?()
                } label: {
                    Label("Copiar", systemImage: "doc.on.doc")
                }
            }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.type {
        case .text, .disappearing:
            if let text = message.text {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(isFromMe ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        case .voice:
            voiceMessageContent
        case .video:
            videoMessageContent
        case .image:
            imageMessageContent
        case .gift:
            giftMessageContent
        case .kiss:
            HStack(spacing: 8) {
                Text("💋")
                    .font(.system(size: 32))
                Text("Te di un beso")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isFromMe ? .white : theme.primaryPink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        case .hug:
            HStack(spacing: 8) {
                Text("🤗")
                    .font(.system(size: 32))
                Text("Te di un abrazo")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isFromMe ? .white : theme.primaryPink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        case .touch:
            HStack(spacing: 8) {
                Text("✨")
                    .font(.system(size: 32))
                Text("Siente mi toque")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isFromMe ? .white : theme.primaryPink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        case .letter:
            letterMessageContent
        }
    }

    private var voiceMessageContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundColor(isFromMe ? .white : theme.primaryPink)
            HStack(spacing: 3) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isFromMe ? Color.white.opacity(0.8) : theme.primaryPink.opacity(0.7))
                        .frame(width: 3, height: 8 + CGFloat(i * 4))
                }
            }
            Text("0:\(Int.random(in: 3..<12))")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isFromMe ? .white.opacity(0.8) : theme.textSecondary)
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundColor(isFromMe ? .white.opacity(0.7) : theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var videoMessageContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.25))
                .frame(width: 180, height: 130)
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .shadow(radius: 4)
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "video.fill")
                        .font(.system(size: 10))
                    Text("Video")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.4))
                .cornerRadius(6)
                .padding(6)
            }
        }
        .frame(width: 180, height: 130)
    }

    private var imageMessageContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo.fill")
                .font(.system(size: 50))
                .foregroundColor(isFromMe ? .white.opacity(0.7) : theme.textSecondary)
            Text("Tap para ver")
                .font(.system(size: 11))
                .foregroundColor(isFromMe ? .white.opacity(0.7) : theme.textSecondary)
        }
        .frame(width: 160, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFromMe ? Color.white.opacity(0.15) : Color.black.opacity(0.05))
        )
    }

    private var giftMessageContent: some View {
        HStack(spacing: 10) {
            Text("🎁")
                .font(.system(size: 36))
            VStack(alignment: .leading, spacing: 2) {
                Text("Regalo especial")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isFromMe ? .white : theme.primaryPink)
                if let gid = message.giftId {
                    Text(gid.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.system(size: 11))
                        .foregroundColor(isFromMe ? .white.opacity(0.7) : theme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var letterMessageContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isFromMe ? .white : theme.primaryPink)
                Text("Carta")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isFromMe ? .white : theme.primaryPink)
            }
            if let title = message.letterTitle {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isFromMe ? .white.opacity(0.9) : .primary)
                    .lineLimit(1)
            }
            if let preview = message.text {
                Text(preview)
                    .font(.system(size: 12))
                    .foregroundColor(isFromMe ? .white.opacity(0.7) : theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var replyPreview: some View {
        if let replyText = message.replyToText {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isFromMe ? Color.white : theme.primaryPink)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(message.replyToSenderId == currentUserId ? "Tú" : partnerName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isFromMe ? .white.opacity(0.8) : theme.primaryPink)
                    Text(replyText)
                        .font(.system(size: 12))
                        .foregroundColor(isFromMe ? .white.opacity(0.7) : theme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 200)
            .background(isFromMe ? Color.white.opacity(0.12) : Color.black.opacity(0.04))
            .cornerRadius(8)
        }
    }

    private var timestampRow: some View {
        HStack(spacing: 4) {
            if let read = message.readTimestamp {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isFromMe ? theme.primaryPink : theme.textSecondary.opacity(0.6))
                Text(timeString(read))
                    .font(.system(size: 9))
                    .foregroundColor(isFromMe ? theme.primaryPink.opacity(0.7) : theme.textSecondary.opacity(0.6))
            } else if isFromMe {
                Image(systemName: "clock")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textSecondary.opacity(0.5))
            }
            Text(timeString(message.timestamp))
                .font(.system(size: 10))
                .foregroundColor(isFromMe ? theme.primaryPink.opacity(0.7) : theme.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 4)
    }

    private func reactionsRow(reactions: [String: String]) -> some View {
        HStack(spacing: 3) {
            ForEach(Array(Set(reactions.values)).sorted(), id: \.self) { emoji in
                let count = reactions.values.filter { $0 == emoji }.count
                let isMine = reactions[currentUserId] == emoji
                HStack(spacing: 2) {
                    Text(emoji)
                        .font(.system(size: 12))
                    if count > 1 {
                        Text("\(count)")
                            .font(.system(size: 9))
                            .foregroundColor(isMine ? theme.primaryPink : theme.textSecondary)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isMine ? theme.primaryPink.opacity(0.15) : Color.gray.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(isMine ? theme.primaryPink.opacity(0.4) : Color.clear, lineWidth: 1)
                )
            }
        }
    }

    private var reactionContextMenu: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(reactionEmojis, id: \.self) { emoji in
                    Button {
                        onReaction?(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 26))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var bubbleBackground: some View {
        Group {
            if isFromMe {
                theme.neonGlowGradient
            } else {
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground).opacity(0.92),
                        Color(UIColor.systemBackground).opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    private var hasReply: Bool {
        message.replyToId != nil && message.replyToText != nil
    }

    private var currentUserId: String { AuthService.shared.currentUser?.id ?? "user_me" }
    private var partnerName: String { UserService.shared.partnerUser?.displayName ?? "Mi Amor" }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        ChatBubbleView(
            message: MessageModel(id: "p1", senderId: "me", text: "Hola amor ❤️", timestamp: Date(), type: .text, reactions: ["them": "😘"]),
            isFromMe: true
        )
        ChatBubbleView(
            message: MessageModel(id: "p2", senderId: "them", text: "¡Hola cielo! 🥰", timestamp: Date(), type: .text, readTimestamp: Date()),
            isFromMe: false
        )
    }
    .padding()
    .background(Color.black.opacity(0.05))
}
