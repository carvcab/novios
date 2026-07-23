import SwiftUI
import FirebaseFirestore

public struct GamesView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var activeGames: [GameSession] = []
    @State private var showGamePicker = false
    @State private var selectedGameType = ""
    @State private var snapshotListener: ListenerRegistration?
    @Environment(\.dismiss) private var dismiss

    private let db = Firestore.firestore()

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var gamesRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("games")
    }

    private struct GameDef: Identifiable {
        let id: String; let icon: String; let name: String; let desc: String; let colors: [Color]
    }

    private let games: [GameDef] = [
        GameDef(id: "quiz", icon: "questionmark.square.fill", name: "Quiz", desc: "Pon a prueba tu conocimiento", colors: [Color(red: 1, green: 0.36, blue: 0.54), Color(red: 1, green: 0.54, blue: 0.67)]),
        GameDef(id: "truth_dare", icon: "heart.fill", name: "Verdad o Reto", desc: "Respuestas y desafíos", colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.77, green: 0.71, blue: 0.99)]),
        GameDef(id: "memorama", icon: "rectangle.3.group.fill", name: "Memorama", desc: "Encuentra las parejas", colors: [Color(red: 1, green: 0.72, blue: 0.3), Color(red: 1, green: 0.84, blue: 0.31)]),
        GameDef(id: "tictactoe", icon: "grid.3x3", name: "Tres en Raya", desc: "Juego clásico por turnos", colors: [Color(red: 0.4, green: 0.73, blue: 0.42), Color(red: 0.65, green: 0.84, blue: 0.65)]),
        GameDef(id: "rps", icon: "hand.raised.fill", name: "Piedra Papel Tijera", desc: "Prueba tu suerte", colors: [Color(red: 0.26, green: 0.65, blue: 0.96), Color(red: 0.56, green: 0.79, blue: 0.98)]),
        GameDef(id: "hangman", icon: "person.fill.questionmark", name: "Ahorcado", desc: "Adivina palabras de amor", colors: [Color(red: 0.94, green: 0.33, blue: 0.31), Color(red: 0.94, green: 0.6, blue: 0.6)]),
        GameDef(id: "dice", icon: "dice.fill", name: "Dados del Amor", desc: "Acción y parte del cuerpo 🎲", colors: [Color(red: 0.93, green: 0.28, blue: 0.6), Color(red: 0.96, green: 0.25, blue: 0.37)]),
        GameDef(id: "cards", icon: "rectangle.on.rectangle.fill", name: "Carta Mayor", desc: "La carta más alta manda 🃏", colors: [Color(red: 0.55, green: 0.35, blue: 0.96), Color(red: 0.85, green: 0.28, blue: 0.94)]),
        GameDef(id: "prefer", icon: "questionmark.bubble.fill", name: "¿Qué Prefieres?", desc: "Elige tu dilema amoroso 🤔", colors: [Color(red: 0.23, green: 0.51, blue: 0.96), Color(red: 0.02, green: 0.71, blue: 0.83)]),
        GameDef(id: "roulette", icon: "arrow.trianglehead.2.clockwise.rotate.90", name: "Ruleta del Amor", desc: "Gira por un reto o premio 🎡", colors: [Color(red: 0.06, green: 0.73, blue: 0.51), Color(red: 0.2, green: 0.83, blue: 0.6)]),
        GameDef(id: "never", icon: "wineglass.fill", name: "Yo Nunca Nunca", desc: "Revela tus secretos 🍷", colors: [Color(red: 0.96, green: 0.62, blue: 0.04), Color(red: 0.98, green: 0.73, blue: 0.14)]),
        GameDef(id: "picante", icon: "flame.fill", name: "Picante", desc: "Verdad, reto y más 🔥", colors: [Color(red: 1, green: 0.36, blue: 0.54), Color(red: 1, green: 0.54, blue: 0.67)]),
    ]

    public init() {}

    public var body: some View {
        ZStack {
            LiquidBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerSection
                    activeGamesSection
                    gamesGrid
                }
                .padding(16)
            }
        }
        .navigationTitle("Juegos de Pareja 🎮")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let vc = UIHostingController(rootView: GameHistoryView())
                    if let top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                        var t = top; while let p = t.presentedViewController { t = p }
                        t.present(vc, animated: true)
                    }
                } label: {
                    Image(systemName: "chart.bar.fill").foregroundColor(theme.primary)
                }
            }
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 32))
                .foregroundColor(theme.primary)
            Text("Juegos de Pareja")
                .appFont(size: 22, weight: .bold)
                .foregroundColor(theme.textPrimary)
            Text("Diviértanse juntos online o en el mismo celular")
                .appFont(size: 13)
                .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - Active Games

    @ViewBuilder
    private var activeGamesSection: some View {
        if !activeGames.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "wifi").font(.system(size: 14)).foregroundColor(theme.primary)
                    Text("Partidas en Tiempo Real")
                        .appFont(size: 15, weight: .bold)
                        .foregroundColor(theme.primary)
                }
                .padding(.leading, 4)

                ForEach(activeGames) { g in
                    activeGameCard(g)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func activeGameCard(_ g: GameSession) -> some View {
        let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
        let partnerName = CoupleService.shared.partnerName
        let isSender = g.senderId == AuthService.shared.currentUser?.id
        let gameLabel = gameLabel(for: g.gameType)

        return GlassCard(cornerRadius: 14) {
            HStack {
                if g.status == "pending" {
                    if isSender {
                        ProgressView().scaleEffect(0.8).frame(width: 24)
                        Text("Esperando a \(partnerName)...")
                            .appFont(size: 14, weight: .medium)
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Button { deleteGameSession(g.id) } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                        }
                    } else {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(theme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("¡\(g.sender) te invitó!")
                                .appFont(size: 14, weight: .semibold)
                            Text("Juego: \(gameLabel)")
                                .appFont(size: 12)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Button { acceptGame(g) } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green).font(.system(size: 24))
                            }
                            Button { deleteGameSession(g.id) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red).font(.system(size: 24))
                            }
                        }
                    }
                } else {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(theme.primary)
                    Text("Partida de \(gameLabel) activa")
                        .appFont(size: 14, weight: .medium)
                    Spacer()
                    Button("Jugar") { playGame(g) }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.primary)
                        .controlSize(.small)
                    Button { deleteGameSession(g.id) } label: {
                        Image(systemName: "trash").foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Games Grid

    private var gamesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(games) { game in
                gameCard(game)
                    .onTapGesture { showGamePicker = true; selectedGameType = game.id }
            }
        }
    }

    private func gameCard(_ g: GameDef) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: g.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: g.colors[0].opacity(0.3), radius: 12, x: 0, y: 6)
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: g.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                Text(g.name)
                    .appFont(size: 14, weight: .bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(g.desc)
                    .appFont(size: 10)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .frame(minHeight: 140)
    }

    // MARK: - Game Picker Sheet

    private var gamePickerSheet: some View {
        let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
        let partnerName = CoupleService.shared.partnerName
        let label = gameLabel(for: selectedGameType)
        let cs = ThemeManager.shared

        return VStack(spacing: 16) {
            Text("Jugar a \(label)")
                .appFont(size: 18, weight: .bold)
                .foregroundColor(cs.textPrimary)
                .padding(.top, 20)

            Button {
                showGamePicker = false
                createGameSession(selectedGameType)
            } label: {
                HStack {
                    Image(systemName: "wifi")
                    Text("Jugar Online con mi pareja")
                        .appFont(size: 15)
                    Spacer()
                    Text("Invitar a \(partnerName)")
                        .appFont(size: 12)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(cs.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showGamePicker = false
                startLocalGame(selectedGameType)
            } label: {
                HStack {
                    Image(systemName: "iphone")
                    Text("Jugar en este mismo celular")
                        .appFont(size: 15)
                    Spacer()
                    Text("Pásense el teléfono")
                        .appFont(size: 12)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(.regularMaterial)
    }

    // MARK: - Firestore

    private func startListening() {
        snapshotListener = gamesRef.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            let items = docs.compactMap { doc -> GameSession? in
                let d = doc.data()
                guard let type = d["gameType"] as? String else { return nil }
                return GameSession(id: doc.documentID, gameType: type, status: d["status"] as? String ?? "pending", sender: d["sender"] as? String ?? "", senderId: d["senderId"] as? String ?? "", data: d)
            }
            activeGames = items
        }
    }

    private func stopListening() {
        snapshotListener?.remove(); snapshotListener = nil
    }

    private func createGameSession(_ type: String) {
        guard let uid = AuthService.shared.currentUser?.id else { return }
        Task {
            let id = UUID().uuidString
            try? await gamesRef.document(id).setData([
                "id": id, "gameType": type, "status": "pending",
                "sender": AuthService.shared.currentUser?.displayName ?? "Yo",
                "senderId": uid, "createdAt": FieldValue.serverTimestamp()
            ])
        }
    }

    private func deleteGameSession(_ id: String) {
        Task { try? await gamesRef.document(id).delete() }
    }

    private func acceptGame(_ g: GameSession) {
        Task {
            try? await gamesRef.document(g.id).updateData(["status": "active"])
            playGame(g)
        }
    }

    private func playGame(_ g: GameSession) {
        guard let top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else { return }
        var t = top; while let p = t.presentedViewController { t = p }
        let host = UIHostingController(rootView: OnlineGameView(gameId: g.id, gameType: g.gameType, gamesRef: gamesRef))
        t.present(host, animated: true)
    }

    private func startLocalGame(_ type: String) {
        guard let top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else { return }
        var t = top; while let p = t.presentedViewController { t = p }
        let host = UIHostingController(rootView: LocalGameView(gameType: type))
        t.present(host, animated: true)
    }

    private func gameLabel(for type: String) -> String {
        switch type {
        case "quiz": return "Quiz"
        case "truth_dare": return "Verdad o Reto"
        case "memorama": return "Memorama"
        case "tictactoe": return "Tres en Raya"
        case "rps": return "Piedra Papel Tijera"
        case "hangman": return "Ahorcado"
        case "dice": return "Dados del Amor"
        case "cards": return "Carta Mayor"
        case "prefer": return "¿Qué Prefieres?"
        case "roulette": return "Ruleta del Amor"
        case "never": return "Yo Nunca Nunca"
        case "picante": return "Picante"
        default: return type
        }
    }
}

// MARK: - Game Session Model

private struct GameSession: Identifiable {
    let id: String
    let gameType: String
    let status: String
    let sender: String
    let senderId: String
    let data: [String: Any]
}

// MARK: - Game History View

private struct GameHistoryView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                VStack(spacing: 32) {
                    Image(systemName: "chart.bar.xaxis").font(.system(size: 48)).foregroundColor(ThemeManager.shared.primary.opacity(0.5))
                    Text("Estadísticas e Historial").appFont(size: 20, weight: .bold).foregroundColor(ThemeManager.shared.textPrimary)
                    Text("Próximamente disponible").appFont(size: 14).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
        }
    }
    @Environment(\.dismiss) private var dismiss
}

// MARK: - Online Game View (Firestore synced)

private struct OnlineGameView: View {
    let gameId: String
    let gameType: String
    let gamesRef: CollectionReference
    @State private var docData: [String: Any] = [:]
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if isLoading {
                    ProgressView("Conectando a la partida...")
                } else {
                    gameContent
                }
            }
            .navigationTitle(gameTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
            .onAppear { startStream() }
        }
    }

    private var gameTitle: String {
        switch gameType {
        case "quiz": return "Quiz (Online)"
        case "truth_dare": return "Verdad o Reto (Online)"
        case "memorama": return "Memorama (Online)"
        case "tictactoe": return "Tres en Raya (Online)"
        case "rps": return "PPT (Online)"
        case "hangman": return "Ahorcado (Online)"
        default: return gameType
        }
    }

    @ViewBuilder
    private var gameContent: some View {
        switch gameType {
        case "quiz": OnlineQuizView(gameId: gameId, docData: $docData, update: update)
        case "truth_dare": OnlineTruthDareView(gameId: gameId, docData: $docData, update: update)
        case "memorama": OnlineMemoramaView(gameId: gameId, docData: $docData, update: update)
        case "tictactoe": OnlineTTTView(gameId: gameId, docData: $docData, update: update)
        case "rps": OnlineRPSView(gameId: gameId, docData: $docData, update: update)
        case "hangman": OnlineHangmanView(gameId: gameId, docData: $docData, update: update)
        default:
            VStack(spacing: 16) {
                Image(systemName: "wifi").font(.system(size: 48)).foregroundColor(.green)
                Text("Invitación enviada!").appFont(size: 18, weight: .bold)
                Text("Ambos abran este juego en su teléfono").appFont(size: 14).foregroundColor(.secondary)
            }
        }
    }

    private func startStream() {
        gamesRef.document(gameId).addSnapshotListener { snapshot, _ in
            guard let d = snapshot?.data() else { return }
            docData = d; isLoading = false
            if !snapshot!.exists { dismiss() }
        }
    }

    private func update(_ fields: [String: Any]) {
        Task { try? await gamesRef.document(gameId).updateData(fields) }
    }
}

