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
            // Try to list messages subcollection
            var documents: [[String: Any]] = []
            if let docs = try? await FirebaseRESTService.shared.firestoreList(path: "couples/\(coupleId)/messages") {
                documents = docs
            } else if let docs = try? await FirebaseRESTService.shared.firestoreGet(path: "couples/\(coupleId)/messages"),
                      let arr = docs["documents"] as? [[String: Any]] {
                documents = arr
            } else {
                // Fallback: try to read from the couples document itself
                if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "couples/\(coupleId)"),
                   let fields = doc["fields"] as? [String: Any],
                   let messagesJson = (fields["messages"] as? [String: Any])?["arrayValue"] as? [String: Any],
                   let values = messagesJson["values"] as? [[String: Any]] {
                    documents = values
                } else if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "couples/\(coupleId)"),
                          let fields = doc["fields"] as? [String: Any],
                          let msgsJson = (fields["messagesJson"] as? [String: Any])?["stringValue"] as? String,
                          let data = msgsJson.data(using: .utf8),
                          let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    documents = arr
                }
            }

            guard !documents.isEmpty else { return }

            for doc in documents {
                let fields: [String: Any]
                let msgId: String
                let createTime: String

                if let f = doc["fields"] as? [String: Any], let name = doc["name"] as? String {
                    // Standard Firestore document format
                    fields = f
                    msgId = name.split(separator: "/").last.map(String.init) ?? UUID().uuidString
                    createTime = doc["createTime"] as? String ?? ""
                } else if let id = doc["id"] as? String {
                    // Inline message format (from JSON array)
                    fields = doc
                    msgId = id
                    createTime = doc["timestamp"] as? String ?? ""
                } else {
                    continue
                }

                let extractStr = { (key: String) -> String? in
                    if let v = fields[key] as? String { return v }
                    return (fields[key] as? [String: Any])?["stringValue"] as? String
                }
                let extractBool = { (key: String) -> Bool in
                    if let v = fields[key] as? Bool { return v }
                    return (fields[key] as? [String: Any])?["booleanValue"] as? Bool ?? false
                }

                let senderId = extractStr("senderId") ?? ""
                let text = extractStr("text") ?? ""
                let typeRaw = extractStr("type") ?? "chat"
                let timestamp = ISO8601DateFormatter().date(from: createTime)
                    ?? extractStr("timestamp").flatMap { ISO8601DateFormatter().date(from: $0) }
                    ?? Date()
                let mediaUrl = extractStr("mediaUrl")
                let isDisappearing = extractBool("isDisappearing")
                let disappearDuration = extractStr("disappearDurationSeconds") ?? extractStr("disappearDuration")
                let readTsStr = extractStr("readTimestamp")
                let readTs = readTsStr.flatMap { ISO8601DateFormatter().date(from: $0) }

                var reactions: [String: String]?
                if let r = fields["reactions"] as? [String: Any] {
                    reactions = [:]
                    if let mapFields = r["mapValue"] as? [String: Any],
                       let fields2 = mapFields["fields"] as? [String: Any] {
                        for (k, v) in fields2 {
                            if let sv = (v as? [String: Any])?["stringValue"] as? String { reactions?[k] = sv }
                        }
                    } else {
                        for (k, v) in r {
                            if let sv = (v as? [String: Any])?["stringValue"] as? String { reactions?[k] = sv }
                            else if let sv = v as? String { reactions?[k] = sv }
                        }
                    }
                    if reactions?.isEmpty == true { reactions = nil }
                }

                if let idx = messages.firstIndex(where: { $0.id == msgId }) {
                    if messages[idx].readTimestamp != readTs { messages[idx].readTimestamp = readTs }
                    if messages[idx].reactions != reactions { messages[idx].reactions = reactions }
                    continue
                }
                if sentIds.contains(msgId) { continue }

                let replyToId = extractStr("replyToId")
                let replyToText = extractStr("replyToText")
                let replyToSenderId = extractStr("replyToSenderId")

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
        let now = df.string(from: msg.timestamp)

        var fields: [String: Any] = [
            "id": msg.id,
            "senderId": msg.senderId,
            "text": msg.text ?? "",
            "timestamp": now,
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
            // 1. Save as subcollection document (primary method, works with SDK)
            try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: fields)

            // 2. Store full message in couples doc messagesJson array (reliable with REST API)
            let msgDict: [String: Any] = [
                "id": msg.id, "senderId": msg.senderId, "text": msg.text ?? "",
                "timestamp": now, "type": msg.type == .text ? "chat" : msg.type.rawValue,
                "isDisappearing": msg.isDisappearing,
                "disappearDurationSeconds": msg.disappearDurationSeconds,
            ]
            if let msgJson = (try? JSONSerialization.data(withJSONObject: msgDict)).flatMap({ String(data: $0, encoding: .utf8) }) {
                // Read existing messages, append new one, write back
                if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "couples/\(coupleId)"),
                   let existingFields = doc["fields"] as? [String: Any],
                   let existingJson = (existingFields["messagesJson"] as? [String: Any])?["stringValue"] as? String,
                   let existingData = existingJson.data(using: .utf8),
                   var existingArr = try? JSONSerialization.jsonObject(with: existingData) as? [[String: Any]] {
                    existingArr.append(msgDict)
                    if let updatedJson = (try? JSONSerialization.data(withJSONObject: existingArr)).flatMap({ String(data: $0, encoding: .utf8) }) {
                        try? await FirebaseRESTService.shared.firestoreSet(path: "couples/\(coupleId)", fields: [
                            "messagesJson": updatedJson,
                            "lastMessageTime": now,
                            "lastMessageId": msg.id,
                        ])
                    }
                } else {
                    // First message
                    let arr = [msgDict]
                    if let json = (try? JSONSerialization.data(withJSONObject: arr)).flatMap({ String(data: $0, encoding: .utf8) }) {
                        try? await FirebaseRESTService.shared.firestoreSet(path: "couples/\(coupleId)", fields: [
                            "messagesJson": json,
                            "lastMessageTime": now,
                            "lastMessageId": msg.id,
                        ])
                    }
                }
            }

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
