import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation

// MARK: - Places

struct PartnerPlace: Identifiable, Codable {
    var id: String
    var name: String
    var icon: String
    var color: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var notifyArrival: Bool
    var notifyDeparture: Bool
    var memories: [PlaceMemory]?
}

struct PlaceMemory: Identifiable, Codable {
    var id: String
    var title: String
    var date: String
    var note: String
    var photoCount: Int
    var songName: String?
    var createdAt: String
}

// MARK: - History

struct LocationHistoryEntry: Identifiable {
    var id: String
    var place: String?
    var placeIcon: String?
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var type: String
}

// MARK: - Route

struct ActiveRoute {
    var destination: String
    var destLat: Double
    var destLng: Double
    var eta: String
    var remainingDist: Double
    var polyline: [CLLocationCoordinate2D]
}

// MARK: - Map Annotations

struct MapAnnotationItem: Identifiable {
    var id: String
    var coordinate: CLLocationCoordinate2D
    var label: String
    var color: Color
    var isHeart: Bool
    var isPartner: Bool
    var imageName: String?
    var photoURL: String?
}

// MARK: - Map Style

enum MapStyleOption: String, CaseIterable {
    case standard
    case satellite
    case hybrid
}

// MARK: - Weather

struct WeatherInfo {
    var condition: String
    var icon: String
    var temperature: Int
}

// MARK: - Daily Stats

struct DailyStats {
    var kilometers: Double
    var timeOutside: TimeInterval
    var placesVisited: Int
    var timeTogether: TimeInterval
}
