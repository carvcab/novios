import SwiftUI
import MapKit

public struct LocationView: View {
    @ObservedObject private var locationService = LocationService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showCheckInSheet = false
    @State private var checkInMessage = ""
    @State private var checkIns: [[String: Any]] = []
    @State private var showHistory = false

    private let defaults = UserDefaults.standard
    private let df = ISO8601DateFormatter()

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapView
                    .ignoresSafeArea(edges: [.top, .horizontal])

                bottomSheet
            }
            .navigationTitle("Ubicación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        locationService.startSharing()
                    } label: {
                        Image(systemName: locationService.isSharing ? "location.fill" : "location.slash.fill")
                            .foregroundColor(locationService.isSharing ? theme.primary : theme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showCheckInSheet) {
                checkInSheet
            }
            .sheet(isPresented: $showHistory) {
                historySheet
            }
            .onAppear {
                loadCheckIns()
                updateRegionToFitBoth()
            }
            .onChange(of: locationService.lastLatitude) { _ in updateRegionToFitBoth() }
            .onChange(of: locationService.partnerLatitude) { _ in updateRegionToFitBoth() }
        }
    }

    private func updateRegionToFitBoth() {
        let myLat = locationService.lastLatitude
        let myLng = locationService.lastLongitude
        let pLat = locationService.partnerLatitude
        let pLng = locationService.partnerLongitude

        if let lat = myLat, let lng = myLng {
            region.center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        if let lat = pLat, let lng = pLng, let myLat = myLat, let myLng = myLng {
            let midLat = (myLat + lat) / 2
            let midLng = (myLng + lng) / 2
            region.center = CLLocationCoordinate2D(latitude: midLat, longitude: midLng)
            let spanLat = abs(myLat - lat) * 1.5 + 0.01
            let spanLng = abs(myLng - lng) * 1.5 + 0.01
            region.span = MKCoordinateSpan(latitudeDelta: max(spanLat, 0.01), longitudeDelta: max(spanLng, 0.01))
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(coordinateRegion: $region, showsUserLocation: false, annotationItems: annotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                VStack(spacing: 2) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(radius: 3)
                    Text(item.label)
                        .appFont(size: 10, weight: .medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 8) {
                Button {
                    updateRegionToFitBoth()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .appFont(size: 16)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                if let dist = locationService.distanceToPartner {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler").appFont(size: 10)
                        Text("\(String(format: "%.1f", dist)) km")
                            .appFont(size: 11, weight: .semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
            }
            .padding(12)
        }
    }

    private var annotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
            items.append(MapAnnotationItem(
                id: "me",
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                label: "Tú",
                color: theme.primary
            ))
        }
        if let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude {
            items.append(MapAnnotationItem(
                id: "partner",
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                label: locationService.partnerOnline ? "Pareja" : "Offline",
                color: locationService.partnerOnline ? .green : .gray
            ))
        }
        return items
    }

    // MARK: - Bottom Sheet

    private var bottomSheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(theme.textSecondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(locationService.isSharing ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(locationService.isSharing ? "Compartiendo ubicación" : "Ubicación no compartida")
                            .appFont(size: 14, weight: .medium)
                            .foregroundColor(locationService.isSharing ? .green : theme.textSecondary)
                        Spacer()
                        if !locationService.isSharing {
                            Button("Activar") {
                                locationService.startSharing()
                            }
                            .appFont(size: 13, weight: .semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(theme.primaryGradient)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if locationService.isSharing {
                        if locationService.partnerOnline {
                            HStack {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("Pareja en línea")
                                    .appFont(size: 13).foregroundColor(theme.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }

                        Divider().padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            Button {
                                sendCheckIn(message: "Voy para casa 🏠")
                            } label: {
                                Label("Voy a casa", systemImage: "house.fill")
                                    .appFont(size: 12, weight: .semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(LinearGradient(colors: [theme.pastelMint, Color(red: 0.5, green: 0.8, blue: 0.5)], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(10)
                            }
                            Button {
                                sendCheckIn(message: "Llegué bien! Estoy en mi destino ✅")
                            } label: {
                                Label("Llegué bien", systemImage: "checkmark.circle.fill")
                                    .appFont(size: 12, weight: .semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(LinearGradient(colors: [theme.pastelBlue, Color(red: 0.5, green: 0.6, blue: 0.9)], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 16)

                        Button {
                            showCheckInSheet = true
                        } label: {
                            Label("Enviar check-in", systemImage: "paperplane.fill")
                                .appFont(size: 13)
                                .foregroundColor(theme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.primary.opacity(0.3)))
                        }
                        .padding(.horizontal, 16)

                        if !checkIns.isEmpty {
                            Button {
                                showHistory = true
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("Historial (\(checkIns.count))")
                                }
                                .appFont(size: 12)
                                .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 220)
            .background(.ultraThinMaterial)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
    }

    // MARK: - Sheets

    private var checkInSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Check-in personalizado")
                    .appFont(size: 18, weight: .semibold)
                TextField("¿Qué quieres decir?", text: $checkInMessage)
                    .appFont(size: 14)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                Button {
                    sendCheckIn(message: checkInMessage)
                    showCheckInSheet = false
                    checkInMessage = ""
                } label: {
                    Text("Enviar")
                        .appFont(size: 16, weight: .bold).foregroundColor(.white)
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

    private var historySheet: some View {
        NavigationStack {
            List {
                ForEach(checkIns.indices, id: \.self) { i in
                    let item = checkIns[i]
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item["message"] as? String ?? "")
                            .appFont(size: 14)
                        if let ts = item["timestamp"] as? String,
                           let date = df.date(from: ts) {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .appFont(size: 11).foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Historial")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cerrar") { showHistory = false } } }
        }
    }

    // MARK: - Firestore

    private func sendCheckIn(message: String) {
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        guard !coupleId.isEmpty, let lat = locationService.lastLatitude, let lng = locationService.lastLongitude else { return }
        let msgId = UUID().uuidString
        let now = df.string(from: Date())
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "couples/\(coupleId)/checkins/\(msgId)", fields: [
                "message": message, "latitude": lat, "longitude": lng, "timestamp": now,
            ])
            await MainActor.run {
                checkIns.insert(["message": message, "latitude": lat, "longitude": lng, "timestamp": now], at: 0)
            }
        }
    }

    private func loadCheckIns() {
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        guard !coupleId.isEmpty else { return }
        Task {
            if let docs = try? await FirebaseRESTService.shared.firestoreList(path: "couples/\(coupleId)/checkins") {
                var items: [[String: Any]] = []
                for doc in docs {
                    guard let f = doc["fields"] as? [String: Any] else { continue }
                    let s = { (k: String) -> String? in (f[k] as? [String: Any])?["stringValue"] as? String }
                    let d = { (k: String) -> Double? in
                        if let dv = (f[k] as? [String: Any])?["doubleValue"] as? Double { return dv }
                        if let sv = (f[k] as? [String: Any])?["stringValue"] as? String { return Double(sv) }
                        return nil
                    }
                    if let msg = s("message") {
                        items.append(["message": msg, "latitude": d("latitude") ?? 0, "longitude": d("longitude") ?? 0, "timestamp": s("timestamp") ?? ""])
                    }
                }
                await MainActor.run { checkIns = items.reversed() }
            }
        }
    }
}

// MARK: - Annotation Model

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let label: String
    let color: Color
}

// MARK: - CornerRadius helper

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
