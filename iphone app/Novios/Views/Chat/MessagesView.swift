import SwiftUI

public struct MessagesView: View {
    @StateObject private var chatService = ChatService.shared
    @StateObject private var audioService = AudioService.shared
    @EnvironmentObject var authService: AuthService
    
    @State private var textInput = ""
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(chatService.messages) { msg in
                                    let isMe = msg.senderId == (authService.currentUser?.id ?? "user_me")
                                    ChatBubbleView(message: msg, isFromMe: isMe) { reaction in
                                        chatService.addReaction(to: msg.id, emoji: reaction)
                                    }
                                    .id(msg.id)
                                    .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .opacity))
                                }
                            }
                            .padding(.vertical, 14)
                        }
                        .onChange(of: chatService.messages.count) { _ in
                            if let last = chatService.messages.last {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Bar con diseño Glassmorphism
                    HStack(spacing: 12) {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            chatService.sendKissAction()
                        } label: {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                                .shadow(color: ThemeManager.shared.primaryPink.opacity(0.6), radius: 8)
                        }
                        
                        TextField("Escribe un mensaje de amor...", text: $textInput)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        
                        if textInput.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                if audioService.isRecording {
                                    _ = audioService.stopRecording()
                                    chatService.sendMessage(text: "🎙️ Nota de Voz (0:05)", type: .audio)
                                } else {
                                    audioService.startRecording()
                                }
                            } label: {
                                Image(systemName: audioService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(audioService.isRecording ? .red : ThemeManager.shared.primaryPink)
                            }
                        } else {
                            Button {
                                let trimmed = textInput.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    withAnimation(.spring()) {
                                        chatService.sendMessage(text: trimmed)
                                    }
                                    textInput = ""
                                }
                            } label: {
                                Image(systemName: "paperplane.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                    .shadow(color: ThemeManager.shared.primaryPink.opacity(0.6), radius: 8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Color(red: 0.1, green: 0.1, blue: 0.12)
                            .opacity(0.85)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle("Chat con mi Amor ❤️")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
