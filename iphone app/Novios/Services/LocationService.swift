import Foundation
import CoreLocation
import Combine
import UIKit
import FirebaseCore
import FirebaseFirestore

public class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationService()

    @Published public var isSharing = false
    @Published public var lastLatitude: Double?
    @Published public var lastLongitude: Double?
    @Published public var lastSpeed: Double?
    @Published public var lastHeading: Double?
    @Published public var lastPrecision: Double?
    @Published public var lastAddress: String?

    @Published public var partnerLatitude: Double?
    @Published public var partnerLongitude: Double?
    @Published public var partnerOnline = false
    @Published public var partnerLastUpdate: Date?
    @Published public var partnerSpeed: Double?
    @Published public var partnerBattery: Int?
    @Published public var partnerHeading: Double?
    @Published public var partnerPrecision: Double?
    @Published public var partnerAddress: String?
    @Published public var partnerIsCharging: Bool?
    @Published public var partnerIsGPSOn = true
    @Published public var distanceToPartner: Double?
    @Published public var partnerMotion: String?
    @Published var partnerRoute: ActiveRoute?
    @Published public var partnerName = ""

    @Published public var isRouting = false
    @Published public var routeDestination: String?
    @Published public var routeDestinationLat: Double?
    @Published public var routeDestinationLng: Double?
    @Published public var routeEta: String?
    @Published public var routePolyline: [CLLocationCoordinate2D] = []

    private var locationManager: CLLocationManager?
    private var firebaseTimer: Timer?
    private var listener: ListenerRegistration?
    private var routesListener: ListenerRegistration?
    private var lastFirebaseUpdate = Date.distantPast
    private var motionState = "static"
    private let defaults = UserDefaults.standard
    private let df = ISO8601DateFormatter()
    private var db: Firestore? { FirebaseApp.app() != nil ? Firestore.firestore() : nil }

    private var myLocationPath: String? {
        guard let uid = AuthService.shared.currentUser?.id else { return nil }
        return "parejas/\(CoupleService.coupleId)/ubicacion/\(uid)"
    }

    private var partnerLocationPath: String? {
        let puid = CoupleService.shared.partnerUid
        guard !puid.isEmpty else { return nil }
        return "parejas/\(CoupleService.coupleId)/ubicacion/\(puid)"
    }

    private override init() {
        super.init()
        partnerName = CoupleService.shared.partnerName
    }

    private func ensureManager() -> CLLocationManager {
        if let mgr = locationManager { return mgr }
        let mgr = CLLocationManager()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
        mgr.distanceFilter = 20
        mgr.headingFilter = 5
        mgr.allowsBackgroundLocationUpdates = true
        mgr.showsBackgroundLocationIndicator = true
        mgr.pausesLocationUpdatesAutomatically = false
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
        if status == .denied || status == .restricted { return }
        mgr.startUpdatingLocation()
        mgr.startUpdatingHeading()
        isSharing = true
        defaults.set(true, forKey: "location_sharing_enabled")
        startFirebaseTimer()
        startPartnerListener()
        startRoutesListener()
        if let loc = mgr.location { updateFirebasePosition(loc) } else { setOnline() }
    }

    public func stopSharing() {
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
        isSharing = false
        defaults.set(false, forKey: "location_sharing_enabled")
        firebaseTimer?.invalidate(); firebaseTimer = nil
        listener?.remove(); listener = nil
        routesListener?.remove(); routesListener = nil
        setOffline()
    }

    private func setOffline() {
        guard let p = myLocationPath, let db = db else { return }
        Task { try? await db.document(p).setData(["isOnline": false, "lastLocationUpdate": df.string(from: Date())], merge: true) }
    }

    private func setOnline() {
        guard let p = myLocationPath, let db = db else { return }
        Task { try? await db.document(p).setData(["isOnline": true, "lastLocationUpdate": df.string(from: Date())], merge: true) }
    }

    public func requestPermission() { ensureManager().requestAlwaysAuthorization() }
    public func appDidEnterBackground() { if isSharing { setOffline() } }
    public func appDidBecomeActive() { if defaults.bool(forKey: "location_sharing_enabled") { startSharing() } }

    // MARK: - Route Sharing

    public func startRoute(destination: String, lat: Double, lng: Double) {
        guard let p = myLocationPath else { return }
        isRouting = true
        routeDestination = destination
        routeDestinationLat = lat
        routeDestinationLng = lng
        let data: [String: Any] = [
            "routeActive": true,
            "routeDestination": destination,
            "routeDestLat": lat,
            "routeDestLng": lng,
            "routeStartTime": df.string(from: Date())
        ]
        guard let db = db else { return }
        Task { try? await db.document(p).setData(data, merge: true) }
    }

    public func stopRoute() {
        guard let p = myLocationPath, let db = db else { return }
        isRouting = false
        routeDestination = nil
        routeDestinationLat = nil
        routeDestinationLng = nil
        routeEta = nil
        routePolyline = []
        let data: [String: Any] = [
            "routeActive": false,
            "routeDestination": FieldValue.delete(),
            "routeDestLat": FieldValue.delete(),
            "routeDestLng": FieldValue.delete(),
            "routeStartTime": FieldValue.delete()
        ]
        Task { try? await db.document(p).setData(data, merge: true) }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if defaults.bool(forKey: "location_sharing_enabled") { startSharing() }
        case .denied, .restricted: isSharing = false; defaults.set(false, forKey: "location_sharing_enabled")
        case .notDetermined: break
        @unknown default: break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastLatitude = loc.coordinate.latitude
        lastLongitude = loc.coordinate.longitude
        lastSpeed = loc.speed >= 0 ? loc.speed * 3.6 : nil
        lastPrecision = loc.horizontalAccuracy >= 0 ? loc.horizontalAccuracy : nil

        let s = loc.speed * 3.6
        if s > 50 { motionState = "driving" }
        else if s > 10 { motionState = "running" }
        else if s > 3 { motionState = "walking" }
        else { motionState = "static" }

        if isRouting, let dLat = routeDestinationLat, let dLng = routeDestinationLng {
            routePolyline = routePolyline + [loc.coordinate]
            objectWillChange.send()
            let dist = haversine(lat1: loc.coordinate.latitude, lon1: loc.coordinate.longitude,
                                 lat2: dLat, lon2: dLng) / 1000.0
            let speedKmh = max(loc.speed * 3.6, 1)
            let minutes = Int(dist / (speedKmh / 60))
            if minutes < 1 { routeEta = "< 1 min" }
            else if minutes < 60 { routeEta = "\(minutes) min" }
            else { routeEta = "\(minutes / 60)h \(minutes % 60)m" }
            updateRouteInFirebase(dist: dist)
        }

        updateFirebasePosition(loc)
        reverseGeocode(loc)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        lastHeading = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Location] Error: \(error.localizedDescription)")
    }

    private func reverseGeocode(_ loc: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let p = placemarks?.first else { return }
            let parts = [p.thoroughfare, p.subThoroughfare, p.locality, p.subLocality, p.administrativeArea].compactMap { $0 }
            self?.lastAddress = parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
    }

    // MARK: - Firebase Write

    private func updateFirebasePosition(_ loc: CLLocation) {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFirebaseUpdate)
        let minInterval: TimeInterval = motionState == "static" ? 10 : (motionState == "walking" ? 5 : 3)
        guard elapsed >= minInterval else { return }
        lastFirebaseUpdate = now

        guard let p = myLocationPath else { return }
        let speed = loc.speed >= 0 ? loc.speed * 3.6 : 0.0
        let battery = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
        let isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        let precision = loc.horizontalAccuracy >= 0 ? loc.horizontalAccuracy : nil
        let gpsOn = loc.horizontalAccuracy >= 0 && loc.horizontalAccuracy < 1000

        var fields: [String: Any] = [
            "lat": loc.coordinate.latitude, "lng": loc.coordinate.longitude,
            "latitude": loc.coordinate.latitude, "longitude": loc.coordinate.longitude,
            "speed": speed, "battery": battery, "batteryLevel": battery,
            "isCharging": isCharging, "motion": motionState,
            "lastLocationUpdate": df.string(from: now), "isOnline": true,
            "gpsOn": gpsOn,
        ]
        if let h = lastHeading { fields["heading"] = h }
        if let pr = precision { fields["precision"] = pr }
        if let addr = lastAddress { fields["address"] = addr }

        Task { try? await db?.document(p).setData(fields, merge: true) }
    }

    private func updateRouteInFirebase(dist: Double) {
        guard let p = myLocationPath else { return }
        var coords: [[String: Double]] = []
        for coord in routePolyline.suffix(200) {
            coords.append(["lat": coord.latitude, "lng": coord.longitude])
        }
        Task { try? await db?.document(p).setData([
            "routePolyline": coords,
            "routeRemainingDist": dist,
            "routeEta": routeEta ?? ""
        ], merge: true) }
    }

    // MARK: - Partner Listener

    private func startPartnerListener() {
        listener?.remove()
        guard let p = partnerLocationPath else { return }
        listener = db?.document(p).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self, let d = snapshot?.data() else { return }
            let ed = { (k: String) -> Double? in d[k] as? Double ?? Double(d[k] as? String ?? "") }
            let newLat = ed("latitude") ?? ed("lat")
            let newLng = ed("longitude") ?? ed("lng")
            self.partnerLatitude = newLat
            self.partnerLongitude = newLng
            self.partnerOnline = d["isOnline"] as? Bool ?? false
            self.partnerSpeed = ed("speed")
            self.partnerBattery = d["battery"] as? Int ?? d["batteryLevel"] as? Int
            self.partnerHeading = ed("heading")
            self.partnerPrecision = ed("precision")
            self.partnerAddress = d["address"] as? String
            self.partnerIsCharging = d["isCharging"] as? Bool
            self.partnerMotion = d["motion"] as? String
            self.partnerIsGPSOn = d["gpsOn"] as? Bool ?? true
            if let tsStr = d["lastLocationUpdate"] as? String {
                self.partnerLastUpdate = self.df.date(from: tsStr)
            }
            if let myLat = self.lastLatitude, let myLng = self.lastLongitude,
               let pLat = newLat, let pLng = newLng {
                self.distanceToPartner = self.haversine(lat1: myLat, lon1: myLng, lat2: pLat, lon2: pLng) / 1000.0
            }
            let routeActive = d["routeActive"] as? Bool ?? false
            if routeActive {
                self.partnerRoute = ActiveRoute(
                    destination: d["routeDestination"] as? String ?? "",
                    destLat: d["routeDestLat"] as? Double ?? 0,
                    destLng: d["routeDestLng"] as? Double ?? 0,
                    eta: d["routeEta"] as? String ?? "",
                    remainingDist: d["routeRemainingDist"] as? Double ?? 0,
                    polyline: []
                )
            } else {
                self.partnerRoute = nil
            }
        }
    }

    private func startRoutesListener() {
        routesListener?.remove()
        guard let p = partnerLocationPath else { return }
        routesListener = db?.document(p).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self, let d = snapshot?.data() else { return }
            let routeActive = d["routeActive"] as? Bool ?? false
            if routeActive {
                var coords: [CLLocationCoordinate2D] = []
                if let raw = d["routePolyline"] as? [[String: Double]] {
                    for item in raw {
                        if let lat = item["lat"], let lng = item["lng"] {
                            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        }
                    }
                }
                self.partnerRoute = ActiveRoute(
                    destination: d["routeDestination"] as? String ?? "",
                    destLat: d["routeDestLat"] as? Double ?? 0,
                    destLng: d["routeDestLng"] as? Double ?? 0,
                    eta: d["routeEta"] as? String ?? "",
                    remainingDist: d["routeRemainingDist"] as? Double ?? 0,
                    polyline: coords
                )
            } else {
                self.partnerRoute = nil
            }
        }
    }

    private func startFirebaseTimer() {
        firebaseTimer?.invalidate()
        firebaseTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self = self, let loc = self.locationManager?.location else { return }
            self.updateFirebasePosition(loc)
        }
    }

    public func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi/180) * cos(lat2 * .pi/180) * sin(dLon/2) * sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }
}
