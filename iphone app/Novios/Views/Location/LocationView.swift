import SwiftUI
import MapKit

public struct RealMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var userLocation: CLLocationCoordinate2D?
    var showsUserLocation: Bool

    public func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = showsUserLocation
        map.userTrackingMode = .follow
        return map
    }

    public func updateUIView(_ map: MKMapView, context: Context) {
        map.setRegion(region, animated: true)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RealMapView
        init(_ parent: RealMapView) { self.parent = parent }
    }
}

public struct LocationView: View {
    @StateObject private var locationService = LocationService.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var places: [Place2] = [
        Place2(emoji: "🍕", name: "Nuestra pizzería", address: "Av. Central 123, Centro", dateAdded: Date().addingTimeInterval(-86400 * 30)),
        Place2(emoji: "🌅", name: "Mirador del sol", address: "Cerro Alto 456, Colina", dateAdded: Date().addingTimeInterval(-86400 * 14)),
        Place2(emoji: "☕", name: "Café favorito", address: "Calle Real 789, Downtown", dateAdded: Date().addingTimeInterval(-86400 * 7)),
    ]
    @State private var isSharingLocation = true
    @State private var selectedZone: Zone2?
    @State private var showNewPlaceAlert = false
    @State private var newPlaceName = ""
    @State private var newPlaceAddress = ""
    @State private var showPermissionAlert = false

