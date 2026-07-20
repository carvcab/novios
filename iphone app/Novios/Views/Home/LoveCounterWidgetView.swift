import SwiftUI

public struct LoveCounterWidgetView: View {
    public var anniversaryDate: Date?
    
    @State private var timeElapsed: (days: Int, hours: Int, minutes: Int, seconds: Int) = (0, 0, 0, 0)
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .font(.system(size: 22))
                    
                    Text("TIEMPO JUNTOS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ThemeManager.shared.primaryPink)
                        .tracking(1.2)
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    TimeUnitView(value: timeElapsed.days, unit: "DÍAS")
                    TimeUnitView(value: timeElapsed.hours, unit: "HORAS")
                    TimeUnitView(value: timeElapsed.minutes, unit: "MIN")
                    TimeUnitView(value: timeElapsed.seconds, unit: "SEG")
                }
            }
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
        .onAppear {
            updateTimer()
        }
    }
    
    private func updateTimer() {
        let start = anniversaryDate ?? Date().addingTimeInterval(-86400 * 365) // 1 year default
        let diff = Int(Date().timeIntervalSince(start))
        
        let days = diff / 86400
        let hours = (diff % 86400) / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        
        self.timeElapsed = (days, hours, minutes, seconds)
    }
}

public struct TimeUnitView: View {
    public let value: Int
    public let unit: String
    
    public var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(ThemeManager.shared.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
