import Foundation
import Combine
import SwiftUI

public class ChatService: ObservableObject {
    public static let shared = ChatService()

    @Published public var messages: [MessageModel] = []
    @Published public var isRecording = false
    @Published public var isShowingDisappearing = false
    @Published public var replyToMessage: MessageModel?

    public let autoScrollToBottom = PassthroughSubject<Void, Never>()

    private var currentUserId: String { AuthService.shared.currentUser?.id ?? "user_me" }
    private var partnerId: String { UserService.shared.partnerUser?.id ?? "partner_sample_123" }
    private var partnerName: String { UserService.shared.partnerUser?.displayName ?? "Mi Amor" }

    private init() {
        loadSampleMessages()
    }

    public func sendMessage(text: String) {
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: text,
            timestamp: Date(),
            type: .text,
            replyToId: replyToMessage?.id,
            replyToText: replyToMessage?.text,
            replyToSenderId: replyToMessage?.senderId
        )
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            messages.append(msg)
        }
        clearReply()
        autoScrollToBottom.send()
    }

    public func sendVoiceNote(path: String) {
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: nil,
            timestamp: Date(),
            type: .voice,
            voiceNotePath: path
        )
        messages.append(msg)
        autoScrollToBottom.send()
    }

    public func sendMedia(url: String) {
        let type: MessageType = url.hasSuffix(".mp4") || url.hasSuffix(".mov") ? .video : .image
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: nil,
            timestamp: Date(),
            type: type,
            mediaUrl: url
        )
        messages.append(msg)
        autoScrollToBottom.send()
    }

    public func sendKissAction() {
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: "💋",
            timestamp: Date(),
            type: .kiss
        )
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        messages.append(msg)
        autoScrollToBottom.send()
    }

    public func sendHugAction() {
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: "🤗",
            timestamp: Date(),
            type: .hug
        )
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        messages.append(msg)
        autoScrollToBottom.send()
    }

    public func sendTouchAction() {
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: "✨",
            timestamp: Date(),
            type: .touch
        )
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        messages.append(msg)
        autoScrollToBottom.send()
    }

    public func sendGift(giftId: String) {
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
            text: "🎁",
            timestamp: Date(),
            type: .gift,
            giftId: giftId
        )
        messages.append(msg)
        autoScrollToBottom.send()
    }

    public func addReaction(to messageId: String, emoji: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        let uid = currentUserId
        var current = messages[index].reactions ?? [:]
        if current[uid] == emoji {
            current.removeValue(forKey: uid)
        } else {
            current[uid] = emoji
        }
        messages[index].reactions = current.isEmpty ? nil : current
    }

    public func removeReaction(to messageId: String, userId: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              var current = messages[index].reactions else { return }
        current.removeValue(forKey: userId)
        messages[index].reactions = current.isEmpty ? nil : current
    }

    public func markAsRead(messageId: String) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              messages[index].readTimestamp == nil else { return }
        messages[index].readTimestamp = Date()
    }

    public func startDisappearingMode() {
        isShowingDisappearing = true
    }

    public func stopDisappearingMode() {
        isShowingDisappearing = false
    }

    public func setReplyTo(message: MessageModel) {
        replyToMessage = message
    }

    public func clearReply() {
        replyToMessage = nil
    }

    public func deleteExpiredMessages() {
        messages.removeAll { !$0.isVisible }
    }

    private func loadSampleMessages() {
        let now = Date()
        let me = currentUserId
        let partner = partnerId
        let pName = partnerName

        messages = [
            MessageModel(id: "s1", senderId: partner, text: "Buenos días mi amor ❤️ ¿Dormiste bien?", timestamp: now.addingTimeInterval(-86400 * 3 - 36000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 3 - 35900)),
            MessageModel(id: "s2", senderId: me, text: "¡Buenos días! Dormí soñando contigo 🥰", timestamp: now.addingTimeInterval(-86400 * 3 - 35000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 3 - 34900)),
            MessageModel(id: "s3", senderId: partner, text: "Qué lindo eres 💕 ¿Qué planes tienes hoy?", timestamp: now.addingTimeInterval(-86400 * 3 - 34000), type: .text, reactions: [me: "❤️"], readTimestamp: now.addingTimeInterval(-86400 * 3 - 33900)),
            MessageModel(id: "s4", senderId: me, text: "Trabajar y luego ir al gimnasio. ¿Tú?", timestamp: now.addingTimeInterval(-86400 * 3 - 33000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 3 - 32900)),
            MessageModel(id: "s5", senderId: partner, text: "Te extraño mucho... ¿Podemos vernos hoy?", timestamp: now.addingTimeInterval(-86400 * 2 - 40000), type: .text, reactions: [me: "😘"], readTimestamp: now.addingTimeInterval(-86400 * 2 - 39900)),
            MessageModel(id: "s6", senderId: me, text: "Claro que sí amor. Te recojo a las 7 🚗", timestamp: now.addingTimeInterval(-86400 * 2 - 39000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 2 - 38900)),
            MessageModel(id: "s7", senderId: partner, text: "💋", timestamp: now.addingTimeInterval(-86400 * 2 - 38500), type: .kiss, reactions: [me: "💖"], readTimestamp: now.addingTimeInterval(-86400 * 2 - 38400)),
            MessageModel(id: "s8", senderId: me, text: "Mira lo que encontré... un recuerdo hermoso 📸", timestamp: now.addingTimeInterval(-86400 - 40000), type: .image, mediaUrl: "photo_placeholder", readTimestamp: now.addingTimeInterval(-86400 - 39900)),
            MessageModel(id: "s9", senderId: partner, text: "¡Qué bonito! Me encanta esa foto 🥹", timestamp: now.addingTimeInterval(-86400 - 39000), type: .text, reactions: ["me": "❤️", partner: "😍"], readTimestamp: now.addingTimeInterval(-86400 - 38900)),
            MessageModel(id: "s10", senderId: me, text: "Te tengo una sorpresa... 🎁", timestamp: now.addingTimeInterval(-86400 - 20000), type: .gift, giftId: "gift_rose", readTimestamp: now.addingTimeInterval(-86400 - 19900)),
            MessageModel(id: "s11", senderId: partner, text: "¿Una sorpresa? Dime ya 😍", timestamp: now.addingTimeInterval(-86400 - 19000), type: .text, readTimestamp: now.addingTimeInterval(-86400 - 18900)),
            MessageModel(id: "s12", senderId: me, text: nil, timestamp: now.addingTimeInterval(-43200), type: .voice, voiceNotePath: "voice_sample", readTimestamp: now.addingTimeInterval(-43100)),
            MessageModel(id: "s13", senderId: me, text: "Te amo con todo mi corazón ❤️", timestamp: now.addingTimeInterval(-40000), type: .text, reactions: [partner: "💖"], readTimestamp: now.addingTimeInterval(-39900)),
            MessageModel(id: "s14", senderId: partner, text: "Y yo a ti, más que ayer pero menos que mañana 🥰", timestamp: now.addingTimeInterval(-38000), type: .text, reactions: [me: "🔥"], readTimestamp: now.addingTimeInterval(-37500)),
            MessageModel(id: "s15", senderId: me, text: "🤗", timestamp: now.addingTimeInterval(-35000), type: .hug, readTimestamp: now.addingTimeInterval(-34500)),
            MessageModel(id: "s16", senderId: partner, text: "Siento tus abrazos desde aquí 🫂", timestamp: now.addingTimeInterval(-34000), type: .text, readTimestamp: now.addingTimeInterval(-33500)),
            MessageModel(id: "s17", senderId: me, text: "¿Qué opinas de este lugar? 🏖️", timestamp: now.addingTimeInterval(-30000), type: .image, mediaUrl: "beach_placeholder", readTimestamp: now.addingTimeInterval(-29500)),
            MessageModel(id: "s18", senderId: partner, text: "¡Se ve espectacular! Vamos este finde 🌊", timestamp: now.addingTimeInterval(-29000), type: .text, readTimestamp: now.addingTimeInterval(-28500)),
            MessageModel(id: "s19", senderId: me, text: "✨", timestamp: now.addingTimeInterval(-25000), type: .touch, readTimestamp: now.addingTimeInterval(-24500)),
            MessageModel(id: "s20", senderId: partner, text: "Siento tu toque... electricidad pura ⚡", timestamp: now.addingTimeInterval(-24000), type: .text, reactions: [me: "💖", partner: "😘"], readTimestamp: now.addingTimeInterval(-23500)),
            MessageModel(id: "s21", senderId: me, text: "Te escribí una carta en la app 📝", timestamp: now.addingTimeInterval(-18000), type: .letter, letterTitle: "Para el amor de mi vida", readTimestamp: now.addingTimeInterval(-17500)),
            MessageModel(id: "s22", senderId: partner, text: "¡Corrí a leerla! Me hizo llorar de felicidad 🥲💕", timestamp: now.addingTimeInterval(-17000), type: .text, reactions: [me: "❤️"], readTimestamp: now.addingTimeInterval(-16500)),
            MessageModel(id: "s23", senderId: me, text: "Te grabé un video corto 📹", timestamp: now.addingTimeInterval(-12000), type: .video, videoMessagePath: "video_sample", readTimestamp: now.addingTimeInterval(-11500)),
            MessageModel(id: "s24", senderId: partner, text: "¡Me encantó! Eres tan tierno 😊", timestamp: now.addingTimeInterval(-11000), type: .text, reactions: [me: "😘"], readTimestamp: now.addingTimeInterval(-10500)),
            MessageModel(id: "s25", senderId: me, text: "Buenas noches mi cielo. Dulces sueños 🌙", timestamp: now.addingTimeInterval(-7200), type: .text, readTimestamp: now.addingTimeInterval(-7100)),
            MessageModel(id: "s26", senderId: partner, text: "Buenas noches amor. Sueña conmigo 💤", timestamp: now.addingTimeInterval(-7000), type: .text, reactions: [me: "💖"], readTimestamp: now.addingTimeInterval(-6900)),
            MessageModel(id: "s27", senderId: partner, text: "¡Buenos días! Te amo 💕", timestamp: now.addingTimeInterval(-3600), type: .text, readTimestamp: now.addingTimeInterval(-3500)),
            MessageModel(id: "s28", senderId: me, text: "¡Buenos días! Te amo más 🥰", timestamp: now.addingTimeInterval(-3400), type: .text, readTimestamp: now.addingTimeInterval(-3300)),
            MessageModel(id: "s29", senderId: partner, text: "¿Ya viste lo que te envié? Especial para ti 🎶", timestamp: now.addingTimeInterval(-1800), type: .voice, voiceNotePath: "voice_audio_sample", replyToId: "s13", replyToText: "Te amo con todo mi corazón ❤️", replyToSenderId: me, readTimestamp: now.addingTimeInterval(-1700)),
            MessageModel(id: "s30", senderId: me, text: "Me encantó. La pondré en repeat todo el día 🎵", timestamp: now.addingTimeInterval(-900), type: .text, reactions: [partner: "❤️"], readTimestamp: now)
        ]
    }
}
