import Foundation
import Combine
import UIKit
import AVFoundation

public class ChatService: ObservableObject {
    public static let shared = ChatService()

    @Published public var messages: [MessageModel] = []
    @Published public var isRecording = false
    @Published public var isShowingDisappearing = false
    @Published public var replyToMessage: MessageModel?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var recordingDuration: TimeInterval = 0

    public let didSendMessage = PassthroughSubject<Void, Never>()
    public let autoScrollToBottom = PassthroughSubject<Void, Never>()

    private var pollingTimer: Timer?
    private var sentLocalIds = Set<String>()
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var currentUserId: String { AuthService.shared.currentUser?.id ?? FirebaseRESTService.shared.localId ?? "me" }
    private var partnerId: String { UserDefaults.standard.string(forKey: "partner_uid") ?? "partner" }

    private init() { startPolling() }

    public func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.fetchNewMessages()
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate(); pollingTimer = nil
    }

    private func fetchNewMessages() {
        guard let myUid = FirebaseRESTService.shared.localId else { return }
        let partnerUid = partnerId
        guard partnerUid != "partner" else { return }
        let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
        let path = "couples/\(coupleId)/messages?pageSize=100"

        Task { @MainActor in
            guard let docs = try? await FirebaseRESTService.shared.firestoreGet(path: path),
                  let documents = (docs["documents"] as? [[String: Any]]) else { return }

            var newMessages: [MessageModel] = []
            let existingIds = Set(self.messages.map { $0.id })

            for doc in documents {
                guard let name = doc["name"] as? String,
                      let fields = doc["fields"] as? [String: Any],
                      let createTime = doc["createTime"] as? String else { continue }

                let msgId = name.split(separator: "/").last.map(String.init) ?? UUID().uuidString
                if existingIds.contains(msgId) || sentLocalIds.contains(msgId) { continue }

                let senderId = (fields["senderId"] as? [String: Any])?["stringValue"] as? String ?? ""
                let text = (fields["text"] as? [String: Any])?["stringValue"] as? String ?? ""
                let typeRaw = (fields["type"] as? [String: Any])?["stringValue"] as? String ?? "text"
                let timestamp = ISO8601DateFormatter().date(from: createTime) ?? Date()
                let mediaUrl = (fields["mediaUrl"] as? [String: Any])?["stringValue"] as? String
                let readTS = (fields["readTimestamp"] as? [String: Any])?["stringValue"] as? String
                let readDate = readTS.flatMap { ISO8601DateFormatter().date(from: $0) }

                let msg = MessageModel(id: msgId, senderId: senderId, text: text,
                    timestamp: timestamp, type: MessageType(rawValue: typeRaw) ?? .text,
                    isDisappearing: (fields["isDisappearing"] as? [String: Any])?["booleanValue"] as? Bool ?? false,
                    disappearDurationSeconds: Int((fields["disappearDurationSeconds"] as? [String: Any])?["integerValue"] as? String ?? "0") ?? 0,
                    readTimestamp: readDate, mediaUrl: mediaUrl)
                newMessages.append(msg)
            }

            if !newMessages.isEmpty {
                self.messages.append(contentsOf: newMessages)
                self.messages.sort { $0.timestamp < $1.timestamp }
                self.autoScrollToBottom.send()
            }
        }
    }

    public func sendMessage(text: String) {
        Task { @MainActor in
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let partnerUid = partnerId
            let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
            let msgId = "\(myUid)_\(Date().timeIntervalSince1970)"
            let path = "couples/\(coupleId)/messages"

            sentLocalIds.insert(msgId)
            let fields: [String: Any] = ["senderId": myUid, "text": text, "timestamp": Date(),
                "type": isShowingDisappearing ? "disappearing" : "text",
                "isDisappearing": isShowingDisappearing, "disappearDurationSeconds": isShowingDisappearing ? 15 : 0]
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

    public func sendImage(imageData: Data) {
        Task { @MainActor in
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let partnerUid = partnerId
            let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
            let msgId = "\(myUid)_\(Date().timeIntervalSince1970)"

            let b64 = imageData.base64EncodedString()
            sentLocalIds.insert(msgId)

            // Store image in Firestore as base64
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "pairs/\(coupleId)/photos/\(msgId)",
                fields: ["data": b64, "timestamp": Date()])

            let mediaUrl = "firestore://pairs/\(coupleId)/photos/\(msgId)"
            let fields: [String: Any] = ["senderId": myUid, "text": "📷 Foto", "timestamp": Date(),
                "type": "image", "mediaUrl": mediaUrl]
            try? await FirebaseRESTService.shared.firestoreCreate(
                path: "couples/\(coupleId)/messages", fields: fields)

            let msg = MessageModel(id: msgId, senderId: myUid, text: "📷 Foto", timestamp: Date(),
                type: .image, mediaUrl: mediaUrl)
            self.messages.append(msg)
            self.didSendMessage.send()
        }
    }

    public func sendVoiceNote(audioData: Data) {
        Task { @MainActor in
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let partnerUid = partnerId
            let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")
            let msgId = "\(myUid)_\(Date().timeIntervalSince1970)"

            let b64 = audioData.base64EncodedString()
            sentLocalIds.insert(msgId)

            try? await FirebaseRESTService.shared.firestoreSet(
                path: "pairs/\(coupleId)/audio/\(msgId)",
                fields: ["data": b64, "timestamp": Date()])

            let mediaUrl = "firestore://pairs/\(coupleId)/audio/\(msgId)"
            let fields: [String: Any] = ["senderId": myUid, "text": "🎤 Nota de voz",
                "timestamp": Date(), "type": "voice", "mediaUrl": mediaUrl,
                "voiceNotePath": mediaUrl]
            try? await FirebaseRESTService.shared.firestoreCreate(
                path: "couples/\(coupleId)/messages", fields: fields)

            let msg = MessageModel(id: msgId, senderId: myUid, text: "🎤 Nota de voz",
                timestamp: Date(), type: .voice, mediaUrl: mediaUrl)
            self.messages.append(msg)
            self.didSendMessage.send()
        }
    }

    public func markAsRead(messageId: String) {
        Task { @MainActor in
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let partnerUid = partnerId
            let coupleId = [myUid, partnerUid].sorted().joined(separator: "_")

            // Update local
            if let idx = self.messages.firstIndex(where: { $0.id == messageId }) {
                self.messages[idx].readTimestamp = Date()
            }

            // Update Firestore
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "couples/\(coupleId)/messages/\(messageId)",
                fields: ["readTimestamp": Date()])
        }
    }

    // MARK: - Voice Recording

    public func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default)
        try? audioSession.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(Date().timeIntervalSince1970).m4a")
        audioRecorder = try? AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        isRecording = true
        recordingDuration = 0

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let recorder = self?.audioRecorder else { return }
            self?.recordingDuration = recorder.currentTime
        }
    }

    public func stopRecording() -> Data? {
        recordingTimer?.invalidate(); recordingTimer = nil
        audioRecorder?.stop()
        isRecording = false
        guard let url = audioRecorder?.url, let data = try? Data(contentsOf: url) else { return nil }
        sendVoiceNote(audioData: data)
        return data
    }

    // MARK: - Other actions

    public func sendKissAction() { sendMessage(text: "💋") }
    public func sendHugAction() { sendMessage(text: "🤗") }
    public func sendTouchAction() { sendMessage(text: "✨") }

    public func sendGift(giftId: String) { sendMessage(text: "🎁 Regalo") }
    public func sendMedia(url: String) { sendMessage(text: "📸 \(url)") }

    public func addReaction(to messageId: String, emoji: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var msg = messages[idx]
        var reactions = msg.reactions ?? [:]
        if reactions[currentUserId] == emoji { reactions.removeValue(forKey: currentUserId) }
        else { reactions[currentUserId] = emoji }
        msg.reactions = reactions.isEmpty ? nil : reactions
        messages[idx] = msg
    }

    public func setReplyTo(message: MessageModel) { replyToMessage = message }
    public func clearReply() { replyToMessage = nil }
    public func startDisappearingMode() { isShowingDisappearing = true }
    public func stopDisappearingMode() { isShowingDisappearing = false }
    public func deleteExpiredMessages() { messages.removeAll { !$0.isVisible } }

    deinit { stopPolling() }
}
