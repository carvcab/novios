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

    private var myUid: String { FirebaseRESTService.shared.localId ?? AuthService.shared.currentUser?.id ?? "me" }
    private var partnerUid: String { UserDefaults.standard.string(forKey: "partner_uid") ?? "" }
    private var coupleId: String {
        let ids = [myUid, partnerUid].sorted().joined(separator: "_")
        return ids
    }

    override public init() {
        super.init()
        loadLocalMessages()
        startPolling()
    }

    // MARK: - Local Storage

    private func saveLocalMessages() {
        let data = messages.map { $0.text ?? "" }
        UserDefaults.standard.set(data, forKey: "local_messages_text")
        let ids = messages.map { $0.id }
        UserDefaults.standard.set(ids, forKey: "local_messages_ids")
    }

    private func loadLocalMessages() {
        guard let texts = UserDefaults.standard.array(forKey: "local_messages_text") as? [String],
              let ids = UserDefaults.standard.array(forKey: "local_messages_ids") as? [String],
              texts.count == ids.count else { return }
        for i in 0..<ids.count {
            let msg = MessageModel(id: ids[i], senderId: "", text: texts[i], timestamp: Date(), type: .text)
            if !messages.contains(where: { $0.id == msg.id }) {
                messages.append(msg)
            }
        }
    }

    // MARK: - Polling

    public func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.fetchMessages()
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func fetchMessages() {
        guard !partnerUid.isEmpty, partnerUid != "partner" else { return }

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

                let msg = MessageModel(id: msgId, senderId: senderId, text: text, timestamp: timestamp,
                    type: MessageType(rawValue: typeRaw) ?? .text)
                messages.append(msg)
                newFound = true
            }

            if newFound {
                messages.sort { $0.timestamp < $1.timestamp }
                saveLocalMessages()
                autoScrollToBottom.send()
            }
        }
    }

    // MARK: - Send Message

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
        saveLocalMessages()

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Send to Firestore
        guard !partnerUid.isEmpty, partnerUid != "partner" else { return }
        let path = "couples/\(coupleId)/messages/\(msgId)"
        let fields: [String: Any] = ["senderId": myUid, "text": text, "timestamp": Date().timeIntervalSince1970,
            "type": isShowingDisappearing ? "disappearing" : "text",
            "isDisappearing": isShowingDisappearing, "disappearDurationSeconds": isShowingDisappearing ? 15 : 0]

        Task {
            do {
                try await FirebaseRESTService.shared.firestoreSet(path: path, fields: fields)
            } catch {
                print("[Chat] send error: \(error)")
            }
        }
    }

    public func sendImage(imageData: Data) {
        let msgId = UUID().uuidString
        sentIds.insert(msgId)

        let b64 = imageData.base64EncodedString()
        let couple = coupleId
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "pairs/\(couple)/photos/\(msgId)",
                fields: ["data": b64, "timestamp": Date().timeIntervalSince1970])
            let mediaUrl = "firestore://pairs/\(couple)/photos/\(msgId)"
            let path = "couples/\(couple)/messages/\(msgId)"
            try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: [
                "senderId": myUid, "text": "📷 Foto", "timestamp": Date().timeIntervalSince1970,
                "type": "image", "mediaUrl": mediaUrl])
        }
        let msg = MessageModel(id: msgId, senderId: myUid, text: "📷 Foto", timestamp: Date(), type: .image)
        messages.append(msg)
        didSendMessage.send()
    }

    public func sendVoiceNote(audioData: Data) {
        let msgId = UUID().uuidString
        sentIds.insert(msgId)

        let b64 = audioData.base64EncodedString()
        let couple = coupleId
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "pairs/\(couple)/audio/\(msgId)",
                fields: ["data": b64, "timestamp": Date().timeIntervalSince1970])
            let mediaUrl = "firestore://pairs/\(couple)/audio/\(msgId)"
            let path = "couples/\(couple)/messages/\(msgId)"
            try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: [
                "senderId": myUid, "text": "🎤 Nota de voz", "timestamp": Date().timeIntervalSince1970,
                "type": "voice", "mediaUrl": mediaUrl, "voiceNotePath": mediaUrl])
        }
        let msg = MessageModel(id: msgId, senderId: myUid, text: "🎤 Nota de voz", timestamp: Date(), type: .voice)
        messages.append(msg)
        didSendMessage.send()
    }

    public func markAsRead(messageId: String) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            messages[idx].readTimestamp = Date()
        }
        guard !partnerUid.isEmpty, partnerUid != "partner" else { return }
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "couples/\(coupleId)/messages/\(messageId)",
                fields: ["readTimestamp": Date().timeIntervalSince1970])
        }
    }

    public func addReaction(to messageId: String, emoji: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var msg = messages[idx]
        var reactions = msg.reactions ?? [:]
        if reactions[myUid] == emoji { reactions.removeValue(forKey: myUid) }
        else { reactions[myUid] = emoji }
        msg.reactions = reactions.isEmpty ? nil : reactions
        messages[idx] = msg
    }

    public func setReplyTo(message: MessageModel) { replyToMessage = message }
    public func clearReply() { replyToMessage = nil }
    public func startDisappearingMode() { isShowingDisappearing = true }
    public func stopDisappearingMode() { isShowingDisappearing = false }

    // MARK: - Recording

    public func startRecording() {
        guard AVAudioSession.sharedInstance().recordPermission == .granted else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("voice_\(Date().timeIntervalSince1970).m4a")
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
            }
        } catch {
            print("[Chat] record error: \(error)")
        }
    }

    public func stopRecording() -> Data? {
        recordingTimer?.invalidate()
        audioRecorder?.stop()
        isRecording = false
        guard let url = audioRecorder?.url, let data = try? Data(contentsOf: url) else { return nil }
        sendVoiceNote(audioData: data)
        return data
    }

    deinit { stopPolling() }
}
