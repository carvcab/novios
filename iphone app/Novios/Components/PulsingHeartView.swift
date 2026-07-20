import SwiftUI

public struct PulsingHeartView: View {
    public var size: CGFloat
    @State private var isPulsing = false
    
    public init(size: CGFloat = 64) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Heart Glow Ring 1
            Image(systemName: "heart.fill")
                .font(.system(size: size))
                .foregroundColor(ThemeManager.shared.primaryPink.opacity(0.4))
                .scaleEffect(isPulsing ? 1.35 : 1.0)
                .blur(radius: isPulsing ? 14 : 4)
            
            // Heart Glow Ring 2
            Image(systemName: "heart.fill")
                .font(.system(size: size))
                .foregroundColor(ThemeManager.shared.primaryPurple.opacity(0.3))
                .scaleEffect(isPulsing ? 1.2 : 0.95)
                .blur(radius: 8)
            
            // Core Main Heart
            Image(systemName: "heart.fill")
                .font(.system(size: size))
                .foregroundStyle(ThemeManager.shared.neonGlowGradient)
                .shadow(color: ThemeManager.shared.primaryPink.opacity(0.8), radius: 12, x: 0, y: 4)
                .scaleEffect(isPulsing ? 1.08 : 0.98)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isPulsing.toggle()
            }
        }
    }
}

public struct FloatingHeartParticle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var opacity: Double
    public var scale: CGFloat
}

public struct FloatingHeartsEffect: View {
    @State private var particles: [FloatingHeartParticle] = []
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ThemeManager.shared.primaryPink.opacity(p.opacity))
                        .scaleEffect(p.scale)
                        .position(x: p.x, y: p.y)
                }
            }
            .onReceive(timer) { _ in
                let newParticle = FloatingHeartParticle(
                    x: CGFloat.random(in: 40...(geo.size.width - 40)),
                    y: geo.size.height + 20,
                    opacity: Double.random(in: 0.4...0.8),
                    scale: CGFloat.random(in: 0.6...1.2)
                )
                particles.append(newParticle)
                
                // Animate upwards and fade out
                withAnimation(.easeOut(duration: 4.0)) {
                    if let index = particles.firstIndex(where: { $0.id == newParticle.id }) {
                        particles[index].y -= CGFloat.random(in: 250...450)
                        particles[index].opacity = 0
                    }
                }
                
                // Cleanup old particles
                if particles.count > 15 {
                    particles.removeFirst()
                }
            }
        }
        .allowsHitTesting(false)
    }
}
