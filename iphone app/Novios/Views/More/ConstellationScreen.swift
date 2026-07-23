import SwiftUI

public struct ConstellationScreen: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var selectedShape = "heart"

    private let shapes = ["heart", "infinity", "aries", "taurus", "gemini", "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            VStack(spacing: 12) {
                Text("Toca una constelación").appFont(size: 14, weight: .medium).foregroundColor(theme.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shapes, id: \.self) { shape in
                            Button {
                                selectedShape = shape
                            } label: {
                                Text(shapeIcon(shape)).appFont(size: 16)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(selectedShape == shape ? theme.primary.opacity(0.3) : theme.surfaceBackground)
                                    .clipShape(Capsule())
                            }
                        }
                    }.padding(.horizontal, 12)
                }
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    ConstellationCanvas(shape: selectedShape)
                }
                .cornerRadius(20).padding(.horizontal, 12)
            }
            .padding(.vertical, 12)
        }
        .navigationTitle("Constelación")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func shapeIcon(_ s: String) -> String {
        switch s {
        case "heart": return "❤️"
        case "infinity": return "♾️"
        case "aries": return "♈"
        case "taurus": return "♉"
        case "gemini": return "♊"
        case "cancer": return "♋"
        case "leo": return "♌"
        case "virgo": return "♍"
        case "libra": return "♎"
        case "scorpio": return "♏"
        case "sagittarius": return "♐"
        case "capricorn": return "♑"
        case "aquarius": return "♒"
        case "pisces": return "♓"
        default: return "⭐"
        }
    }
}

private struct ConstellationCanvas: View {
    let shape: String
    @State private var stars: [(CGPoint, String, Double)] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                ForEach(0..<60, id: \.self) { _ in
                    Circle().fill(Color.white.opacity(Double.random(in: 0.1...0.6)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(x: CGFloat.random(in: 0...w), y: CGFloat.random(in: 0...h))
                }
                let points = constellationPoints(shape, w, h)
                ForEach(Array(points.enumerated()), id: \.offset) { i, pt in
                    Circle().fill(Color.yellow).frame(width: 8, height: 8)
                        .shadow(color: .yellow, radius: 4).position(pt)
                    if i > 0 {
                        Path { path in
                            path.move(to: points[i-1])
                            path.addLine(to: pt)
                        }.stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                    }
                }
                ForEach(Array(stars.enumerated()), id: \.offset) { i, star in
                    Circle().fill(Color.cyan).frame(width: 6, height: 6)
                        .shadow(color: .cyan, radius: 3).position(star.0)
                    Text(star.1).appFont(size: 8).foregroundColor(.white.opacity(0.7))
                        .position(x: star.0.x, y: star.0.y + 12)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { loc in
                let names = ["Beso", "Abrazo", "Eterno", "Pasión", "Dulzura", "Sueño", "Destino", "Alma", "Corazón", "Luz"]
                stars.append((loc, "Estrella del \(names.randomElement()!)", Double.random(in: 10...999)))
            }
        }
    }

    private func constellationPoints(_ shape: String, _ w: CGFloat, _ h: CGFloat) -> [CGPoint] {
        let cx = w/2, cy = h/2, s = min(w, h) * 0.3
        switch shape {
        case "heart":
            return (0..<16).map { i in
                let t = Double(i) / 15 * 2 * .pi
                let x = cx + CGFloat(16 * pow(sin(t), 3)) * s / 16
                let y = cy - CGFloat(13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t)) * s / 16
                return CGPoint(x: x, y: y)
            }
        case "infinity":
            return (0..<20).map { i in
                let t = Double(i) / 19 * 2 * .pi
                let x = cx + CGFloat(s * cos(t)) / (1 + pow(sin(t), 2))
                let y = cy + CGFloat(s * sin(t) * cos(t)) / (1 + pow(sin(t), 2))
                return CGPoint(x: x, y: y)
            }
        default:
            return (0..<8).map { i in
                let a = Double(i) / 8 * 2 * .pi
                let r = s * (i % 2 == 0 ? 1.0 : 0.6)
                return CGPoint(x: cx + CGFloat(r * cos(a)), y: cy + CGFloat(r * sin(a)))
            }
        }
    }
}
