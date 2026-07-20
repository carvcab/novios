import SwiftUI
import PhotosUI

public struct MessagesView: View {
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var authService: AuthService
    @State private var textInput = ""
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let emojis = ["❤️", "😘", "🥺", "💖", "💑", "🔥", "🌹", "✨", "💍"]

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(chatService.messages) { msg in
                                let isMe = msg.senderId == (authService.currentUser?.id ?? FirebaseRESTService.shared.localId ?? "me")
                                ChatBubbleView(message: msg, isFromMe: isMe, onReply: { chatService.setReplyTo(message: msg) }, onReact: { chatService.addReaction(to: msg.id, emoji: $0) })
                                    .id(msg.id)
                            }
                            Color.clear.frame(height: 4).id("bottom")
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                    }
                    .onReceive(chatService.autoScrollToBottom) { _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onReceive(chatService.$messages) { msgs in
                        for msg in msgs where msg.readTimestamp == nil && msg.senderId != (authService.currentUser?.id ?? "me") {
                            chatService.markAsRead(messageId: msg.id)
                            break
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojis, id: \.self) { e in
                            Button {
                                chatService.sendMessage(text: e)
                            } label: {
                                Text(e).font(.system(size: 15)).padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(ThemeManager.shared.primaryPink.opacity(0.08)).cornerRadius(16)
                            }
                        }
                    }.padding(.horizontal, 12)
                }.frame(height: 38).background(Color(.systemBackground).opacity(0.5))

                HStack(spacing: 8) {
                    Button { chatService.isShowingDisappearing.toggle() } label: {
                        Image(systemName: "timer").font(.system(size: 20))
                            .foregroundColor(chatService.isShowingDisappearing ? .pink : .primary.opacity(0.3)) }
                    Button {
                        if chatService.isRecording { _ = chatService.stopRecording() }
                        else { chatService.startRecording() }
                    } label: {
                        Image(systemName: chatService.isRecording ? "stop.circle.fill" : "mic.fill").font(.system(size: 20))
                            .foregroundColor(chatService.isRecording ? .red : .primary.opacity(0.3)) }
                    Button { showImagePicker = true } label: {
                        Image(systemName: "plus.circle").font(.system(size: 20)).foregroundColor(.primary.opacity(0.3)) }
                    TextField("Escribe un mensaje...", text: $textInput)
                        .font(.system(size: 15)).foregroundColor(.primary)
                        .padding(.horizontal, 16).padding(.vertical, 10).background(Color(.systemGray6)).cornerRadius(24)
                    Button {
                        let t = textInput.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty { chatService.sendMessage(text: t); textInput = "" }
                    } label: {
                        Image(systemName: "paperplane.fill").font(.system(size: 16)).foregroundColor(.white)
                            .padding(12).background(ThemeManager.shared.primaryPink).clipShape(Circle()) }
                }
                .padding(.horizontal, 12).padding(.vertical, 8).background(Color(.systemBackground).opacity(0.3))
            }
            .navigationTitle("Chat").navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                    chatService.sendImage(imageData: data); selectedPhotoItem = nil
                }
            }
        }
    }
}
