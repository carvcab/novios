import Foundation
import CoreLocation
import Combine

public class LocationService: NSObject, ObservableObject {
    public static let shared = LocationService()

    private let manager = CLLocationManager()

    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public var currentLocation: CLLocation?
    @Published public var error: Error?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }

    public func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    public func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    public func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    public func requestLocation() {
        manager.requestLocation()
    }

    public func formattedDistance(to coordinate: CLLocationCoordinate2D) -> String {
        guard let current = currentLocation else { return "Sin datos" }
        let distance = current.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        if distance < 1000 {
            return "\(Int(distance)) m"
        }
        return String(format: "%.1f km", distance / 1000)
    }
}

extension LocationService: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
    }
}
