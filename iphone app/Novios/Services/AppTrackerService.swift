import Foundation
import UIKit

public class AppTrackerService {
    public static let shared = AppTrackerService()

    private var lastReportedApp = ""
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    public func reportExternalApp(_ appName: String) {
        guard appName != lastReportedApp else { return }
        lastReportedApp = appName
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(myUid)", fields: [
                "currentApp": appName.lowercased(),
                "currentAppLabel": appName,
                "currentScreen": appName,
                "lastSeenDate": Date()
            ])
        }
    }

    public func openExternalApp(urlScheme: String, appName: String) {
        reportExternalApp(appName)
        guard let url = URL(string: urlScheme) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public func reportNotificationFromApp(_ appName: String, title: String, text: String) {
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let data: [String: Any] = [
                "app": appName, "title": title, "text": text,
                "timestamp": Date(), "type": "notification"
            ]
            try? await FirebaseRESTService.shared.firestoreCreate(
                path: "users/\(myUid)/activities",
                fields: data
            )
            // Also set as last notification
            try? await FirebaseRESTService.shared.firestoreSet(path: "users/\(myUid)", fields: [
                "lastNotificationApp": appName,
                "lastNotificationTitle": title,
                "lastNotificationText": text,
                "lastNotificationTime": Date()
            ])
        }
    }
}
