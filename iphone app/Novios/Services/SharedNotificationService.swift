import Foundation
import FirebaseFirestore
import UIKit

public class SharedNotificationService {
    public static let shared = SharedNotificationService()
    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var sharedNotifsRef: CollectionReference {
        db.collection("parejas").document(coupleId).collection("notificaciones_compartidas")
    }

    public func saveSharedNotification(text: String, app: String = "", title: String = "", sender: String = "") {
        var data: [String: Any] = [
            "text": text,
            "title": title,
            "app": app,
            "sender": sender.isEmpty ? (defaults.string(forKey: "user_name") ?? "Yo") : sender,
            "senderId": defaults.string(forKey: "user_id") ?? "",
            "createdAt": FieldValue.serverTimestamp(),
        ]
        sharedNotifsRef.addDocument(data: data)
    }

    public func streamSharedNotifications() -> Query {
        sharedNotifsRef.order(by: "createdAt", descending: true).limit(to: 100)
    }

    public func checkClipboard() -> String? {
        guard UIPasteboard.general.hasStrings else { return nil }
        guard let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        guard !text.isEmpty else { return nil }
        let lastCopied = defaults.string(forKey: "last_copied_text") ?? ""
        if text == lastCopied { return nil }
        defaults.set(text, forKey: "last_copied_text")
        return text
    }
}
