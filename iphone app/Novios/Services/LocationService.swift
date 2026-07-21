import Foundation
import CoreLocation
import Combine

public class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationService()

    @Published public var isSharing = false
    @Published public var lastLatitude: Double?
    @Published public var lastLongitude: Double?
    @Published public var lastSpeed: Double?
    @Published public var partnerLatitude: Double?
    @Published public var partnerLongitude: Double?
    @Published public var partnerOnline = false
    @Published public var partnerLastUpdate: Date?
    @Published public var distanceToPartner: Double?

    private var locationManager: CLLocationManager?
    private var firebaseTimer: Timer?
    private var partnerPollTimer: Timer?
    private var lastFirebaseUpdate = Date.distantPast
    private var motionState = "static"
    private let defaults = UserDefaults.standard
    private let df = ISO8601DateFormatter()
    private let rest = FirebaseRESTService.shared

    private override init() {
        super.init()
        if UserDefaults.standard.bool(forKey: "location_sharing_enabled") {
            startSharing()
        }
    }

    private func ensureManager() -> CLLocationManager {
        if let mgr = locationManager { return mgr }
        let mgr = CLLocationManager()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
        mgr.distanceFilter = 30
        locationManager = mgr
        return mgr
    }

    // MARK: - Public API

    public func startSharing() {
        let mgr = ensureManager()
        let status = mgr.authorizationStatus
        if status == .notDetermined {
            mgr.requestAlwaysAuthorization()
            return
        }
        if status == .denied || status == .restricted {
            return
        }
        mgr.startUpdatingLocation()
        isSharing = true
        defaults.set(true, forKey: "location_sharing_enabled")
        startFirebaseTimer()
        startPartnerPolling()
    }

    public func stopSharing() {
        locationManager?.stopUpdatingLocation()
        isSharing = false
        defaults.set(false, forKey: "location_sharing_enabled")
        firebaseTimer?.invalidate()
        firebaseTimer = nil
        partnerPollTimer?.invalidate()
        partnerPollTimer = nil
    }

    public func requestPermission() {
        ensureManager().requestAlwaysAuthorization()
    }

    public func refreshPartnerNow() {
        fetchPartnerLocation()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if defaults.bool(forKey: "location_sharing_enabled") { startSharing() }
        case .denied, .restricted:
            isSharing = false
            defaults.set(false, forKey: "location_sharing_enabled")
        case .notDetermined: break
        @unknown default: break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastLatitude = loc.coordinate.latitude
        lastLongitude = loc.coordinate.longitude
        lastSpeed = loc.speed >= 0 ? loc.speed * 3.6 : nil

        let speedKmh = loc.speed * 3.6
        if speedKmh > 50 { motionState = "driving" }
        else if speedKmh > 10 { motionState = "walking" }
        else { motionState = "static" }

        updateFirebasePosition(loc)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Location] Error: \(error.localizedDescription)")
    }

    // MARK: - Firebase Write (with API key fallback)

    private func firestoreSetWithFallback(path: String, fields: [String: Any]) async {
        if (try? await rest.firestoreSet(path: path, fields: fields)) != nil { return }
        let urlStr = "https://firestore.googleapis.com/v1/projects/\(rest.currentProjectID)/databases/(default)/documents/\(path)?key=\(rest.currentAPIKey)"
        guard let url = URL(string: urlStr) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = try? JSONSerialization.data(withJSONObject: ["fields": encodeFields(fields)]) {
            req.httpBody = body
            _ = try? await URLSession.shared.data(for: req)
        }
    }

    private func firestoreGetWithFallback(path: String) async -> [String: Any]? {
        if let doc = try? await rest.firestoreGet(path: path) { return doc }
        let urlStr = "https://firestore.googleapis.com/v1/projects/\(rest.currentProjectID)/databases/(default)/documents/\(path)?key=\(rest.currentAPIKey)"
        guard let url = URL(string: urlStr),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json
    }

    private func encodeFields(_ fields: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in fields { result[key] = firestoreValue(value) }
        return result
    }

    private func firestoreValue(_ value: Any) -> [String: Any] {
        if let s = value as? String { return ["stringValue": s] }
        if let n = value as? Int { return ["integerValue": "\(n)"] }
        if let n = value as? Double { return ["doubleValue": n] }
        if let b = value as? Bool { return ["booleanValue": b] }
        if let d = value as? Date { return ["timestampValue": df.string(from: d)] }
        return ["stringValue": "\(value)"]
    }

    // MARK: - Firebase Sync

    private func updateFirebasePosition(_ loc: CLLocation) {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFirebaseUpdate)

        let minInterval: TimeInterval
        switch motionState {
        case "static": minInterval = 120
        case "walking": minInterval = 60
        default: minInterval = 30
        }
        guard elapsed >= minInterval else { return }
        lastFirebaseUpdate = now

        guard let uid = AuthService.shared.currentUser?.id ?? rest.localId else { return }
        let shareLocation = defaults.bool(forKey: "privacy_share_location")
        guard shareLocation else { return }

        let shareSpeed = defaults.bool(forKey: "privacy_share_speed")
        let speed = shareSpeed ? (loc.speed >= 0 ? loc.speed * 3.6 : 0.0) : 0.0

        Task {
            await firestoreSetWithFallback(path: "users/\(uid)", fields: [
                "latitude": loc.coordinate.latitude,
                "longitude": loc.coordinate.longitude,
                "speed": speed,
                "lastLocationUpdate": df.string(from: now),
                "isOnline": true,
            ])
        }
    }

    private func startFirebaseTimer() {
        firebaseTimer?.invalidate()
        firebaseTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            guard let self = self, let loc = self.locationManager?.location else { return }
            self.updateFirebasePosition(loc)
        }
    }

    private func startPartnerPolling() {
        partnerPollTimer?.invalidate()
        partnerPollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetchPartnerLocation()
        }
    }

    private func fetchPartnerLocation() {
        let puid = defaults.string(forKey: "partner_uid") ?? ""
        guard !puid.isEmpty else { return }
        Task { @MainActor in
            if let doc = await firestoreGetWithFallback(path: "users/\(puid)"),
               let fields = doc["fields"] as? [String: Any] {
                let ed = { (k: String) -> Double? in
                    if let dv = (fields[k] as? [String: Any])?["doubleValue"] as? Double { return dv }
                    if let sv = (fields[k] as? [String: Any])?["stringValue"] as? String { return Double(sv) }
                    return nil
                }
                let newLat = ed("latitude")
                let newLng = ed("longitude")
                let online = ((fields["isOnline"] as? [String: Any])?["booleanValue"] as? Bool) ?? false
                if let tsStr = (fields["lastLocationUpdate"] as? [String: Any])?["stringValue"] as? String {
                    self.partnerLastUpdate = self.df.date(from: tsStr)
                }
                self.partnerLatitude = newLat
                self.partnerLongitude = newLng
                self.partnerOnline = online
                if let myLat = self.lastLatitude, let myLng = self.lastLongitude,
                   let pLat = newLat, let pLng = newLng {
                    self.distanceToPartner = self.haversine(lat1: myLat, lon1: myLng, lat2: pLat, lon2: pLng) / 1000.0
                }
            }
        }
    }

    // MARK: - Distance

    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi/180) * cos(lat2 * .pi/180) * sin(dLon/2) * sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }
}
