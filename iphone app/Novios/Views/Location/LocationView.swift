import SwiftUI
import MapKit

public struct LocationView: View {
    @ObservedObject private var locationService = LocationService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var position: MapCameraPosition = .automatic
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
                // Map
                mapView
                    .ignoresSafeArea(edges: [.top, .horizontal])

                // Bottom sheet
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
            }
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $position) {
            if let lat = locationService.lastLatitude, let lng = locationService.lastLongitude {
                Annotation("Tú", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(radius: 4)
                }
            }
            if let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude {
                Annotation(locationService.partnerOnline ? "Pareja" : "Pareja (offline)", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                    Circle()
                        .fill(locationService.partnerOnline ? Color.green : Color.gray)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(radius: 4)
                }
            }
            if let myLat = locationService.lastLatitude, let myLng = locationService.lastLongitude,
               let pLat = locationService.partnerLatitude, let pLng = locationService.partnerLongitude {
                MapPolyline(coordinates: [
                    CLLocationCoordinate2D(latitude: myLat, longitude: myLng),
                    CLLocationCoordinate2D(latitude: pLat, longitude: pLng)
                ])
                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
            }
            ForEach(checkIns.indices, id: \.self) { i in
                if let lat = checkIns[i]["latitude"] as? Double,
                   let lng = checkIns[i]["longitude"] as? Double {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.orange)
                            .appFont(size: 16)
                    }
                }
            }
        }
        .mapStyle(.standard)
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
                    // Status
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
                        // Partner info
                        if let dist = locationService.distanceToPartner {
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(theme.primary)
                                Text("A \(String(format: "%.1f", dist)) km de tu pareja")
                                    .appFont(size: 14)
                                Spacer()
                                if let lat = locationService.partnerLatitude, let lng = locationService.partnerLongitude {
                                    Button("Centrar") {
                                        position = .region(MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        ))
                                    }
                                    .appFont(size: 12)
                                    .foregroundColor(theme.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if locationService.partnerOnline {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.green)
                                    .appFont(size: 8)
                                Text("Pareja en línea")
                                    .appFont(size: 13)
                                    .foregroundColor(theme.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }

                        Divider().padding(.horizontal, 16)

                        // Buttons
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

                        // Check-in button
                        Button {
                            showCheckInSheet = true
                        } label: {
                            Label("Enviar check-in personalizado", systemImage: "paperplane.fill")
                                .appFont(size: 13)
                                .foregroundColor(theme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.primary.opacity(0.3)))
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 220)
            .background(.ultraThinMaterial)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
    }

    // MARK: - Check-In Sheet

    private var checkInSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Enviar check-in")
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
                        .appFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.primaryGradient)
                        .cornerRadius(14)
                }
                .disabled(checkInMessage.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { showCheckInSheet = false }
                }
            }
        }
    }

    // MARK: - History Sheet

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
                                .appFont(size: 11)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Historial")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { showHistory = false }
                }
            }
        }
    }

    // MARK: - Firestore

    private func sendCheckIn(message: String) {
        let coupleId = defaults.string(forKey: "couple_id") ?? ""
        guard !coupleId.isEmpty,
              let lat = locationService.lastLatitude,
              let lng = locationService.lastLongitude else { return }
        let msgId = UUID().uuidString
        let now = df.string(from: Date())
        Task {
            try? await FirebaseRESTService.shared.firestoreSet(path: "couples/\(coupleId)/checkins/\(msgId)", fields: [
                "message": message,
                "latitude": lat,
                "longitude": lng,
                "timestamp": now,
            ])
            await MainActor.run {
                let item: [String: Any] = ["message": message, "latitude": lat, "longitude": lng, "timestamp": now]
                checkIns.append(item)
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
                    let extract = { (key: String) -> String? in (f[key] as? [String: Any])?["stringValue"] as? String }
                    let extractD = { (key: String) -> Double? in
                        if let v = (f[key] as? [String: Any])?["doubleValue"] as? Double { return v }
                        return (f[key] as? [String: Any])?["stringValue"].flatMap { Double($0) }
                    }
                    if let msg = extract("message") {
                        items.append([
                            "message": msg,
                            "latitude": extractD("latitude") ?? 0,
                            "longitude": extractD("longitude") ?? 0,
                            "timestamp": extract("timestamp") ?? ""
                        ])
                    }
                }
                await MainActor.run { checkIns = items.reversed() }
            }
        }
    }
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
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
