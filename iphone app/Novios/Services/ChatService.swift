import Foundation
import Combine
import UIKit

public class ChatService: ObservableObject {
    public static let shared = ChatService()

    @Published public var messages: [MessageModel] = []
    @Published public var isRecording = false
    @Published public var isShowingDisappearing = false
    @Published public var replyToMessage: MessageModel?
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    public let didSendMessage = PassthroughSubject<Void, Never>()
    public let autoScrollToBottom = PassthroughSubject<Void, Never>()

    private var pollingTimer: Timer?
    private var lastFetchTime = Date(timeIntervalSince1970: 0)
    private var currentUserId: String { AuthService.shared.currentUser?.id ?? FirebaseRESTService.shared.localId ?? "me" }
    private var partnerId: String { UserDefaults.standard.string(forKey: "partner_uid") ?? "partner" }

    private init() {
        startPolling()
    }

    public func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.fetchNewMessages()
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func fetchNewMessages() {
        let partnerUid = partnerId
        guard !partnerUid.isEmpty, partnerUid != "partner" else { return }

        Task { @MainActor in
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
            let path = "couples/\(coupleId)/messages"

            guard let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "\(path)?orderBy=timestamp&pageSize=50"),
                  let documents = docs["documents"] as? [[String: Any]] else { return }

            var newMessages: [MessageModel] = []
            for doc in documents {
                guard let name = doc["name"] as? String,
                      let fields = doc["fields"] as? [String: Any],
                      let createTime = doc["createTime"] as? String else { continue }

                let msgId = name.split(separator: "/").last.map(String.init) ?? UUID().uuidString
                let senderId = (fields["senderId"] as? [String: Any])?["stringValue"] as? String ?? ""
                let text = (fields["text"] as? [String: Any])?["stringValue"] as? String ?? ""
                let typeRaw = (fields["type"] as? [String: Any])?["stringValue"] as? String ?? "text"
                let timestamp = ISO8601DateFormatter().date(from: createTime) ?? Date()

                let msg = MessageModel(id: msgId, senderId: senderId, text: text,
                    timestamp: timestamp, type: MessageType(rawValue: typeRaw) ?? .text,
                    isDisappearing: (fields["isDisappearing"] as? [String: Any])?["booleanValue"] as? Bool ?? false,
                    disappearDurationSeconds: Int((fields["disappearDurationSeconds"] as? [String: Any])?["integerValue"] as? String ?? "0") ?? 0)
                newMessages.append(msg)
            }

            let existingIds = Set(self.messages.map { $0.id })
            let uniqueNew = newMessages.filter { !existingIds.contains($0.id) }
            if !uniqueNew.isEmpty {
                self.messages.append(contentsOf: uniqueNew)
                self.messages.sort { $0.timestamp < $1.timestamp }
                self.autoScrollToBottom.send()
            }
        }
    }

    public func sendMessage(text: String) {
        Task { @MainActor in
            guard let myUid = FirebaseRESTService.shared.localId else {
                // Fallback local
                let msg = MessageModel(id: UUID().uuidString, senderId: currentUserId,
                    text: text, timestamp: Date(), type: isShowingDisappearing ? .disappearing : .text,
                    isDisappearing: isShowingDisappearing, disappearDurationSeconds: isShowingDisappearing ? 15 : 0,
                    replyToId: replyToMessage?.id, replyToText: replyToMessage?.text,
                    replyToSenderId: replyToMessage?.senderId)
                self.messages.append(msg)
                self.clearReply()
                self.didSendMessage.send()
                return
            }

            let partnerUid = partnerId
            let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
            let msgId = UUID().uuidString
            let path = "couples/\(coupleId)/messages"

            let fields: [String: Any] = [
                "id": msgId,
                "senderId": myUid,
                "text": text,
                "timestamp": Date(),
                "type": isShowingDisappearing ? "disappearing" : "text",
                "isDisappearing": isShowingDisappearing,
                "disappearDurationSeconds": isShowingDisappearing ? 15 : 0
            ]

            try? await FirebaseRESTService.shared.firestoreCreate(path: path, fields: fields)

            let msg = MessageModel(id: msgId, senderId: myUid, text: text, timestamp: Date(),
                type: isShowingDisappearing ? .disappearing : .text,
                isDisappearing: isShowingDisappearing, disappearDurationSeconds: isShowingDisappearing ? 15 : 0,
                replyToId: replyToMessage?.id, replyToText: replyToMessage?.text,
                replyToSenderId: replyToMessage?.senderId)
            self.messages.append(msg)
            self.clearReply()
            self.didSendMessage.send()
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    public func sendKissAction() {
        sendMessage(text: "💋")
    }

    public func sendHugAction() {
        sendMessage(text: "🤗")
    }

    public func sendTouchAction() {
        sendMessage(text: "✨")
    }

    public func sendGift(giftId: String) {
        Task { @MainActor in
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let partnerUid = partnerId
            let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
            let fields: [String: Any] = ["id": UUID().uuidString, "senderId": myUid,
                "text": "🎁 Te envié un regalo", "timestamp": Date(), "type": "gift", "giftId": giftId]
            try? await FirebaseRESTService.shared.firestoreCreate(path: "couples/\(coupleId)/messages", fields: fields)
        }
    }

    public func sendVoiceNote(path: String) {
        sendMessage(text: "🎙️ Nota de voz")
    }

    public func sendMedia(url: String) {
        sendMessage(text: "📸 \(url)")
    }

    public func addReaction(to messageId: String, emoji: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var msg = messages[idx]
        var reactions = msg.reactions ?? [:]
        if reactions[currentUserId] == emoji {
            reactions.removeValue(forKey: currentUserId)
        } else {
            reactions[currentUserId] = emoji
        }
        msg.reactions = reactions.isEmpty ? nil : reactions
        messages[idx] = msg
    }

    public func markAsRead(messageId: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[idx].readTimestamp = Date()
    }

    public func setReplyTo(message: MessageModel) { replyToMessage = message }
    public func clearReply() { replyToMessage = nil }
    public func startDisappearingMode() { isShowingDisappearing = true }
    public func stopDisappearingMode() { isShowingDisappearing = false }
    public func deleteExpiredMessages() { messages.removeAll { !$0.isVisible } }

    deinit { stopPolling() }
}
