import SwiftUI
import PhotosUI

public struct MessagesView: View {
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var authService: AuthService
    @State private var textInput = ""
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var floatingHearts: [HeartP] = []
    @State private var heartId = 0

    private let emojis = ["❤️", "😘", "🥺", "💖", "💑", "🔥", "🌹", "✨", "💍"]

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(chatService.messages.reversed()) { msg in
                                let isMe = msg.senderId == (authService.currentUser?.id ?? FirebaseRESTService.shared.localId ?? "me")
                                BubbleView(msg: msg, isMe: isMe, chatService: chatService)
                                    .id(msg.id)
                            }
                            Color.clear.frame(height: 4).id("bottom")
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                    }
                    .onReceive(chatService.autoScrollToBottom) { _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                // Emoji bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojis, id: \.self) { e in
                            Button {
                                chatService.sendMessage(text: e)
                                spawnHearts(25)
                            } label: {
                                Text(e).font(.system(size: 15)).padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(ThemeManager.shared.primaryPink.opacity(0.08)).cornerRadius(16)
                            }
                        }
                    }.padding(.horizontal, 12)
                }.frame(height: 38).background(Color(.systemBackground).opacity(0.5))

                // Input
                HStack(spacing: 8) {
                    Button { chatService.isShowingDisappearing.toggle() } label: {
                        Image(systemName: "timer").font(.system(size: 20))
                            .foregroundColor(chatService.isShowingDisappearing ? .pink : .primary.opacity(0.3))
                    }
                    Button {
                        if chatService.isRecording { _ = chatService.stopRecording() }
                        else { chatService.startRecording() }
                    } label: {
                        Image(systemName: chatService.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(chatService.isRecording ? .red : .primary.opacity(0.3))
                    }
                    Button { showImagePicker = true } label: {
                        Image(systemName: "plus.circle").font(.system(size: 20)).foregroundColor(.primary.opacity(0.3))
                    }
                    TextField("Escribe un mensaje...", text: $textInput)
                        .font(.system(size: 15)).foregroundColor(.primary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color(.systemGray6)).cornerRadius(24)
                    Button {
                        let t = textInput.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty {
                            chatService.sendMessage(text: t)
                            textInput = ""
                            let special = t.contains("❤️") || t.contains("😘") || t.lowercased().contains("te amo")
                            spawnHearts(special ? 30 : 6)
                        }
                    } label: {
                        Image(systemName: "paperplane.fill").font(.system(size: 16)).foregroundColor(.white)
                            .padding(12).background(ThemeManager.shared.primaryPink).clipShape(Circle())
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.3))
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
                    chatService.sendImage(imageData: data)
                    selectedPhotoItem = nil
                }
            }
        }
    }

    private func spawnHearts(_ count: Int) {
        for _ in 0..<count {
            let h = HeartP(id: heartId, x: .random(in: -140...140), size: .random(in: 10...26), op: .random(in: 0.3...0.7))
            heartId += 1
            floatingHearts.append(h)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { floatingHearts.removeAll() }
    }
}

private struct HeartP: Identifiable {
    let id: Int; let x: CGFloat; let size: CGFloat; let op: Double
}

private struct BubbleView: View {
    let msg: MessageModel
    let isMe: Bool
    let chatService: ChatService
    @State private var showMenu = false
    @State private var loadedImage: UIImage?

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 60) }
            VStack(alignment: .leading, spacing: 2) {
                if msg.type == .image || msg.type == .video {
                    mediaContent
                } else if msg.type == .voice {
                    voiceContent
                } else {
                    Text(msg.text ?? "").font(.system(size: 15)).foregroundColor(.primary).lineSpacing(3)
                }
                HStack(spacing: 5) {
                    Text(msg.timestamp, style: .time).font(.system(size: 10)).foregroundColor(.secondary)
                    if isMe {
                        Image(systemName: msg.readTimestamp != nil ? "heart.fill" : "heart")
                            .font(.system(size: 10)).foregroundColor(msg.readTimestamp != nil ? .pink : .secondary)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(isMe ? ThemeManager.shared.primaryPink.opacity(0.15) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isMe ? .trailing : .leading)
            if !isMe { Spacer(minLength: 60) }
        }
        .padding(.vertical, 2)
        .onLongPressGesture { showMenu = true }
        .sheet(isPresented: $showMenu) {
            VStack(spacing: 12) {
                Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 4).padding(.top, 8)
                Text("Reacciones").font(.system(size: 14, weight: .semibold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(["❤️","😘","😂","😮","😢","🔥","💖","👍","👎"], id: \.self) { e in
                        Button { chatService.addReaction(to: msg.id, emoji: e); showMenu = false } label: {
                            Text(e).font(.system(size: 28)).padding(6).background(Color.pink.opacity(0.08)).cornerRadius(12)
                        }
                    }
                }.padding(.horizontal, 20)
                Divider()
                Button { chatService.setReplyTo(message: msg); showMenu = false } label: {
                    HStack { Image(systemName: "arrowshape.turn.up.left").foregroundColor(.pink)
                        Text("Responder").foregroundColor(.primary); Spacer() }.padding(.horizontal, 20)
                }
                Spacer().frame(height: 20)
            }.presentationDetents([.height(280)])
        }
        .task(id: msg.id) { await loadImage() }
    }

    private func loadImage() async {
        guard let url = msg.mediaUrl, url.hasPrefix("firestore://"), msg.type == .image else { return }
        let path = url.replacingOccurrences(of: "firestore://", with: "")
        guard let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
              let fields = doc["fields"] as? [String: Any],
              let b64 = (fields["data"] as? [String: Any])?["stringValue"] as? String,
              let data = Data(base64Encoded: b64) else { return }
        await MainActor.run { loadedImage = UIImage(data: data) }
    }

    private var mediaContent: some View {
        Group {
            if let img = loadedImage {
                Image(uiImage: img).resizable().scaledToFill().frame(width: 160, height: 160).cornerRadius(12).clipped()
            } else {
                ProgressView().frame(width: 160, height: 160)
            }
        }
    }

    private var voiceContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.fill").font(.system(size: 12)).foregroundColor(ThemeManager.shared.primaryPink)
                .padding(6).background(ThemeManager.shared.primaryPink.opacity(0.1)).clipShape(Circle())
            Text("Nota de voz").font(.system(size: 12)).foregroundColor(.primary)
        }
    }
}
