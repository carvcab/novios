import SwiftUI
import MapKit

public struct LocationView: View {
    @StateObject private var locationService = LocationService.shared
    @StateObject private var statusService = StatusService.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isSharingLocation = true
    @State private var showNewPlaceAlert = false
    @State private var newPlaceName = ""
    @State private var newPlaceAddress = ""

    @State private var partnerCoordinate: CLLocationCoordinate2D?

    private var partnerName: String { UserDefaults.standard.string(forKey: "partner_name") ?? "Pareja" }
    private var isPartnerOnline: Bool { statusService.isOnline }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        permissionBanner
                        sharingToggle
                        mapSection
                        partnerInfoCard
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 16).padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill").foregroundColor(ThemeManager.shared.primaryPink).font(.system(size: 14, weight: .bold))
                        Text("Ubicación").font(.system(size: 17, weight: .bold)).foregroundColor(.primary)
                    }
                }
            }
            .alert("Nuevo lugar", isPresented: $showNewPlaceAlert) {
                TextField("Nombre", text: $newPlaceName)
                TextField("Dirección", text: $newPlaceAddress)
                Button("Cancelar", role: .cancel) { newPlaceName = ""; newPlaceAddress = "" }
                Button("Agregar") {
                    let n = newPlaceName.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty { savePlace(name: n, address: newPlaceAddress.trimmingCharacters(in: .whitespaces)) }
                    newPlaceName = ""; newPlaceAddress = ""
                }
            }
        }
        .onAppear {
            locationService.requestAuthorization()
        }
        .onChange(of: locationService.currentLocation) { loc in
            if let loc = loc { region.center = loc.coordinate }
        }
        .onReceive(statusService.$partnerStatus) { status in
            if let lat = status["latitude"] as? Double, let lon = status["longitude"] as? Double {
                partnerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
    }

    @ViewBuilder
    private var permissionBanner: some View {
        if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
            GlassCard {
                HStack(spacing: 10) {
                    Image(systemName: "location.slash.fill").foregroundColor(.red).font(.system(size: 18))
                    Text("Ubicación desactivada. Actívala en Ajustes para compartir con tu pareja.").font(.system(size: 12)).foregroundColor(.primary)
                    Spacer()
                    Button("Ajustes") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }.font(.system(size: 13, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                }
            }
        }
    }

    private var sharingToggle: some View {
        GlassCard {
            HStack {
                Image(systemName: "location.circle.fill").foregroundColor(isSharingLocation ? ThemeManager.shared.primaryPink : .gray).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compartir ubicación").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                    Text(isSharingLocation ? "Visible para tu pareja" : "Oculta para tu pareja").font(.system(size: 11)).foregroundColor(.primary.opacity(0.5))
                }
                Spacer()
                Toggle("", isOn: $isSharingLocation).tint(ThemeManager.shared.primaryPink)
                    .onChange(of: isSharingLocation) { sharing in
                        if sharing, let loc = locationService.currentLocation {
                            StatusService.shared.updateLocation(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
                        }
                    }
            }
        }
    }

    private var mapSection: some View {
        GlassCard {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotationItems) { item in
                MapMarker(coordinate: item.coordinate, tint: ThemeManager.shared.primaryPink)
            }
            .frame(height: 260).clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var annotationItems: [MapAnnotationItem] {
        if let coord = partnerCoordinate {
            return [MapAnnotationItem(coordinate: coord)]
        }
        return []
    }

    private var partnerInfoCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Circle().fill(isPartnerOnline ? Color.green : .gray).frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white, lineWidth: 2))

                VStack(alignment: .leading, spacing: 3) {
                    Text(partnerName).font(.system(size: 17, weight: .bold)).foregroundColor(.primary)
                    Text(isPartnerOnline ? "🟢 En línea" : "🔴 Desconectado").font(.system(size: 11)).foregroundColor(.primary.opacity(0.55))
                    if let coord = partnerCoordinate, let myLoc = locationService.currentLocation {
                        let dist = myLoc.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                        let distText = dist < 1000 ? "\(Int(dist)) m" : String(format: "%.1f km", dist / 1000)
                        Text("📍 \(distText)").font(.system(size: 12)).foregroundColor(ThemeManager.shared.primaryPink)
                    }
                }
                Spacer()
            }
        }
    }

    private func savePlace(name: String, address: String) {
        var places = loadPlaces()
        places.append(PlaceItem(name: name, address: address))
        if let encoded = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(encoded, forKey: "saved_places")
        }
    }

    private func loadPlaces() -> [PlaceItem] {
        guard let data = UserDefaults.standard.data(forKey: "saved_places"),
              let decoded = try? JSONDecoder().decode([PlaceItem].self, from: data) else { return [] }
        return decoded
    }
}

private struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

private struct PlaceItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let address: String
}
