import Foundation
import UserNotifications
import Combine

public class ChatNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = ChatNotificationService()
    
    @Published public var isAuthorized: Bool = false
    
    public static let heartCategoryIdentifier = "NOVIO_HEART_CATEGORY"
    public static let replyActionIdentifier = "REPLY_TEXT_ACTION"
    
    public override init() {
        super.init()
        requestAuthorization()
        setupHeartNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    public func setupHeartNotificationCategories() {
        let textReplyAction = UNTextInputNotificationAction(
            identifier: ChatNotificationService.replyActionIdentifier,
            title: "Responder 💬",
            options: [],
            textInputButtonTitle: "Enviar",
            textInputPlaceholder: "Escribe un mensaje de amor..."
        )
        
        let kissAction = UNNotificationAction(identifier: "REPLY_KISS", title: "Enviar Beso 💋", options: [])
        let hugAction = UNNotificationAction(identifier: "REPLY_HUG", title: "Enviar Abrazo 🤗", options: [])
        
        let heartCategory = UNNotificationCategory(
            identifier: ChatNotificationService.heartCategoryIdentifier,
            actions: [textReplyAction, kissAction, hugAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([heartCategory])
    }
    
    public func sendLocalNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        
        content.title = "💖 Novios • \(title)"
        content.body = body
        content.sound = .default
        content.categoryIdentifier = ChatNotificationService.heartCategoryIdentifier
        content.threadIdentifier = "novios_heart_messages"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Partner Specific Notifications
    
    public func notifyKissReceived(from partnerName: String) {
        sendLocalNotification(title: "Beso Virtual de \(partnerName)", body: "💋 \(partnerName) te ha enviado un beso con mucho amor.")
    }
    
    public func notifyScreenShareStarted(from partnerName: String) {
        sendLocalNotification(title: "Transmisión en Vivo", body: "📱 \(partnerName) ha iniciado a compartir pantalla en tiempo real.")
    }
    
    public func notifyLoveMessage(from partnerName: String, text: String) {
        sendLocalNotification(title: partnerName, body: "💬 \(text)")
    }
    
    public func notifyPartnerLowBattery(partnerName: String, level: Int) {
        sendLocalNotification(title: "Batería de \(partnerName)", body: "🔋 ¡Atención! Tu pareja tiene poco nivel de batería (\(level)%). Recordarle recargar.")
    }
    
    public func notifyPartnerCharging(partnerName: String) {
        sendLocalNotification(title: "Cargando Teléfono", body: "⚡ \(partnerName) acaba de poner a cargar su celular.")
    }
    
    public func notifyPartnerMoodChange(partnerName: String, moodEmoji: String, message: String?) {
        let msgStr = message != nil ? " \"\(message!)\"" : ""
        sendLocalNotification(title: "Estado de Ánimo", body: "\(moodEmoji) \(partnerName) actualizó su estado a\(msgStr)")
    }
    
    public func notifyPartnerProximity(partnerName: String, distanceText: String) {
        sendLocalNotification(title: "Cerca de ti 📍", body: "✨ ¡\(partnerName) está muy cerca! \(distanceText)")
    }
    
    public func notifyAnniversaryReminder(daysRemaining: Int) {
        if daysRemaining == 0 {
            sendLocalNotification(title: "¡FELIZ ANIVERSARIO! 🎉", body: "❤️ Hoy celebran otro día inolvidable juntos. ¡Felicidades!")
        } else {
            sendLocalNotification(title: "Próximo Aniversario 🗓️", body: "💖 Faltan solo \(daysRemaining) días para su próximo aniversario.")
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate (WhatsApp-like Inline Reply Handling)
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        if actionIdentifier == ChatNotificationService.replyActionIdentifier || actionIdentifier == UNNotificationDefaultActionIdentifier {
            if let textResponse = response as? UNTextInputNotificationResponse {
                let userMessageText = textResponse.userText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !userMessageText.isEmpty {
                    print("💬 Respuesta de mensaje desde notificación recibida: \(userMessageText)")
                    ChatService.shared.sendMessage(text: userMessageText)
                }
            }
        } else if actionIdentifier == "REPLY_KISS" {
            ChatService.shared.sendKissAction()
        } else if actionIdentifier == "REPLY_HUG" {
            ChatService.shared.sendHugAction()
        }
        
        completionHandler()
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
