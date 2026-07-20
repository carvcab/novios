import SwiftUI

public struct LoveDiceView: View {
    let actions = ["beso", "caricia", "mordisco", "masaje", "soplo", "cosquillas", "susurro", "lamer"]
    let bodyParts = ["cuello", "labios", "espalda", "manos", "oreja", "mejilla", "frente", "abdomen"]

    @State private var die1Value = 1
    @State private var die2Value = 2
    @State private var isRolling = false
    @State private var result: String?
    @State private var rollCount = 0

    public var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager.shared.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Dados del Amor 🎲")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        HStack(spacing: 40) {
                            VStack(spacing: 8) {
                                Text("Acción")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Image(systemName: "die.face.\(die1Value)")
                                    .font(.system(size: 80))
                                    .foregroundColor(.primary)
                                    .rotationEffect(.degrees(isRolling ? 360 : 0))
                                    .animation(isRolling ? .linear(duration: 0.1).repeatCount(10, autoreverses: false) : .default, value: die1Value)
                            }

                            VStack(spacing: 8) {
                                Text("Parte del Cuerpo")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ThemeManager.shared.primaryPink)
                                Image(systemName: "die.face.\(die2Value)")
                                    .font(.system(size: 80))
                                    .foregroundColor(.primary)
                                    .rotationEffect(.degrees(isRolling ? -360 : 0))
                                    .animation(isRolling ? .linear(duration: 0.1).repeatCount(10, autoreverses: false) : .default, value: die2Value)
                            }
                        }
                        .padding(.vertical, 8)

                        Button {
                            rollDice()
                        } label: {
                            Text("Lanzar Dados 🎲")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(ThemeManager.shared.primaryPink.opacity(0.8))
                                .cornerRadius(16)
                        }
                        .disabled(isRolling)
                        .padding(.horizontal, 40)

                        if let result {
                            GlassCard {
                                Text(result)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 12)
                            }
                            .padding(.horizontal, 24)
                            .transition(.scale.combined(with: .opacity))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Acciones posibles:")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                            ForEach(actions, id: \.self) { action in
                                Text("• \(action)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                            }

                            Text("Partes del cuerpo:")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ThemeManager.shared.primaryPink)
                                .padding(.top, 8)
                            ForEach(bodyParts, id: \.self) { part in
                                Text("• \(part)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Dados del Amor")
        }
    }

    func rollDice() {
        isRolling = true
        result = nil
        rollCount = 0

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            die1Value = Int.random(in: 1...6)
            die2Value = Int.random(in: 1...6)
            rollCount += 1

            if rollCount >= 10 {
                timer.invalidate()
                let action = actions.randomElement()!
                let bodyPart = bodyParts.randomElement()!
                withAnimation {
                    result = "¡Dale un \(action) en \(bodyPart) a tu pareja!"
                }
                isRolling = false
            }
        }
    }
}
