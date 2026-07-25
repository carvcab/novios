import SwiftUI
import FirebaseFirestore

public struct NeverHaveIEverView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var statements: [String] = []
    @State private var currentIndex = 0
    @State private var scoreDiego = 0
    @State private var scoreYosmari = 0
    @State private var gameOver = false
    @State private var currentPlayer = 0

    private let allStatements: [String] = [
        "Nunca he fingido un orgasmo",
        "Nunca he espiado tu telefono",
        "Nunca he mentido sobre mis sentimientos",
        "Nunca he pensado en terminar",
        "Nunca he tenido una cita a escondidas",
        "Nunca he stalkeado a un ex",
        "Nunca me he quedado dormido en una cita",
        "Nunca he dicho 'te amo' sin sentirlo",
        "Nunca he cancelado planes solo por flojera",
        "Nunca he comparado nuestra relacion con otra",
        "Nunca he visto tu historial de busquedas",
        "Nunca he contado un secreto que me confiaste",
        "Nunca he hecho algo solo para impresionarte",
        "Nunca he usado tu ropa sin permiso",
        "Nunca he fingido gustar de algo que odio",
        "Nunca he evitado una discusion importante",
        "Nunca he puesto a alguien mas antes que a ti",
        "Nunca he hecho cena y dicho que la cocine yo",
        "Nunca me he hecho el enojado sin razon",
        "Nunca he guardado mensajes viejos de otros",
        "Nunca he fingido estar bien cuando no lo estoy",
        "Nunca he hecho un plan sin consultarte",
        "Nunca he usado el silencio como castigo",
        "Nunca he gastado dinero a escondidas",
        "Nunca he fingido escuchar cuando no ponia atencion",
        "Nunca he dicho 'no me importa' cuando si importaba",
        "Nunca he revisado tus notificaciones",
        "Nunca he fingido estar dormido para evitar hablar",
        "Nunca he usado algo tuyo sin devolverlo",
        "Nunca he tenido un sueno erotico con otra persona",
        "Nunca he fingido recordar algo que olvide",
        "Nunca he hecho un regalo que me gustaba mas a mi",
        "Nunca he escondido mis emociones verdaderas"
    ]

    private let db = Firestore.firestore()
    private var coupleId: String { [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_") }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    if gameOver {
                        resultView
                    } else {
                        scoreBoard
                        progressBar
                        statementCard
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("Nunca He Hecho")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
            .onAppear { shuffleAndStart() }
        }
    }

    private var scoreBoard: some View {
        HStack {
            playerScore(name: "Diego", score: scoreDiego, color: Color.blue.opacity(0.7))
            Spacer()
            playerScore(name: "Yosmari", score: scoreYosmari, color: Color.pink.opacity(0.7))
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func playerScore(name: String, score: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(name).appFont(size: 12, weight: .semibold).foregroundColor(theme.textSecondary)
            Text("\(score)").appFont(size: 24, weight: .bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Text("\(currentIndex + 1)/\(statements.count)").appFont(size: 12).foregroundColor(theme.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                    Capsule().fill(theme.primary).frame(width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(statements.count), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var statementCard: some View {
        VStack(spacing: 16) {
            Text(statements[currentIndex])
                .appFont(size: 20, weight: .semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.textPrimary)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Text("Tu turno: \(currentPlayer == 0 ? "Diego" : "Yosmari")")
                .appFont(size: 13, weight: .semibold)
                .foregroundColor(theme.textSecondary)

            HStack(spacing: 16) {
                Button {
                    tapHeHecho()
                } label: {
                    Label("He hecho", systemImage: "hand.raised.fill")
                        .appFont(size: 15, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.green.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundColor(.green)

                Button {
                    tapNunca()
                } label: {
                    Label("Nunca", systemImage: "xmark.circle.fill")
                        .appFont(size: 15, weight: .semibold)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundColor(.red)
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Image(systemName: scoreDiego > scoreYosmari ? "diego" : scoreYosmari > scoreDiego ? "yosmari" : "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.primary)

            Text("Juego terminado").appFont(size: 22, weight: .bold).foregroundColor(theme.textPrimary)

            HStack(spacing: 30) {
                VStack {
                    Text("Diego").appFont(size: 14).foregroundColor(theme.textSecondary)
                    Text("\(scoreDiego)").appFont(size: 36, weight: .bold).foregroundColor(Color.blue)
                }
                VStack {
                    Text("Yosmari").appFont(size: 14).foregroundColor(theme.textSecondary)
                    Text("\(scoreYosmari)").appFont(size: 36, weight: .bold).foregroundColor(Color.pink)
                }
            }

            Text(winnerText()).appFont(size: 16, weight: .semibold).foregroundColor(theme.textPrimary)

            Button {
                shuffleAndStart()
            } label: {
                Label("Jugar otra vez", systemImage: "arrow.counterclockwise")
                    .appFont(size: 14, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
            }
        }
    }

    private func tapHeHecho() {
        if currentPlayer == 0 { scoreDiego += 1 } else { scoreYosmari += 1 }
        nextStatement()
    }

    private func tapNunca() {
        nextStatement()
    }

    private func nextStatement() {
        withAnimation {
            if currentIndex + 1 >= statements.count {
                gameOver = true
            } else {
                currentIndex += 1
                currentPlayer = currentPlayer == 0 ? 1 : 0
            }
        }
    }

    private func shuffleAndStart() {
        statements = allStatements.shuffled()
        currentIndex = 0
        scoreDiego = 0
        scoreYosmari = 0
        gameOver = false
        currentPlayer = 0
    }

    private func winnerText() -> String {
        if scoreDiego > scoreYosmari { return "Gano Diego 🎉" }
        if scoreYosmari > scoreDiego { return "Gano Yosmari 🎉" }
        return "Empate! 🤝"
    }
}
