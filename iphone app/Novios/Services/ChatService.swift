import Foundation
import Combine

public class ChatService: ObservableObject {
    public static let shared = ChatService()
    
    @Published public var messages: [MessageModel] = []
    
    private init() {
        loadInitialSampleMessages()
    }
    
    public func sendMessage(text: String, type: MessageType = .text, mediaUrl: String? = nil) {
        guard let myId = AuthService.shared.currentUser?.id else { return }
        let partnerId = UserService.shared.partnerUser?.id ?? "partner_sample_123"
        
        let newMsg = MessageModel(
            senderId: myId,
            receiverId: partnerId,
            text: text,
            mediaUrl: mediaUrl,
            type: type,
            timestamp: Date(),
            isRead: false
        )
        
        messages.append(newMsg)
    }
    
    public func sendKissAction() {
        sendMessage(text: "💋 ¡Te envié un beso virtual!", type: .kiss)
    }
    
    public func sendHugAction() {
        sendMessage(text: "🤗 ¡Te envié un abrazo apretado!", type: .hug)
    }
    
    public func sendTouchAction() {
        sendMessage(text: "✨ ¡Siente mi toque!", type: .touch)
    }
    
    public func addReaction(to messageId: String, emoji: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              let myId = AuthService.shared.currentUser?.id else { return }
        
        var currentReactions = messages[index].reactions ?? [:]
        currentReactions[myId] = emoji
        messages[index].reactions = currentReactions
    }
    
    private func loadInitialSampleMessages() {
        let sample1 = MessageModel(
            id: "msg_1",
            senderId: "partner_sample_123",
            receiverId: "user_me",
            text: "¡Hola mi amor! 💕 ¿Cómo va tu día?",
            type: .text,
            timestamp: Date().addingTimeInterval(-3600),
            reactions: ["user_me": "❤️"]
        )
        let sample2 = MessageModel(
            id: "msg_2",
            senderId: "user_me",
            receiverId: "partner_sample_123",
            text: "¡Hola cielo! Extrañándote mucho 🥰",
            type: .text,
            timestamp: Date().addingTimeInterval(-1800)
        )
        let sample3 = MessageModel(
            id: "msg_3",
            senderId: "partner_sample_123",
            receiverId: "user_me",
            text: "💋 ¡Te envié un beso virtual!",
            type: .kiss,
            timestamp: Date().addingTimeInterval(-600)
        )
        self.messages = [sample1, sample2, sample3]
    }
}
