import Foundation
import Combine
import UIKit
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

public class ChatService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    public static let shared = ChatService()

    @Published public var messages: [MessageModel] = []
    @Published public var isRecording = false
    @Published public var isShowingDisappearing = false
    @Published public var replyToMessage: MessageModel?
    @Published public var recordingDuration: TimeInterval = 0
    @Published public var isLoaded = false
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    public let didSendMessage = PassthroughSubject<Void, Never>()
    public let autoScrollToBottom = PassthroughSubject<Void, Never>()

    private var listener: ListenerRegistration?
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?

    private var coupleId: String { "pareja_001" }
    private var myUid: String { AuthService.shared.currentUser?.id ?? (CoupleService.shared.currentUid) }
    private let db = Firestore.firestore()

    override public init() {
        super.init()
        startListening()
    }

    private func startListening() {
        guard Auth.auth().currentUser != nil else {
            errorMessage = "Sesión expirada. Vuelve a iniciar sesión."
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        let path = "parejas/\(coupleId)/chat"
        listener = db.collection(path)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("[Chat] snapshot error: \(error.localizedDescription)")
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                guard let snapshot = snapshot else {
                    self.errorMessage = "No se pudo conectar al chat"
                    self.isLoading = false
                    return
                }
                for change in snapshot.documentChanges {
                    switch change.type {
                    case .added: self.addMessage(from: change.document)
                    case .modified: self.updateMessage(from: change.document)
                    case .removed: self.removeMessage(with: change.document.documentID)
                    }
                }
                self.messages.sort { $0.timestamp < $1.timestamp }
                self.isLoaded = true
                self.isLoading = false
                self.errorMessage = nil
                print("[Chat] snapshot: \(snapshot.documentChanges.count) changes, total=\(self.messages.count)")
            }
    }

    public func stopListening() {
        listener?.remove()
        listener = nil
    }

    public func retry() {
        stopListening()
        startListening()
    }

    private func addMessage(from doc: DocumentSnapshot) {
        guard let data = doc.data() else { return }
        let msg = parseMessage(id: doc.documentID, data: data)
        if !messages.contains(where: { $0.id == doc.documentID }) {
            messages.append(msg)
            autoScrollToBottom.send()
        }
    }

    private func updateMessage(from doc: DocumentSnapshot) {
        guard let data = doc.data(),
              let idx = messages.firstIndex(where: { $0.id == doc.documentID }) else { return }
        let updated = parseMessage(id: doc.documentID, data: data)
        messages[idx] = updated
    }

    private func removeMessage(with id: String) {
        messages.removeAll(where: { $0.id == id })
    }

    private func parseMessage(id: String, data: [String: Any]) -> MessageModel {
        let senderId = data["senderId"] as? String ?? ""
        let text = data["text"] as? String
        let typeRaw = data["type"] as? String ?? "chat"
        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
            ?? ISO8601DateFormatter().date(from: data["timestamp"] as? String ?? "")
            ?? Date()
        let mediaUrl = data["mediaUrl"] as? String
        let isDisappearing = data["isDisappearing"] as? Bool ?? false
        let disappearDuration = data["disappearDurationSeconds"] as? Int ?? Int(data["disappearDuration"] as? String ?? "0") ?? 0
        let readTsStr = data["readTimestamp"] as? String
        let readTs = readTsStr.flatMap { Self.parseIsoDate($0) }
            ?? (data["readTimestamp"] as? Timestamp)?.dateValue()
        let replyToId = data["replyToId"] as? String
        let replyToText = data["replyToText"] as? String
        let replyToSenderId = data["replyToSenderId"] as? String
        let reactions = data["reactions"] as? [String: String]

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

        return MessageModel(
            id: id,
            senderId: senderId,
            text: text,
            timestamp: timestamp,
            type: msgType,
            isDisappearing: isDisappearing,
            disappearDurationSeconds: disappearDuration,
            readTimestamp: readTs,
            mediaUrl: mediaUrl,
            replyToId: replyToId,
            replyToText: replyToText,
            replyToSenderId: replyToSenderId,
            reactions: reactions
        )
    }

    private static func parseIsoDate(_ str: String) -> Date? {
        var cleanStr = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanStr.isEmpty { return nil }
        let hasTimezone = cleanStr.contains("Z") || cleanStr.contains("+") || (cleanStr.count > 10 && cleanStr.dropFirst(10).contains("-"))
        if !hasTimezone { cleanStr += "Z" }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: cleanStr) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        if let d = f2.date(from: cleanStr) { return d }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        let noZ = cleanStr.hasSuffix("Z") ? String(cleanStr.dropLast()) : cleanStr
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let d = df.date(from: noZ) { return d }
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let d = df.date(from: noZ) { return d }
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let d = df.date(from: noZ) { return d }
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let d = df.date(from: noZ) { return d }
        return nil
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
        let df = ISO8601DateFormatter()
        let isMe = msg.senderId == CoupleService.diegoUid
        let senderName = isMe ? CoupleService.diegoName : CoupleService.yosmariName

        var fields: [String: Any] = [
            "id": msg.id,
            "senderId": msg.senderId,
            "senderName": senderName,
            "text": msg.text ?? "",
            "timestamp": df.string(from: msg.timestamp),
            "type": msg.type == .text ? "chat" : msg.type.rawValue,
            "isDisappearing": msg.isDisappearing,
            "disappearDurationSeconds": msg.disappearDurationSeconds
        ]
        if let rid = msg.replyToId { fields["replyToId"] = rid }
        if let rt = msg.replyToText { fields["replyToText"] = rt }
        if let rs = msg.replyToSenderId { fields["replyToSenderId"] = rs }
        if let mu = msg.mediaUrl { fields["mediaUrl"] = mu }
        if let rt = msg.readTimestamp { fields["readTimestamp"] = df.string(from: rt) }

        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: fields)
        }
    }

    public func markAsRead(messageId: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        messages[idx].readTimestamp = ISO8601DateFormatter().date(from: now)
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "parejas/\(coupleId)/chat/\(messageId)",
                fields: ["readTimestamp": now]
            )
        }
    }

    public func addReaction(to messageId: String, emoji: String) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
        var reactions = messages[idx].reactions ?? [:]
        if reactions[myUid] == emoji { reactions.removeValue(forKey: myUid) }
        else { reactions[myUid] = emoji }
        messages[idx].reactions = reactions.isEmpty ? nil : reactions
        let fields: [String: Any] = ["reactions": reactions]
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "parejas/\(coupleId)/chat/\(messageId)",
                fields: fields
            )
        }
    }

    public func sendImage(imageData: Data) {
        let msgId = UUID().uuidString
        let compressed = Self.compressImage(imageData)
        let base64 = compressed.base64EncodedString()
        guard base64.count <= 730_000 else {
            errorMessage = "Imagen demasiado grande (máx ~550KB)"
            return
        }
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "chat_media/\(msgId)",
                fields: ["data": base64, "mimeType": "image/jpeg"]
            )
        }
        let msg = MessageModel(
            id: msgId,
            senderId: myUid,
            text: "Foto",
            timestamp: Date(),
            type: .image,
            mediaUrl: "firestore://chat_media/\(msgId)"
        )
        messages.append(msg)
        didSendMessage.send()
        saveMessage(msg: msg)
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
        let base64 = audioData.base64EncodedString()
        guard base64.count <= 730_000 else {
            errorMessage = "Audio demasiado largo (máx ~15s)"
            return
        }
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(
                path: "chat_media/\(msgId)",
                fields: ["data": base64, "mimeType": "audio/m4a"]
            )
        }
        let msg = MessageModel(
            id: msgId,
            senderId: myUid,
            text: "Nota de voz",
            timestamp: Date(),
            type: .voice,
            mediaUrl: "firestore://chat_media/\(msgId)"
        )
        messages.append(msg)
        didSendMessage.send()
        saveMessage(msg: msg)
    }

    public func setReplyTo(message: MessageModel) { replyToMessage = message }
    public func clearReply() { replyToMessage = nil }
    public func sendKissAction() { sendMessage(text: "\u{1F48B}") }
    public func sendHugAction() { sendMessage(text: "\u{1F917}") }

    public func startRecording() {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .denied:
            errorMessage = "Permiso de micrófono denegado. Ve a Ajustes > Novios > Micrófono."
            return
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                if granted { DispatchQueue.main.async { self?.startRecording() } }
            }
            return
        case .granted: break
        @unknown default: return
        }
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("voice_\(Date().timeIntervalSince1970).m4a")
            let recorder = try AVAudioRecorder(
                url: url,
                settings: [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
            )
            recorder.delegate = self
            guard recorder.record() else {
                errorMessage = "No se pudo iniciar la grabación"
                return
            }
            audioRecorder = recorder
            isRecording = true
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingDuration = self.audioRecorder?.currentTime ?? 0
            }
        } catch {
            print("[Chat] record error: \(error)")
            errorMessage = "Error al grabar: \(error.localizedDescription)"
        }
    }

    public func stopRecording() -> Data? {
        recordingTimer?.invalidate()
        recordingTimer = nil
        guard let recorder = audioRecorder else { return nil }
        recorder.stop()
        let url = recorder.url
        audioRecorder = nil
        isRecording = false
        guard let data = try? Data(contentsOf: url), !data.isEmpty else {
            errorMessage = "No se pudo leer el audio grabado"
            return nil
        }
        sendVoiceNote(audioData: data)
        return data
    }

    deinit { stopListening() }
}