// MARK: - Online Quiz

private struct OnlineQuizView: View {
    let gameId: String
    @Binding var docData: [String: Any]
    let update: ([String: Any]) -> Void
    @State private var q = 0
    @State private var score = 0
    @State private var finished = false

    private let questions: [[String: Any]] = [
        ["q": "¿Dónde fue nuestra primera cita oficial?", "o": ["Restaurante italiano", "El cine", "Un café acogedor", "Un parque"], "a": 2],
        ["q": "¿Quién dijo \"te amo\" primero?", "o": ["Yo", "Mi pareja", "Ambos", "Nadie"], "a": 0],
        ["q": "¿Cuál es nuestra comida favorita?", "o": ["Pizza", "Sushi", "Hamburguesas", "Tacos"], "a": 0],
        ["q": "¿Qué hacemos en un día lluvioso?", "o": ["Ver películas", "Dormir", "Cocinar", "Juegos"], "a": 0],
    ]

    var body: some View {
        let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
        let sender = docData["sender"] as? String ?? ""
        let isSender = myName == sender
        let myScoreField = isSender ? "senderScore" : "receiverScore"
        let partnerScoreField = isSender ? "receiverScore" : "senderScore"
        let myFinal = docData[myScoreField] as? Int
        let partnerFinal = docData[partnerScoreField] as? Int
        let partnerName = CoupleService.shared.partnerName

        return ScrollView {
            VStack(spacing: 20) {
                if let _ = myFinal {
                    Image(systemName: "trophy.fill").font(.system(size: 56)).foregroundColor(.yellow)
                    Text("Tu puntuación: \(score) / \(questions.count)")
                        .appFont(size: 18, weight: .bold)
                    Text(partnerFinal != nil ? "Puntuación de \(partnerName): \(partnerFinal!) / \(questions.count)" : "Esperando a que \(partnerName) termine de jugar...")
                        .appFont(size: 14).foregroundColor(.secondary)
                    if let pf = partnerFinal {
                        Text(score == pf ? "¡Empate! Se conocen igual de bien ❤️" : (score > pf ? "¡Ganaste! Conoces mejor la relación 🌟" : "¡\(partnerName) ganó! 🌟"))
                            .appFont(size: 16, weight: .bold).foregroundColor(.green)
                    }
                } else {
                    ProgressView(value: Double(q + 1) / Double(questions.count))
                    Text("Pregunta \(q + 1) de \(questions.count)")
                        .appFont(size: 12).foregroundColor(.secondary)
                    Text(questions[q]["q"] as? String ?? "")
                        .appFont(size: 17, weight: .semibold)
                        .multilineTextAlignment(.center)
                    ForEach(Array((questions[q]["o"] as? [String] ?? []).enumerated()), id: \.offset) { i, opt in
                        Button {
                            if i == (questions[q]["a"] as? Int ?? -1) { score += 1 }
                            if q < questions.count - 1 { q += 1 }
                            else { update([myScoreField: score]); finished = true }
                        } label: {
                            Text(opt).appFont(size: 14).foregroundColor(ThemeManager.shared.textPrimary)
                                .frame(maxWidth: .infinity).padding(14)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeManager.shared.primary.opacity(0.3)))
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Online Truth or Dare

private struct OnlineTruthDareView: View {
    let gameId: String
    @Binding var docData: [String: Any]
    let update: ([String: Any]) -> Void
    @State private var isGenerating = false

    private let categories = ["Divertido", "Romántico", "Atrevido"]
    private let truths = ["¿Qué fue lo primero que te atrajo de mí?", "¿Cuál ha sido el momento más conectado que has sentido?", "Si pudieras cambiar un hábito mío, ¿cuál sería?", "¿Qué canción te recuerda a nosotros?", "¿Cuál ha sido la mentira más piadosa que me has dicho?"]
    private let dares = ["Dame un beso de 10 segundos.", "Cántame una canción de amor mirándome a los ojos.", "Hazme un masaje de hombros por 2 minutos.", "Susúrrame al oído 3 cosas que te gustan de mí.", "Imita cómo hablo o actúo."]

    var body: some View {
        let prompt = docData["selectedPrompt"] as? String ?? "Toca un botón para empezar"
        let category = docData["selectedCategory"] as? String ?? "Divertido"
        let selectedType = docData["selectedType"] as? String ?? ""
        let photoUrl = docData["photoProofUrl"] as? String ?? ""
        let photoStatus = docData["photoStatus"] as? String ?? ""
        let challenger = docData["challenger"] as? String ?? ""
        let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
        let isChallenger = myName == challenger
        let theme = ThemeManager.shared

        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    ForEach(categories, id: \.self) { cat in
                        Button(cat) { update(["selectedCategory": cat]) }
                            .buttonStyle(.bordered)
                            .tint(category == cat ? theme.primary : .gray)
                            .controlSize(.small)
                    }
                }

                GlassCard(cornerRadius: 16) {
                    Text(prompt)
                        .appFont(size: 15).italic()
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 16) {
                    Button("Verdad") {
                        isGenerating = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            update(["selectedPrompt": truths.randomElement()!, "selectedType": "Verdad", "challenger": myName, "photoProofUrl": "", "photoStatus": ""])
                            isGenerating = false
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(Color(red: 0.49, green: 0.51, blue: 1))
                    Button("Reto") {
                        isGenerating = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            update(["selectedPrompt": dares.randomElement()!, "selectedType": "Reto", "challenger": myName, "photoProofUrl": "", "photoStatus": ""])
                            isGenerating = false
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(Color(red: 1, green: 0.36, blue: 0.54))
                }

                if selectedType == "Reto" && prompt != "Toca un botón para empezar" {
                    Divider()
                    Text("Prueba del Reto").appFont(size: 14, weight: .bold).foregroundColor(theme.primary)
                    if photoUrl.isEmpty {
                        if isChallenger {
                            Button("Subir Foto de Prueba 📸") {
                                let picker = UIImagePickerController()
                                picker.sourceType = .camera
                                // TODO: handle photo upload
                            }
                        } else {
                            Text("Esperando que tu pareja suba la foto del reto...").appFont(size: 12).italic().foregroundColor(.secondary)
                        }
                    } else {
                        Text("Foto subida por \(challenger)").appFont(size: 12)
                        if photoStatus == "pending" {
                            if !isChallenger {
                                HStack {
                                    Button("Aprobar") { update(["photoStatus": "approved"]) }.tint(.green).buttonStyle(.borderedProminent)
                                    Button("Rechazar") { update(["photoStatus": "rejected"]) }.tint(.red).buttonStyle(.borderedProminent)
                                }
                            } else {
                                Text("Esperando aprobación...").appFont(size: 12).foregroundColor(.secondary)
                            }
                        } else if photoStatus == "approved" {
                            Label("¡Reto Completado! 🎉", systemImage: "checkmark.circle.fill").foregroundColor(.green)
                        } else if photoStatus == "rejected" {
                            Text("Reto Rechazado").foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Online Tic-Tac-Toe

private struct OnlineTTTView: View {
    let gameId: String
    @Binding var docData: [String: Any]
    let update: ([String: Any]) -> Void

    var body: some View {
        let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
        let partnerName = CoupleService.shared.partnerName
        let sender = docData["sender"] as? String ?? ""
        let receiver = docData["receiver"] as? String ?? ""
        let isSender = myName == sender
        let mySymbol = isSender ? "X" : "O"
        let partnerSymbol = isSender ? "O" : "X"
        let rawBoard = docData["board"] as? [String] ?? Array(repeating: "", count: 9)
        let board = rawBoard.count == 9 ? rawBoard : Array(repeating: "", count: 9)
        let turn = docData["turn"] as? String ?? sender
        let winner = docData["winner"] as? String ?? ""
        let isMyTurn = turn == myName
        let theme = ThemeManager.shared

        VStack(spacing: 16) {
            Text(winner.isEmpty ? (isMyTurn ? "🌟 ¡Tu Turno! (\(mySymbol))" : "Esperando a \(partnerName) (\(partnerSymbol))...") : (winner == "Empate" ? "¡Empate!" : "¡Ganador: \(winner)! 🎉"))
                .appFont(size: 16, weight: .semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 0) {
                ForEach(0..<9, id: \.self) { i in
                    Button {
                        if !isMyTurn || !board[i].isEmpty || !winner.isEmpty { return }
                        var newBoard = board
                        newBoard[i] = mySymbol
                        var nextWinner = ""
                        if tttWinner(newBoard, mySymbol) { nextWinner = myName }
                        else if !newBoard.contains("") { nextWinner = "Empate" }
                        update(["board": newBoard, "turn": isSender ? receiver : sender, "winner": nextWinner])
                    } label: {
                        Text(board[i])
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(board[i] == "X" ? Color(red: 1, green: 0.36, blue: 0.54) : Color(red: 0.65, green: 0.55, blue: 0.98))
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .overlay(Rectangle().stroke(theme.primary.opacity(0.2)))
                    }
                }
            }
            .frame(width: 240)

            if !winner.isEmpty {
                Button("Reiniciar Partida") { update(["board": Array(repeating: "", count: 9), "turn": sender, "winner": ""]) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }

    private func tttWinner(_ b: [String], _ p: String) -> Bool {
        (b[0]==p&&b[1]==p&&b[2]==p) || (b[3]==p&&b[4]==p&&b[5]==p) || (b[6]==p&&b[7]==p&&b[8]==p) || (b[0]==p&&b[3]==p&&b[6]==p) || (b[1]==p&&b[4]==p&&b[7]==p) || (b[2]==p&&b[5]==p&&b[8]==p) || (b[0]==p&&b[4]==p&&b[8]==p) || (b[2]==p&&b[4]==p&&b[6]==p)
    }
}

// MARK: - Online RPS

private struct OnlineRPSView: View {
    let gameId: String
    @Binding var docData: [String: Any]
    let update: ([String: Any]) -> Void

    var body: some View {
        let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
        let partnerName = CoupleService.shared.partnerName
        let sender = docData["sender"] as? String ?? ""
        let isSender = myName == sender
        let myField = isSender ? "senderChoice" : "receiverChoice"
        let partnerField = isSender ? "receiverChoice" : "senderChoice"
        let myChoice = docData[myField] as? String ?? ""
        let partnerChoice = docData[partnerField] as? String ?? ""
        let bothChosen = !myChoice.isEmpty && !partnerChoice.isEmpty

        let choices = ["Piedra", "Papel", "Tijera"]
        let icons = ["Piedra": "circle", "Papel": "doc.text", "Tijera": "scissors"]
        let theme = ThemeManager.shared

        var result: String {
            if myChoice.isEmpty { return "Elige tu jugada" }
            if partnerChoice.isEmpty { return "Esperando a \(partnerName)..." }
            if myChoice == partnerChoice { return "¡Empate!" }
            if (myChoice=="Piedra"&&partnerChoice=="Tijera")||(myChoice=="Papel"&&partnerChoice=="Piedra")||(myChoice=="Tijera"&&partnerChoice=="Papel") { return "¡Ganaste! 🎉" }
            return "Perdiste 😢"
        }

        return VStack(spacing: 20) {
            Text(result).appFont(size: 20, weight: .bold).foregroundColor(theme.primary)
            if bothChosen {
                Text("Tú: \(myChoice)  vs  \(partnerName): \(partnerChoice)").appFont(size: 15)
            }
            if myChoice.isEmpty {
                HStack(spacing: 20) {
                    ForEach(choices, id: \.self) { c in
                        Button {
                            update([myField: c])
                            if !partnerChoice.isEmpty {
                                update([myField: c, partnerField: ""])
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: icons[c]!).font(.system(size: 36)).foregroundColor(theme.primary)
                                Text(c).appFont(size: 12)
                            }
                            .padding(16)
                            .background(theme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            } else if !bothChosen {
                ProgressView()
            }
            if bothChosen {
                Button("Jugar de nuevo") { update(["senderChoice": "", "receiverChoice": ""]) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
    }
}

// MARK: - Online Memorama

private struct OnlineMemoramaView: View {
    let gameId: String
    @Binding var docData: [String: Any]
    let update: ([String: Any]) -> Void
    @State private var flips = Array(repeating: false, count: 12)
    @State private var selected: [Int] = []
    @State private var matches = 0
    @State private var moves = 0
    @State private var finished = false

    private let items: [String] = {
        let base = ["❤️", "💍", "🌸", "🍫", "🧸", "🍷"]
        var all = base + base
        all.shuffle()
        return all
    }()

    var body: some View {
        let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
        let sender = docData["sender"] as? String ?? ""
        let isSender = myName == sender
        let myField = isSender ? "senderMoves" : "receiverMoves"
        let partnerField = isSender ? "receiverMoves" : "senderMoves"
        let myFinal = docData[myField] as? Int
        let partnerFinal = docData[partnerField] as? Int
        let partnerName = CoupleService.shared.partnerName

        ScrollView {
            VStack(spacing: 16) {
                if let _ = myFinal {
                    Image(systemName: "trophy.fill").font(.system(size: 56)).foregroundColor(.yellow)
                    Text("Tus movimientos: \(moves)").appFont(size: 18, weight: .bold)
                    Text(partnerFinal != nil ? "Movimientos de \(partnerName): \(partnerFinal!)" : "Esperando a que \(partnerName) termine...")
                        .appFont(size: 14).foregroundColor(.secondary)
                    if let pf = partnerFinal {
                        Text(moves == pf ? "¡Empate de velocidad! 🧠" : (moves < pf ? "¡Ganaste! 🌟" : "¡\(partnerName) ganó! 🌟"))
                            .appFont(size: 16, weight: .bold).foregroundColor(.green)
                    }
                } else {
                    Text("Movimientos: \(moves)").appFont(size: 14, weight: .bold)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(0..<12, id: \.self) { i in
                            Button {
                                if flips[i] || selected.count >= 2 { return }
                                flips[i] = true; selected.append(i)
                                if selected.count == 2 {
                                    moves += 1
                                    let a = selected[0], b = selected[1]
                                    if items[a] == items[b] { matches += 1; selected.removeAll()
                                        if matches == 6 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { update([myField: moves]); finished = true } }
                                    } else { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { flips[a] = false; flips[b] = false; selected.removeAll() } }
                                }
                            } label: {
                                Text(flips[i] ? items[i] : "?").font(.system(size: 28))
                                    .foregroundColor(flips[i] ? ThemeManager.shared.textPrimary : .white)
                                    .frame(maxWidth: .infinity, minHeight: 70)
                                    .background(flips[i] ? ThemeManager.shared.primary.opacity(0.1) : ThemeManager.shared.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Online Hangman

private struct OnlineHangmanView: View {
    let gameId: String
    @Binding var docData: [String: Any]
    let update: ([String: Any]) -> Void

    private let words = ["TEAMO", "ANIVERSARIO", "COMPROMISO", "ABRAZO", "DULCE", "SIEMPRE"]

    var body: some View {
        let secret = docData["secretWord"] as? String ?? ""
        let guessed = docData["guessedLetters"] as? [String] ?? []
        let wrong = docData["wrongCount"] as? Int ?? 0
        let display = secret.map { guessed.contains(String($0)) ? "\($0) " : "_ " }.joined()
        let won = !display.contains("_")
        let lost = wrong >= 6
        let theme = ThemeManager.shared

        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    ForEach(0..<6, id: \.self) { i in
                        Image(systemName: i < 6 - wrong ? "heart.fill" : "heart").foregroundColor(Color(red: 1, green: 0.36, blue: 0.54)).font(.system(size: 22))
                    }
                }

                Text(display).appFont(size: 26, weight: .bold).tracking(6)

                if won {
                    Text("¡Salvaron la palabra! 🎉").foregroundColor(.green).appFont(size: 16, weight: .bold)
                    Button("Jugar otra palabra") { update(["secretWord": words.randomElement()!, "guessedLetters": [String](), "wrongCount": 0]) }
                        .buttonStyle(.borderedProminent)
                } else if lost {
                    Text("Era: \(secret) 😢").foregroundColor(.red).appFont(size: 16, weight: .bold)
                    Button("Intentar de nuevo") { update(["secretWord": words.randomElement()!, "guessedLetters": [String](), "wrongCount": 0]) }
                        .buttonStyle(.borderedProminent)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                        ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init), id: \.self) { letter in
                            let used = guessed.contains(letter)
                            Button(letter) {
                                if used || won || lost { return }
                                var newGuessed = guessed; newGuessed.append(letter)
                                let isCorrect = secret.contains(letter)
                                update(["guessedLetters": newGuessed, "wrongCount": isCorrect ? wrong : wrong + 1])
                            }
                            .buttonStyle(.bordered)
                            .tint(used ? .gray : theme.primary)
                            .disabled(used)
                            .controlSize(.small)
                        }
                    }
                }

                if won || lost {
                    let myName = AuthService.shared.currentUser?.displayName ?? "Yo"
                    let sender = docData["sender"] as? String ?? ""
                    let isSender = myName == sender
                    let myField = isSender ? "senderScore" : "receiverScore"
                    let partnerField = isSender ? "receiverScore" : "senderScore"
                    let myFinal = docData[myField] as? Int
                    let partnerFinal = docData[partnerField] as? Int

                    if myFinal == nil && won {
                        Button("Marcar como completado") { update([myField: 1]) }
                            .buttonStyle(.borderedProminent).tint(.green)
                    }
                    if let mf = myFinal {
                        Text("Completado ✓").foregroundColor(.green)
                        if let pf = partnerFinal {
                            Text("Ambos completaron la palabra 🎉")
                        } else {
                            Text("Esperando a tu pareja...").foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            if secret.isEmpty {
                update(["secretWord": words.randomElement()!, "guessedLetters": [String](), "wrongCount": 0])
            }
        }
    }
}

// MARK: - Local Game View

private struct LocalGameView: View {
    let gameType: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                localGameContent
            }
            .navigationTitle(localTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
        }
    }

    private var localTitle: String {
        switch gameType {
        case "quiz": return "Quiz"
        case "truth_dare": return "Verdad o Reto"
        case "memorama": return "Memorama"
        case "tictactoe": return "Tres en Raya"
        case "rps": return "Piedra Papel Tijera"
        case "hangman": return "Ahorcado"
        case "dice": return "Dados del Amor"
        case "cards": return "Carta Mayor"
        case "prefer": return "¿Qué Prefieres?"
        case "roulette": return "Ruleta del Amor"
        case "never": return "Yo Nunca Nunca"
        case "picante": return "Picante"
        default: return gameType
        }
    }

    @ViewBuilder
    private var localGameContent: some View {
        switch gameType {
        case "quiz": LocalQuizView()
        case "truth_dare": LocalTruthDareView()
        case "memorama": LocalMemoramaView()
        case "tictactoe": LocalTTTView()
        case "rps": LocalRPSView()
        case "hangman": LocalHangmanView()
        case "dice": LoveDiceView()
        case "cards": HigherCardView()
        case "prefer": WouldYouRatherView()
        case "roulette": LoveRouletteView()
        case "never": NeverHaveIEverView()
        case "picante": SpicyGamesView()
        default: Text("Coming Soon")
        }
    }
}

// MARK: - Local Quiz

private struct LocalQuizView: View {
    @State private var q = 0; @State private var score = 0; @State private var showResult = false

    private let questions: [[String: Any]] = [
        ["q": "¿Dónde fue nuestra primera cita oficial?", "o": ["Restaurante italiano", "El cine", "Un café acogedor", "Un parque"], "a": 2],
        ["q": "¿Quién dijo \"te amo\" primero?", "o": ["Yo", "Mi pareja", "Ambos", "Nadie"], "a": 0],
        ["q": "¿Cuál es nuestra comida favorita?", "o": ["Pizza", "Sushi", "Hamburguesas", "Tacos"], "a": 0],
        ["q": "¿Qué hacemos en un día lluvioso?", "o": ["Ver películas", "Dormir", "Cocinar", "Juegos"], "a": 0],
    ]

    var body: some View {
        if showResult { resultView }
        else { quizContent }
    }

    private var quizContent: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(q + 1) / Double(questions.count))
            Text("Pregunta \(q + 1) de \(questions.count)").appFont(size: 12).foregroundColor(.secondary)
            Text(questions[q]["q"] as? String ?? "").appFont(size: 17, weight: .semibold).multilineTextAlignment(.center)
            ForEach(Array((questions[q]["o"] as? [String] ?? []).enumerated()), id: \.offset) { i, opt in
                Button {
                    if i == (questions[q]["a"] as? Int ?? -1) { score += 1 }
                    if q < questions.count - 1 { q += 1 } else { showResult = true }
                } label: {
                    Text(opt).appFont(size: 14).foregroundColor(ThemeManager.shared.textPrimary).frame(maxWidth: .infinity).padding(14).overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeManager.shared.primary.opacity(0.3)))
                }
            }
        }.padding(20)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: score == questions.count ? "trophy.fill" : "heart.fill").font(.system(size: 56)).foregroundColor(score == questions.count ? .yellow : ThemeManager.shared.primary)
            Text("\(score) / \(questions.count)").appFont(size: 28, weight: .bold)
            Text(score == questions.count ? "¡Perfecto! Conoces a tu pareja!" : "Sigue intentando!").appFont(size: 14).foregroundColor(.secondary)
            Button("Cerrar") { if let t = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first { var v = t; while let p = v.presentedViewController { v = p }; v.dismiss(animated: true) } }
                .buttonStyle(.borderedProminent)
        }.padding(20)
    }
}

// MARK: - Local Truth or Dare

private struct LocalTruthDareView: View {
    @State private var prompt = "Toca un botón para empezar"

    private let truths = ["¿Qué fue lo primero que te atrajo de mí?", "¿Cuál ha sido el momento más conectado que has sentido?", "Si pudieras cambiar un hábito mío, ¿cuál sería?", "¿Qué canción te recuerda a nosotros?", "¿Cuál ha sido la mentira más piadosa que me has dicho?"]
    private let dares = ["Dame un beso de 10 segundos.", "Cántame una canción de amor mirándome a los ojos.", "Hazme un masaje de hombros por 2 minutos.", "Susúrrame al oído 3 cosas que te gustan de mí.", "Imita cómo hablo o actúo."]

    var body: some View {
        VStack(spacing: 20) {
            GlassCard(cornerRadius: 16) {
                Text(prompt).appFont(size: 15).italic().multilineTextAlignment(.center).padding(20)
            }
            HStack(spacing: 16) {
                Button("Verdad") { prompt = truths.randomElement()! }.buttonStyle(.borderedProminent).tint(Color(red: 0.49, green: 0.51, blue: 1))
                Button("Reto") { prompt = dares.randomElement()! }.buttonStyle(.borderedProminent).tint(Color(red: 1, green: 0.36, blue: 0.54))
            }
        }.padding(20)
    }
}

// MARK: - Local Memorama

private struct LocalMemoramaView: View {
    @State private var flips = Array(repeating: false, count: 12)
    @State private var selected: [Int] = []
    @State private var matches = 0

    private let items: [String] = {
        var a = ["❤️", "💍", "🌸", "🍫", "🧸", "🍷"]; var b = a + a; b.shuffle(); return b
    }()

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(0..<12, id: \.self) { i in
                Button {
                    if flips[i] || selected.count >= 2 { return }
                    flips[i] = true; selected.append(i)
                    if selected.count == 2 {
                        let a = selected[0], b = selected[1]
                        if items[a] == items[b] { matches += 1; selected.removeAll()
                            if matches == 6 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if let t = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first { var v = t; while let p = v.presentedViewController { v = p }; let alert = UIAlertController(title: "🎉", message: "¡Memorama completado!", preferredStyle: .alert); alert.addAction(UIAlertAction(title: "🥳", style: .default)); v.present(alert, animated: true) }
                            } }
                        } else { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { flips[a] = false; flips[b] = false; selected.removeAll() } }
                    }
                } label: {
                    Text(flips[i] ? items[i] : "?").font(.system(size: 28))
                        .foregroundColor(flips[i] ? ThemeManager.shared.textPrimary : .white)
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(flips[i] ? ThemeManager.shared.primary.opacity(0.1) : ThemeManager.shared.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }.padding(16)
    }
}

// MARK: - Local Tic-Tac-Toe

private struct LocalTTTView: View {
    @State private var board = Array(repeating: "", count: 9)
    @State private var turn = "X"
    @State private var winner = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(winner.isEmpty ? "Turno de \(turn)" : "Ganador: \(winner)").appFont(size: 16, weight: .semibold)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 0) {
                ForEach(0..<9, id: \.self) { i in
                    Button {
                        if !board[i].isEmpty || !winner.isEmpty { return }
                        board[i] = turn
                        if tttWinner(board, turn) { winner = turn }
                        else if !board.contains("") { winner = "Empate" }
                        else { turn = turn == "X" ? "O" : "X" }
                    } label: {
                        Text(board[i]).font(.system(size: 36, weight: .bold))
                            .foregroundColor(board[i] == "X" ? Color(red: 1, green: 0.36, blue: 0.54) : Color(red: 0.65, green: 0.55, blue: 0.98))
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .overlay(Rectangle().stroke(ThemeManager.shared.primary.opacity(0.2)))
                    }
                }
            }.frame(width: 240)
            if !winner.isEmpty { Button("Reiniciar") { board = Array(repeating: "", count: 9); turn = "X"; winner = "" }.buttonStyle(.borderedProminent) }
        }.padding(20)
    }

    private func tttWinner(_ b: [String], _ p: String) -> Bool {
        (b[0]==p&&b[1]==p&&b[2]==p) || (b[3]==p&&b[4]==p&&b[5]==p) || (b[6]==p&&b[7]==p&&b[8]==p) || (b[0]==p&&b[3]==p&&b[6]==p) || (b[1]==p&&b[4]==p&&b[7]==p) || (b[2]==p&&b[5]==p&&b[8]==p) || (b[0]==p&&b[4]==p&&b[8]==p) || (b[2]==p&&b[4]==p&&b[6]==p)
    }
}

// MARK: - Local RPS

private struct LocalRPSView: View {
    @State private var player = ""; @State private var ai = ""; @State private var result = "Elige"
    private let choices = ["Piedra", "Papel", "Tijera"]
    private let icons = ["Piedra": "circle", "Papel": "doc.text", "Tijera": "scissors"]

    var body: some View {
        VStack(spacing: 20) {
            Text(result).appFont(size: 20, weight: .bold).foregroundColor(ThemeManager.shared.primary)
            if !player.isEmpty { Text("Tú: \(player)  vs  Pareja: \(ai)").appFont(size: 15) }
            HStack(spacing: 20) {
                ForEach(choices, id: \.self) { c in
                    Button {
                        let a = choices.randomElement()!; player = c; ai = a
                        if c == a { result = "¡Empate!" }
                        else if (c=="Piedra"&&a=="Tijera")||(c=="Papel"&&a=="Piedra")||(c=="Tijera"&&a=="Papel") { result = "¡Ganaste!" }
                        else { result = "Perdiste" }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: icons[c]!).font(.system(size: 36)).foregroundColor(ThemeManager.shared.primary)
                            Text(c).appFont(size: 12)
                        }.padding(16).background(ThemeManager.shared.primary.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }.padding(20)
    }
}

// MARK: - Local Hangman

private struct LocalHangmanView: View {
    @State private var guessed: [String] = []; @State private var wrong = 0
    private let words = ["TEAMO", "ANIVERSARIO", "COMPROMISO", "ABRAZO", "DULCE", "SIEMPRE"]
    @State private var secret = ""

    var body: some View {
        let display = secret.map { guessed.contains(String($0)) ? "\($0) " : "_ " }.joined()
        let won = !display.contains("_"); let lost = wrong >= 6

        VStack(spacing: 16) {
            HStack {
                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: i < 6-wrong ? "heart.fill" : "heart").foregroundColor(Color(red: 1, green: 0.36, blue: 0.54)).font(.system(size: 22))
                }
            }
            Text(display).appFont(size: 26, weight: .bold).tracking(6)
            if won { Text("¡Salvaste la palabra! 🎉").foregroundColor(.green).appFont(size: 16, weight: .bold) }
            else if lost { Text("Era: \(secret) 😢").foregroundColor(.red).appFont(size: 16, weight: .bold) }
            else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                    ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init), id: \.self) { letter in
                        Button(letter) {
                            if guessed.contains(letter) || won || lost { return }
                            guessed.append(letter)
                            if !secret.contains(letter) { wrong += 1 }
                        }.buttonStyle(.bordered).tint(guessed.contains(letter) ? .gray : ThemeManager.shared.primary).disabled(guessed.contains(letter)).controlSize(.small)
                    }
                }
            }
            if won || lost {
                Button(won ? "Jugar otra palabra" : "Intentar de nuevo") {
                    secret = words.randomElement()!; guessed = []; wrong = 0
                }.buttonStyle(.borderedProminent)
            }
        }.padding(20).onAppear { secret = words.randomElement()! }
    }
}

// MARK: - Love Dice

private struct LoveDiceView: View {
    @State private var action = "Toca para lanzar"
    @State private var bodyPart = ""

    private let actions = ["Besar", "Abrazar", "Acariciar", "Morder", "Masajear", "Hacer cosquillas"]
    private let parts = ["Labios", "Cuello", "Manos", "Hombros", "Espalda", "Cabello"]

    var body: some View {
        VStack(spacing: 24) {
            GlassCard(cornerRadius: 20) {
                VStack(spacing: 16) {
                    Text("🎲").font(.system(size: 64))
                    if !action.contains("lanzar") {
                        Text(action).appFont(size: 22, weight: .bold).foregroundColor(Color(red: 1, green: 0.36, blue: 0.54))
                        Text(bodyPart).appFont(size: 18).foregroundColor(.secondary)
                    } else {
                        Text(action).appFont(size: 16).foregroundColor(.secondary)
                    }
                }.padding(30)
            }
            Button("Lanzar Dados 🎲") {
                action = actions.randomElement()!; bodyPart = parts.randomElement()!
            }.buttonStyle(.borderedProminent).tint(Color(red: 0.93, green: 0.28, blue: 0.6))
        }.padding(20)
    }
}

// MARK: - Higher Card

private struct HigherCardView: View {
    @State private var myCard = ""; @State private var partnerCard = ""; @State private var result = "Toca para robar"
    @State private var showResult = false

    private let suits = ["♠️", "♥️", "♣️", "♦️"]
    private let ranks = ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]
    private let values: [String: Int] = ["2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9,"10":10,"J":11,"Q":12,"K":13,"A":14]

    var body: some View {
        VStack(spacing: 20) {
            Text(result).appFont(size: 20, weight: .bold).foregroundColor(ThemeManager.shared.primary)
            if showResult {
                HStack(spacing: 40) {
                    VStack { Text(myCard).font(.system(size: 48)); Text("Tú").appFont(size: 12) }
                    Text("vs").appFont(size: 18).foregroundColor(.secondary)
                    VStack { Text(partnerCard).font(.system(size: 48)); Text("Pareja").appFont(size: 12) }
                }
            }
            Button("Robar Carta 🃏") {
                myCard = "\(ranks.randomElement()!)\(suits.randomElement()!)"
                partnerCard = "\(ranks.randomElement()!)\(suits.randomElement()!)"
                showResult = true
                let mv = values[String(myCard.dropLast())] ?? 0
                let pv = values[String(partnerCard.dropLast())] ?? 0
                if mv > pv { result = "¡Ganaste! 🎉" }
                else if mv < pv { result = "Perdiste 😢" }
                else { result = "¡Empate!" }
            }.buttonStyle(.borderedProminent).tint(Color(red: 0.55, green: 0.35, blue: 0.96))
        }.padding(20)
    }
}

// MARK: - Would You Rather

private struct WouldYouRatherView: View {
    @State private var q = 0; @State private var answers: [String] = []; @State private var showResult = false

    private let questions = [
        ("¿Prefieres una cena romántica o una aventura? ❤️", "Cena romántica 🍝", "Aventura emocionante 🎢"),
        ("¿Película en casa o salir al cine? 🎬", "Película en casa 🏠", "Salir al cine 🎥"),
        ("¿Viaje a la playa o a la montaña? 🌴", "Playa 🌊", "Montaña ⛰️"),
        ("¿Desayuno en la cama o sorpresa? ☕", "Desayuno 🥐", "Sorpresa 🎁"),
        ("¿Mensaje dulce o llamada inesperada? 💌", "Mensaje 💬", "Llamada 📞"),
        ("¿Bailar juntos o cantar juntos? 🎵", "Bailar 💃", "Cantar 🎤"),
    ]

    var body: some View {
        if showResult { resultView }
        else { questionView }
    }

    private var questionView: some View {
        VStack(spacing: 20) {
            Text("Pregunta \(q + 1) de \(questions.count)").appFont(size: 12).foregroundColor(.secondary)
            Text(questions[q].0).appFont(size: 17, weight: .semibold).multilineTextAlignment(.center).padding(.horizontal)
            Button(questions[q].1) { answer(questions[q].1) }.buttonStyle(.borderedProminent).tint(Color(red: 0.23, green: 0.51, blue: 0.96))
            Button(questions[q].2) { answer(questions[q].2) }.buttonStyle(.borderedProminent).tint(Color(red: 0.02, green: 0.71, blue: 0.83))
        }.padding(20)
    }

    private func answer(_ a: String) {
        answers.append(a)
        if q < questions.count - 1 { q += 1 }
        else { showResult = true }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Text("¡Completaron el quiz! 🎉").appFont(size: 20, weight: .bold)
            Text("Ahora comparen sus respuestas").appFont(size: 14).foregroundColor(.secondary)
            Button("Cerrar") {
                if let t = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first { var v = t; while let p = v.presentedViewController { v = p }; v.dismiss(animated: true) }
            }.buttonStyle(.borderedProminent)
        }.padding(20)
    }
}

// MARK: - Love Roulette

private struct LoveRouletteView: View {
    @State private var spinning = false; @State private var result = "Gira la ruleta 🎡"
    @State private var angle: Double = 0

    private let options = ["💋 Beso", "❤️ Te Amo", "💃 Baila", "🎤 Canta", "😂 Cuenta un chiste", "🤗 Abrazo"]

    var body: some View {
        VStack(spacing: 24) {
            Text("Ruleta del Amor").appFont(size: 20, weight: .bold)
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    let startAngle = Angle.degrees(Double(i) * 60)
                    let endAngle = Angle.degrees(Double(i + 1) * 60)
                    PieShape(startAngle: startAngle, endAngle: endAngle)
                        .fill(Color(hue: Double(i) / 6, saturation: 0.5, brightness: 0.9))
                }
                Circle().fill(Color.white).frame(width: 40, height: 40)
                Image(systemName: "heart.fill").foregroundColor(ThemeManager.shared.primary)
            }
            .frame(width: 200, height: 200)
            .rotationEffect(.degrees(angle))
            .animation(.easeOut(duration: 2), value: angle)

            Text(result == "Gira la ruleta 🎡" ? result : "\(result)").appFont(size: 18).foregroundColor(ThemeManager.shared.primary)

            Button(result.contains("Gira") ? "¡Girar! 🎡" : "Girar de nuevo") {
                spinning = true; angle += 720 + Double.random(in: 0...360)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    let idx = Int.random(in: 0..<6); result = options[idx]
                }
            }.buttonStyle(.borderedProminent).tint(Color(red: 0.06, green: 0.73, blue: 0.51))
                .disabled(spinning)
        }.padding(20)
    }
}

private struct PieShape: Shape {
    let startAngle: Angle; let endAngle: Angle
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Never Have I Ever

private struct NeverHaveIEverView: View {
    @State private var q = 0; @State private var showResult = false

    private let statements = [
        "Nunca he mentido para quedar bien contigo",
        "Nunca he revisado tu teléfono",
        "Nunca he fingido estar de acuerdo solo para evitarte un disgusto",
        "Nunca he comparado nuestra relación con la de otros",
        "Nunca he guardado silencio cuando debería haber hablado",
        "Nunca he preferido estar solo a estar contigo",
        "Nunca he olvidado una fecha importante para nosotros",
        "Nunca he dicho 'estoy bien' cuando no lo estaba",
        "Nunca he pensado en alguien más estando contigo",
        "Nunca he dejado de decir 'te amo' por costumbre",
    ]

    var body: some View {
        if showResult { resultView }
        else { statementView }
    }

    private var statementView: some View {
        VStack(spacing: 20) {
            Text("\(q + 1) de \(statements.count)").appFont(size: 12).foregroundColor(.secondary)
            Text(statements[q]).appFont(size: 18, weight: .semibold).multilineTextAlignment(.center).padding()
            HStack(spacing: 20) {
                Button("Nunca 🤥") {
                    if q < statements.count - 1 { q += 1 } else { showResult = true }
                }.buttonStyle(.borderedProminent).tint(Color(red: 0.96, green: 0.62, blue: 0.04))
                Button("Sí, una vez 🫣") {
                    if q < statements.count - 1 { q += 1 } else { showResult = true }
                }.buttonStyle(.borderedProminent).tint(Color(red: 0.98, green: 0.73, blue: 0.14))
            }
        }.padding(20)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Text("🍷").font(.system(size: 64))
            Text("¡Completaron el juego!").appFont(size: 20, weight: .bold)
            Text("Ahora compartan sus historias").appFont(size: 14).foregroundColor(.secondary)
            Button("Cerrar") { if let t = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first { var v = t; while let p = v.presentedViewController { v = p }; v.dismiss(animated: true) } }
                .buttonStyle(.borderedProminent)
        }.padding(20)
    }
}

// MARK: - Spicy Games

private struct SpicyGamesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill").font(.system(size: 48)).foregroundColor(Color(red: 1, green: 0.36, blue: 0.54))
            Text("Zona Picante 🔥").appFont(size: 20, weight: .bold)
            Text("Próximamente disponible").appFont(size: 14).foregroundColor(.secondary)
        }.padding(20)
    }
}
