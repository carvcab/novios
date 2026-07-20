import SwiftUI

private struct Place: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let address: String
    let dateAdded: Date
}

private struct Zone: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let address: String
}

public struct LocationView: View {
    @State private var places: [Place] = [
        Place(emoji: "🍕", name: "Nuestra pizzería", address: "Av. Central 123, Centro", dateAdded: Date().addingTimeInterval(-86400 * 30)),
        Place(emoji: "🌅", name: "Mirador del sol", address: "Cerro Alto 456, Colina", dateAdded: Date().addingTimeInterval(-86400 * 14)),
        Place(emoji: "☕", name: "Café favorito", address: "Calle Real 789, Downtown", dateAdded: Date().addingTimeInterval(-86400 * 7)),
    ]
    @State private var isSharingLocation = true
    @State private var selectedZone: Zone?
    @State private var showNewPlaceAlert = false
    @State private var newPlaceName = ""
    @State private var newPlaceAddress = ""

    private let zones: [Zone] = [
        Zone(emoji: "🏠", name: "Casa", address: "Residencial Paz 234"),
        Zone(emoji: "💼", name: "Trabajo", address: "Zona Corporativa Torre B"),
        Zone(emoji: "❤️", name: "Nuestro Lugar", address: "Parque del Amor"),
        Zone(emoji: "🎬", name: "Cine fav", address: "Plaza Central Cine 3"),
    ]

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
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
                        Image(systemName: "location.fill")
                            .foregroundColor(ThemeManager.shared.primaryPink)
                            .font(.system(size: 14, weight: .bold))
                        Text("Ubicación")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Nuevo lugar", isPresented: $showNewPlaceAlert) {
                TextField("Nombre", text: $newPlaceName)
                TextField("Dirección", text: $newPlaceAddress)
                Button("Cancelar", role: .cancel) {
                    newPlaceName = ""
                    newPlaceAddress = ""
                }
                Button("Agregar") {
                    let trimmedName = newPlaceName.trimmingCharacters(in: .whitespaces)
                    let trimmedAddress = newPlaceAddress.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty {
                        places.append(Place(emoji: "📍", name: trimmedName, address: trimmedAddress, dateAdded: Date()))
                    }
                    newPlaceName = ""
                    newPlaceAddress = ""
                }
            } message: {
                Text("Ingresa los datos del lugar especial")
            }
        }
    }

    // MARK: - Compartir ubicación toggle

    private var compartirToggle: some View {
        GlassCard {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(isSharingLocation ? ThemeManager.shared.primaryPink : .gray)
                    .font(.system(size: 22))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compartir ubicación")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(isSharingLocation ? "Visible para tu pareja" : "Oculta para tu pareja")
                        .font(.system(size: 11))
                        .foregroundColor(.primary.opacity(0.5))
                }
                Spacer()
                Toggle("", isOn: $isSharingLocation)
                    .tint(ThemeManager.shared.primaryPink)
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        GlassCard(cornerRadius: 20) {
            ZStack {
                simulatedMap
                VStack {
                    searchBar
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                    Spacer()
                    hereLabel
                        .padding(.bottom, 12)
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var simulatedMap: some View {
        ZStack(alignment: .center) {
            Rectangle().fill(Color(red: 0.6, green: 0.85, blue: 0.4)).frame(height: 120)
                .frame(maxWidth: .infinity, alignment: .top)
            Rectangle().fill(Color(red: 0.3, green: 0.6, blue: 0.3)).frame(height: 60)
                .frame(maxWidth: .infinity, alignment: .top).offset(y: 60)
            Rectangle().fill(Color(red: 0.55, green: 0.45, blue: 0.35)).frame(height: 80)
                .frame(maxWidth: .infinity, alignment: .bottom)
            Rectangle().fill(Color(red: 0.2, green: 0.5, blue: 0.8)).frame(width: 80, height: 50)
                .offset(x: -80, y: -30)
            Rectangle().fill(Color(red: 0.15, green: 0.45, blue: 0.75)).frame(width: 60, height: 40)
                .offset(x: 100, y: 40)
            Rectangle().fill(Color(red: 0.7, green: 0.7, blue: 0.3)).frame(width: 50, height: 50)
                .offset(x: -50, y: 70)
            Rectangle().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 90, height: 30)
                .offset(x: 60, y: -50)

            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                )
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.primary.opacity(0.4))
                .font(.system(size: 14))
            Text("Buscar lugares")
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.4))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var hereLabel: some View {
        HStack(spacing: 4) {
            Text("📍")
                .font(.system(size: 12))
            Text("Estás aquí")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Partner Info

    private var partnerInfoCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Circle()
                    .fill(ThemeManager.shared.neonGlowGradient)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("💞 Valentina")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    Text("🟢 En línea")
                        .font(.system(size: 11))
                        .foregroundColor(.primary.opacity(0.55))
                    Text("Visto hace 2 min")
                        .font(.system(size: 10))
                        .foregroundColor(.primary.opacity(0.4))
                }
                Spacer()
                Text("2.3 km")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ThemeManager.shared.primaryPink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(ThemeManager.shared.primaryPink.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Zonas Guardadas

    private var zonasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Zonas Guardadas")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(zones) { zone in
                        Button {
                            selectedZone = zone
                        } label: {
                            ZoneCard(zone: zone, isSelected: selectedZone?.id == zone.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Lugares Especiales

    private var lugaresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Lugares Especiales")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(places.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            VStack(spacing: 10) {
                ForEach(places) { place in
                    PlacesCard(place: place, onDelete: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            places.removeAll { $0.id == place.id }
                        }
                    })
                }
            }
            Button {
                showNewPlaceAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Agregar lugar")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(ThemeManager.shared.primaryPink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ThemeManager.shared.primaryPink.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

// MARK: - Zone Card

private struct ZoneCard: View {
    let zone: Zone
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(zone.emoji)
                .font(.system(size: 32))
            Text(zone.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            Text(zone.address)
                .font(.system(size: 9))
                .foregroundColor(.primary.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(width: 110, height: 110)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ThemeManager.shared.primaryPink.opacity(0.18))
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? ThemeManager.shared.primaryPink.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Places Card

private struct PlacesCard: View {
    let place: Place
    let onDelete: () -> Void

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "es_MX")
        return f
    }

    var body: some View {
        GlassCard(cornerRadius: 18) {
            HStack(spacing: 12) {
                Text(place.emoji)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(place.address)
                        .font(.system(size: 11))
                        .foregroundColor(.primary.opacity(0.5))
                        .lineLimit(1)
                    Text("Agregado \(dateFormatter.string(from: place.dateAdded))")
                        .font(.system(size: 9))
                        .foregroundColor(.primary.opacity(0.35))
                }
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
