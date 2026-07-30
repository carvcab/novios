import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation

@available(iOS 17.0, *)
public struct LocationView: View {
    @ObservedObject private var locationService = LocationService.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedAnnotationId: String?
    @State private var showPartnerCard = false
    @State private var showPlacesList = false
    @State private var showAddPlace = false
    @State private var showHistory = false
    @State private var showStats = false
    @State private var showSettings = false
    @State private var showRouteShare = false
    @State private var selectedPlace: PartnerPlace?
    @State private var showPlaceDetail = false
    @State private var showAddMemory = false
    @State private var memoryTitle = ""
    @State private var memoryNote = ""
    @State private var memoryDate = Date()
    @State private var mapStyle: MapStyleOption = .standard
    @State private var places: [PartnerPlace] = []
    @State private var locationHistory: [LocationHistoryEntry] = []
    @State private var searchText = ""
    @State private var weather: WeatherInfo?

    @State private var placeName = ""
    @State private var placeIcon = "heart"
    @State private var colorStr = "#FF6B9D"
    @State private var placeRadius: Double = 100
    @State private var notifyArrival = true
    @State private var notifyDeparture = false
    @State private var placeLat: Double = 0
    @State private var placeLng: Double = 0

    @State private var showNotificationAlert = false
    @State private var notificationMessage = ""
    @State private var sheetOffset: CGFloat = 0
    @State private var sheetHeight: CGFloat = 200
    @State private var pulseScale: CGFloat = 1.0

    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard
    private let df = ISO8601DateFormatter()

