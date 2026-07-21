import Foundation
import Combine

public class StatusService: ObservableObject {
    public static let shared = StatusService()

    @Published public var partnerStatus: [String: Any] = [:]
    @Published public var myPosition: (lat: Double, lon: Double)? = nil
    @Published public var isOnline = false

    private var pollingTimer: Timer?
    private var presenceTimer: Timer?

    private init() {
        startPolling()
        startPresenceUpdates()
    }

    public func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetchPartnerStatus()
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        presenceTimer?.invalidate()
        presenceTimer = nil
    }

    private func fetchPartnerStatus() {
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            let partnerUid = UserDefaults.standard.string(forKey: "partner_uid") ?? ""
            guard !partnerUid.isEmpty else { return }

            // Try to fetch, refresh token if needed
            var doc: [String: Any]?
            do {
                doc = try await FirebaseRESTService.shared.firestoreGet(path: "usuarios/\(partnerUid)")
            } catch FirebaseError.notAuthenticated {
                // Token expired, try refresh
                if let newToken = try? await FirebaseRESTService.shared.refreshIdToken() {
                    _ = newToken
                    doc = try? await FirebaseRESTService.shared.firestoreGet(path: "usuarios/\(partnerUid)")
                }
            } catch {
                // Silently fail for other errors
            }

            guard let fields = (doc?["fields"] as? [String: Any]) else { return }

            var status: [String: Any] = [:]
            for (key, val) in fields {
                if let map = val as? [String: Any] {
                    if let s = map["stringValue"] as? String { status[key] = s }
                    else if let b = map["booleanValue"] as? Bool { status[key] = b }
                    else if let n = map["integerValue"] as? String { status[key] = Int(n) ?? 0 }
                    else if let d = map["doubleValue"] as? Double { status[key] = d }
                    else if let ts = map["timestampValue"] as? String,
                            let date = ISO8601DateFormatter().date(from: ts) {
                        status[key] = date
                    }
                }
            }
            await MainActor.run {
                self.partnerStatus = status
                self.isOnline = status["isOnline"] as? Bool ?? false
                // Update partner location in UserService
                if let lat = status["latitude"] as? Double, let lon = status["longitude"] as? Double {
                    if var partner = UserService.shared.partnerUser {
                        partner.latitude = lat
                        partner.longitude = lon
                        UserService.shared.partnerUser = partner
                    }
                }
            }
        }
    }

    private func startPresenceUpdates() {
        presenceTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.updatePresence()
        }
        updatePresence()
    }

    private func updatePresence() {
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(myUid)", fields: [
                "isOnline": true,
                "lastSeenDate": Date()
            ])
        }
    }

    public func updateCurrentScreen(_ screen: String) {
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(myUid)", fields: [
                "currentScreen": screen,
                "lastSeenDate": Date()
            ])
        }
    }

    public func updateLocation(lat: Double, lon: Double) {
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(myUid)", fields: [
                "latitude": lat, "longitude": lon
            ])
        }
    }

    public func setOffline() {
        Task {
            guard let myUid = FirebaseRESTService.shared.localId else { return }
            try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(myUid)", fields: [
                "isOnline": false
            ])
        }
    }

    deinit {
        stopPolling()
        setOffline()
    }
}
