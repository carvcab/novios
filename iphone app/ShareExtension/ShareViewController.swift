import UIKit
import Social
import FirebaseCore
import FirebaseFirestore
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var sharedText = ""
    private var sharedApp = ""
    private let appNames: [String: String] = [
        "com.whatsapp": "WhatsApp",
        "com.burbn.instagram": "Instagram",
        "com.google.Gmail": "Gmail",
        "com.facebook.Facebook": "Facebook",
        "com.facebook.Messenger": "Messenger",
        "com.spotify.client": "Spotify",
        "com.google.ios.youtube": "YouTube",
        "com.toyopagroup.picaboo": "Snapchat",
        "com.zhiliaoapp.musically": "TikTok",
        "ph.telegra.Telegraph": "Telegram",
        "com.apple.mobilemail": "Mail",
        "com.apple.MobileSMS": "SMS",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        setupFirebase()
        extractContent()
    }
    
    private func setupFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    private func extractContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            showError("No se pudo obtener el contenido")
            return
        }
        
        // Get source app bundle ID
        if let source = parent?.value(forKey: "sourceApplicationContext") as? [String: Any],
           let bundleId = source["bundleIdentifier"] as? String {
            sharedApp = appNames[bundleId] ?? bundleId
        }
        
        var hasContent = false
        
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            
            for provider in attachments {
                // Text
                if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] (text, error) in
                        guard let self = self, let text = text as? String else { return }
                        self.sharedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        hasContent = true
                        self.saveAndDismiss()
                    }
                    return
                }
                // URL
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                        guard let self = self, let url = url as? URL else { return }
                        self.sharedText = url.absoluteString
                        hasContent = true
                        self.saveAndDismiss()
                    }
                    return
                }
                // Plain Text
                if #available(iOS 15.0, *) {
                    if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
                            guard let self = self, let text = text as? String else { return }
                            self.sharedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            hasContent = true
                            self.saveAndDismiss()
                        }
                        return
                    }
                }
            }
        }
        
        if !hasContent {
            showError("No hay texto para compartir")
        }
    }
    
    private func saveAndDismiss() {
        guard !sharedText.isEmpty else {
            showError("No hay contenido para compartir")
            return
        }
        
        do {
            let db = Firestore.firestore()
            let coupleId = getCoupleId()
            let data: [String: Any] = [
                "text": sharedText,
                "app": sharedApp,
                "title": "Compartido desde \(sharedApp.isEmpty ? "otra app" : sharedApp)",
                "sender": "Compartido desde iPhone",
                "createdAt": FieldValue.serverTimestamp(),
            ]
            db.collection("parejas").document(coupleId).collection("notificaciones_compartidas")
                .addDocument(data: data) { error in
                    if let error = error {
                        self.showError("Error: \(error.localizedDescription)")
                    } else {
                        self.dismissExtension()
                    }
                }
        } catch {
            // Fallback: save to UserDefaults if Firebase fails
            if let shared = UserDefaults(suiteName: "group.com.novios.share") {
                var items = shared.array(forKey: "shared_items") as? [[String: String]] ?? []
                items.append(["text": sharedText, "app": sharedApp, "date": ISO8601DateFormatter().string(from: Date())])
                shared.set(items, forKey: "shared_items")
                shared.synchronize()
            }
            dismissExtension()
        }
    }
    
    private func getCoupleId() -> String {
        let defaults = UserDefaults.standard
        let uid1 = defaults.string(forKey: "diego_uid") ?? "joeBcVn2o1hfXfU68rWNOyAZIqt2"
        let uid2 = defaults.string(forKey: "yosmari_uid") ?? "Dd1X94n3gxg7leWtMtnLlxDVHcm2"
        return [uid1, uid2].sorted().joined(separator: "_")
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Novios", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismissExtension()
        })
        present(alert, animated: true)
    }
    
    private func dismissExtension() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
