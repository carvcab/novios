import SwiftUI

public struct LocationView: View {
    @StateObject private var userService = UserService.shared
    @State private var distanceKm: Double = 0
    @State private var partnerOnline = false
    @State private var partnerName = ""
    @State private var partnerScreen = ""
    @State private var partnerBattery = -1

    public var body: some View {
        ZStack {
            LiquidBackgroundView()

            VStack(spacing: 0) {
                // Top bar
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundColor(ThemeManager.shared.primaryPink)
                    Text(distanceKm > 0 ? "\(distanceKm, specifier: "%.1f") km" : "Ubicación")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    if partnerBattery > 0 {
                        BatteryChipView(label: partnerName, level: partnerBattery, color: ThemeManager.shared.primaryPink)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Map placeholder
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 48))
                            .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                        Text("Mapa de ubicación")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Tu pareja está a \(distanceKm > 0 ? "\(distanceKm, specifier: "%.1f") km" : "—")")
                            .font(.system(size: 13))
                            .foregroundColor(.primary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                .padding(.horizontal, 16)

                Spacer()

                // Bottom sheet content
                VStack(spacing: 16) {
                    // Partner card
                    GlassCard {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(ThemeManager.shared.neonGlowGradient)
                                .frame(width: 50, height: 50)
                                .overlay(Image(systemName: "person.fill").foregroundColor(.primary))
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("💞 \(partnerName)")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.primary)
                                    Circle()
                                        .fill(partnerOnline ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)
                                }
                                Text(partnerOnline ? (partnerScreen.isEmpty ? "🟢 En línea" : "📱 \(partnerScreen)") : "⚫ Sin conexión")
                                    .font(.system(size: 11))
                                    .foregroundColor(.primary.opacity(0.6))
                            }
                            Spacer()
                            Text(distanceKm > 0 ? "\(distanceKm, specifier: "%.1f") km" : "--")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ThemeManager.shared.primaryPink.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(16)
                    }

                    // Quick actions
                    HStack(spacing: 10) {
                        QuickActionButtonView(icon: "location", label: "Cómo llegar", color: .blue, action: {})
                        QuickActionButtonView(icon: "heart", label: "Corazón", color: ThemeManager.shared.primaryPink, action: {})
                        QuickActionButtonView(icon: "square.and.arrow.up", label: "Compartir", color: .teal, action: {})
                        QuickActionButtonView(icon: "hand.raised", label: "Privacidad", color: .gray, action: {})
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            partnerName = userService.partnerUser?.displayName ?? "Pareja"
            partnerOnline = userService.partnerUser?.isOnline ?? false
        }
    }
}

public struct BatteryChipView: View {
    public let label: String
    public let level: Int
    public let color: Color

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level < 20 ? "battery.25" : "battery.75")
                .foregroundColor(level < 20 ? .red : color)
            Text("\(label): \(level)%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

public struct QuickActionButtonView: View {
    public let icon: String
    public let label: String
    public let color: Color
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