    private let zones: [Zone2] = [
        Zone2(emoji: "🏠", name: "Casa", address: "Residencial Paz 234"),
        Zone2(emoji: "💼", name: "Trabajo", address: "Zona Corporativa Torre B"),
        Zone2(emoji: "❤️", name: "Nuestro Lugar", address: "Parque del Amor"),
        Zone2(emoji: "🎬", name: "Cine fav", address: "Plaza Central Cine 3"),
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ThemeManager.shared.backgroundGradient.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        permissionBanner
                        compartirToggle
                        mapSection
                        partnerInfoCard
                        zonasSection
                        lugaresSection
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
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
            .alert("Permiso de ubicación", isPresented: $showPermissionAlert) {
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Necesitamos acceso a tu ubicación para compartirla con tu pareja. Ve a Ajustes y activa la ubicación.")
            }
            .onChange(of: locationService.authorizationStatus) { status in
                if status == .denied || status == .restricted {
                    showPermissionAlert = true
                }
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    locationService.startUpdatingLocation()
                }
            }
            .onReceive(locationService.$currentLocation) { loc in
                if let loc = loc {
                    region.center = loc.coordinate
                }
            }
            .alert("Nuevo lugar", isPresented: $showNewPlaceAlert) {
                TextField("Nombre", text: $newPlaceName)
                TextField("Dirección", text: $newPlaceAddress)
                Button("Cancelar", role: .cancel) { newPlaceName = ""; newPlaceAddress = "" }
                Button("Agregar") {
                    let n = newPlaceName.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty {
                        places.append(Place2(emoji: "📍", name: n, address: newPlaceAddress.trimmingCharacters(in: .whitespaces), dateAdded: Date()))
                    }
                    newPlaceName = ""; newPlaceAddress = ""
                }
            }
        }
        .onAppear {
            locationService.requestAuthorization()
        }
    }

    @ViewBuilder
    private var permissionBanner: some View {
        if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
            GlassCard {
                HStack(spacing: 10) {
                    Image(systemName: "location.slash.fill").foregroundColor(.red).font(.system(size: 18))
                    Text("Ubicación desactivada. Actívala en Ajustes para compartir con tu pareja.")
                        .font(.system(size: 12)).foregroundColor(.primary)
                    Spacer()
                    Button("Ajustes") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                    .font(.system(size: 13, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                }
            }
        }
    }

    private var compartirToggle: some View {
        GlassCard {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(isSharingLocation ? ThemeManager.shared.primaryPink : .gray).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compartir ubicación").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                    Text(isSharingLocation ? "Visible para tu pareja" : "Oculta para tu pareja").font(.system(size: 11)).foregroundColor(.primary.opacity(0.5))
                }
                Spacer()
                Toggle("", isOn: $isSharingLocation).tint(ThemeManager.shared.primaryPink)
            }
        }
    }

    private var mapSection: some View {
        GlassCard {
            ZStack {
                RealMapView(region: $region, userLocation: $locationService.currentLocation.map { $0.coordinate }, showsUserLocation: true)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                VStack {
                    searchBar.padding(.horizontal, 12).padding(.top, 12)
                    Spacer()
                }
            }
            .frame(height: 260)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.primary.opacity(0.4)).font(.system(size: 14))
            Text("Buscar lugares").font(.system(size: 13)).foregroundColor(.primary.opacity(0.4))
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var partnerInfoCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Circle().fill(ThemeManager.shared.neonGlowGradient).frame(width: 52, height: 52)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 22)).foregroundColor(.primary))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("💞 Valentina").font(.system(size: 17, weight: .bold)).foregroundColor(.primary)
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                    }
                    Text("🟢 En línea").font(.system(size: 11)).foregroundColor(.primary.opacity(0.55))
                    Text("Visto hace 2 min").font(.system(size: 10)).foregroundColor(.primary.opacity(0.4))
                }
                Spacer()
                Text("2.3 km").font(.system(size: 14, weight: .bold)).foregroundColor(ThemeManager.shared.primaryPink)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(ThemeManager.shared.primaryPink.opacity(0.12)).clipShape(Capsule())
            }
        }
    }

    private var zonasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Zonas Guardadas").font(.system(size: 16, weight: .bold)).foregroundColor(.primary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(zones) { zone in
                        Button { selectedZone = zone } label: {
                            Zone2Card(zone: zone, isSelected: selectedZone?.id == zone.id)
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 2)
            }
        }
    }

    private var lugaresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Lugares Especiales").font(.system(size: 16, weight: .bold)).foregroundColor(.primary)
                Spacer()
                Text("\(places.count)").font(.system(size: 12, weight: .semibold)).foregroundColor(.primary.opacity(0.5))
                    .padding(.horizontal, 8).padding(.vertical, 3).background(.ultraThinMaterial).clipShape(Capsule())
            }
            VStack(spacing: 10) {
                ForEach(places) { place in
                    Place2Card(place: place, onDelete: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { places.removeAll { $0.id == place.id } }
                    })
                }
            }
            Button {
                showNewPlaceAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 18))
                    Text("Agregar lugar").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(ThemeManager.shared.primaryPink)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(ThemeManager.shared.primaryPink.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

private struct Place2: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let address: String
    let dateAdded: Date
}

private struct Zone2: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let address: String
}

private struct Zone2Card: View {
    let zone: Zone2
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 8) {
            Text(zone.emoji).font(.system(size: 32))
            Text(zone.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.primary).multilineTextAlignment(.center)
            Text(zone.address).font(.system(size: 9)).foregroundColor(.primary.opacity(0.45)).multilineTextAlignment(.center).lineLimit(1)
        }
        .frame(width: 110, height: 110)
        .background(
            Group {
                if isSelected { RoundedRectangle(cornerRadius: 18).fill(ThemeManager.shared.primaryPink.opacity(0.18)) }
                else { RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial) }
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(isSelected ? ThemeManager.shared.primaryPink.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct Place2Card: View {
    let place: Place2
    let onDelete: () -> Void
    private var df: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium; f.locale = Locale(identifier: "es_MX")
        return f
    }
    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Text(place.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
                    Text(place.address).font(.system(size: 11)).foregroundColor(.primary.opacity(0.5)).lineLimit(1)
                    Text("Agregado \(df.string(from: place.dateAdded))").font(.system(size: 9)).foregroundColor(.primary.opacity(0.35))
                }
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.red.opacity(0.7))
                        .frame(width: 32, height: 32).background(.ultraThinMaterial).clipShape(Circle())
                }.buttonStyle(.plain)
            }
        }
    }
}
