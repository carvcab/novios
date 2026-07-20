import SwiftUI

public struct ConstellationView: View {
    private let coupleName = "Diego & Ana"
    private let coupleDate = "14 Feb 2025"

    private struct Star: Identifiable {
        let id = UUID()
        let position: CGPoint
        let size: CGFloat
        let opacity: Double
    }

    private struct Connection: Identifiable {
        let id = UUID()
        let from: Int
        let to: Int
    }

    @State private var stars: [Star] = []
    @State private var connections: [Connection] = []
    @State private var animate = false

    private func generateConstellation(in size: CGSize) {
        var newStars: [Star] = []
        for _ in 0..<25 {
            newStars.append(Star(
                position: CGPoint(x: CGFloat.random(in: 20...size.width - 20), y: CGFloat.random(in: 80...size.height - 60)),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.3...1.0)
            ))
        }
        stars = newStars

        var newConnections: [Connection] = []
        let mainStarIndices = Array(0..<min(7, newStars.count))
        for i in 0..<mainStarIndices.count - 1 {
            newConnections.append(Connection(from: mainStarIndices[i], to: mainStarIndices[i + 1]))
        }
        for i in 0..<newStars.count {
            if !mainStarIndices.contains(i) {
                let nearest = mainStarIndices.min(by: { a, b in
                    distance(newStars[i].position, newStars[a].position) < distance(newStars[i].position, newStars[b].position)
                }) ?? 0
                newConnections.append(Connection(from: i, to: nearest))
            }
        }
        connections = newConnections
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }

    private func shareConstellation() {
        let text = "✨ Nuestra Constelación ✨\n\(coupleName)\n📅 \(coupleDate)\nUnidos por el destino bajo las estrellas."
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let root = window.rootViewController {
            root.present(av, animated: true)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.08).ignoresSafeArea()

                GeometryReader { geo in
                    ZStack {
                        ForEach(Array(connections.enumerated()), id: \.element.id) { _, conn in
                            if conn.from < stars.count, conn.to < stars.count {
                                Path { path in
                                    path.move(to: stars[conn.from].position)
                                    path.addLine(to: stars[conn.to].position)
                                }
                                .stroke(ThemeManager.shared.primaryPink.opacity(0.3), lineWidth: 0.8)
                            }
                        }

                        ForEach(Array(stars.enumerated()), id: \.element.id) { index, star in
                            Circle()
                                .fill(Color.white.opacity(star.opacity))
                                .frame(width: star.size, height: star.size)
                                .position(star.position)
                                .shadow(color: ThemeManager.shared.primaryPink.opacity(0.6), radius: animate ? 6 : 2)
                                .animation(
                                    Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                    value: animate
                                )
                        }
                    }
                    .onAppear {
                        generateConstellation(in: geo.size)
                        withAnimation { animate = true }
                    }
                    .onChange(of: geo.size) { newSize in
                        generateConstellation(in: newSize)
                    }
                }

                VStack {
                    VStack(spacing: 4) {
                        Text(coupleName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text(coupleDate)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    Spacer()

                    Button {
                        shareConstellation()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Compartir")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(ThemeManager.shared.neonGlowGradient)
                        .cornerRadius(14)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Nuestra Constelación")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
