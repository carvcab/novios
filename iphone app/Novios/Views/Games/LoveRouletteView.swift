import SwiftUI

public struct LoveRouletteView: View {
    let sectors = ["Abrazo 🤗", "Secreto 🤫", "Beso 😘", "Cumido 🌶️", "Beso Apasionado 💋", "Masaje 💆"]
    let sectorColors: [Color] = [
        Color(red: 0.91, green: 0.27, blue: 0.49),
        Color(red: 0.61, green: 0.44, blue: 0.91),
        Color(red: 0.27, green: 0.67, blue: 0.91),
        Color(red: 0.91, green: 0.61, blue: 0.27),
        Color(red: 0.44, green: 0.81, blue: 0.44),
        Color(red: 0.91, green: 0.44, blue: 0.67)
    ]

    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var result: String?
    @State private var history: [String] = []

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Ruleta del Amor 🎡")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 8)

                    ZStack {
                        wheelView
                            .rotationEffect(.degrees(rotation))

                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .offset(y: -135)
                    }

                    if let result {
                        GlassCard {
                            Text(result)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button {
                        spinWheel()
                    } label: {
                        Text("Girar 🎡")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(ThemeManager.shared.primaryPink.opacity(0.8))
                            .cornerRadius(16)
                    }
                    .disabled(isSpinning)
                    .padding(.horizontal, 40)

                    if !history.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Últimos giros:")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                                .padding(.leading, 24)

                            ForEach(Array(history.prefix(5).enumerated()), id: \.offset) { _, item in
                                Text("• \(item)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                    .padding(.leading, 24)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Ruleta del Amor")
        }
    }

    var wheelView: some View {
        let anglePerSector = 360.0 / Double(sectors.count)
        return ZStack {
            ForEach(0..<sectors.count, id: \.self) { i in
                Pie(startAngle: .degrees(Double(i) * anglePerSector - 90),
                    endAngle: .degrees(Double(i + 1) * anglePerSector - 90))
                    .fill(sectorColors[i])
            }

            ForEach(0..<sectors.count, id: \.self) { i in
                let midAngle = (Double(i) + 0.5) * anglePerSector - 90
                let radius: CGFloat = 85
                let x = CGFloat(cos(midAngle * .pi / 180)) * radius
                let y = CGFloat(sin(midAngle * .pi / 180)) * radius

                Text(sectors[i])
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .position(x: 130 + x, y: 130 + y)
            }
        }
        .frame(width: 260, height: 260)
    }

    func spinWheel() {
        isSpinning = true
        result = nil

        let extraSpins = Double.random(in: 720...1800)
        let targetSector = Int.random(in: 0..<sectors.count)
        let sectorAngle = 360.0 / Double(sectors.count)
        let targetRotation = Double(targetSector) * sectorAngle + sectorAngle / 2

        withAnimation(.easeOut(duration: 2.5)) {
            rotation += extraSpins + targetRotation
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isSpinning = false
            let sector = sectors[targetSector]
            withAnimation {
                result = "¡\(sector)! 🎉"
            }
            history.insert(sector, at: 0)
            if history.count > 5 {
                history.removeLast()
            }
        }
    }
}

struct Pie: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
