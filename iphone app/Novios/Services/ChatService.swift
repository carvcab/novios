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
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?

    private var coupleId: String { "pareja_001" }
    private var myUid: String { AuthService.shared.currentUser?.id ?? (CoupleService.shared.currentUid) }

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
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private static func parseIsoDate(_ str: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: str) { return d }
        let f2 = ISO8601DateFormatter()
        if let d = f2.date(from: str) { return d }
        return nil
    }

    private func fetchMessages() {
        let path = "parejas/\(coupleId)/chat"
        Task { @MainActor in
            guard let documents = try? await FirebaseRESTService.shared.firestoreList(path: path), !documents.isEmpty else { return }

            for doc in documents {
                let f: [String: Any]
                let msgId: String
                let createTimeStr: String

                if let fields = doc["fields"] as? [String: Any], let name = doc["name"] as? String {
                    f = fields
                    msgId = name.split(separator: "/").last.map(String.init) ?? UUID().uuidString
                    createTimeStr = doc["createTime"] as? String ?? ""
                } else if let id = doc["id"] as? String {
                    f = doc
                    msgId = id
                    createTimeStr = doc["timestamp"] as? String ?? ""
                } else { continue }

                let s = { (k: String) -> String? in
                    if let v = f[k] as? String { return v }
                    if let dict = f[k] as? [String: Any] {
                        if let sv = dict["stringValue"] as? String { return sv }
                        if let tv = dict["timestampValue"] as? String { return tv }
                        if let iv = dict["integerValue"] as? String { return iv }
                    }
                    return nil
                }
                let b = { (k: String) -> Bool in
                    if let v = f[k] as? Bool { return v }
                    if let dict = f[k] as? [String: Any], let bv = dict["booleanValue"] as? Bool { return bv }
                    return false
                }

                let senderId = s("senderId") ?? ""
                let text = s("text") ?? ""
                let typeRaw = s("type") ?? "chat"
                let rawTs = s("timestamp") ?? createTimeStr
                let timestamp = Self.parseIsoDate(rawTs) ?? Date()

                let mediaUrl = s("mediaUrl")
                let isDisappearing = b("isDisappearing")
                let disappearDuration = s("disappearDurationSeconds") ?? s("disappearDuration")
                let readTsStr = s("readTimestamp")
                let readTs = readTsStr.flatMap { Self.parseIsoDate($0) }

                if let idx = messages.firstIndex(where: { $0.id == msgId }) {
                    if messages[idx].readTimestamp != readTs { messages[idx].readTimestamp = readTs }
                    continue
                }

                let replyToId = s("replyToId")
                let replyToText = s("replyToText")
                let replyToSenderId = s("replyToSenderId")

                let msgType: MessageType
                switch typeRaw {
                case "chat","text": msgType = .text
                case "voice": msgType = .voice
                case "image","photo": msgType = .image
                case "video": msgType = .video
                case "gift": msgType = .gift
                case "letter": msgType = .letter
                default: msgType = .text
                }

                let msg = MessageModel(
                    id: msgId,
                    senderId: senderId,
                    text: text,
                    timestamp: timestamp,
                    type: msgType,
                    isDisappearing: isDisappearing,
                    disappearDurationSeconds: Int(disappearDuration ?? "0") ?? 0,
                    readTimestamp: readTs,
                    mediaUrl: mediaUrl,
                    replyToId: replyToId,
                    replyToText: replyToText,
                    replyToSenderId: replyToSenderId
                )
                messages.append(msg)
            }
            messages.sort { $0.timestamp < $1.timestamp }
            autoScrollToBottom.send()
        }
    }

    public func sendMessage(text: String) {
        let msgId = UUID().uuidString

        let msg = MessageModel(
            id: msgId,
            senderId: myUid,
            text: text,
            timestamp: Date(),
            type: isShowingDisappearing ? .disappearing : .text,
            isDisappearing: isShowingDisappearing,
            disappearDurationSeconds: isShowingDisappearing ? 15 : 0,
            replyToId: replyToMessage?.id,
            replyToText: replyToMessage?.text,
            replyToSenderId: replyToMessage?.senderId
        )
        messages.append(msg)
        clearReply()
        didSendMessage.send()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        saveMessage(msg: msg)
    }

    private func saveMessage(msg: MessageModel) {
        let path = "parejas/\(coupleId)/chat/\(msg.id)"

        var fields: [String: Any] = [
            "id": msg.id,
            "senderId": msg.senderId,
            "text": msg.text ?? "",
            "timestamp": msg.timestamp, // Passed as Date to convert to timestampValue in Firestore
            "type": msg.type == .text ? "chat" : msg.type.rawValue,
            "isDisappearing": msg.isDisappearing,
            "disappearDurationSeconds": msg.disappearDurationSeconds
        ]
        if let rid = msg.replyToId { fields["replyToId"] = rid }
        if let rt = msg.replyToText { fields["replyToText"] = rt }
        if let rs = msg.replyToSenderId { fields["replyToSenderId"] = rs }
        if let mu = msg.mediaUrl { fields["mediaUrl"] = mu }
        if let rt = msg.readTimestamp { fields["readTimestamp"] = rt }

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: fields)
        }
    }

    public func markAsRead(messageId: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let now = Date()
        messages[idx].readTimestamp = now
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(coupleId)/chat/\(messageId)", fields: ["readTimestamp": now])
        }
    }

    public func addReaction(to messageId: String, emoji: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var reactions = messages[idx].reactions ?? [:]
        if reactions[myUid] == emoji { reactions.removeValue(forKey: myUid) }
        else { reactions[myUid] = emoji }
        messages[idx].reactions = reactions.isEmpty ? nil : reactions
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(coupleId)/chat/\(messageId)", fields: ["reactions": reactions])
        }
    }

    public func sendImage(imageData: Data) {
        let msgId = UUID().uuidString
        let compressed = Self.compressImage(imageData)
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(coupleId)/chat/fotos/\(msgId)", fields: [
                "data": compressed.base64EncodedString(),
                "mimeType": "image/jpeg",
                "timestamp": Date()
            ])
            let msg = MessageModel(id: msgId, senderId: myUid, text: "Foto", timestamp: Date(), type: .image, mediaUrl: "firestore://parejas/\(coupleId)/chat/fotos/\(msgId)")
            await MainActor.run { self.messages.append(msg); self.didSendMessage.send() }
            self.saveMessage(msg: msg)
        }
    }

    private static func compressImage(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        if data.count < 500_000 { return data }
        let maxSize: CGFloat = 1024
        var newSize = image.size
        if newSize.width > maxSize || newSize.height > maxSize {
            if newSize.width > newSize.height { newSize = CGSize(width: maxSize, height: maxSize * newSize.height / newSize.width) }
            else { newSize = CGSize(width: maxSize * newSize.width / newSize.height, height: maxSize) }
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let resizedImg = resized else { return data }
        return resizedImg.jpegData(compressionQuality: 0.6) ?? data
    }

    public func sendVoiceNote(audioData: Data) {
        let msgId = UUID().uuidString
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(coupleId)/chat/audio/\(msgId)", fields: [
                "data": audioData.base64EncodedString(),
                "mimeType": "audio/m4a",
                "timestamp": Date()
            ])
            let msg = MessageModel(id: msgId, senderId: myUid, text: "Nota de voz", timestamp: Date(), type: .voice, mediaUrl: "firestore://parejas/\(coupleId)/chat/audio/\(msgId)")
            await MainActor.run { self.messages.append(msg); self.didSendMessage.send() }
            self.saveMessage(msg: msg)
        }
    }

    public func setReplyTo(message: MessageModel) { replyToMessage = message }
    public func clearReply() { replyToMessage = nil }
    public func sendKissAction() { sendMessage(text: "💋") }
    public func sendHugAction() { sendMessage(text: "🤗") }

    public func startRecording() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .denied: return
        case .undetermined: AVAudioSession.sharedInstance().requestRecordPermission { granted in if granted { DispatchQueue.main.async { self.startRecording() } } }; return
        case .granted: break
        @unknown default: return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("voice_\(Date().timeIntervalSince1970).m4a")
            audioRecorder = try AVAudioRecorder(url: url, settings: [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0 }
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
