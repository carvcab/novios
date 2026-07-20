import SwiftUI

public struct MessagesView: View {
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var authService: AuthService

    @State private var textInput = ""
    @State private var showAttachmentSheet = false
    @State private var floatingHearts: [ChatHeartParticle] = []

    private let theme = ThemeManager.shared
    private let quickEmojis = ["❤️", "😘", "🥺", "💖", "💑", "🔥", "🌹", "✨", "💍"]

    private var myId: String { authService.currentUser?.id ?? "user_me" }
    private var partnerName: String { UserService.shared.partnerUser?.displayName ?? "Mi Amor ❤️" }

    public var body: some View {
        VStack(spacing: 0) {
            messageList

            if chatService.isShowingDisappearing {
                disappearingBanner
            }

            if chatService.replyToMessage != nil {
                replyBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            quickEmojiBar

            inputBar
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Chat con mi Amor ❤️")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        withAnimation { chatService.isShowingDisappearing.toggle() }
                    } label: {
                        Image(systemName: chatService.isShowingDisappearing ? "timer.square.fill" : "timer")
                            .font(.system(size: 16))
                            .foregroundColor(chatService.isShowingDisappearing ? theme.primaryPink : theme.textSecondary)
                    }
                    if let partner = UserService.shared.partnerUser {
                        AsyncImage(url: URL(string: partner.avatarUrl ?? "")) { phase in
                            if let img = phase.image {
                                img.resizable()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(theme.primaryPink)
                            }
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    }
                }
            }
        }
        .overlay(floatingHeartsOverlay)
        .onChange(of: chatService.messages.count) { _ in
            chatService.autoScrollToBottom.send()
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(groupedMessages.indices, id: \.self) { sectionIndex in
                        let (date, msgs) = groupedMessages[sectionIndex]
                        dateSeparator(date: date)
                        ForEach(msgs.filter { $0.isVisible }) { msg in
                            let isMe = msg.senderId == myId
                            ChatBubbleView(
                                message: msg,
                                isFromMe: isMe,
                                onReaction: { emoji in
                                    chatService.addReaction(to: msg.id, emoji: emoji)
                                    let impact = UIImpactFeedbackGenerator(style: .soft)
                                    impact.impactOccurred()
                                },
                                onReply: {
                                    chatService.setReplyTo(message: msg)
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                },
                                onCopy: {
                                    if let text = msg.text {
                                        UIPasteboard.general.string = text
                                    }
                                }
                            )
                            .id(msg.id)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .onAppear {
                                if msg.senderId != myId && msg.readTimestamp == nil {
                                    chatService.markAsRead(messageId: msg.id)
                                }
                            }
                        }
                    }
                    Color.clear
                        .id("bottom_scroll")
                        .frame(height: 8)
                }
                .padding(.vertical, 8)
            }
            .onReceive(chatService.autoScrollToBottom) { _ in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    proxy.scrollTo("bottom_scroll", anchor: .bottom)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        proxy.scrollTo("bottom_scroll", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Date Separator

    private func dateSeparator(date: Date) -> some View {
        let text: String = {
            if Calendar.current.isDateInToday(date) { return "Hoy" }
            if Calendar.current.isDateInYesterday(date) { return "Ayer" }
            let fmt = DateFormatter()
            fmt.dateFormat = "dd/MM/yyyy"
            return fmt.string(from: date)
        }()
        return Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(theme.textSecondary.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.08))
            )
            .padding(.vertical, 6)
    }

    // MARK: - Disappearing Banner

    private var disappearingBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            Text("Mensajes que desaparecen")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.orange)
            Spacer()
            Button {
                withAnimation { chatService.isShowingDisappearing = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.08))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Reply Bar

    private var replyBar: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(theme.primaryPink)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(replySenderName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.primaryPink)
                    Spacer()
                    Button {
                        withAnimation { chatService.clearReply() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textSecondary.opacity(0.5))
                    }
                }
                if let replyText = chatService.replyToMessage?.text {
                    Text(replyText)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground.opacity(0.85))
    }

    private var replySenderName: String {
        guard let reply = chatService.replyToMessage else { return "" }
        return reply.senderId == myId ? "Tú" : partnerName
    }

    // MARK: - Quick Emoji Bar

    private var quickEmojiBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quickEmojis, id: \.self) { emoji in
                    Button {
                        textInput += emoji
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 22))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(theme.cardBackground.opacity(0.5))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                chatService.sendKissAction()
                spawnHearts(count: 5)
            } label: {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(theme.primaryPink)
                    .shadow(color: theme.primaryPink.opacity(0.5), radius: 6)
            }

            TextField("Escribe un mensaje de amor...", text: $textInput)
                .foregroundColor(.primary)
                .accentColor(theme.primaryPink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.gray.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            HStack(spacing: 8) {
                if textInput.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showAttachmentSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(theme.textSecondary)
                    }
                } else {
                    Button {
                        let trimmed = textInput.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        chatService.sendMessage(text: trimmed)
                        spawnHearts(count: 8)
                        textInput = ""
                    } label: {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(theme.primaryPink)
                            .shadow(color: theme.primaryPink.opacity(0.5), radius: 6)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            (theme.cardBackground)
                .opacity(0.92)
                .ignoresSafeArea(edges: .bottom)
        )
        .confirmationDialog("Adjuntar", isPresented: $showAttachmentSheet, titleVisibility: .visible) {
            Button("Galería") { chatService.sendMedia(url: "gallery_placeholder") }
            Button("Cámara") { chatService.sendMedia(url: "camera_placeholder") }
            Button("Nota de Voz") {
                chatService.sendVoiceNote(path: "voice_note_\(UUID().uuidString.prefix(6))")
            }
            Button("Regalo") { chatService.sendGift(giftId: "gift_rose") }
            Button("Carta") {
                let msg = MessageModel(
                    id: UUID().uuidString,
                    senderId: myId,
                    text: "Te escribí una carta...",
                    timestamp: Date(),
                    type: .letter,
                    letterTitle: "Para ti 💌"
                )
                chatService.messages.append(msg)
                chatService.autoScrollToBottom.send()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Floating Hearts

    private var floatingHeartsOverlay: some View {
        ZStack {
            ForEach(floatingHearts) { heart in
                Text(heart.emoji)
                    .font(.system(size: heart.size))
                    .opacity(heart.opacity)
                    .position(heart.position)
                    .animation(.easeOut(duration: heart.duration), value: heart.position)
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnHearts(count: Int) {
        let screenWidth = UIScreen.main.bounds.width
        for _ in 0..<count {
            let heart = ChatHeartParticle(
                id: UUID(),
                emoji: ["❤️", "💕", "💖", "🥰", "💗", "✨"].randomElement() ?? "❤️",
                position: CGPoint(
                    x: CGFloat.random(in: screenWidth * 0.2...screenWidth * 0.8),
                    y: UIScreen.main.bounds.height - 80
                ),
                opacity: 1.0,
                size: CGFloat.random(in: 20...40),
                duration: Double.random(in: 1.0...2.0)
            )
            floatingHearts.append(heart)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let idx = floatingHearts.firstIndex(where: { $0.id == heart.id }) {
                    withAnimation(.easeOut(duration: heart.duration)) {
                        floatingHearts[idx].position.y -= CGFloat.random(in: 200...400)
                        floatingHearts[idx].position.x += CGFloat.random(in: -40...40)
                        floatingHearts[idx].opacity = 0
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + heart.duration + 0.2) {
                floatingHearts.removeAll { $0.id == heart.id }
            }
        }
    }

    // MARK: - Helpers

    private var groupedMessages: [(Date, [MessageModel])] {
        let grouped = Dictionary(grouping: chatService.messages) { msg in
            Calendar.current.startOfDay(for: msg.timestamp)
        }
        return grouped.sorted { $0.key < $1.key }
    }

    private var backgroundGradient: some View {
        Group {
            if theme.isDarkMode {
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.04, blue: 0.04), Color(red: 0.08, green: 0.05, blue: 0.09)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.96, blue: 0.97), Color(red: 1.0, green: 0.94, blue: 0.96)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Heart Particle Model

private struct ChatHeartParticle: Identifiable {
    let id: UUID
    let emoji: String
    var position: CGPoint
    var opacity: Double
    let size: CGFloat
    let duration: Double
}

#Preview {
    NavigationStack {
        MessagesView()
            .environmentObject(AuthService.shared)
    }
}
