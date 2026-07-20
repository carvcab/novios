import SwiftUI

public struct PartnerStatusCard: View {
    public var partner: UserModel?
    
    public var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(ThemeManager.shared.primaryPink.opacity(0.2))
                            .frame(width: 54, height: 54)
                        
                        Text(partner?.mood ?? "🥰")
                            .font(.system(size: 28))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(partner?.displayName ?? "Mi Pareja ❤️")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(partner?.moodMessage ?? "Conectado contigo")
                            .font(.system(size: 13))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Battery Indicator
                    HStack(spacing: 4) {
                        Image(systemName: partner?.isCharging == true ? "battery.100.bolt" : "battery.75")
                            .foregroundColor(partner?.isCharging == true ? .green : .white)
                        
                        Text("\(Int((partner?.batteryLevel ?? 0.85) * 100))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Botones de acciones rápidas de amor
                HStack(spacing: 12) {
                    QuickLoveActionButton(title: "Beso 💋", color: .pink) {
                        ChatService.shared.sendKissAction()
                    }
                    
                    QuickLoveActionButton(title: "Abrazo 🤗", color: .purple) {
                        ChatService.shared.sendHugAction()
                    }
                    
                    QuickLoveActionButton(title: "Toque ✨", color: .orange) {
                        ChatService.shared.sendTouchAction()
                    }
                }
            }
        }
    }
}

public struct QuickLoveActionButton: View {
    public let title: String
    public let color: Color
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(color.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        }
    }
}
