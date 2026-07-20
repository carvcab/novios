import SwiftUI
import CoreLocation

public struct DistanceWidgetView: View {
    @StateObject private var locationService = LocationService.shared
    public var partnerCoordinate: CLLocationCoordinate2D?
    
    @State private var pulseWave = false
    
    public var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    // Animated Radar Wave Ring 1
                    Circle()
                        .stroke(ThemeManager.shared.primaryPink.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 52, height: 52)
                        .scaleEffect(pulseWave ? 1.5 : 0.8)
                        .opacity(pulseWave ? 0.0 : 0.8)

                    // Animated Radar Wave Ring 2
                    Circle()
                        .stroke(ThemeManager.shared.primaryPurple.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 52, height: 52)
                        .scaleEffect(pulseWave ? 1.25 : 0.9)
                        .opacity(pulseWave ? 0.1 : 0.7)

                    Circle()
                        .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 22))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .shadow(color: ThemeManager.shared.primaryPink.opacity(0.8), radius: 6)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("DISTANCIA EN VIVO")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                            .tracking(1.0)
                    }
                    
                    Text(locationService.formattedDistance(to: partnerCoordinate ?? CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    locationService.requestPermission()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                pulseWave = true
            }
        }
    }
}
