import SwiftUI

public struct ChatBubbleView: View {
    public let message: MessageModel
    public var isFromMe: Bool
    public var onReply: () -> Void
    public var onReact: (String) -> Void

    @State private var showMenu = false

    private let reactions = ["❤️", "😘", "😂", "😮", "😢", "🔥", "💖", "👍", "👎"]

    public var body: some View {
        VStack(spacing: 2) {
            HStack {
                if isFromMe { Spacer(minLength: 60) }
                if !isFromMe { Spacer(minLength: 40) }

                VStack(alignment: .leading, spacing: 4) {
                    // Reply preview
                    if let replyText = message.replyToText {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(ThemeManager.shared.primaryPink)
                                .frame(width: 2.5)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(message.replyToSenderId == message.senderId ? "Tú" : "Ella/Él")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Text(replyText)
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary.opacity(0.7))
                                    .lineLimit(2)
                            }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(.systemBackground).opacity(0.5))
                        .cornerRadius(6)
                    }

                    // Message content
                    if message.type == .voice {
                        voiceContent
                    } else if message.type == .image || message.type == .video {
                        mediaContent
                    } else {
                        Text(message.text ?? "")
                            .font(.system(size: 15, weight: message.type == .kiss || message.type == .hug || message.type == .touch ? .bold : .regular))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                    }

                    // Reactions
                    if let reactions = message.reactions, !reactions.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(Array(reactions.values), id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 5).padding(.vertical, 1)
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.primary.opacity(0.1)))
                            }
                        }
                        .padding(.top, 2)
                    }

                    // Timestamp + read receipt
                    HStack(spacing: 5) {
                        Text(message.timestamp, style: .time)
                            .font(.system(size: 10))
                            .foregroundColor(isFromMe ? .white.opacity(0.7) : .primary.opacity(0.6))
                        if isFromMe {
                            Image(systemName: message.readTimestamp != nil ? "heart.fill" : "heart")
                                .font(.system(size: 11))
                                .foregroundColor(message.readTimestamp != nil ? .pink : .white.opacity(0.4))
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background {
                    if isFromMe {
                        ThemeManager.shared.neonGlowGradient
                    } else {
                        Color(.systemGray5)
                    }
                }
                .clipShape(CustomBubbleShape(isFromMe: isFromMe))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: isFromMe ? .trailing : .leading)

                if !isFromMe { Spacer(minLength: 60) }
                if isFromMe { Spacer(minLength: 40) }
            }
        }
        .padding(.vertical, 3)
        .onLongPressGesture { showMenu = true }
        .sheet(isPresented: $showMenu) {
            VStack(spacing: 12) {
                Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 4).padding(.top, 8)
                Text("Reacciones").font(.system(size: 14, weight: .semibold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(reactions, id: \.self) { emoji in
                        Button {
                            onReact(emoji)
                            showMenu = false
                        } label: {
                            Text(emoji).font(.system(size: 28))
                                .padding(6)
                                .background(ThemeManager.shared.primaryPink.opacity(0.08))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Divider()

                Button {
                    onReply()
                    showMenu = false
                } label: {
                    HStack {
                        Image(systemName: "arrowshape.turn.up.left").foregroundColor(ThemeManager.shared.primaryPink)
                        Text("Responder").foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                Spacer().frame(height: 20)
            }
            .presentationDetents([.height(280)])
        }
    }

    private var voiceContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "play.fill").font(.system(size: 14)).foregroundColor(ThemeManager.shared.primaryPink)
                .padding(6).background(ThemeManager.shared.primaryPink.opacity(0.1)).clipShape(Circle())
            Text("Nota de voz").font(.system(size: 12, weight: .semibold)).foregroundColor(.primary)
            Text("0:05").font(.system(size: 10)).foregroundColor(.primary.opacity(0.5))
        }
    }

    private var mediaContent: some View {
        VStack(spacing: 4) {
            Image(systemName: message.type == .video ? "video.fill" : "photo.fill")
                .font(.system(size: 32)).foregroundColor(.primary.opacity(0.3))
                .frame(width: 180, height: message.type == .video ? 120 : 160)
                .background(.gray.opacity(0.1)).cornerRadius(12)
            if message.type == .video {
                Image(systemName: "play.circle.fill").font(.system(size: 28)).foregroundColor(.white.opacity(0.8))
                    .offset(y: -60)
            }
        }
    }
}

private struct CustomBubbleShape: Shape {
    let isFromMe: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r: CGFloat = 20
        if isFromMe {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r), style: .continuous)
        } else {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r), style: .continuous)
        }
        return path
    }
}
