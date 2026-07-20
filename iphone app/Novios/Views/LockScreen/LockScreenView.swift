import SwiftUI
import LocalAuthentication

public struct LockScreenView: View {
    @State private var pin: String = ""
    @State private var isLocked = true
    private let correctPin = "1234"

    public init() {}

    public var body: some View {
        if isLocked {
            lockedContent
        } else {
            unlockedContent
        }
    }

    private var lockedContent: some View {
        ZStack {
            LiquidBackgroundView()

            VStack(spacing: 32) {
                Text("Novios")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                    .padding(.top, 60)

                Spacer()

                VStack(spacing: 16) {
                    Text("Bloqueo de App")
                        .font(.title2)
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index < pin.count ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }

                Spacer()

                numberPad

                HStack(spacing: 40) {
                    Button(action: authenticateWithBiometrics) {
                        Image(systemName: "faceid")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                    }

                    Button(action: deleteDigit) {
                        Image(systemName: "delete.left")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            ForEach(1..<10, id: \.self) { number in
                numberButton("\(number)")
            }
            Color.clear.frame(height: 72)
            numberButton("0")
            Color.clear.frame(height: 72)
        }
        .padding(.horizontal, 48)
    }

    private func numberButton(_ label: String) -> some View {
        Button(action: { addDigit(label) }) {
            Text(label)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.white.opacity(0.15)))
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
        }
    }

    private func addDigit(_ digit: String) {
        guard pin.count < 4 else { return }
        pin.append(digit)
        if pin.count == 4 {
            if pin == correctPin {
                withAnimation(.easeInOut) { isLocked = false }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    pin = ""
                }
            }
        }
    }

    private func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Desbloquear Novios")
            { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.easeInOut) { isLocked = false }
                    }
                }
            }
        }
    }

    private var unlockedContent: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("App desbloqueada")
                    .font(.title)
                    .foregroundColor(.primary)

                GlassCard {
                    Text("Bienvenido de vuelta")
                        .foregroundColor(.primary)
                        .padding()
                }
                .padding(.horizontal, 32)

                Button(action: {
                    pin = ""
                    withAnimation(.easeInOut) { isLocked = true }
                }) {
                    Text("Bloquear App")
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(ThemeManager.shared.primaryPink)
                        .cornerRadius(12)
                }
            }
        }
    }
}
