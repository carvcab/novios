import SwiftUI
import FirebaseFirestore

public struct DiceView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isRolling = false
    @State private var resultText = ""
    @State private var showResult = false
    @State private var dice1Offset: CGFloat = 0
    @State private var dice2Offset: CGFloat = 0
    @State private var dice1Rotation: Double = 0
    @State private var dice2Rotation: Double = 0

    private let bodyParts = ["Labios", "Cuello", "Manos", "Frente", "Mejilla", "Hombros", "Espalda", "Cintura"]
    private let actions = ["Besar", "Acariciar", "Abrazar", "Masajear", "Susurrar", "Morder suave", "Soplar", "Hacer cosquillas"]
    private let places = ["Sofa", "Cocina", "Balcon", "Cama", "Ducha", "Espejo", "Suelo", "Silla"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Dados Romanticos")
                        .appFont(size: 22, weight: .bold)
                        .foregroundColor(theme.textPrimary)

                    diceSection
                    categoryLabels

                    if showResult, !resultText.isEmpty {
                        resultCard
                    }

                    Spacer()

                    rollButton
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
        }
    }

    private var diceSection: some View {
        HStack(spacing: 30) {
            diceView(label: "Parte\ndel cuerpo", emoji: "🫦", offset: dice1Offset, rotation: dice1Rotation)
            diceView(label: "Accion", emoji: "💋", offset: dice2Offset, rotation: dice2Rotation)
        }
        .padding(.vertical, 20)
    }

    private func diceView(label: String, emoji: String, offset: CGFloat, rotation: Double) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.isDarkMode ? Color.white.opacity(0.1) : Color.white)
                    .shadow(color: theme.primary.opacity(0.15), radius: 10)
                    .frame(width: 100, height: 100)

                Text(isRolling ? "?" : emoji)
                    .font(.system(size: 44))
                    .offset(y: offset)
                    .rotationEffect(.degrees(rotation))
            }
            Text(label)
                .appFont(size: 11, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textSecondary)
        }
    }

    private var categoryLabels: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text("Parte del cuerpo").appFont(size: 9, weight: .bold).foregroundColor(theme.primary)
                Text("Accion").appFont(size: 9, weight: .bold).foregroundColor(theme.secondary)
                Text("Lugar").appFont(size: 9, weight: .bold).foregroundColor(Color.orange)
            }
            Spacer()
        }
    }

    private var resultCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill").font(.system(size: 24)).foregroundColor(theme.primary)
            Text(resultText)
                .appFont(size: 18, weight: .bold)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }

    private var rollButton: some View {
        Button {
            rollDice()
        } label: {
            Label(isRolling ? "Lanzando..." : "Lanzar Dados", systemImage: "dice.fill")
                .appFont(size: 16, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(isRolling ? Color.gray : theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .foregroundColor(.white)
        }
        .disabled(isRolling)
    }

    private func rollDice() {
        isRolling = true
        showResult = false

        withAnimation(.interpolatingSpring(stiffness: 100, damping: 5).repeatCount(5, autoreverses: false)) {
            dice1Offset = -20
            dice2Offset = 20
            dice1Rotation = 360
            dice2Rotation = -360
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let bodyPart = bodyParts.randomElement() ?? "Labios"
            let action = actions.randomElement() ?? "Besar"
            let place = places.randomElement() ?? "Sofa"

            resultText = "\(action) \(bodyPart.lowercased()) en \(place.lowercased())"

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                dice1Offset = 0
                dice2Offset = 0
                dice1Rotation = 0
                dice2Rotation = 0
                showResult = true
                isRolling = false
            }
        }
    }
}