    private var coupleId: String { CoupleService.coupleId }
    private var myUid: String { AuthService.shared.currentUser?.id ?? "" }
    private var partnerName: String { CoupleService.shared.partnerName }
    private var myName: String { CoupleService.shared.currentName }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                mapLayer
                overlayContent
            }
            .navigationTitle("Ubicacion")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar lugares")
            .onSubmit(of: .search) {
                if let first = filteredPlaces.first {
                    centerOnPlace(first)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(locationService.isSharing ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(locationService.isSharing ? "Compartiendo" : "Apagado")
                            .appFont(size: 11)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        toggleSharing()
                    } label: {
                        Image(systemName: locationService.isSharing ? "location.fill" : "location.slash")
                            .foregroundColor(locationService.isSharing ? theme.primary : theme.textSecondary)
                    }
                    Menu {
                        Picker("Estilo", selection: $mapStyle) {
                            Label("Estandar", systemImage: "map").tag(MapStyleOption.standard)
                            Label("Satelite", systemImage: "globe.americas").tag(MapStyleOption.satellite)
                            Label("Hibrido", systemImage: "map.fill").tag(MapStyleOption.hybrid)
                        }
                        Divider()
                        Button {
                            showHistory = true
                        } label: {
                            Label("Historial", systemImage: "clock.arrow.circlepath")
                        }
                        Button {
                            showStats = true
                        } label: {
                            Label("Estadisticas", systemImage: "chart.bar")
                        }
                        Button {
                            showRouteShare = true
                        } label: {
                            Label("Compartir ruta", systemImage: "arrow.triangle.branch")
                        }
                        Divider()
                        Button {
                            showSettings = true
                        } label: {
                            Label("Ajustes", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showPartnerCard) {
                PartnerInfoCardView(
                    partnerName: partnerName,
                    locationService: locationService,
                    theme: theme,
                    onDirections: openDirections,
                    onChat: openChat,
                    onCall: callPartner,
                    onArrived: sendArrived,
                    onHistory: { showPartnerCard = false; showHistory = true },
                    onPlaces: { showPartnerCard = false; showPlacesList = true },
                    onDismiss: { showPartnerCard = false }
                )
            }
            .sheet(isPresented: $showPlacesList) { placesListView }
            .sheet(isPresented: $showAddPlace) { addPlaceView }
            .sheet(isPresented: $showHistory) { historyView }
            .sheet(isPresented: $showStats) { statsView }
            .sheet(isPresented: $showSettings) { settingsView }
            .sheet(isPresented: $showRouteShare) { routeShareView }
            .sheet(isPresented: $showPlaceDetail) { placeDetailView }
            .sheet(isPresented: $showAddMemory) { addMemoryView }
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                loadPlaces()
                if !locationService.isSharing && defaults.bool(forKey: "location_sharing_enabled") {
                    locationService.startSharing()
                }
                startPulseAnimation()
                fetchWeather()
                checkGeofences()
            }
            .onChange(of: locationService.partnerLatitude) { _, newLat in
                checkGeofences()
                checkProximity()
                withAnimation(.easeInOut(duration: 0.5)) {
                    if case .automatic = cameraPosition {}
                }
            }
            .onChange(of: locationService.partnerRoute) { _, newRoute in
                if let route = newRoute {
                    let ref = db.collection("couples").document(coupleId).collection("activities").document()
                    ref.setData([
                        "type": "route_started",
                        "title": "Ruta iniciada",
                        "text": "\(partnerName) inicio una ruta hacia \(route.destination)",
                        "icon": "arrow.triangle.branch",
                        "fromUid": myUid,
                        "fromName": myName,
                        "timestamp": Timestamp(date: Date())
                    ])
                }
            }
            .onChange(of: locationService.isSharing) { _, newVal in
                if !newVal {
                    let ref = db.collection("couples").document(coupleId).collection("activities").document()
                    ref.setData([
                        "type": "sharing_disabled",
                        "title": "Ubicacion desactivada",
                        "text": "\(myName) desactivo la ubicacion",
                        "icon": "location.slash",
                        "fromUid": myUid,
                        "fromName": myName,
                        "timestamp": Timestamp(date: Date())
                    ])
                }
            }
            .onChange(of: locationService.lastLatitude) { _, _ in
                fetchWeather()
                checkGeofences()
                checkTogether()
            }
            .onChange(of: locationService.partnerBattery) { _, newVal in
                if let level = newVal, level <= 15, level > 0 {
                    sendLowBatteryNotif()
                }
            }
            .onChange(of: locationService.partnerOnline) { _, newVal in
                if !newVal {
                    sendLostConnectionNotif()
                }
            }
        }
    }

    // MARK: - Weather

    private func fetchWeather() {
        let lat = locationService.partnerLatitude ?? locationService.lastLatitude ?? 19.4326
        let lng = locationService.partnerLongitude ?? locationService.lastLongitude ?? -99.1332
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&current_weather=true"
        guard let url = URL(string: urlStr) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let d = data,
                  let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                  let cw = json["current_weather"] as? [String: Any],
                  let temp = cw["temperature"] as? Double,
                  let code = cw["weathercode"] as? Int else { return }
            let (icon, condition) = self.weatherSymbol(for: code)
            DispatchQueue.main.async {
                self.weather = WeatherInfo(condition: condition, icon: icon, temperature: Int(temp))
            }
        }.resume()
    }

    private func weatherSymbol(for code: Int) -> (String, String) {
        switch code {
        case 0: return ("sun.max.fill", "Despejado")
        case 1,2,3: return ("cloud.sun.fill", "Parcialmente nublado")
        case 45,48: return ("cloud.fog.fill", "Niebla")
        case 51...57: return ("cloud.drizzle.fill", "Llovizna")
        case 61...67: return ("cloud.rain.fill", "Lluvia")
        case 71...77: return ("cloud.snow.fill", "Nieve")
        case 80...84: return ("cloud.rain.fill", "Chubascos")
        case 95...99: return ("cloud.bolt.fill", "Tormenta")
        default: return ("cloud.fill", "Nublado")
        }
    }

    // MARK: - Geofences

    private func checkGeofences() {
        guard let myLat = locationService.lastLatitude,
              let myLng = locationService.lastLongitude else { return }
        for place in places {
            let dist = locationService.haversine(lat1: myLat, lon1: myLng, lat2: place.latitude, lon2: place.longitude)
            let key = "geofence_\(place.id)"
            let wasInside = defaults.bool(forKey: key)
            let isInside = dist <= place.radius
            if isInside && !wasInside && place.notifyArrival {
                sendGeofenceNotif("Llegaste a \(place.name)", type: "arrival")
            } else if !isInside && wasInside && place.notifyDeparture {
                sendGeofenceNotif("Saliste de \(place.name)", type: "departure")
            }
            defaults.set(isInside, forKey: key)
        }
    }

    private func sendGeofenceNotif(_ text: String, type: String) {
        let ref = db.collection("couples").document(coupleId).collection("activities").document()
        ref.setData([
            "type": type,
            "title": type == "arrival" ? "Llegada" : "Salida",
            "text": text,
            "icon": "mappin.and.ellipse",
            "fromUid": myUid,
            "fromName": myName,
            "timestamp": Timestamp(date: Date()),
            "lat": locationService.lastLatitude ?? 0,
            "lng": locationService.lastLongitude ?? 0
        ])
    }

    private func sendLowBatteryNotif() {
        let ref = db.collection("couples").document(coupleId).collection("activities").document()
        ref.setData([
            "type": "low_battery",
            "title": "Bateria baja",
            "text": "\(partnerName) tiene poca bateria (\(locationService.partnerBattery ?? 0)%)",
            "icon": "battery.25",
            "fromUid": myUid,
            "fromName": myName,
            "timestamp": Timestamp(date: Date())
        ])
    }

    private static let proximityNotifMinInterval: TimeInterval = 300

    private func checkProximity() {
        guard let d = locationService.distanceToPartner else { return }
        if d < 0.5 {
            let now = Date()
            let last = defaults.object(forKey: "last_proximity_notif") as? Date
            if let last = last, now.timeIntervalSince(last) < Self.proximityNotifMinInterval { return }
            defaults.set(now, forKey: "last_proximity_notif")
            let ref = db.collection("couples").document(coupleId).collection("activities").document()
            ref.setData([
                "type": "proximity",
                "title": "Cerca de ti",
                "text": "\(partnerName) esta a menos de 500 m",
                "icon": "figure.wave",
                "fromUid": myUid,
                "fromName": myName,
                "timestamp": Timestamp(date: now)
            ])
        }
    }

    private func sendLostConnectionNotif() {
        let ref = db.collection("couples").document(coupleId).collection("activities").document()
        ref.setData([
            "type": "lost_connection",
            "title": "Sin conexion",
            "text": "\(partnerName) perdio conexion",
            "icon": "wifi.slash",
            "fromUid": myUid,
            "fromName": myName,
            "timestamp": Timestamp(date: Date())
        ])
    }

    private func checkTogether() {
        guard let d = locationService.distanceToPartner, d < 0.05 else { return }
        let now = Date()
        let last = defaults.object(forKey: "last_together_notif") as? Date
        if let last = last, now.timeIntervalSince(last) < 600 { return }
        defaults.set(now, forKey: "last_together_notif")
        let ref = db.collection("couples").document(coupleId).collection("activities").document()
        ref.setData([
            "type": "together",
            "title": "Estan juntos",
            "text": "Disfruten este momento \u{2764}",
            "icon": "heart.fill",
            "fromUid": myUid,
            "fromName": myName,
            "timestamp": Timestamp(date: now)
        ])
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }

    private var filteredPlaces: [PartnerPlace] {
        if searchText.isEmpty { return places }
        return places.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
        let annotations = allAnnotations
        return Map(position: $cameraPosition) {
            ForEach(annotations) { item in
                Annotation(item.label, coordinate: item.coordinate) {
                    Button {
                        if item.id == "partner" {
                            selectedAnnotationId = item.id
                            showPartnerCard = true
                        } else if item.id != "me" && item.id != "together" {
                            if let place = places.first(where: { $0.id == item.id }) {
                                centerOnPlace(place)
                            }
                        }
                    } label: {
                        annotationView(for: item)
                    }
                    .buttonStyle(.plain)
                }
                .annotationTitles(.hidden)
            }
            if let route = locationService.partnerRoute, route.polyline.count > 1 {
                MapPolyline(coordinates: route.polyline)
                    .stroke(Color.orange.opacity(0.7), lineWidth: 3)
            }
            if locationService.isRouting, locationService.routePolyline.count > 1 {
                MapPolyline(coordinates: Array(locationService.routePolyline))
                    .stroke(theme.primary.opacity(0.7), lineWidth: 3)
            }
        }
        .mapStyle(mapStyle == .standard ? .standard : (mapStyle == .satellite ? .imagery : .hybrid))
    }

    @ViewBuilder
    private func annotationView(for item: MapAnnotationItem) -> some View {
        if item.isPartner, let urlStr = item.photoURL, let url = URL(string: urlStr) {
            ZStack {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Circle().fill(item.color)
                            Text(String(item.label.prefix(1)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: item.color.opacity(0.4), radius: 6)
                .scaleEffect(pulseScale)
            }
        } else if item.isPartner {
            ZStack {
                Circle()
                    .fill(item.color)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: item.color.opacity(0.4), radius: 6)
                    .scaleEffect(pulseScale)
                Text(String(item.label.prefix(1)))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
        } else if item.isHeart {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .scaleEffect(pulseScale)
                Text("\u{2764}")
                    .font(.system(size: 22))
            }
        } else if item.id == "me" {
            ZStack {
                Circle()
                    .fill(item.color)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(color: item.color.opacity(0.4), radius: 6)
                Text(String(item.label.prefix(1)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        } else {
            ZStack {
                Capsule()
                    .fill(item.color)
                    .frame(width: 28, height: 34)
                    .overlay(Capsule().stroke(Color.white, lineWidth: 2))
                    .shadow(color: item.color.opacity(0.3), radius: 4)
                Image(systemName: placeIconSF(item.imageName ?? "heart"))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }

    private var allAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
            items.append(MapAnnotationItem(
                id: "me", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                label: myName, color: theme.primary, isHeart: false, isPartner: false, imageName: nil, photoURL: nil
            ))
        }
        if let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude {
            let puid = CoupleService.shared.partnerUid
            let photoURL = "https://ui-avatars.com/api/?name=\(partnerName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "U")&background=5684EE&color=fff&size=64"
            items.append(MapAnnotationItem(
                id: "partner", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                label: partnerName, color: Color.blue, isHeart: false, isPartner: true, imageName: nil, photoURL: photoURL
            ))
        }
        if let myLat = locationService.lastLatitude, let myLng = locationService.lastLongitude,
           let pLat = locationService.partnerLatitude, let pLng = locationService.partnerLongitude {
            let dist = locationService.haversine(lat1: myLat, lon1: myLng, lat2: pLat, lon2: pLng)
            if dist < 50 {
                let midLat = (myLat + pLat) / 2
                let midLng = (myLng + pLng) / 2
                items.append(MapAnnotationItem(
                    id: "together", coordinate: CLLocationCoordinate2D(latitude: midLat, longitude: midLng),
                    label: "Estan juntos", color: .red, isHeart: true, isPartner: false, imageName: nil, photoURL: nil
                ))
            }
        }
        for place in filteredPlaces {
            items.append(MapAnnotationItem(
                id: place.id, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                label: place.name, color: parseColor(place.color), isHeart: false, isPartner: false, imageName: place.icon, photoURL: nil
            ))
        }
        return items
    }

    // MARK: - Overlay Content

    private var overlayContent: some View {
        VStack(spacing: 0) {
            Spacer()
            mapControlsOverlay
            bottomSheet
        }
    }

    // MARK: - Map Controls

    private var mapControlsOverlay: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                controlButton(icon: "plus") { zoomIn() }
                controlButton(icon: "minus") { zoomOut() }
                controlButton(icon: "location") { centerOnMe() }
                controlButton(icon: "person.2") { centerOnBoth() }
                controlButton(icon: "safari") { resetNorth() }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 8)
        }
    }

    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textPrimary)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.08), radius: 4)
        }
    }

    // MARK: - Bottom Sheet

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)

            VStack(spacing: 10) {
                if let route = locationService.partnerRoute {
                    routeBanner(route)
                }
                if let dist = locationService.distanceToPartner, dist < 0.05 {
                    togetherBanner
                }
                distanceRow
                statusRow
                speedBatteryRow
                if let w = weather {
                    weatherRow(w)
                }
                quickActionsRow
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 12, y: -4)
        .offset(y: sheetOffset)
        .gesture(
            DragGesture()
                .onChanged { val in
                    let newOffset = val.translation.height
                    if newOffset > 0 {
                        sheetOffset = min(newOffset, 300)
                    }
                }
                .onEnded { val in
                    withAnimation(.interpolatingSpring(stiffness: 200, damping: 25)) {
                        if val.translation.height > 100 {
                            sheetOffset = 200
                        } else {
                            sheetOffset = 0
                        }
                    }
                }
        )
    }

    // MARK: - Route Banner

    private func routeBanner(_ route: ActiveRoute) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            Text("\(partnerName) va hacia \(route.destination)")
                .appFont(size: 11, weight: .medium)
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
            Spacer()
            if !route.eta.isEmpty {
                Text(route.eta)
                    .appFont(size: 10, weight: .bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Together Banner

    private var togetherBanner: some View {
        HStack(spacing: 8) {
            Text("\u{2764}")
                .font(.system(size: 18))
                .scaleEffect(pulseScale)
            Text("Estan juntos")
                .appFont(size: 13, weight: .bold)
                .foregroundColor(.red)
            Spacer()
        }
        .padding(10)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Distance Row

    private var distanceRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text("\u{2764}")
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(myName) & \(partnerName)")
                    .appFont(size: 13, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
                if let dist = locationService.distanceToPartner {
                    Text(formatDistance(dist))
                        .appFont(size: 11)
                        .foregroundColor(theme.textSecondary)
                } else {
                    Text("Calculando distancia...")
                        .appFont(size: 11)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let dist = locationService.distanceToPartner {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(etaCar(dist))
                        .appFont(size: 11, weight: .medium)
                        .foregroundColor(theme.textPrimary)
                    Text(etaWalk(dist))
                        .appFont(size: 10)
                        .foregroundColor(theme.textSecondary)
                }
            }
            Button {
                showPartnerCard = true
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Status Row

    private var statusRow: some View {
        HStack(spacing: 8) {
            statusChip(
                icon: partnerStatusIcon(),
                label: partnerStatusText(),
                color: locationService.partnerOnline ? .green : (locationService.partnerIsGPSOn ? .gray : .orange)
            )
            if let date = locationService.partnerLastUpdate {
                statusChip(
                    icon: "clock",
                    label: lastUpdateText(date),
                    color: theme.textSecondary
                )
            }
            if let addr = locationService.partnerAddress, !addr.isEmpty {
                statusChip(
                    icon: "location",
                    label: addr.prefix(20) + (addr.count > 20 ? "..." : ""),
                    color: theme.primary
                )
            }
        }
    }

    private func statusChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
            Text(label)
                .appFont(size: 10)
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func partnerStatusIcon() -> String {
        if !locationService.partnerIsGPSOn { return "location.slash" }
        if locationService.partnerOnline { return "circle.fill" }
        return "circle.slash"
    }

    private func partnerStatusText() -> String {
        if !locationService.partnerIsGPSOn { return "GPS apagado" }
        if locationService.partnerOnline { return "En linea" }
        return "Offline"
    }

    // MARK: - Speed / Battery Row

    private var speedBatteryRow: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 8), count: 4), spacing: 6) {
            infoTile(icon: speedIcon, label: "Velocidad", value: speedValue)
            infoTile(icon: batteryIconName, label: "Bateria", value: batteryValue)
            infoTile(icon: "scope", label: "Precision", value: precisionValue)
            infoTile(icon: motionIconName, label: "Estado", value: motionLabel)
        }
    }

    private func infoTile(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.primary)
            Text(value)
                .appFont(size: 12, weight: .semibold)
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
            Text(label)
                .appFont(size: 9)
                .foregroundColor(theme.textSecondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var speedIcon: String {
        if let s = locationService.partnerSpeed, s > 10 { return "car.fill" }
        return "figure.walk"
    }

    private var speedValue: String {
        guard let s = locationService.partnerSpeed else { return "--" }
        return String(format: "%.1f km/h", s)
    }

    private var batteryIconName: String {
        guard let level = locationService.partnerBattery else { return "battery.25" }
        let isCharging = locationService.partnerIsCharging ?? false
        if isCharging { return "battery.100.bolt" }
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }

    private var batteryValue: String {
        guard let level = locationService.partnerBattery else { return "--" }
        let charging = locationService.partnerIsCharging ?? false
        return "\(level)%" + (charging ? " +" : "")
    }

    private var precisionValue: String {
        guard let p = locationService.partnerPrecision else { return "--" }
        if p < 10 { return "Alta" }
        if p < 50 { return "Media" }
        return "Baja"
    }

    private var motionIconName: String {
        motionIcon(for: locationService.partnerMotion)
    }

    private var motionLabel: String {
        motionLabel(for: locationService.partnerMotion)
    }

    // MARK: - Weather Row

    private func weatherRow(_ w: WeatherInfo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: w.icon)
                .font(.system(size: 18))
                .foregroundColor(theme.primary)
            Text("\(w.temperature)\u{00B0}")
                .appFont(size: 14, weight: .semibold)
                .foregroundColor(theme.textPrimary)
            Text(w.condition)
                .appFont(size: 11)
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Quick Actions Row

    private var quickActionsRow: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 8), count: 4), spacing: 8) {
            quickActionButton(icon: "location.circle.fill", label: "Como llegar", color: .blue) { openDirections() }
            quickActionButton(icon: "hand.thumbsup.fill", label: "LLegue bien", color: .green) { sendArrived() }
            quickActionButton(icon: "bell.badge.fill", label: "Notificar", color: .orange) { showNotificationAlert = true }
            quickActionButton(icon: "building.2.fill", label: "Lugares", color: theme.primary) { showPlacesList = true }
        }
        .padding(.top, 2)
        .alert("Enviar notificacion", isPresented: $showNotificationAlert) {
            TextField("Mensaje...", text: $notificationMessage)
            Button("Enviar") { sendCustomNotif() }
            Button("Cancelar", role: .cancel) { notificationMessage = "" }
        } message: {
            Text("Escribe un mensaje para \(partnerName)")
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(label)
                    .appFont(size: 9, weight: .medium)
                    .foregroundColor(theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Places List Sheet

    private var placesListView: some View {
        NavigationStack {
            List {
                if places.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("No hay lugares guardados")
                            .appFont(size: 14)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(places) { place in
                        Button {
                            selectedPlace = place
                            showPlaceDetail = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(parseColor(place.color).opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: placeIconSF(place.icon))
                                        .font(.system(size: 14))
                                        .foregroundColor(parseColor(place.color))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.name)
                                        .appFont(size: 14, weight: .medium)
                                        .foregroundColor(theme.textPrimary)
                                    if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
                                        Text(formatDistance(locationService.haversine(lat1: lat, lon1: lng, lat2: place.latitude, lon2: place.longitude) / 1000.0))
                                            .appFont(size: 11)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                }
                                Spacer()
                                Text("\(Int(place.radius))m")
                                    .appFont(size: 11)
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            deletePlace(places[idx])
                        }
                    }
                }
            }
            .navigationTitle("Lugares")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddPlace = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showPlacesList = false }
                }
            }
        }
    }

    // MARK: - Add Place Sheet

    private var addPlaceView: some View {
        NavigationStack {
            Form {
                Section("Lugar") {
                    TextField("Nombre", text: $placeName)
                }

                Section("Icono") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            let icons = ["heart", "star", "house", "building", "bag", "cup.and.saucer", "fork.knife", "cart", "fuelpump", "airplane", "suitcase", "beach.umbrella", "tent", "tree", "mappin"]
                            ForEach(icons, id: \.self) { ico in
                                ZStack {
                                    Circle()
                                        .fill(placeIcon == ico ? parseColor(colorStr).opacity(0.2) : Color.clear)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: placeIconSF(ico))
                                        .font(.system(size: 16))
                                        .foregroundColor(placeIcon == ico ? parseColor(colorStr) : .secondary)
                                }
                                .onTapGesture { placeIcon = ico }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            let colors = ["#FF6B9D", "#FF7F7F", "#FFB37F", "#FFD700", "#7FFF7F", "#7FB2FF", "#B27FFF", "#FF7FFF"]
                            ForEach(colors, id: \.self) { col in
                                ZStack {
                                    Circle()
                                        .fill(parseColor(col))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(colorStr == col ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                        .shadow(color: colorStr == col ? parseColor(col).opacity(0.4) : .clear, radius: 4)
                                }
                                .onTapGesture { colorStr = col }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Radio") {
                    VStack {
                        Slider(value: $placeRadius, in: 10...500, step: 10)
                        Text("\(Int(placeRadius)) metros")
                            .appFont(size: 12)
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Section("Notificaciones") {
                    Toggle("Al llegar", isOn: $notifyArrival)
                    Toggle("Al salir", isOn: $notifyDeparture)
                }

                Section("Ubicacion actual") {
                    HStack {
                        if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
                            Text(String(format: "%.4f, %.4f", lat, lng))
                                .appFont(size: 12)
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                            Button("Usar esta") {
                                placeLat = lat
                                placeLng = lng
                            }
                            .appFont(size: 12, weight: .medium)
                            .foregroundColor(theme.primary)
                        } else {
                            Text("Sin ubicacion")
                                .appFont(size: 12)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Nuevo lugar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showAddPlace = false
                        resetPlaceForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { savePlace() }
                        .disabled(placeName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func resetPlaceForm() {
        placeName = ""
        placeIcon = "heart"
        colorStr = "#FF6B9D"
        placeRadius = 100
        notifyArrival = true
        notifyDeparture = false
        placeLat = 0
        placeLng = 0
    }

    // MARK: - History Sheet

    private var historyView: some View {
        NavigationStack {
            Group {
                if locationHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("Sin historial")
                            .appFont(size: 15, weight: .medium)
                            .foregroundColor(theme.textPrimary)
                        Text("El historial de ubicaciones aparecera aqui")
                            .appFont(size: 12)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.backgroundGradient.ignoresSafeArea())
                } else {
                    List {
                        ForEach(groupedHistory, id: \.date) { dayGroup in
                            Section(header: dayHeader(dayGroup.date)) {
                                ForEach(Array(dayGroup.entries.enumerated()), id: \.element.id) { idx, entry in
                                    VStack(spacing: 2) {
                                        Button {
                                            openMapAt(lat: entry.latitude, lng: entry.longitude)
                                        } label: {
                                            HStack(spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(typeColor(entry.type).opacity(0.15))
                                                        .frame(width: 36, height: 36)
                                                    Image(systemName: typeIcon(entry.type))
                                                        .font(.system(size: 14))
                                                        .foregroundColor(typeColor(entry.type))
                                                }
                                                VStack(alignment: .leading, spacing: 2) {
                                                    HStack(spacing: 6) {
                                                        if let icon = entry.placeIcon, !icon.isEmpty {
                                                            Image(systemName: placeIconSF(icon))
                                                                .font(.system(size: 10))
                                                                .foregroundColor(typeColor(entry.type))
                                                        }
                                                        Text(entry.place ?? typeName(entry.type))
                                                            .appFont(size: 14, weight: .medium)
                                                            .foregroundColor(theme.textPrimary)
                                                        Spacer()
                                                        Text(entry.timestamp, style: .time)
                                                            .appFont(size: 10)
                                                            .foregroundColor(theme.textSecondary)
                                                    }
                                                    Text(typeName(entry.type))
                                                        .appFont(size: 10)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        if idx < dayGroup.entries.count - 1 {
                                            Image(systemName: "arrowtriangle.down.fill")
                                                .font(.system(size: 8))
                                                .foregroundColor(theme.primary.opacity(0.3))
                                                .padding(.vertical, 2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showHistory = false }
                }
            }
            .onAppear { loadHistory() }
        }
    }

    private struct DayGroup {
        var date: Date
        var entries: [LocationHistoryEntry]
    }

    private var groupedHistory: [DayGroup] {
        let grouped = Dictionary(grouping: locationHistory) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
        return grouped.map { DayGroup(date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    private func dayHeader(_ date: Date) -> some View {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es")
        if Calendar.current.isDateInToday(date) {
            return Text("Hoy").appFont(size: 13, weight: .semibold).foregroundColor(theme.primary)
        } else if Calendar.current.isDateInYesterday(date) {
            return Text("Ayer").appFont(size: 13, weight: .semibold).foregroundColor(theme.primary)
        } else {
            f.dateFormat = "EEEE d MMM"
            return Text(f.string(from: date).capitalized).appFont(size: 13, weight: .semibold).foregroundColor(theme.primary)
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "arrival": return .green
        case "departure": return .orange
        case "manual": return theme.primary
        default: return .secondary
        }
    }

    private func typeIcon(_ type: String) -> String {
        switch type {
        case "arrival": return "arrow.down.circle"
        case "departure": return "arrow.up.circle"
        case "manual": return "pencil.circle"
        default: return "location.circle"
        }
    }

    private func typeName(_ type: String) -> String {
        switch type {
        case "arrival": return "Llegada"
        case "departure": return "Salida"
        case "manual": return "Manual"
        default: return "Ubicacion"
        }
    }

    // MARK: - Stats Sheet

    @State private var dailyStats = DailyStats(kilometers: 0, timeOutside: 0, placesVisited: 0, timeTogether: 0)

    private var statsView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 4) {
                        Text("Hoy")
                            .appFont(size: 14, weight: .semibold)
                            .foregroundColor(theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            statCard(icon: "ruler", value: dailyKm, label: "Kilometros", color: theme.primary)
                            statCard(icon: "clock.arrow.circlepath", value: dailyTimeOutside, label: "Tiempo fuera", color: .blue)
                            statCard(icon: "mappin.and.ellipse", value: "\(dailyStats.placesVisited)", label: "Lugares", color: .orange)
                            statCard(icon: "heart.fill", value: dailyTimeTogether, label: "Tiempo juntos", color: .red)
                        }
                    }

                    if let dist = locationService.distanceToPartner {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Distancia actual: \(distanceDisplayValue)")
                                .appFont(size: 13, weight: .medium)
                                .foregroundColor(theme.textPrimary)
                            Text("Tiempo estimado")
                                .appFont(size: 14, weight: .semibold)
                                .foregroundColor(theme.textPrimary)
                            HStack(spacing: 12) {
                                etaCard(icon: "car.fill", label: "Auto", time: etaCar(dist))
                                etaCard(icon: "figure.walk", label: "Caminando", time: etaWalk(dist))
                                etaCard(icon: "shoeprints.fill", label: "Pasos", time: stepsEstimate(dist))
                            }
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: locationService.partnerOnline ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 10))
                            .foregroundColor(locationService.partnerOnline ? .green : .gray)
                        Text("\(partnerName): \(locationService.partnerOnline ? "Conectado" : "Desconectado")")
                            .appFont(size: 11)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Estadisticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showStats = false }
                }
            }
            .onAppear { loadDailyStats() }
        }
    }

    private var dailyKm: String {
        if dailyStats.kilometers < 1 {
            return "\(Int(dailyStats.kilometers * 1000))m"
        }
        return String(format: "%.1f km", dailyStats.kilometers)
    }

    private var dailyTimeOutside: String {
        let t = dailyStats.timeOutside
        let hours = Int(t) / 3600
        let mins = (Int(t) % 3600) / 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }

    private var dailyTimeTogether: String {
        let t = dailyStats.timeTogether
        let hours = Int(t) / 3600
        let mins = (Int(t) % 3600) / 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }

    private func loadDailyStats() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        db.collection("parejas").document(coupleId).collection("ubicacion").getDocuments { snap, _ in
            guard let docs = snap?.documents else { return }
            var totalKm = 0.0
            var togetherMinutes = 0.0
            for doc in docs {
                let d = doc.data()
                if let lat = d["latitude"] as? Double, let lng = d["longitude"] as? Double {
                    totalKm += 0.1
                }
            }
            dailyStats = DailyStats(
                kilometers: totalKm,
                timeOutside: totalKm > 0 ? totalKm * 300 : 0,
                placesVisited: places.count,
                timeTogether: locationService.distanceToPartner.map { $0 < 0.05 ? 3600 : 0 } ?? 0
            )
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(value)
                .appFont(size: 18, weight: .bold)
                .foregroundColor(theme.textPrimary)
            Text(label)
                .appFont(size: 10)
                .foregroundColor(theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func etaCard(icon: String, label: String, time: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(time)
                    .appFont(size: 14, weight: .semibold)
                    .foregroundColor(theme.textPrimary)
                Text(label)
                    .appFont(size: 10)
                    .foregroundColor(theme.textSecondary)
            }
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var distanceDisplayValue: String {
        guard let d = locationService.distanceToPartner else { return "--" }
        if d < 1 { return "\(Int(d * 1000))m" }
        return String(format: "%.2f km", d)
    }

    // MARK: - Settings Sheet

    @State private var shareLocation = true
    @State private var shareBattery = true
    @State private var shareSpeed = true
    @State private var shareDirection = true
    @State private var shareHistory = true
    @State private var shareArrivals = true
    @State private var shareDepartures = true
    @State private var shareRoute = true
    @State private var sharePlaces = true
    @State private var shareWeather = true
    @State private var sharePrecision = true

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("Ubicacion") {
                    Toggle(isOn: $shareLocation) {
                        Label("Compartir ubicacion", systemImage: "location.fill")
                    }
                    .onChange(of: shareLocation) { _, newVal in
                        saveSettings()
                        if newVal { locationService.startSharing() } else { locationService.stopSharing() }
                    }
                    Toggle(isOn: $sharePrecision) {
                        Label("Precision GPS", systemImage: "scope")
                    }
                    .onChange(of: sharePrecision) { _, _ in saveSettings() }
                    Toggle(isOn: $shareDirection) {
                        Label("Direccion", systemImage: "safari")
                    }
                    .onChange(of: shareDirection) { _, _ in saveSettings() }
                }
                Section("Dispositivo") {
                    Toggle(isOn: $shareBattery) {
                        Label("Bateria", systemImage: "battery.75")
                    }
                    .onChange(of: shareBattery) { _, _ in saveSettings() }
                    Toggle(isOn: $shareSpeed) {
                        Label("Velocidad", systemImage: "speedometer")
                    }
                    .onChange(of: shareSpeed) { _, _ in saveSettings() }
                }
                Section("Notificaciones") {
                    Toggle(isOn: $shareArrivals) {
                        Label("Llegadas", systemImage: "arrow.down.circle")
                    }
                    .onChange(of: shareArrivals) { _, _ in saveSettings() }
                    Toggle(isOn: $shareDepartures) {
                        Label("Salidas", systemImage: "arrow.up.circle")
                    }
                    .onChange(of: shareDepartures) { _, _ in saveSettings() }
                    Toggle(isOn: $shareRoute) {
                        Label("Ruta compartida", systemImage: "arrow.triangle.branch")
                    }
                    .onChange(of: shareRoute) { _, _ in saveSettings() }
                }
                Section("Contenido") {
                    Toggle(isOn: $shareHistory) {
                        Label("Historial", systemImage: "clock.arrow.circlepath")
                    }
                    .onChange(of: shareHistory) { _, _ in saveSettings() }
                    Toggle(isOn: $sharePlaces) {
                        Label("Lugares", systemImage: "building.2.fill")
                    }
                    .onChange(of: sharePlaces) { _, _ in saveSettings() }
                    Toggle(isOn: $shareWeather) {
                        Label("Clima", systemImage: "cloud.sun.fill")
                    }
                    .onChange(of: shareWeather) { _, _ in saveSettings() }
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showSettings = false }
                }
            }
            .onAppear {
                shareLocation = defaults.bool(forKey: "location_sharing_enabled")
                shareBattery = defaults.bool(forKey: "share_battery")
                shareSpeed = defaults.bool(forKey: "share_speed")
                shareDirection = defaults.bool(forKey: "share_direction")
                shareHistory = defaults.bool(forKey: "share_history")
                shareArrivals = defaults.bool(forKey: "share_arrivals")
                shareDepartures = defaults.bool(forKey: "share_departures")
                shareRoute = defaults.bool(forKey: "share_route")
                sharePlaces = defaults.bool(forKey: "share_places")
                shareWeather = defaults.bool(forKey: "share_weather")
                sharePrecision = defaults.bool(forKey: "share_precision")
            }
        }
    }

    // MARK: - Route Share Sheet

    private var routeShareView: some View {
        NavigationStack {
            Form {
                Section("Compartir ruta") {
                    Toggle(isOn: $locationService.isRouting) { Text("Compartir ruta activa") }
                }
                if locationService.isRouting {
                    Section("Destino") {
                        TextField("Destino", text: Binding(
                            get: { locationService.routeDestination ?? "" },
                            set: { locationService.routeDestination = $0 }
                        ))
                    }
                    if let eta = locationService.routeEta {
                        Section("ETA") {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(theme.primary)
                                Text(eta)
                                    .appFont(size: 14, weight: .medium)
                                    .foregroundColor(theme.textPrimary)
                            }
                        }
                    }
                    Section {
                        Button("Detener ruta", role: .destructive) {
                            locationService.stopRoute()
                        }
                    }
                }
            }
            .navigationTitle("Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showRouteShare = false }
                }
            }
            .onChange(of: locationService.isRouting) { _, newVal in
                if newVal {
                    locationService.startRoute(
                        destination: locationService.routeDestination ?? "Destino",
                        lat: locationService.lastLatitude ?? 0,
                        lng: locationService.lastLongitude ?? 0
                    )
                } else if !newVal {
                    locationService.stopRoute()
                }
            }
        }
    }

    // MARK: - Place Detail Sheet

    private var placeDetailView: some View {
        NavigationStack {
            if let place = selectedPlace {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(parseColor(place.color).opacity(0.15))
                                    .frame(width: 60, height: 60)
                                Image(systemName: placeIconSF(place.icon))
                                    .font(.system(size: 24))
                                    .foregroundColor(parseColor(place.color))
                            }
                            Text(place.name)
                                .appFont(size: 20, weight: .bold)
                                .foregroundColor(theme.textPrimary)
                            Text("Radio: \(Int(place.radius))m")
                                .appFont(size: 12)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.top, 12)

                        HStack(spacing: 12) {
                            actionChip(icon: "location.circle.fill", label: "Centrar", color: theme.primary) {
                                centerOnPlace(place)
                                showPlaceDetail = false
                            }
                            actionChip(icon: "bell.fill", label: place.notifyArrival ? "Notif. llegada on" : "Notif. llegada off", color: place.notifyArrival ? .green : .gray, action: {})
                            actionChip(icon: "bell.slash.fill", label: place.notifyDeparture ? "Notif. salida on" : "Notif. salida off", color: place.notifyDeparture ? .orange : .gray, action: {})
                        }

                        if let memories = place.memories, !memories.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Nuestros recuerdos")
                                    .appFont(size: 14, weight: .semibold)
                                    .foregroundColor(theme.textPrimary)
                                ForEach(memories) { memory in
                                    HStack(spacing: 10) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(memory.title)
                                                .appFont(size: 13, weight: .medium)
                                                .foregroundColor(theme.textPrimary)
                                            if !memory.note.isEmpty {
                                                Text(memory.note)
                                                    .appFont(size: 11)
                                                    .foregroundColor(theme.textSecondary)
                                                    .lineLimit(2)
                                            }
                                            HStack(spacing: 4) {
                                                Image(systemName: "calendar")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.secondary)
                                                Text(memory.date)
                                                    .appFont(size: 9)
                                                    .foregroundColor(.secondary)
                                                if memory.photoCount > 0 {
                                                    Text("· \(memory.photoCount) fotos")
                                                        .appFont(size: 9)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "heart.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text("Aun no hay recuerdos")
                                    .appFont(size: 12)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 20)
                        }

                        Button {
                            showAddMemory = true
                        } label: {
                            Label("Agregar recuerdo", systemImage: "plus.heart.fill")
                                .appFont(size: 13, weight: .medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(role: .destructive) {
                            deletePlace(place)
                            showPlaceDetail = false
                        } label: {
                            Label("Eliminar lugar", systemImage: "trash")
                                .appFont(size: 13, weight: .medium)
                        }
                    }
                    .padding(16)
                }
                .background(theme.backgroundGradient.ignoresSafeArea())
                .navigationTitle(place.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { showPlaceDetail = false }
                    }
                }
            }
        }
    }

    private func actionChip(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .appFont(size: 10)
            }
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Add Memory Sheet

    private var addMemoryView: some View {
        NavigationStack {
            Form {
                Section("Recuerdo") {
                    TextField("Titulo", text: $memoryTitle)
                    TextField("Nota", text: $memoryNote)
                    DatePicker("Fecha", selection: $memoryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Nuevo recuerdo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetMemoryForm()
                        showAddMemory = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveMemory() }
                        .disabled(memoryTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func resetMemoryForm() {
        memoryTitle = ""
        memoryNote = ""
        memoryDate = Date()
    }

    private func saveMemory() {
        guard let place = selectedPlace, !memoryTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let memRef = db.collection("parejas").document(coupleId).collection("ubicacion").document("lugares").collection("data").document(place.id).collection("memories").document()
        let data: [String: Any] = [
            "title": memoryTitle.trimmingCharacters(in: .whitespaces),
            "note": memoryNote.trimmingCharacters(in: .whitespaces),
            "date": df.string(from: memoryDate),
            "photoCount": 0,
            "createdAt": df.string(from: Date())
        ]
        memRef.setData(data) { _ in
            loadPlaces()
            resetMemoryForm()
            showAddMemory = false
        }
    }

    // MARK: - Helper Functions

    private func toggleSharing() {
        if locationService.isSharing {
            locationService.stopSharing()
            defaults.set(false, forKey: "location_sharing_enabled")
        } else {
            locationService.startSharing()
            defaults.set(true, forKey: "location_sharing_enabled")
        }
    }

    private func openDirections() {
        guard let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude else { return }
        let urlStr = "http://maps.apple.com/?daddr=\(lat),\(lng)&dirflg=d"
        guard let url = URL(string: urlStr) else { return }
        UIApplication.shared.open(url)
    }

    private func openChat() {
        showPartnerCard = false
    }

    private func callPartner() {
        guard let url = URL(string: "tel://") else { return }
        UIApplication.shared.open(url)
    }

    private func sendArrived() {
        let activityRef = db.collection("couples").document(coupleId).collection("activities").document()
        activityRef.setData([
            "type": "arrived",
            "title": "LLegue bien",
            "text": "\(myName) llego bien \u{2764}",
            "icon": "hand.thumbsup.fill",
            "fromUid": myUid,
            "fromName": myName,
            "timestamp": Timestamp(date: Date()),
            "lat": locationService.lastLatitude ?? 0,
            "lng": locationService.lastLongitude ?? 0
        ])
    }

    private func sendCustomNotif() {
        guard !notificationMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let activityRef = db.collection("couples").document(coupleId).collection("activities").document()
        activityRef.setData([
            "type": "notification",
            "title": "Notificacion",
            "text": notificationMessage,
            "icon": "bell.badge.fill",
            "fromUid": myUid,
            "fromName": myName,
            "timestamp": Timestamp(date: Date())
        ])
        notificationMessage = ""
    }

    private func savePlace() {
        guard !placeName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let placeRef = db.collection("parejas").document(coupleId).collection("ubicacion").document("lugares").collection("data").document()
        let data: [String: Any] = [
            "name": placeName.trimmingCharacters(in: .whitespaces),
            "icon": placeIcon,
            "color": colorStr,
            "latitude": placeLat,
            "longitude": placeLng,
            "radius": placeRadius,
            "notifyArrival": notifyArrival,
            "notifyDeparture": notifyDeparture
        ]
        placeRef.setData(data) { _ in
            loadPlaces()
        }
        let notifRef = db.collection("couples").document(coupleId).collection("activities").document()
        notifRef.setData([
            "type": "new_place",
            "title": "Nuevo lugar",
            "text": "\(myName) agrego \(placeName) como lugar favorito",
            "icon": "heart.fill",
            "fromUid": myUid,
            "fromName": myName,
            "timestamp": Timestamp(date: Date())
        ])
        resetPlaceForm()
        showAddPlace = false
    }

    private func deletePlace(_ place: PartnerPlace) {
        db.collection("parejas").document(coupleId).collection("ubicacion").document("lugares").collection("data").document(place.id).delete { _ in
            loadPlaces()
        }
    }

    private func loadPlaces() {
        db.collection("parejas").document(coupleId).collection("ubicacion").document("lugares").collection("data").getDocuments { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let group = DispatchGroup()
            var items: [PartnerPlace] = []
            for doc in docs {
                group.enter()
                let d = doc.data()
                guard let name = d["name"] as? String else { group.leave(); continue }
                var place = PartnerPlace(
                    id: doc.documentID,
                    name: name,
                    icon: d["icon"] as? String ?? "heart",
                    color: d["color"] as? String ?? "#FF6B9D",
                    latitude: d["latitude"] as? Double ?? 0,
                    longitude: d["longitude"] as? Double ?? 0,
                    radius: d["radius"] as? Double ?? 100,
                    notifyArrival: d["notifyArrival"] as? Bool ?? false,
                    notifyDeparture: d["notifyDeparture"] as? Bool ?? false,
                    memories: nil
                )
                db.collection("parejas").document(self.coupleId).collection("lugares").document(doc.documentID).collection("memories").getDocuments { memSnap, _ in
                    if let memDocs = memSnap?.documents {
                        place.memories = memDocs.compactMap { memDoc -> PlaceMemory? in
                            let md = memDoc.data()
                            guard let title = md["title"] as? String else { return nil }
                            return PlaceMemory(
                                id: memDoc.documentID,
                                title: title,
                                date: md["date"] as? String ?? "",
                                note: md["note"] as? String ?? "",
                                photoCount: md["photoCount"] as? Int ?? 0,
                                songName: md["songName"] as? String,
                                createdAt: md["createdAt"] as? String ?? ""
                            )
                        }
                    }
                    items.append(place)
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                self.places = items
            }
        }
    }

    private func loadHistory() {
        db.collection("parejas").document(coupleId).collection("ubicacion").document("history").collection("data")
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let items = docs.compactMap { doc -> LocationHistoryEntry? in
                    let d = doc.data()
                    let date: Date
                    if let ts = d["timestamp"] as? Timestamp {
                        date = ts.dateValue()
                    } else if let str = d["timestamp"] as? String {
                        date = self.df.date(from: str) ?? Date()
                    } else {
                        date = Date()
                    }
                    return LocationHistoryEntry(
                        id: doc.documentID,
                        place: d["place"] as? String,
                        placeIcon: d["placeIcon"] as? String,
                        latitude: d["latitude"] as? Double ?? 0,
                        longitude: d["longitude"] as? Double ?? 0,
                        timestamp: date,
                        type: d["type"] as? String ?? "manual"
                    )
                }
                locationHistory = items
            }
    }

    private func saveSettings() {
        defaults.set(shareLocation, forKey: "location_sharing_enabled")
        defaults.set(shareBattery, forKey: "share_battery")
        defaults.set(shareSpeed, forKey: "share_speed")
        defaults.set(shareDirection, forKey: "share_direction")
        defaults.set(shareHistory, forKey: "share_history")
        defaults.set(shareArrivals, forKey: "share_arrivals")
        defaults.set(shareDepartures, forKey: "share_departures")
        defaults.set(shareRoute, forKey: "share_route")
        defaults.set(sharePlaces, forKey: "share_places")
        defaults.set(shareWeather, forKey: "share_weather")
        defaults.set(sharePrecision, forKey: "share_precision")

        let data: [String: Any] = [
            "shareLocation": shareLocation,
            "shareBattery": shareBattery,
            "shareSpeed": shareSpeed,
            "shareDirection": shareDirection,
            "shareHistory": shareHistory,
            "shareArrivals": shareArrivals,
            "shareDepartures": shareDepartures,
            "shareRoute": shareRoute,
            "sharePlaces": sharePlaces,
            "shareWeather": shareWeather,
            "sharePrecision": sharePrecision
        ]
        db.collection("usuarios").document(myUid).setData(data, merge: true)
    }

    // MARK: - Map Controls

    private func centerOnMe() {
        guard let lat = locationService.lastLatitude, let lng = locationService.lastLongitude else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    private func centerOnBoth() {
        guard let myLat = locationService.lastLatitude, let myLng = locationService.lastLongitude,
              let pLat = locationService.partnerLatitude, let pLng = locationService.partnerLongitude else { return }
        let midLat = (myLat + pLat) / 2
        let midLng = (myLng + pLng) / 2
        let latDelta = abs(myLat - pLat) * 1.8 + 0.01
        let lngDelta = abs(myLng - pLng) * 1.8 + 0.01
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLng),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
            ))
        }
    }

    private func centerOnPlace(_ place: PartnerPlace) {
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    private func zoomIn() {
        if let region = cameraPosition.region {
            let newLat = max(region.span.latitudeDelta / 1.5, 0.001)
            let newLng = max(region.span.longitudeDelta / 1.5, 0.001)
            withAnimation(.easeInOut(duration: 0.2)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(latitudeDelta: newLat, longitudeDelta: newLng)
                ))
            }
        }
    }

    private func zoomOut() {
        if let region = cameraPosition.region {
            let newLat = min(region.span.latitudeDelta * 1.5, 180)
            let newLng = min(region.span.longitudeDelta * 1.5, 180)
            withAnimation(.easeInOut(duration: 0.2)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(latitudeDelta: newLat, longitudeDelta: newLng)
                ))
            }
        }
    }

    private func resetNorth() {
        if let region = cameraPosition.region {
            withAnimation(.easeInOut(duration: 0.3)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: region.center,
                    span: region.span
                ))
            }
        }
    }

    // MARK: - Computed Helpers

    private func formatDistance(_ km: Double) -> String {
        if km < 1 { return "\(Int(km * 1000)) m" }
        return String(format: "%.2f km", km)
    }

    private func etaCar(_ km: Double) -> String {
        let minutes = Int(km / 0.8)
        if minutes < 1 { return "< 1 min" }
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func etaWalk(_ km: Double) -> String {
        let minutes = Int(km / 0.083)
        if minutes < 1 { return "< 1 min" }
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func stepsEstimate(_ km: Double) -> String {
        let steps = Int(km / 0.000762)
        if steps < 1000 { return "\(steps)" }
        return String(format: "%.1fk", Double(steps) / 1000)
    }

    private func batteryIcon(for level: Int?) -> String {
        guard let level = level else { return "battery.25" }
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }

    private func motionIcon(for motion: String?) -> String {
        switch motion {
        case "driving": return "car.fill"
        case "walking": return "figure.walk"
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        default: return "figure.stand"
        }
    }

    private func motionLabel(for motion: String?) -> String {
        switch motion {
        case "driving": return "Conduciendo"
        case "walking": return "Caminando"
        case "running": return "Corriendo"
        case "cycling": return "Bicicleta"
        default: return "Quieto"
        }
    }

    private func placeIconSF(_ icon: String) -> String {
        switch icon {
        case "heart": return "heart.fill"
        case "star": return "star.fill"
        case "house": return "house.fill"
        case "building": return "building.2.fill"
        case "bag": return "bag.fill"
        case "cup.and.saucer": return "cup.and.saucer.fill"
        case "fork.knife": return "fork.knife"
        case "cart": return "cart.fill"
        case "fuelpump": return "fuelpump.fill"
        case "airplane": return "airplane"
        case "suitcase": return "suitcase.fill"
        case "beach.umbrella": return "beach.umbrella.fill"
        case "tent": return "tent.fill"
        case "tree": return "tree.fill"
        case "mappin": return "mappin"
        default: return "heart.fill"
        }
    }

    private func parseColor(_ hex: String) -> Color {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if clean.count == 6 { clean = "FF" + clean }
        guard let val = UInt64(clean, radix: 16) else { return Color(red: 1, green: 0.5, blue: 0.5) }
        return Color(
            red: Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8) & 0xFF) / 255,
            blue: Double(val & 0xFF) / 255
        )
    }

    private func lastUpdateText(_ date: Date) -> String {
        let elapsed = Int(-date.timeIntervalSinceNow)
        if elapsed < 60 { return "\(elapsed)s" }
        if elapsed < 3600 { return "\(elapsed / 60)m" }
        if elapsed < 86400 { return "\(elapsed / 3600)h" }
        let f = DateFormatter()
        f.dateFormat = "d MMM HH:mm"
        f.locale = Locale(identifier: "es")
        return f.string(from: date)
    }

    private func openMapAt(lat: Double, lng: Double) {
        let urlStr = "http://maps.apple.com/?ll=\(lat),\(lng)&q=Ubicacion"
        guard let url = URL(string: urlStr) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Partner Info Card Sheet

struct PartnerInfoCardView: View {
    let partnerName: String
    let locationService: LocationService
    let theme: ThemeManager
    let onDirections: () -> Void
    let onChat: () -> Void
    let onCall: () -> Void
    let onArrived: () -> Void
    let onHistory: () -> Void
    let onPlaces: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Text(String(partnerName.prefix(1)))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        Text(partnerName)
                            .appFont(size: 20, weight: .bold)
                            .foregroundColor(theme.textPrimary)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(statusText)
                                .appFont(size: 13)
                                .foregroundColor(statusColor)
                        }
                        if let date = locationService.partnerLastUpdate {
                            Text(lastUpdateRelative(date))
                                .appFont(size: 11)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.top, 12)

                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        statBox(value: distanceValue, label: "Distancia", icon: "ruler")
                        statBox(value: batteryText, label: "Bateria", icon: batteryIconName)
                        statBox(value: signalText, label: "Senal", icon: signalIcon)
                    }

                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        statBox(value: speedText, label: "Velocidad", icon: speedCardIcon)
                        statBox(value: precisionText, label: "GPS", icon: "scope")
                        statBox(value: motionLabel, label: "Estado", icon: motionIconName)
                    }

                    if let d = locationService.distanceToPartner {
                        HStack(spacing: 12) {
                            cardRow(icon: "car.fill", text: "Auto: \(etaCar(d))", color: .orange)
                            cardRow(icon: "figure.walk", text: "Caminando: \(etaWalk(d))", color: .green)
                        }
                    }

                    if let addr = locationService.partnerAddress, !addr.isEmpty {
                        infoRow(icon: "location.fill", text: addr, color: theme.primary)
                    }

                    if let heading = locationService.partnerHeading {
                        infoRow(icon: "safari.fill", text: headingText(heading), color: .blue)
                    }

                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        largeActionButton(icon: "location.circle.fill", label: "Como llegar", color: .blue) { onDirections() }
                        largeActionButton(icon: "message.fill", label: "Mensaje", color: .green) { onChat() }
                        largeActionButton(icon: "phone.fill", label: "Llamar", color: .orange) { onCall() }
                        largeActionButton(icon: "hand.thumbsup.fill", label: "LLegue bien", color: theme.primary) { onArrived() }
                        largeActionButton(icon: "clock.arrow.circlepath", label: "Historial", color: .purple) { onHistory() }
                        largeActionButton(icon: "star.fill", label: "Lugares", color: .yellow) { onPlaces() }
                    }
                }
                .padding(16)
            }
            .background(theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(partnerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { onDismiss() }
                }
            }
        }
    }

    private var statusColor: Color {
        if !locationService.partnerIsGPSOn { return .orange }
        if locationService.partnerOnline { return .green }
        return .gray
    }

    private var statusText: String {
        if !locationService.partnerIsGPSOn { return "GPS apagado" }
        if locationService.partnerOnline { return "En linea" }
        return "Sin conexion"
    }

    private var signalIcon: String {
        guard let p = locationService.partnerPrecision else { return "antenna.radiowaves.left.and.right.slash" }
        if p < 10 { return "antenna.radiowaves.left.and.right" }
        if p < 50 { return "antenna.radiowaves.left.and.right" }
        return "antenna.radiowaves.left.and.right.slash"
    }

    private var signalText: String {
        guard let p = locationService.partnerPrecision else { return "--" }
        if p < 10 { return "Excelente" }
        if p < 50 { return "Buena" }
        return "Baja"
    }

    private var speedText: String {
        guard let s = locationService.partnerSpeed else { return "--" }
        return String(format: "%.1f km/h", s)
    }

    private var speedCardIcon: String {
        if let s = locationService.partnerSpeed, s > 10 { return "car.fill" }
        return "figure.walk"
    }

    private var motionLabel: String {
        guard let m = locationService.partnerMotion else { return "--" }
        switch m {
        case "driving": return "Conduciendo"
        case "walking": return "Caminando"
        case "running": return "Corriendo"
        case "cycling": return "Bicicleta"
        default: return "Quieto"
        }
    }

    private var motionIconName: String {
        guard let m = locationService.partnerMotion else { return "figure.stand" }
        switch m {
        case "driving": return "car.fill"
        case "walking": return "figure.walk"
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        default: return "figure.stand"
        }
    }

    private var distanceValue: String {
        guard let d = locationService.distanceToPartner else { return "--" }
        if d < 1 { return "\(Int(d * 1000))m" }
        return String(format: "%.2f km", d)
    }

    private var batteryText: String {
        guard let level = locationService.partnerBattery else { return "--" }
        let charging = locationService.partnerIsCharging ?? false
        return "\(level)%" + (charging ? " +" : "")
    }

    private var batteryIconName: String {
        guard let level = locationService.partnerBattery else { return "battery.25" }
        let isCharging = locationService.partnerIsCharging ?? false
        if isCharging { return "battery.100.bolt" }
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }

    private var precisionText: String {
        guard let p = locationService.partnerPrecision else { return "--" }
        if p < 10 { return "Alta" }
        if p < 50 { return "Media" }
        return "Baja"
    }

    private func lastUpdateRelative(_ date: Date) -> String {
        let elapsed = Int(-date.timeIntervalSinceNow)
        if elapsed < 5 { return "Ahora mismo" }
        if elapsed < 60 { return "Hace \(elapsed)s" }
        if elapsed < 3600 { return "Hace \(elapsed / 60)m" }
        return "Hace \(elapsed / 3600)h"
    }

    private func headingText(_ h: Double) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
        let idx = Int((h + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return "\(dirs[idx]) (\(Int(h))\u{00B0})"
    }

    private func etaCar(_ km: Double) -> String {
        let minutes = Int(km / 0.8)
        if minutes < 1 { return "< 1 min" }
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func etaWalk(_ km: Double) -> String {
        let minutes = Int(km / 0.083)
        if minutes < 1 { return "< 1 min" }
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(text)
                .appFont(size: 12)
                .foregroundColor(theme.textSecondary)
                .lineLimit(2)
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func cardRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(text)
                .appFont(size: 11, weight: .medium)
                .foregroundColor(theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(theme.primary)
            Text(value)
                .appFont(size: 15, weight: .bold)
                .foregroundColor(theme.textPrimary)
            Text(label)
                .appFont(size: 10)
                .foregroundColor(theme.textSecondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func largeActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                Text(label)
                    .appFont(size: 12, weight: .medium)
                    .foregroundColor(theme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
