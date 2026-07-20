import Foundation
import CoreLocation
import Combine

public class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    @Published public var userLocation: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    public func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdating()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        self.userLocation = loc
    }
    
    public func calculateDistanceInKm(to coordinate: CLLocationCoordinate2D?) -> Double? {
        guard let myLoc = userLocation, let targetCoord = coordinate else { return nil }
        let targetLoc = CLLocation(latitude: targetCoord.latitude, longitude: targetCoord.longitude)
        let distanceMeters = myLoc.distance(from: targetLoc)
        return distanceMeters / 1000.0
    }
    
    public func formattedDistance(to coordinate: CLLocationCoordinate2D?) -> String {
        guard let km = calculateDistanceInKm(to: coordinate) else {
            return "Ubicación desconocida"
        }
        if km < 1.0 {
            let meters = Int(km * 1000)
            return "A solo \(meters) metros de ti"
        } else {
            return String(format: "A %.1f km de ti", km)
        }
    }
}
