import SwiftUI
import MapKit

// MARK: - Place Model

struct PlaceItem: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
    var type: String
}

// MARK: - Location View

public struct LocationView: View {
    @ObservedObject private var locationService = LocationService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State private var checkInMessage = ""
    @State private var showCheckInSheet = false
    @State private var showAddPlace = false
    @State private var showPrivacy = false
    @State private var showHistory = false
    @State private var showStats = false
    @State private var showPlaces = false
    @State private var placeName = ""
    @State private var placeDesc = ""
    @State private var placeType = "visited"
    @State private var editingPlace: PlaceItem?
    @State private var shareLocation = true
    @State private var shareHistory = false
    @State private var shareBattery = true
    @State private var shareSpeed = false
    @State private var myBattery: Int = -1

    private let defaults = UserDefaults.standard
    private let df = ISO8601DateFormatter()

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                VStack(spacing: 0) {
                    Spacer()
                    bottomSheet
                }
            }
            .navigationTitle("Ubicación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        if locationService.isSharing {
                            Button { locationService.refreshPartnerNow() } label: {
                                Image(systemName: "arrow.clockwise").appFont(size: 14).foregroundColor(theme.primary)
                            }
                        }
                        Button { locationService.startSharing() } label: {
                            Image(systemName: locationService.isSharing ? "location.fill" : "location.slash.fill")
                                .foregroundColor(locationService.isSharing ? theme.primary : theme.textSecondary)
                        }
                    }
                }
            }
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                loadSettings()
            }
        }
        .sheet(isPresented: $showCheckInSheet) { checkInSheet }
        .sheet(isPresented: $showAddPlace) { addPlaceSheet }
        .sheet(isPresented: $showPrivacy) { privacySheet }
        .sheet(isPresented: $showHistory) { historySheet }
        .sheet(isPresented: $showStats) { statsSheet }
        .sheet(isPresented: $showPlaces) { placesSheet }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(coordinateRegion: $region, showsUserLocation: false, annotationItems: mapAnnotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                if item.isHeart {
                    Image(systemName: "heart.fill").foregroundColor(.red).appFont(size: 18)
                        .shadow(radius: 2)
                } else {
                    VStack(spacing: 1) {
                        Circle().fill(item.color).frame(width: item.isPulse ? 24 : 18, height: item.isPulse ? 24 : 18)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                            .shadow(radius: 3)
                        if !item.label.isEmpty {
                            Text(item.label).appFont(size: 9, weight: .medium).foregroundColor(.primary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.ultraThinMaterial).cornerRadius(4)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) { mapControls }
        .overlay(alignment: .bottomLeading) { sosButton }
    }

    private var mapControls: some View {
        VStack(spacing: 8) {
            Button { updateRegionToFitBoth() } label: {
                Image(systemName: "minus.magnifyingglass").appFont(size: 14).padding(8)
                    .background(.ultraThinMaterial).clipShape(Circle())
            }
            if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
                Button { region.center = CLLocationCoordinate2D(latitude: lat, longitude: lng) } label: {
                    Image(systemName: "location.fill").appFont(size: 14).padding(8)
                        .background(.ultraThinMaterial).clipShape(Circle()).foregroundColor(theme.primary)
                }
            }
            if let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude {
                Button { region.center = CLLocationCoordinate2D(latitude: lat, longitude: lng) } label: {
                    Image(systemName: "heart.fill").appFont(size: 14).padding(8)
                        .background(.ultraThinMaterial).clipShape(Circle()).foregroundColor(.red)
                }
            }
            if locationService.distanceToPartner ?? 999 < 0.02 {
                Text("💞 Juntos").appFont(size: 10, weight: .bold).padding(8)
                    .background(theme.primary.opacity(0.2)).cornerRadius(12)
            }
        }
        .padding(8)
    }

    private var sosButton: some View {
        HStack(spacing: 10) {
            Button {
                sendCheckIn(message: "🚨 SOS — Necesito ayuda! Batería: \(myBattery > 0 ? "\(myBattery)%" : "--")")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").appFont(size: 12)
                    Text("SOS").appFont(size: 11, weight: .bold)
                }.foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.red.opacity(0.85)).cornerRadius(20)
            }
            Button {
                sendCheckIn(message: "Llegué bien! Estoy en mi destino ✅")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").appFont(size: 12)
                    Text("Llegué bien").appFont(size: 11, weight: .bold)
                }.foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8)
                    .background(theme.primaryGradient).cornerRadius(20)
            }
        }
        .padding(12)
    }

    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
            items.append(MapAnnotationItem(id: "me", coordinate: .init(latitude: lat, longitude: lng), label: "", color: theme.primary, isHeart: false, isPulse: true))
        }
        if let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude {
            items.append(MapAnnotationItem(id: "partner", coordinate: .init(latitude: lat, longitude: lng), label: locationService.partnerOnline ? "Pareja" : "Offline", color: locationService.partnerOnline ? .green : .gray, isHeart: false, isPulse: false))
        }
        return items
    }

    private func updateRegionToFitBoth() {
        if let pLat = locationService.partnerLatitude, let pLng = locationService.partnerLongitude,
           let myLat = locationService.lastLatitude, let myLng = locationService.lastLongitude {
            let midLat = (myLat + pLat) / 2; let midLng = (myLng + pLng) / 2
            region.center = .init(latitude: midLat, longitude: midLng)
            region.span = .init(latitudeDelta: max(abs(myLat - pLat) * 1.5 + 0.01, 0.01), longitudeDelta: max(abs(myLng - pLng) * 1.5 + 0.01, 0.01))
        } else if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
            region.center = .init(latitude: lat, longitude: lng)
        }
    }

    // MARK: - Bottom Sheet

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            Capsule().fill(theme.textSecondary.opacity(0.3)).frame(width: 36, height: 4).padding(.top, 8)
            ScrollView {
                VStack(spacing: 10) {
                    partnerCard
                    if locationService.isSharing {
                        infoStrips
                        quickActions
                        expandableSections
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 280)
            .background(.ultraThinMaterial)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
    }

    // MARK: - Partner Card

    private var partnerCard: some View {
        HStack(spacing: 12) {
            Circle().fill(theme.primaryGradient).frame(width: 44, height: 44)
                .overlay(Image(systemName: "person.fill").foregroundColor(.white).appFont(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    let name = defaults.string(forKey: "partner_name") ?? "Pareja"
                    Text("💞 \(name)").appFont(size: 15, weight: .bold).lineLimit(1)
                    Circle().fill(locationService.partnerOnline ? Color.green : Color.gray).frame(width: 8, height: 8)
                }
                Text(locationService.partnerOnline ? "🟢 En línea" : "⚫ Sin conexión")
                    .appFont(size: 11).foregroundColor(theme.textSecondary)
                Text("📍 \(lastUpdateText())").appFont(size: 10).foregroundColor(theme.textSecondary.opacity(0.7))
            }
            Spacer()
            if let dist = locationService.distanceToPartner {
                Text("\(String(format: "%.1f", dist)) km").appFont(size: 14, weight: .bold).foregroundColor(theme.primary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(theme.primary.opacity(0.12)).cornerRadius(20)
            }
        }
        .padding(12)
        .background(theme.cardBackground.opacity(0.5)).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.primary.opacity(0.12), lineWidth: 0.5))
    }

    // MARK: - Info Strips

    private var infoStrips: some View {
        HStack(spacing: 8) {
            infoChip(icon: "speedometer", value: locationService.partnerSpeed.map { "\(String(format: "%.0f", $0)) km/h" } ?? "--", label: "Velocidad", color: .orange)
            infoChip(icon: "battery.100", value: locationService.partnerBattery.map { $0 > 0 ? "\($0)%" : "--" } ?? "--", label: "Batería", color: (locationService.partnerBattery ?? 100) < 20 ? .red : .green)
            infoChip(icon: "timer", value: lastUpdateText(), label: "Actualizado", color: .blue)
        }
    }

    private func infoChip(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).appFont(size: 14).foregroundColor(color)
            Text(value).appFont(size: 12, weight: .bold).foregroundColor(.primary)
            Text(label).appFont(size: 8).foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.06)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.12)))
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 8) {
            quickActionButton(icon: "arrow.triangle.turn.up.right.diamond.fill", label: "Cómo llegar", color: theme.primary) { openDirections() }
            quickActionButton(icon: "heart.fill", label: "Corazón", color: .red) { sendHeart() }
            quickActionButton(icon: "house.fill", label: "Compartir", color: theme.pastelMint) { sendCheckIn(message: "Voy para casa 🏠") }
            quickActionButton(icon: "checkmark.circle.fill", label: "Llegué bien", color: .blue) { sendCheckIn(message: "Llegué bien! ✅") }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).appFont(size: 18).foregroundColor(color)
                Text(label).appFont(size: 9).foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(color.opacity(0.06)).cornerRadius(12)
        }
    }

    // MARK: - Expandable Sections

    private var expandableSections: some View {
        VStack(spacing: 6) {
            Button { showHistory = true } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath").foregroundColor(theme.primary)
                    Text("Historial").appFont(size: 13).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").appFont(size: 10).foregroundColor(theme.textSecondary)
                }.padding(10).background(theme.cardBackground.opacity(0.3)).cornerRadius(10)
            }
            Button { showPlaces = true } label: {
                HStack {
                    Image(systemName: "star.fill").foregroundColor(.orange)
                    Text("Lugares favoritos").appFont(size: 13).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").appFont(size: 10).foregroundColor(theme.textSecondary)
                }.padding(10).background(theme.cardBackground.opacity(0.3)).cornerRadius(10)
            }
            Button { showPrivacy = true } label: {
                HStack {
                    Image(systemName: "lock.fill").foregroundColor(theme.pastelLavender)
                    Text("Privacidad").appFont(size: 13).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").appFont(size: 10).foregroundColor(theme.textSecondary)
                }.padding(10).background(theme.cardBackground.opacity(0.3)).cornerRadius(10)
            }
            Button { showStats = true } label: {
                HStack {
                    Image(systemName: "chart.bar.fill").foregroundColor(theme.pastelPeach)
                    Text("Estadísticas").appFont(size: 13).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").appFont(size: 10).foregroundColor(theme.textSecondary)
                }.padding(10).background(theme.cardBackground.opacity(0.3)).cornerRadius(10)
            }
        }
    }

    // MARK: - Privacy Sheet

    private var privacySheet: some View {
        NavigationStack {
            Form {
                Section("Compartir con tu pareja") {
                    Toggle("Ubicación en tiempo real", isOn: $shareLocation).onChange(of: shareLocation) { newVal in savePrivacy() }
                    Toggle("Historial de ubicaciones", isOn: $shareHistory).onChange(of: shareHistory) { newVal in savePrivacy() }
                    Toggle("Batería", isOn: $shareBattery).onChange(of: shareBattery) { newVal in savePrivacy() }
                    Toggle("Velocidad", isOn: $shareSpeed).onChange(of: shareSpeed) { newVal in savePrivacy() }
                }
            }
            .navigationTitle("Privacidad")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cerrar") { showPrivacy = false } } }
        }
    }

    // MARK: - Places Sheet

    private var placesSheet: some View {
        NavigationStack {
            List {
                ForEach(places, id: \.id) { place in
                    HStack(spacing: 10) {
                        Image(systemName: placeIcon(place.type)).foregroundColor(placeColor(place.type))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name).appFont(size: 14, weight: .semibold)
                            if !place.description.isEmpty {
                                Text(place.description).appFont(size: 11).foregroundColor(theme.textSecondary).lineLimit(1)
                            }
                        }
                        Spacer()
                        Button { editingPlace = place; showAddPlace = true } label: {
                            Image(systemName: "pencil").appFont(size: 12).foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        deletePlace(places[i])
                    }
                }
            }
            .navigationTitle("Lugares favoritos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Cerrar") { showPlaces = false } }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { editingPlace = nil; showAddPlace = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    // MARK: - Add/Edit Place Sheet

    private var addPlaceSheet: some View {
        NavigationStack {
            Form {
                TextField("Nombre", text: $placeName)
                TextField("Descripción", text: $placeDesc)
                Picker("Tipo", selection: $placeType) {
                    Text("Visitado").tag("visited")
                    Text("Por visitar").tag("wish")
                    Text("Restaurante favorito").tag("restaurant")
                    Text("País soñado").tag("dream")
                    Text("Primera cita").tag("first_date")
                    Text("Primer viaje").tag("first_trip")
                }
                if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
                    Text("📍 \(String(format: "%.4f", lat)), \(String(format: "%.4f", lng))")
                        .appFont(size: 12).foregroundColor(theme.textSecondary)
                }
            }
            .navigationTitle(editingPlace != nil ? "Editar lugar" : "Agregar lugar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { savePlace() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { showAddPlace = false }
                }
            }
        }
    }

    // MARK: - History Sheet

    private var historySheet: some View {
        NavigationStack {
            List(checkIns.indices, id: \.self) { i in
                let item = checkIns[i]
                VStack(alignment: .leading, spacing: 4) {
                    Text(item["message"] as? String ?? "").appFont(size: 14)
                    if let ts = item["timestamp"] as? String, let date = df.date(from: ts) {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .appFont(size: 11).foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Historial")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cerrar") { showHistory = false } } }
        }
    }

    // MARK: - Stats Sheet

    private var statsSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCard(icon: "location.fill", value: "\(checkIns.count)", label: "Check-ins", color: theme.primary)
                    statCard(icon: "ruler", value: locationService.distanceToPartner.map { "\(String(format: "%.1f", $0)) km" } ?? "--", label: "Distancia", color: .blue)
                    statCard(icon: "person.2.fill", value: locationService.partnerOnline ? "Juntos 💞" : "Separados", label: "Estado", color: .green)
                    statCard(icon: "sharelocation.fill", value: locationService.isSharing ? "Activo" : "Inactivo", label: "Compartiendo", color: .orange)
                }
                .padding()
                Spacer()
            }
            .navigationTitle("Estadísticas")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cerrar") { showStats = false } } }
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).appFont(size: 20).foregroundColor(color)
            Text(value).appFont(size: 15, weight: .bold).foregroundColor(.primary)
            Text(label).appFont(size: 10).foregroundColor(theme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.06)).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.15)))
    }

    private var checkInSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Check-in personalizado").appFont(size: 18, weight: .semibold)
                TextField("¿Qué quieres decir?", text: $checkInMessage)
                    .appFont(size: 14).padding(12).background(.ultraThinMaterial).cornerRadius(12)
                Button {
                    sendCheckIn(message: checkInMessage)
                    showCheckInSheet = false
                    checkInMessage = ""
                } label: {
                    Text("Enviar").appFont(size: 16, weight: .bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(theme.primaryGradient).cornerRadius(14)
                }
                .disabled(checkInMessage.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
            }
            .padding(20)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancelar") { showCheckInSheet = false } } }
        }
    }

    // MARK: - Data

    @State private var places: [PlaceItem] = []
    @State private var checkIns: [[String: Any]] = []

    private func loadSettings() {
        shareLocation = defaults.bool(forKey: "privacy_share_location")
        shareHistory = defaults.bool(forKey: "privacy_share_history")
        shareBattery = defaults.bool(forKey: "privacy_share_battery")
        shareSpeed = defaults.bool(forKey: "privacy_share_speed")
        myBattery = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
        loadCheckIns()
        loadPlaces()
        updateRegionToFitBoth()
    }

    private func savePrivacy() {
        defaults.set(shareLocation, forKey: "privacy_share_location")
        defaults.set(shareHistory, forKey: "privacy_share_history")
        defaults.set(shareBattery, forKey: "privacy_share_battery")
        defaults.set(shareSpeed, forKey: "privacy_share_speed")
        guard let uid = AuthService.shared.currentUser?.id else { return }
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "usuarios/\(uid)", fields: [
                "privacySettings": ["shareLocation": shareLocation, "shareHistory": shareHistory, "shareBattery": shareBattery, "shareSpeed": shareSpeed]
            ])
        }
    }

    private func sendCheckIn(message: String) {
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        guard !coupleId.isEmpty, let lat = locationService.lastLatitude, let lng = locationService.lastLongitude else { return }
        let msgId = UUID().uuidString; let now = df.string(from: Date())
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(coupleId)/checkins/\(msgId)", fields: [
                "message": message, "latitude": lat, "longitude": lng, "timestamp": now
            ])
            await MainActor.run { checkIns.insert(["message": message, "latitude": lat, "longitude": lng, "timestamp": now], at: 0) }
        }
    }

    private func loadCheckIns() {
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        guard !coupleId.isEmpty else { return }
        Task {
            guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: "parejas/\(coupleId)/checkins") else { return }
            var items: [[String: Any]] = []
            for doc in docs {
                guard let f = doc["fields"] as? [String: Any] else { continue }
                let s = { (k: String) -> String? in (f[k] as? [String: Any])?["stringValue"] as? String }
                if let msg = s("message") { items.append(["message": msg, "latitude": (f["latitude"] as? [String: Any])?["doubleValue"] as? Double ?? 0, "longitude": (f["longitude"] as? [String: Any])?["doubleValue"] as? Double ?? 0, "timestamp": s("timestamp") ?? ""]) }
            }
            await MainActor.run { checkIns = items.reversed() }
        }
    }

    private func loadPlaces() {
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        guard !coupleId.isEmpty else { return }
        Task {
            guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: "parejas/\(coupleId)/places") else { return }
            var items: [PlaceItem] = []
            for doc in docs {
                guard let f = doc["fields"] as? [String: Any], let name = (f["name"] as? [String: Any])?["stringValue"] as? String else { continue }
                let s = { (k: String) -> String? in (f[k] as? [String: Any])?["stringValue"] as? String }
                let d = { (k: String) -> Double? in (f[k] as? [String: Any])?["doubleValue"] as? Double }
                items.append(PlaceItem(id: s("id") ?? UUID().uuidString, name: name, description: s("description") ?? "", latitude: d("latitude") ?? 0, longitude: d("longitude") ?? 0, type: s("type") ?? "visited"))
            }
            await MainActor.run { places = items }
        }
    }

    private func savePlace() {
        let trimmed = placeName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        guard !coupleId.isEmpty, let lat = locationService.lastLatitude, let lng = locationService.lastLongitude else { return }
        let id = editingPlace?.id ?? UUID().uuidString
        let place = PlaceItem(id: id, name: trimmed, description: placeDesc.trimmingCharacters(in: .whitespaces), latitude: editingPlace?.latitude ?? lat, longitude: editingPlace?.longitude ?? lng, type: placeType)
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "parejas/\(coupleId)/places/\(id)", fields: [
                "id": id, "name": place.name, "description": place.description, "latitude": place.latitude, "longitude": place.longitude, "type": place.type
            ])
            await MainActor.run {
                if let idx = places.firstIndex(where: { $0.id == id }) { places[idx] = place }
                else { places.append(place) }
                showAddPlace = false; placeName = ""; placeDesc = ""
            }
        }
    }

    private func deletePlace(_ place: PlaceItem) {
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        Task {
            try? await FirebaseRESTService.shared.firestoreDelete(path: "parejas/\(coupleId)/places/\(place.id)")
            await MainActor.run { places.removeAll { $0.id == place.id } }
        }
    }

    private func openDirections() {
        guard let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude,
              let url = URL(string: "https://maps.apple.com/?daddr=\(lat),\(lng)") else { return }
        UIApplication.shared.open(url)
    }

    private func sendHeart() {
        sendCheckIn(message: "💕 Te envío un corazón!")
    }

    private func lastUpdateText() -> String {
        guard let d = locationService.partnerLastUpdate else { return "0s" }
        let sec = Int(Date().timeIntervalSince(d))
        if sec < 60 { return "\(sec)s" }
        return "\(sec / 60)m \(sec % 60)s"
    }

    private func placeIcon(_ type: String) -> String {
        switch type {
        case "visited": return "checkmark.circle.fill"
        case "wish": return "star.fill"
        case "restaurant": return "fork.knife"
        case "dream": return "globe"
        case "first_date": return "heart.fill"
        case "first_trip": return "airplane"
        default: return "mappin"
        }
    }

    private func placeColor(_ type: String) -> Color {
        switch type {
        case "visited": return .green
        case "wish": return .orange
        case "restaurant": return .orange
        case "dream": return .purple
        case "first_date": return .red
        case "first_trip": return .blue
        default: return theme.primary
        }
    }
}

// MARK: - Models

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let label: String
    let color: Color
    let isHeart: Bool
    let isPulse: Bool
}

// MARK: - Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
