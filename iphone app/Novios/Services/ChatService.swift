import Foundation
import Combine
import UIKit
import AVFoundation

public class ChatService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    public static let shared = ChatService()

    @Published public var messages: [MessageModel] = []
    @Published public var isRecording = false
    @Published public var isShowingDisappearing = false
    @Published public var replyToMessage: MessageModel?
    @Published public var recordingDuration: TimeInterval = 0

    public let didSendMessage = PassthroughSubject<Void, Never>()
    public let autoScrollToBottom = PassthroughSubject<Void, Never>()

    private var pollingTimer: Timer?
    private var sentIds = Set<String>()
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?

    private var myUid: String { AuthService.shared.currentUser?.id ?? FirebaseRESTService.shared.localId ?? "me" }
    private var partnerUid: String { UserDefaults.standard.string(forKey: "partner_uid") ?? "" }
    private var coupleId: String { [myUid, partnerUid].sorted().joined(separator: "_") }

    override public init() {
        super.init()
        startPolling()
    }

    public func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.fetchMessages()
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate(); pollingTimer = nil
    }

    private func fetchMessages() {
        let puid = partnerUid
        guard !puid.isEmpty, puid != "partner" else { return }

        Task { @MainActor in
            guard let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "couples/\(coupleId)/messages?pageSize=100"),
                  let documents = (docs["documents"] as? [[String: Any]]) else { return }

            var newFound = false
            for doc in documents {
                guard let name = doc["name"] as? String,
                      let fields = doc["fields"] as? [String: Any] else { continue }
                let msgId = name.split(separator: "/").last.map(String.init) ?? UUID().uuidString
                if messages.contains(where: { $0.id == msgId }) || sentIds.contains(msgId) { continue }

                let senderId = (fields["senderId"] as? [String: Any])?["stringValue"] as? String ?? ""
                let text = (fields["text"] as? [String: Any])?["stringValue"] as? String ?? ""
                let typeRaw = (fields["type"] as? [String: Any])?["stringValue"] as? String ?? "text"
                let timestamp = ISO8601DateFormatter().date(from: doc["createTime"] as? String ?? "") ?? Date()
                let mediaUrl = (fields["mediaUrl"] as? [String: Any])?["stringValue"] as? String

                let msg = MessageModel(id: msgId, senderId: senderId, text: text, timestamp: timestamp,
                    type: MessageType(rawValue: typeRaw) ?? .text, mediaUrl: mediaUrl)
                messages.append(msg)
                newFound = true
            }
            if newFound {
                messages.sort { $0.timestamp < $1.timestamp }
                autoScrollToBottom.send()
            }
        }
    }

    public func sendMessage(text: String) {
        let msgId = UUID().uuidString
        sentIds.insert(msgId)

        let localMsg = MessageModel(id: msgId, senderId: myUid, text: text, timestamp: Date(),
            type: isShowingDisappearing ? .disappearing : .text,
            isDisappearing: isShowingDisappearing, disappearDurationSeconds: isShowingDisappearing ? 15 : 0,
            replyToId: replyToMessage?.id, replyToText: replyToMessage?.text,
            replyToSenderId: replyToMessage?.senderId)
        messages.append(localMsg)
        clearReply()
        didSendMessage.send()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let puid = partnerUid
        guard !puid.isEmpty, puid != "partner" else { return }
        let path = "couples/\(coupleId)/messages/\(msgId)"
        let fields: [String: Any] = ["senderId": myUid, "text": text,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "type": isShowingDisappearing ? "disappearing" : "text"]

        Task { try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: fields) }
    }

    public func sendImage(imageData: Data) {
        let msgId = UUID().uuidString; sentIds.insert(msgId)
        let couple = coupleId
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "pairs/\(couple)/photos/\(msgId)",
                fields: ["data": imageData.base64EncodedString(), "timestamp": ISO8601DateFormatter().string(from: Date())])
            try? await FirebaseRESTService.shared.firestoreSet(path: "couples/\(couple)/messages/\(msgId)", fields: [
                "senderId": myUid, "text": "📷 Foto", "type": "image",
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "mediaUrl": "firestore://pairs/\(couple)/photos/\(msgId)"])
        }
        messages.append(MessageModel(id: msgId, senderId: myUid, text: "📷 Foto", timestamp: Date(), type: .image))
        didSendMessage.send()
    }

    public func sendVoiceNote(audioData: Data) {
        let msgId = UUID().uuidString; sentIds.insert(msgId)
        let couple = coupleId
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "pairs/\(couple)/audio/\(msgId)",
                fields: ["data": audioData.base64EncodedString(), "timestamp": ISO8601DateFormatter().string(from: Date())])
            try? await FirebaseRESTService.shared.firestoreSet(path: "couples/\(couple)/messages/\(msgId)", fields: [
                "senderId": myUid, "text": "🎤 Nota de voz", "type": "voice",
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "mediaUrl": "firestore://pairs/\(couple)/audio/\(msgId)"])
        }
        messages.append(MessageModel(id: msgId, senderId: myUid, text: "🎤 Nota de voz", timestamp: Date(), type: .voice))
        didSendMessage.send()
    }

    public func markAsRead(messageId: String) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].readTimestamp = Date()
        }
        Task { try? await FirebaseRESTService.shared.firestoreSet(
            path: "couples/\(coupleId)/messages/\(messageId)",
            fields: ["readTimestamp": ISO8601DateFormatter().string(from: Date())]) }
    }

    public func addReaction(to messageId: String, emoji: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var reactions = messages[idx].reactions ?? [:]
        if reactions[myUid] == emoji { reactions.removeValue(forKey: myUid) }
        else { reactions[myUid] = emoji }
        messages[idx].reactions = reactions.isEmpty ? nil : reactions
    }

    public func setReplyTo(message: MessageModel) { replyToMessage = message }
    public func clearReply() { replyToMessage = nil }

    public func startRecording() {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("voice_\(Date().timeIntervalSince1970).m4a")
            audioRecorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0 }
        } catch { print("[Chat] record error: \(error)") }
    }

    public func stopRecording() -> Data? {
        recordingTimer?.invalidate(); audioRecorder?.stop(); isRecording = false
        guard let url = audioRecorder?.url, let data = try? Data(contentsOf: url) else { return nil }
        sendVoiceNote(audioData: data)
        return data
    }

    deinit { stopPolling() }
}
