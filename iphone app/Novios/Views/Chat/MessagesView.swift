import SwiftUI
import PhotosUI

public struct MessagesView: View {
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var authService: AuthService
    @State private var textInput = ""
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showSettings = false

    private let emojis = ["❤️", "😘", "🥺", "💖", "💑", "🔥", "🌹", "✨", "💍"]

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(chatService.messages) { msg in
                                    let isMe = msg.senderId == (authService.currentUser?.id ?? FirebaseRESTService.shared.localId ?? "me")
                                    ChatBubbleView(message: msg, isFromMe: isMe, onReply: { chatService.setReplyTo(message: msg) }, onReact: { chatService.addReaction(to: msg.id, emoji: $0) })
                                        .id(msg.id)
                                }
                                Color.clear.frame(height: 4).id("bottom")
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                        }
                        .scrollIndicators(.hidden)
                        .onReceive(chatService.autoScrollToBottom) { _ in
                            withAnimation(.spring(duration: 0.45)) { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                        .onReceive(chatService.$messages) { msgs in
                            for msg in msgs where msg.readTimestamp == nil && msg.senderId != (authService.currentUser?.id ?? "me") {
                                chatService.markAsRead(messageId: msg.id)
                                break
                            }
                        }
                    }

                    emojiBar
                    inputBar
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                    chatService.sendImage(imageData: data); selectedPhotoItem = nil
                }
            }
        }
    }

    private var emojiBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(emojis, id: \.self) { e in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        chatService.sendMessage(text: e)
                    } label: {
                        Text(e).font(.system(size: 18))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.ultraThinMaterial.opacity(0.6))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
        }
        .frame(height: 42)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    @ViewBuilder
    private var inputBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if chatService.isRecording { _ = chatService.stopRecording() }
                    else { chatService.startRecording() }
                } label: {
                    ZStack {
                        if chatService.isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.red, lineWidth: 2).scaleEffect(1.3))
                                .overlay(Circle().fill(Color.red).frame(width: 10, height: 10))
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.ultraThinMaterial.opacity(0.6))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        showImagePicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }

                    TextField("Escribe un mensaje...", text: $textInput)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .tint(ThemeManager.shared.primaryPink)
                        .onSubmit { sendText() }

                    Button {
                        chatService.isShowingDisappearing.toggle()
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Image(systemName: "flame")
                            .font(.system(size: 16))
                            .foregroundColor(chatService.isShowingDisappearing ? .orange : .secondary.opacity(0.5))
                            .opacity(chatService.isShowingDisappearing ? 1 : 0.5)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.7))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))

                Button {
                    sendText()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(textInput.trimmingCharacters(in: .whitespaces).isEmpty
                            ? .gray.opacity(0.3) : ThemeManager.shared.primaryPink)
                }
                .disabled(textInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)

            if chatService.isRecording {
                recordingIndicator
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(.ultraThinMaterial.opacity(0.6))
        .overlay(alignment: .top) { Divider().opacity(0.3) }
    }

    private var recordingIndicator: some View {
        HStack(spacing: 10) {
            Circle().fill(Color.red).frame(width: 8, height: 8)
            Text("Grabando...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.red)
            Text(String(format: "%.1fs", chatService.recordingDuration))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .monospacedDigit()
            Spacer()
            Button {
                _ = chatService.stopRecording()
            } label: {
                Text("Enviar").font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(ThemeManager.shared.primaryPink).clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .padding(.horizontal, 10)
    }

    private func sendText() {
        let t = textInput.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        chatService.sendMessage(text: t)
        textInput = ""
    }
}
