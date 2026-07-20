import Foundation
import Combine

public class FirebaseService: ObservableObject {
    public static let shared = FirebaseService()
    
    @Published public var isInitialized: Bool = false
    @Published public var activeProjectID: String = "novios-8beb7" // Primary
    @Published public var backupProjectID: String = "novios-49289" // Backup
    
    private init() {
        configureFirebase()
    }
    
    public func configureFirebase() {
        // Look for GoogleService-Info.plist (Primary) or GoogleService-Info (1).plist (Backup)
        if let primaryPlist = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("🔥 Firebase Primary Config Found: \(primaryPlist)")
            self.activeProjectID = "novios-8beb7"
        } else if let backupPlist = Bundle.main.path(forResource: "GoogleService-Info (1)", ofType: "plist") {
            print("🔥 Firebase Backup Config Found: \(backupPlist)")
            self.activeProjectID = "novios-49289"
        }
        self.isInitialized = true
    }
    
    public func switchToBackupIfNeeded() {
        print("🔄 Switching to Firebase Backup Project: \(backupProjectID)")
        let temp = activeProjectID
        activeProjectID = backupProjectID
        backupProjectID = temp
    }
}
