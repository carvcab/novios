import Foundation
import Combine
import UIKit
import SwiftUI

public class ChatService: ObservableObject {
    public static let shared = ChatService()

    @Published public var messages: [MessageModel] = []
    @Published public var isRecording = false
    @Published public var isShowingDisappearing = false
    @Published public var replyToMessage: MessageModel?

    public let didSendMessage = PassthroughSubject<Void, Never>()
    public let autoScrollToBottom = PassthroughSubject<Void, Never>()

    private var currentUserId: String { AuthService.shared.currentUser?.id ?? "me" }
    private var partnerId: String { UserService.shared.partnerUser?.id ?? "partner" }
    private var partnerName: String { UserService.shared.partnerUser?.displayName ?? "Pareja" }

    private init() {
        loadSampleMessages()
    }

    public func sendMessage(text: String) {
        let msg = MessageModel(
            id: UUID().uuidString,
            senderId: currentUserId,
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
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    public func sendKissAction() {
        let msg = MessageModel(id: UUID().uuidString, senderId: currentUserId, text: "💋", timestamp: Date(), type: .kiss)
        messages.append(msg)
        didSendMessage.send()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    public func sendHugAction() {
        let msg = MessageModel(id: UUID().uuidString, senderId: currentUserId, text: "🤗", timestamp: Date(), type: .hug)
        messages.append(msg)
        didSendMessage.send()
    }

    public func sendTouchAction() {
        let msg = MessageModel(id: UUID().uuidString, senderId: currentUserId, text: "✨", timestamp: Date(), type: .touch)
        messages.append(msg)
        didSendMessage.send()
    }

    public func sendGift(giftId: String) {
        let msg = MessageModel(id: UUID().uuidString, senderId: currentUserId, text: "🎁 Te envié un regalo", timestamp: Date(), type: .gift, giftId: giftId)
        messages.append(msg)
        didSendMessage.send()
    }

    public func sendVoiceNote(path: String) {
        let msg = MessageModel(id: UUID().uuidString, senderId: currentUserId, text: nil, timestamp: Date(), type: .voice, voiceNotePath: path)
        messages.append(msg)
        didSendMessage.send()
    }

    public func sendMedia(url: String) {
        let msg = MessageModel(id: UUID().uuidString, senderId: currentUserId, text: nil, timestamp: Date(), type: .image, mediaUrl: url)
        messages.append(msg)
        didSendMessage.send()
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

    public func setReplyTo(message: MessageModel) {
        replyToMessage = message
    }

    public func clearReply() {
        replyToMessage = nil
    }

    public func startDisappearingMode() {
        isShowingDisappearing = true
    }

    public func stopDisappearingMode() {
        isShowingDisappearing = false
    }

    public func deleteExpiredMessages() {
        messages.removeAll { !$0.isVisible }
    }

    private func loadSampleMessages() {
        let now = Date()
        let me = currentUserId
        let partner = partnerId

        messages = [
            MessageModel(id: "s1", senderId: partner, text: "Buenos días mi amor ❤️ ¿Dormiste bien?", timestamp: now.addingTimeInterval(-86400 * 3 - 36000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 3 - 35900)),
            MessageModel(id: "s2", senderId: me, text: "¡Buenos días! Dormí soñando contigo 🥰", timestamp: now.addingTimeInterval(-86400 * 3 - 35000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 3 - 34900)),
            MessageModel(id: "s3", senderId: partner, text: "Qué lindo eres 💕 ¿Qué planes tienes hoy?", timestamp: now.addingTimeInterval(-86400 * 3 - 34000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 3 - 33900), reactions: [me: "❤️"]),
            MessageModel(id: "s4", senderId: me, text: "Trabajar y luego ir al gimnasio. ¿Tú?", timestamp: now.addingTimeInterval(-86400 * 3 - 33000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 3 - 32900)),
            MessageModel(id: "s5", senderId: partner, text: "Te extraño mucho... ¿Podemos vernos hoy?", timestamp: now.addingTimeInterval(-86400 * 2 - 40000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 2 - 39900), reactions: [me: "😘"]),
            MessageModel(id: "s6", senderId: me, text: "Claro que sí amor. Te recojo a las 7 🚗", timestamp: now.addingTimeInterval(-86400 * 2 - 39000), type: .text, readTimestamp: now.addingTimeInterval(-86400 * 2 - 38900)),
            MessageModel(id: "s7", senderId: partner, text: "💋", timestamp: now.addingTimeInterval(-86400 * 2 - 38500), type: .kiss, readTimestamp: now.addingTimeInterval(-86400 * 2 - 38400), reactions: [me: "💖"]),
            MessageModel(id: "s8", senderId: me, text: "Mira lo que encontré... un recuerdo hermoso 📸", timestamp: now.addingTimeInterval(-86400 - 40000), type: .image, readTimestamp: now.addingTimeInterval(-86400 - 39900), mediaUrl: "photo_placeholder"),
            MessageModel(id: "s9", senderId: partner, text: "¡Qué bonito! Me encanta esa foto 🥹", timestamp: now.addingTimeInterval(-86400 - 39000), type: .text, readTimestamp: now.addingTimeInterval(-86400 - 38900), reactions: [me: "❤️", partner: "😍"]),
            MessageModel(id: "s10", senderId: me, text: "Te tengo una sorpresa... 🎁", timestamp: now.addingTimeInterval(-86400 - 20000), type: .gift, readTimestamp: now.addingTimeInterval(-86400 - 19900), giftId: "gift_rose"),
            MessageModel(id: "s11", senderId: partner, text: "¿Una sorpresa? Dime ya 😍", timestamp: now.addingTimeInterval(-86400 - 19000), type: .text, readTimestamp: now.addingTimeInterval(-86400 - 18900)),
            MessageModel(id: "s12", senderId: me, text: nil, timestamp: now.addingTimeInterval(-43200), type: .voice, readTimestamp: now.addingTimeInterval(-43100), voiceNotePath: "voice_sample"),
            MessageModel(id: "s13", senderId: me, text: "Te amo con todo mi corazón ❤️", timestamp: now.addingTimeInterval(-40000), type: .text, readTimestamp: now.addingTimeInterval(-39900), reactions: [partner: "💖"]),
            MessageModel(id: "s14", senderId: partner, text: "Y yo a ti, más que ayer pero menos que mañana 🥰", timestamp: now.addingTimeInterval(-38000), type: .text, readTimestamp: now.addingTimeInterval(-37500), reactions: [me: "🔥"]),
            MessageModel(id: "s15", senderId: me, text: "🤗", timestamp: now.addingTimeInterval(-35000), type: .hug, readTimestamp: now.addingTimeInterval(-34500)),
            MessageModel(id: "s16", senderId: partner, text: "Siento tus abrazos desde aquí 🫂", timestamp: now.addingTimeInterval(-34000), type: .text, readTimestamp: now.addingTimeInterval(-33500)),
            MessageModel(id: "s17", senderId: me, text: "¿Qué opinas de este lugar? 🏖️", timestamp: now.addingTimeInterval(-30000), type: .image, readTimestamp: now.addingTimeInterval(-29500), mediaUrl: "beach_placeholder"),
            MessageModel(id: "s18", senderId: partner, text: "¡Se ve espectacular! Vamos este finde 🌊", timestamp: now.addingTimeInterval(-29000), type: .text, readTimestamp: now.addingTimeInterval(-28500)),
            MessageModel(id: "s19", senderId: me, text: "✨", timestamp: now.addingTimeInterval(-25000), type: .touch, readTimestamp: now.addingTimeInterval(-24500)),
            MessageModel(id: "s20", senderId: partner, text: "Siento tu toque... electricidad pura ⚡", timestamp: now.addingTimeInterval(-24000), type: .text, readTimestamp: now.addingTimeInterval(-23500), reactions: [me: "💖", partner: "😘"]),
            MessageModel(id: "s21", senderId: me, text: "Te escribí una carta en la app 📝", timestamp: now.addingTimeInterval(-18000), type: .letter, readTimestamp: now.addingTimeInterval(-17500), letterTitle: "Para el amor de mi vida"),
            MessageModel(id: "s22", senderId: partner, text: "¡Corrí a leerla! Me hizo llorar de felicidad 🥲💕", timestamp: now.addingTimeInterval(-17000), type: .text, readTimestamp: now.addingTimeInterval(-16500), reactions: [me: "❤️"]),
            MessageModel(id: "s23", senderId: me, text: "Te grabé un video corto 📹", timestamp: now.addingTimeInterval(-12000), type: .video, readTimestamp: now.addingTimeInterval(-11500), videoMessagePath: "video_sample"),
            MessageModel(id: "s24", senderId: partner, text: "¡Me encantó! Eres tan tierno 😊", timestamp: now.addingTimeInterval(-11000), type: .text, readTimestamp: now.addingTimeInterval(-10500), reactions: [me: "😘"]),
            MessageModel(id: "s25", senderId: me, text: "Buenas noches mi cielo. Dulces sueños 🌙", timestamp: now.addingTimeInterval(-7200), type: .text, readTimestamp: now.addingTimeInterval(-7100)),
            MessageModel(id: "s26", senderId: partner, text: "Buenas noches amor. Sueña conmigo 💤", timestamp: now.addingTimeInterval(-7000), type: .text, readTimestamp: now.addingTimeInterval(-6900), reactions: [me: "💖"]),
            MessageModel(id: "s27", senderId: partner, text: "¡Buenos días! Te amo 💕", timestamp: now.addingTimeInterval(-3600), type: .text, readTimestamp: now.addingTimeInterval(-3500)),
            MessageModel(id: "s28", senderId: me, text: "¡Buenos días! Te amo más 🥰", timestamp: now.addingTimeInterval(-3400), type: .text, readTimestamp: now.addingTimeInterval(-3300)),
            MessageModel(id: "s29", senderId: partner, text: "¿Ya viste lo que te envié? Especial para ti 🎶", timestamp: now.addingTimeInterval(-1800), type: .voice, readTimestamp: now.addingTimeInterval(-1700), voiceNotePath: "voice_audio_sample", replyToId: "s13", replyToText: "Te amo con todo mi corazón ❤️", replyToSenderId: me),
            MessageModel(id: "s30", senderId: me, text: "Me encantó. La pondré en repeat todo el día 🎵", timestamp: now.addingTimeInterval(-900), type: .text, readTimestamp: now, reactions: [partner: "❤️"])
        ]
    }
}
