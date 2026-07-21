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
    private var myName: String { AuthService.shared.currentUser?.displayName ?? UserDefaults.standard.string(forKey: "auth_user_name") ?? "Tu pareja" }
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
            guard let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "couples/\(coupleId)/messages"),
                  let documents = (docs["documents"] as? [[String: Any]]) else { return }

            for doc in documents {
                guard let name = doc["name"] as? String,
                      let fields = doc["fields"] as? [String: Any] else { continue }
                let msgId = name.split(separator: "/").last.map(String.init) ?? UUID().uuidString
                if messages.contains(where: { $0.id == msgId }) || sentIds.contains(msgId) { continue }

                let senderId = (fields["senderId"] as? [String: Any])?["stringValue"] as? String ?? ""
                let text = (fields["text"] as? [String: Any])?["stringValue"] as? String ?? ""
                let typeRaw = (fields["type"] as? [String: Any])?["stringValue"] as? String ?? "chat"
                let timestamp = ISO8601DateFormatter().date(from: doc["createTime"] as? String ?? "") ?? Date()
                let mediaUrl = (fields["mediaUrl"] as? [String: Any])?["stringValue"] as? String
                let isDisappearing = (fields["isDisappearing"] as? [String: Any])?["booleanValue"] as? Bool ?? false
                let disappearDuration = (fields["disappearDurationSeconds"] as? [String: Any])?["integerValue"] as? String
                let readTsStr = (fields["readTimestamp"] as? [String: Any])?["stringValue"] as? String
                let readTs = readTsStr.flatMap { ISO8601DateFormatter().date(from: $0) }

                var reactions: [String: String]?
                if let r = fields["reactions"] as? [String: Any],
                   let mapFields = r["mapValue"] as? [String: Any],
                   let fields2 = mapFields["fields"] as? [String: Any] {
                    reactions = [:]
                    for (k, v) in fields2 {
                        if let sv = (v as? [String: Any])?["stringValue"] as? String {
                            reactions?[k] = sv
                        }
                    }
                } else if let r = fields["reactions"] as? [String: Any] {
                    reactions = [:]
                    for (k, v) in r {
                        if let sv = (v as? [String: Any])?["stringValue"] as? String {
                            reactions?[k] = sv
                        } else if let sv = v as? String {
                            reactions?[k] = sv
                        }
                    }
                }

                let replyToId = (fields["replyToId"] as? [String: Any])?["stringValue"] as? String
                let replyToText = (fields["replyToText"] as? [String: Any])?["stringValue"] as? String
                let replyToSenderId = (fields["replyToSenderId"] as? [String: Any])?["stringValue"] as? String

                let msgType: MessageType
                switch typeRaw {
                case "chat", "text": msgType = .text
                case "voice": msgType = .voice
                case "image", "photo": msgType = .image
                case "video": msgType = .video
                case "gift": msgType = .gift
                case "letter": msgType = .letter
                default: msgType = .text
                }

                let msg = MessageModel(id: msgId, senderId: senderId, text: text, timestamp: timestamp,
                    type: msgType, isDisappearing: isDisappearing,
                    disappearDurationSeconds: Int(disappearDuration ?? "0") ?? 0,
                    readTimestamp: readTs, mediaUrl: mediaUrl,
                    replyToId: replyToId, replyToText: replyToText,
                    replyToSenderId: replyToSenderId, reactions: reactions)
                messages.append(msg)
            }
            messages.sort { $0.timestamp < $1.timestamp }
            autoScrollToBottom.send()
        }
    }

    private func sendToFirestore(msg: MessageModel) {
        let puid = partnerUid
        guard !puid.isEmpty, puid != "partner" else { return }

        let path = "couples/\(coupleId)/messages/\(msg.id)"
        let df = ISO8601DateFormatter()

        var fields: [String: Any] = [
            "id": msg.id,
            "senderId": msg.senderId,
            "text": msg.text ?? "",
            "timestamp": df.string(from: msg.timestamp),
            "type": msg.type == .text ? "chat" : msg.type.rawValue,
            "isDisappearing": msg.isDisappearing,
            "disappearDurationSeconds": msg.disappearDurationSeconds,
        ]

        if let rid = msg.replyToId { fields["replyToId"] = rid }
        if let rt = msg.replyToText { fields["replyToText"] = rt }
        if let rs = msg.replyToSenderId { fields["replyToSenderId"] = rs }
        if let mu = msg.mediaUrl { fields["mediaUrl"] = mu }
        if let rt = msg.readTimestamp { fields["readTimestamp"] = df.string(from: rt) }
        if let r = msg.reactions { fields["reactions"] = r }
        if let lt = msg.letterTitle { fields["letterTitle"] = lt }
        if let vnp = msg.voiceNotePath { fields["voiceNotePath"] = vnp }

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: fields)
            sendNotificationToPartner(msg: msg)
        }
    }

    private func sendNotificationToPartner(msg: MessageModel) {
        let puid = partnerUid
        guard !puid.isEmpty, puid != "partner" else { return }

        var preview = msg.text ?? ""
        if msg.type == .voice { preview = "🎤 Nota de voz" }
        else if msg.type == .image { preview = "🖼️ Foto" }
        else if msg.type == .video { preview = "🎬 Video" }

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(puid)", fields: [
                "lastNotification": ["app": "EverUs Chat", "title": myName, "text": String(preview.prefix(100))],
                "lastNotificationTime": Date()
            ])
        }
    }

    public func sendMessage(text: String) {
        let msgId = UUID().uuidString
        sentIds.insert(msgId)

        let msg = MessageModel(id: msgId, senderId: myUid, text: text, timestamp: Date(),
            type: isShowingDisappearing ? .disappearing : .text,
            isDisappearing: isShowingDisappearing, disappearDurationSeconds: isShowingDisappearing ? 15 : 0,
            replyToId: replyToMessage?.id, replyToText: replyToMessage?.text,
            replyToSenderId: replyToMessage?.senderId)
        messages.append(msg)
        clearReply()
        didSendMessage.send()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        sendToFirestore(msg: msg)
    }

    public func sendImage(imageData: Data) {
        let msgId = UUID().uuidString
        sentIds.insert(msgId)
        let compressed = Self.compressImage(imageData)

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "pairs/\(coupleId)/photos/\(msgId)",
                fields: ["data": compressed.base64EncodedString(),
                         "mimeType": "image/jpeg",
                         "timestamp": ISO8601DateFormatter().string(from: Date())])
            let msg = MessageModel(id: msgId, senderId: myUid, text: "Foto", timestamp: Date(),
                type: .image, mediaUrl: "firestore://pairs/\(coupleId)/photos/\(msgId)")
            await MainActor.run {
                messages.append(msg)
                didSendMessage.send()
            }
            sendToFirestore(msg: msg)
        }
    }

    private static func compressImage(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        if data.count < 500_000 { return data }
        let maxSize: CGFloat = 1024
        var newSize = image.size
        if newSize.width > maxSize || newSize.height > maxSize {
            if newSize.width > newSize.height {
                newSize = CGSize(width: maxSize, height: maxSize * newSize.height / newSize.width)
            } else {
                newSize = CGSize(width: maxSize * newSize.width / newSize.height, height: maxSize)
            }
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
        sentIds.insert(msgId)
        let compressed = Self.compressAudio(audioData)

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "pairs/\(coupleId)/audio/\(msgId)",
                fields: ["data": compressed.base64EncodedString(),
                         "mimeType": "audio/m4a",
                         "timestamp": ISO8601DateFormatter().string(from: Date())])
            let msg = MessageModel(id: msgId, senderId: myUid, text: "Nota de voz", timestamp: Date(),
                type: .voice, mediaUrl: "firestore://pairs/\(coupleId)/audio/\(msgId)")
            await MainActor.run {
                messages.append(msg)
                didSendMessage.send()
            }
            sendToFirestore(msg: msg)
        }
    }

    private static func compressAudio(_ data: Data) -> Data {
        if data.count <= 750_000 { return data }
        let tmp = FileManager.default.temporaryDirectory
        let srcURL = tmp.appendingPathComponent("voice_src_\(UUID().uuidString).m4a")
        let dstURL = tmp.appendingPathComponent("voice_dst_\(UUID().uuidString).m4a")
        try? data.write(to: srcURL)
        defer { try? FileManager.default.removeItem(at: srcURL); try? FileManager.default.removeItem(at: dstURL) }
        let asset = AVAsset(url: srcURL)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else { return data }
        session.outputFileType = .m4a
        session.outputURL = dstURL
        let semaphore = DispatchSemaphore(value: 0)
        session.exportAsynchronously { semaphore.signal() }
        _ = semaphore.wait(timeout: .now() + 10)
        guard session.status == .completed, let compressed = try? Data(contentsOf: dstURL) else { return data }
        return compressed.count < data.count ? compressed : data
    }

    public func markAsRead(messageId: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[idx].readTimestamp = Date()
        let df = ISO8601DateFormatter()
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "couples/\(coupleId)/messages/\(messageId)",
                fields: ["readTimestamp": df.string(from: Date())])
        }
    }

    public func addReaction(to messageId: String, emoji: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var reactions = messages[idx].reactions ?? [:]
        if reactions[myUid] == emoji { reactions.removeValue(forKey: myUid) }
        else { reactions[myUid] = emoji }
        messages[idx].reactions = reactions.isEmpty ? nil : reactions

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "couples/\(coupleId)/messages/\(messageId)",
                fields: ["reactions": reactions])
        }
    }

    public func setReplyTo(message: MessageModel) { replyToMessage = message }
    public func clearReply() { replyToMessage = nil }
    public func sendKissAction() { sendMessage(text: "💋") }
    public func sendHugAction() { sendMessage(text: "🤗") }
    public func sendTouchAction() { sendMessage(text: "✨") }

    public func startRecording() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .denied: return
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted { DispatchQueue.main.async { self.startRecording() } }
            }
            return
        case .granted: break
        @unknown default: return
        }
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
