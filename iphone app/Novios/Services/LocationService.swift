import Foundation
import CoreLocation
import Combine
import UIKit

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
    @Published public var partnerSpeed: Double?
    @Published public var partnerBattery: Int?
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
        if let loc = mgr.location {
            updateFirebasePosition(loc)
        } else {
            setOnline()
        }
    }

    public func stopSharing() {
        locationManager?.stopUpdatingLocation()
        isSharing = false
        defaults.set(false, forKey: "location_sharing_enabled")
        firebaseTimer?.invalidate()
        firebaseTimer = nil
        partnerPollTimer?.invalidate()
        partnerPollTimer = nil
        setOffline()
    }

    private func setOffline() {
        guard let uid = AuthService.shared.currentUser?.id ?? rest.localId else { return }
        let path = "couples/\(CoupleService.coupleId)/location/\(uid)"
        Task {
            await firestoreSetWithFallback(path: path, fields: [
                "isOnline": false,
                "lastLocationUpdate": df.string(from: Date()),
            ])
        }
    }

    public func requestPermission() {
        ensureManager().requestAlwaysAuthorization()
    }

    public func refreshPartnerNow() {
        fetchPartnerLocation()
    }

    public func appDidEnterBackground() {
        if isSharing {
            setOffline()
        }
    }

    public func appDidBecomeActive() {
        if defaults.bool(forKey: "location_sharing_enabled") {
            startSharing()
        }
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

    // MARK: - Firebase Write

    private func firestoreSetWithFallback(path: String, fields: [String: Any]) async {
        try? await rest.firestoreSet(path: path, fields: fields)
    }

    private func firestoreGetWithFallback(path: String) async -> [String: Any]? {
        try? await rest.firestoreGet(path: path)
    }

    // MARK: - Firebase Sync

    private func updateFirebasePosition(_ loc: CLLocation) {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFirebaseUpdate)

        let minInterval: TimeInterval
        switch motionState {
        case "static": minInterval = 10
        case "walking": minInterval = 5
        default: minInterval = 3
        }
        guard elapsed >= minInterval else { return }
        lastFirebaseUpdate = now

        guard let uid = AuthService.shared.currentUser?.id ?? rest.localId else { return }

        let speed = (loc.speed >= 0 ? loc.speed * 3.6 : 0.0)
        let battery = (UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1)

        Task {
            let path = "couples/\(CoupleService.coupleId)/location/\(uid)"
            await firestoreSetWithFallback(path: path, fields: [
                "latitude": loc.coordinate.latitude,
                "longitude": loc.coordinate.longitude,
                "lat": loc.coordinate.latitude,
                "lng": loc.coordinate.longitude,
                "speed": speed,
                "batteryLevel": battery,
                "battery": battery,
                "lastLocationUpdate": df.string(from: now),
                "isOnline": true,
            ])
        }
    }

    private func setOnline() {
        guard let uid = AuthService.shared.currentUser?.id ?? rest.localId else { return }
        let path = "couples/\(CoupleService.coupleId)/location/\(uid)"
        Task {
            await firestoreSetWithFallback(path: path, fields: [
                "isOnline": true,
                "lastLocationUpdate": df.string(from: Date()),
            ])
        }
    }

    private func startFirebaseTimer() {
        firebaseTimer?.invalidate()
        firebaseTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self = self, let loc = self.locationManager?.location else { return }
            self.updateFirebasePosition(loc)
        }
    }

    private func startPartnerPolling() {
        partnerPollTimer?.invalidate()
        partnerPollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.fetchPartnerLocation()
        }
    }

    private func fetchPartnerLocation() {
        let puid = CoupleService.shared.partnerUid
        guard !puid.isEmpty else { return }
        Task { @MainActor in
            let partnerPath = "couples/\(CoupleService.coupleId)/location/\(puid)"
            if let doc = await firestoreGetWithFallback(path: partnerPath),
               let fields = doc["fields"] as? [String: Any] {
                let ed = { (k: String) -> Double? in
                    if let dv = (fields[k] as? [String: Any])?["doubleValue"] as? Double { return dv }
                    if let sv = (fields[k] as? [String: Any])?["stringValue"] as? String { return Double(sv) }
                    if let iv = (fields[k] as? [String: Any])?["integerValue"] as? String { return Double(iv) }
                    return nil
                }
                let newLat = ed("latitude") ?? ed("lat")
                let newLng = ed("longitude") ?? ed("lng")
                let online = ((fields["isOnline"] as? [String: Any])?["booleanValue"] as? Bool) ?? false
                if let tsStr = (fields["lastLocationUpdate"] as? [String: Any])?["stringValue"] as? String {
                    self.partnerLastUpdate = self.df.date(from: tsStr)
                }
                let partnerSpeed = ed("speed")
                let partnerBattery = { () -> Int? in
                    if let v = (fields["batteryLevel"] as? [String: Any])?["integerValue"] as? String { return Int(v) }
                    if let v = (fields["battery"] as? [String: Any])?["integerValue"] as? String { return Int(v) }
                    return nil
                }()
                self.partnerLatitude = newLat
                self.partnerLongitude = newLng
                self.partnerOnline = online
                self.partnerSpeed = partnerSpeed
                self.partnerBattery = partnerBattery
                if let myLat = self.lastLatitude, let myLng = self.lastLongitude,
                   let pLat = newLat, let pLng = newLng {
                    self.distanceToPartner = self.haversine(lat1: myLat, lon1: myLng, lat2: pLat, lon2: pLng) / 1000.0
                }
            }
        }
    }

    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi/180) * cos(lat2 * .pi/180) * sin(dLon/2) * sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }
}
