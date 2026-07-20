import SwiftUI

public struct MessagesView: View {
    @StateObject private var chatService = ChatService.shared
    @StateObject private var audioService = AudioService.shared
    @EnvironmentObject var authService: AuthService
    @State private var textInput = ""
    @State private var floatingHearts: [ChatHeartParticle] = []
    @State private var heartCounter = 0

    private let quickEmojis = ["❤️", "😘", "🥺", "💖", "💑", "🔥", "🌹", "✨", "💍"]

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(chatService.messages.reversed()) { msg in
                                    let isMe = msg.senderId == (authService.currentUser?.id ?? "me")
                                    ChatBubbleView(
                                        message: msg,
                                        isFromMe: isMe,
                                        onReply: { chatService.setReplyTo(message: msg) },
                                        onReact: { emoji in chatService.addReaction(to: msg.id, emoji: emoji) }
                                    )
                                    .id(msg.id)
                                }
                                Color.clear.frame(height: 4).id("bottom_scroll")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .onChange(of: chatService.messages.count) { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                proxy.scrollTo("bottom_scroll", anchor: .bottom)
                            }
                        }
                    }

                    // Reply bar
                    if let reply = chatService.replyToMessage {
                        replyBar(for: reply)
                    }

                    // Disappearing mode banner
                    if chatService.isShowingDisappearing {
                        HStack(spacing: 6) {
                            Image(systemName: "timer").font(.system(size: 12)).foregroundColor(.pink)
                            Text("Modo Secreto Activo: los mensajes desaparecerán en 15s al ser leídos")
                                .font(.system(size: 10, weight: .semibold)).foregroundColor(.pink)
                            Spacer()
                        }
                        .padding(.vertical, 6).padding(.horizontal, 16)
                        .background(Color.pink.opacity(0.1))
                    }

                    // Quick emoji bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickEmojis, id: \.self) { emoji in
                                Button {
                                    chatService.sendMessage(text: emoji)
                                    spawnHearts(count: 25)
                                } label: {
                                    Text(emoji).font(.system(size: 15))
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(ThemeManager.shared.primaryPink.opacity(0.08))
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(height: 38)
                    .background(Color(.systemBackground).opacity(0.5))

                    // Input bar
                    HStack(spacing: 8) {
                        Button {
                            chatService.isShowingDisappearing.toggle()
                        } label: {
                            Image(systemName: chatService.isShowingDisappearing ? "timer" : "timer")
                                .font(.system(size: 20))
                                .foregroundColor(chatService.isShowingDisappearing ? .pink : .primary.opacity(0.5))
                        }

                        Button {
                            toggleRecording()
                        } label: {
                            Image(systemName: audioService.isRecording ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(audioService.isRecording ? .red : .primary.opacity(0.5))
                        }

                        Button {
                            showAttachmentMenu()
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20)).foregroundColor(.primary.opacity(0.5))
                        }

                        TextField(chatService.replyToMessage != nil ? "Escribe tu respuesta..." : "Escribe un mensaje...",
                                  text: $textInput)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(24)

                        Button {
                            let trimmed = textInput.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                chatService.sendMessage(text: trimmed)
                                textInput = ""
                                let lower = trimmed.lowercased()
                                let isSpecial = lower.contains("te amo") || lower.contains("te quiero") || lower.contains("love") || lower.contains("❤️") || lower.contains("💖") || lower.contains("😘")
                                spawnHearts(count: isSpecial ? 30 : 6)
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(ThemeManager.shared.primaryPink)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color(.systemBackground).opacity(0.3))
                }

                // Floating hearts
                ForEach(floatingHearts) { heart in
                    Image(systemName: "heart.fill")
                        .font(.system(size: heart.size))
                        .foregroundColor(ThemeManager.shared.primaryPink.opacity(heart.opacity))
                        .offset(x: heart.x, y: heart.y)
                        .animation(.easeOut(duration: 0.8), value: heart.y)
                }
            }
            .navigationTitle("Chat con mi Amor ❤️")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func replyBar(for msg: MessageModel) -> some View {
        let isReplyingToMe = msg.senderId == authService.currentUser?.id
        return VStack(spacing: 0) {
            HStack(spacing: 10) {
                Rectangle().fill(ThemeManager.shared.primaryPink).frame(width: 3, height: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(isReplyingToMe ? "Respondiendo a ti mismo" : "Respondiendo")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(ThemeManager.shared.primaryPink)
                    Text(msg.text?.count ?? 0 > 60 ? "\(msg.text?.prefix(60) ?? "")..." : (msg.text ?? ""))
                        .font(.system(size: 13)).foregroundColor(.primary.opacity(0.7)).lineLimit(1)
                }
                Spacer()
                Button { chatService.clearReply() } label: {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(.primary.opacity(0.5))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color(.systemBackground))
            .overlay(Divider(), alignment: .top)
            .overlay(Divider().opacity(0.3), alignment: .bottom)
        }
    }

    private func spawnHearts(count: Int) {
        for _ in 0..<count {
            let heart = ChatHeartParticle(
                id: heartCounter,
                x: CGFloat.random(in: -140...140),
                y: 0,
                size: CGFloat.random(in: 10...26),
                opacity: Double.random(in: 0.3...0.7)
            )
            heartCounter += 1
            withAnimation(.easeOut(duration: 0.8)) {
                floatingHearts.append(heart)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            floatingHearts.removeAll()
        }
    }

    private func toggleRecording() {
        if audioService.isRecording {
            _ = audioService.stopRecording()
            chatService.sendVoiceNote(path: "voice_note")
        } else {
            audioService.startRecording()
        }
    }

    private func showAttachmentMenu() {
        // Placeholder - would use PHPickerViewController
    }
}

private struct ChatHeartParticle: Identifiable {
    let id: Int
    let x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let opacity: Double
}
