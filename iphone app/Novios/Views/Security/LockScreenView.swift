import SwiftUI
import LocalAuthentication

public struct LockScreenView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var theme = ThemeManager.shared
    @State private var pin: [String] = []
    @State private var message = "Ingresa tu código PIN para entrar"
    @State private var isWrong = false
    @State private var isUnlocked = false
    @State private var showRecovery = false
    @State private var recoveryAnswer = ""
    @State private var recoveryMessage = ""

    private let pinLength = 4
    private let defaults = UserDefaults.standard

    public init() {}

    public var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Lock icon
                Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                    .appFont(size: 48)
                    .foregroundColor(isUnlocked ? .green : theme.primary)
                    .padding(24)
                    .background((isUnlocked ? Color.green : theme.primary).opacity(0.1))
                    .clipShape(Circle())

                Text("Novios App")
                    .appFont(size: 24, weight: .bold)
                    .foregroundColor(.primary)

                Text(message)
                    .appFont(size: 14, weight: isWrong || isUnlocked ? .semibold : .regular)
                    .foregroundColor(isWrong ? .red : theme.textSecondary)

                // PIN dots
                HStack(spacing: 16) {
                    ForEach(0..<pinLength, id: \.self) { i in
                        Circle()
                            .fill(i < pin.count ? theme.primary : theme.textSecondary.opacity(0.3))
                            .frame(width: i < pin.count ? 18 : 14, height: i < pin.count ? 18 : 14)
                            .overlay(Circle().stroke(theme.primary, lineWidth: 2))
                            .animation(.spring(response: 0.2), value: pin.count)
                    }
                }
                .padding(.vertical, 8)

                Spacer()

                // Keypad
                VStack(spacing: 10) {
                    ForEach([["1","2","3"], ["4","5","6"], ["7","8","9"]], id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(row, id: \.self) { digit in
                                keyButton(digit)
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        Button {
                            if !pin.isEmpty { pin.removeLast(); isWrong = false }
                        } label: {
                            Image(systemName: "backspace.fill")
                                .appFont(size: 22)
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 72, height: 72)
                        }
                        keyButton("0")
                        Button {
                            showRecovery = true
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .appFont(size: 22)
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 72, height: 72)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 30)
            }
        }
        .onChange(of: pin.count) { count in
            if count == pinLength { verifyPin() }
        }
        .alert("Recuperar PIN", isPresented: $showRecovery) {
            TextField("Tu respuesta", text: $recoveryAnswer)
            Button("Cancelar", role: .cancel) { recoveryAnswer = "" }
            Button("Verificar") { verifyRecovery() }
        } message: {
            let question = defaults.string(forKey: "security_question") ?? "No hay pregunta configurada"
            Text("Pregunta: \(question)")
        }
    }

    private func keyButton(_ digit: String) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            if pin.count < pinLength && !isUnlocked {
                isWrong = false
                pin.append(digit)
            }
        } label: {
            Text(digit)
                .appFont(size: 26, weight: .bold)
                .foregroundColor(theme.primary)
                .frame(width: 72, height: 72)
                .overlay(Circle().stroke(theme.primary.opacity(0.3), lineWidth: 1.5))
        }
    }

    private func verifyPin() {
        let correctPin = defaults.string(forKey: "pin_code") ?? ""
        guard !correctPin.isEmpty else {
            unlock()
            return
        }
        if pin.joined() == correctPin {
            unlock()
        } else {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            pin.removeAll()
            isWrong = true
            message = "PIN incorrecto. Intenta de nuevo"
        }
    }

    private func unlock() {
        isUnlocked = true
        message = "¡Desbloqueado!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            authService.isLocked = false
        }
    }

    private func verifyRecovery() {
        let correctAnswer = (defaults.string(forKey: "security_answer") ?? "").lowercased()
        if recoveryAnswer.trimmingCharacters(in: .whitespaces).lowercased() == correctAnswer {
            let pin = defaults.string(forKey: "pin_code") ?? "1234"
            recoveryMessage = "Tu PIN es: \(pin)"
            showRecovery = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.message = recoveryMessage
            }
        } else {
            recoveryMessage = "Respuesta incorrecta"
        }
        recoveryAnswer = ""
    }
}
