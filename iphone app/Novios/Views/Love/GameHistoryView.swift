import SwiftUI
import FirebaseFirestore

public struct GameHistoryView: View {
    @ObservedObject private var couple = CoupleService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var games: [[String: Any]] = []
    @State private var snapshotListener: ListenerRegistration?
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    private let db = Firestore.firestore()

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var gamesRef: CollectionReference {
        db.collection("couples").document(coupleId).collection("games")
    }

    private let myName: String = {
        let isDiego = AuthService.shared.currentUser?.id == CoupleService.diegoUid
        return isDiego ? "Diego" : "Yosmari"
    }()

    private let partnerName: String = {
        let isDiego = AuthService.shared.currentUser?.id == CoupleService.diegoUid
        return isDiego ? "Yosmari" : "Diego"
    }()

    private let myUid: String = AuthService.shared.currentUser?.id ?? ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackgroundView()
                if games.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        Picker("", selection: $selectedTab) {
                            Text("Estadísticas").tag(0)
                            Text("Partidas").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        if selectedTab == 0 {
                            statsTab
                        } else {
                            historyTab
                        }
                    }
                }
            }
            .navigationTitle("Historial y Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { dismiss() } } }
            .onAppear { startListening() }
            .onDisappear { stopListening() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller.fill").font(.system(size: 64)).foregroundColor(theme.primary.opacity(0.3))
            Text("No hay partidas registradas aún").appFont(size: 18, weight: .medium).foregroundColor(.secondary)
            Text("¡Empiecen a jugar para ver el historial!").appFont(size: 14).foregroundColor(.secondary.opacity(0.6))
        }
    }

    // MARK: - Stats Tab

    private var statsTab: some View {
        let computed = computeStats()
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                vsHeader(myWins: computed.myTotalWins, partnerWins: computed.partnerTotalWins, ties: computed.totalTies, total: computed.totalGamesCount)

                Text("Rendimiento por Juego").appFont(size: 18, weight: .bold).frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    gameStatCard(title: "Tres en Raya", type: "tictactoe", myWins: computed.ttt.myWins, partnerWins: computed.ttt.partnerWins, ties: computed.ttt.ties, active: computed.ttt.active)
                    gameStatCard(title: "Quiz", type: "quiz", myWins: computed.quiz.myWins, partnerWins: computed.quiz.partnerWins, ties: computed.quiz.ties, active: computed.quiz.active)
                    gameStatCard(title: "Memorama", type: "memorama", myWins: computed.mem.myWins, partnerWins: computed.mem.partnerWins, ties: computed.mem.ties, active: computed.mem.active)
                    gameStatCard(title: "Piedra Papel Tijera", type: "rps", myWins: computed.rps.myWins, partnerWins: computed.rps.partnerWins, ties: computed.rps.ties, active: computed.rps.active)
                }

                coopStatCard(wins: computed.hangman.coopWins, losses: computed.hangman.coopLosses, active: computed.hangman.active)
                truthDareStatCard(myTruths: computed.td.myTruths, partnerTruths: computed.td.partnerTruths, myDares: computed.td.myDares, partnerDares: computed.td.partnerDares)
            }
            .padding(16)
        }
    }

    private func vsHeader(myWins: Int, partnerWins: Int, ties: Int, total: Int) -> some View {
        let totalWins = myWins + partnerWins
        let myPct = totalWins > 0 ? CGFloat(myWins) / CGFloat(totalWins) : 0.5
        let partnerPct = totalWins > 0 ? CGFloat(partnerWins) / CGFloat(totalWins) : 0.5

        return GlassCard(cornerRadius: 24) {
            VStack(spacing: 16) {
                Text("BALANCE GENERAL DE VICTORIAS").appFont(size: 11, weight: .black).foregroundColor(.white.opacity(0.8)).tracking(1.2)
                HStack {
                    VStack(alignment: .leading) {
                        Text(myName).appFont(size: 18, weight: .bold).foregroundColor(.white)
                        Text("\(myWins) Victorias").appFont(size: 14).foregroundColor(.white.opacity(0.9))
                    }
                    Spacer()
                    Text("VS").appFont(size: 24, weight: .black).foregroundColor(.yellow)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(partnerName).appFont(size: 18, weight: .bold).foregroundColor(.white)
                        Text("\(partnerWins) Victorias").appFont(size: 14).foregroundColor(.white.opacity(0.9))
                    }
                }
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Color.white.frame(width: max(geo.size.width * myPct, totalWins == 0 ? geo.size.width * 0.5 : 0))
                        Color.yellow.frame(width: max(geo.size.width * partnerPct, totalWins == 0 ? geo.size.width * 0.5 : 0))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(height: 10)
                }.frame(height: 10)
                HStack {
                    Text("Total Partidas: \(total)").appFont(size: 11).foregroundColor(.white.opacity(0.7))
                    Text("Empates: \(ties)").appFont(size: 11).foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .background(LinearGradient(colors: [theme.primary.opacity(0.85), theme.secondary.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func gameStatCard(title: String, type: String, myWins: Int, partnerWins: Int, ties: Int, active: Int) -> some View {
        let total = myWins + partnerWins + ties
        let colors = gameColors(type)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: gameIcon(type)).font(.system(size: 14)).foregroundColor(.white).padding(6).background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 8))
                Text(title).appFont(size: 13, weight: .bold).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 2) {
                Text("Tú: \(myWins) victorias").appFont(size: 12, weight: .semibold).foregroundColor(theme.primary)
                Text("\(partnerName): \(partnerWins) victorias").appFont(size: 12, weight: .semibold).foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.96))
                Text("Empates: \(ties)").appFont(size: 11).foregroundColor(.secondary)
            }
            Spacer()
            HStack {
                Text("Total: \(total)").appFont(size: 10, weight: .bold).foregroundColor(.secondary.opacity(0.6))
                if active > 0 {
                    Text("\(active) activos").appFont(size: 9, weight: .bold).foregroundColor(theme.primary).padding(.horizontal, 6).padding(.vertical, 2).background(theme.primary.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1)))
    }

    private func coopStatCard(wins: Int, losses: Int, active: Int) -> some View {
        let total = wins + losses
        let rate = total > 0 ? "\(wins * 100 / total)" : "0"
        return HStack(spacing: 16) {
            Image(systemName: "person.fill.questionmark").font(.system(size: 24)).foregroundColor(.white).padding(12).background(LinearGradient(colors: gameColors("hangman"), startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
                Text("Ahorcado (Cooperativo)").appFont(size: 15, weight: .bold)
                HStack {
                    Text("Resueltos: \(wins)").appFont(size: 13, weight: .semibold).foregroundColor(.green)
                    Text("Perdidos: \(losses)").appFont(size: 13, weight: .semibold).foregroundColor(.red)
                    if active > 0 { Text("Activos: \(active)").appFont(size: 13, weight: .semibold).foregroundColor(theme.primary) }
                }
            }
            Spacer()
            VStack {
                Text("\(rate)%").appFont(size: 22, weight: .bold).foregroundColor(.green)
                Text("Éxito").appFont(size: 10).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1)))
    }

    private func truthDareStatCard(myTruths: Int, partnerTruths: Int, myDares: Int, partnerDares: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill").font(.system(size: 18)).foregroundColor(.white).padding(8).background(LinearGradient(colors: [Color(red: 0.49, green: 0.51, blue: 1), Color(red: 1, green: 0.36, blue: 0.54)], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Retos y Verdades").appFont(size: 15, weight: .bold)
            }
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(myName).appFont(size: 13, weight: .bold).foregroundColor(theme.primary)
                    Text("💬 Verdades: \(myTruths)").appFont(size: 12)
                    Text("🌶️ Retos: \(myDares)").appFont(size: 12)
                }
                Divider().frame(height: 50)
                VStack(alignment: .leading, spacing: 6) {
                    Text(partnerName).appFont(size: 13, weight: .bold).foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.96))
                    Text("💬 Verdades: \(partnerTruths)").appFont(size: 12)
                    Text("🌶️ Retos: \(partnerDares)").appFont(size: 12)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1)))
    }

    // MARK: - History Tab

    private var historyTab: some View {
        List {
            ForEach(Array(games.enumerated()), id: \.offset) { _, g in
                historyRow(g)
            }
        }
        .listStyle(.plain)
    }

    private func historyRow(_ g: [String: Any]) -> some View {
        let gameType = g["gameType"] as? String ?? ""
        let spicyType = g["type"] as? String ?? ""
        let type = gameType.isEmpty ? spicyType : gameType
        let status = g["status"] as? String ?? "pending"
        let sender = g["sender"] as? String ?? g["senderName"] as? String ?? ""
        let timestamp = (g["timestamp"] as? Timestamp)?.dateValue() ?? (g["responseTimestamp"] as? Timestamp)?.dateValue() ?? (g["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let isSpicy = !spicyType.isEmpty

        let result = gameOutcome(g, gameType: gameType, spicyType: spicyType, sender: sender)
        let isCompleted = result.statusColor == .green

        return GlassCard(cornerRadius: 16) {
            HStack(spacing: 14) {
                Image(systemName: gameIcon(type)).font(.system(size: 20)).foregroundColor(.white).frame(width: 44, height: 44).background(LinearGradient(colors: gameColors(type), startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(gameLabel(type)).appFont(size: 15, weight: .bold)
                        Spacer()
                        Text(formattedDate(timestamp)).appFont(size: 10).foregroundColor(.secondary)
                    }
                    Text(result.text).appFont(size: 13).foregroundColor(.secondary).lineLimit(2)
                    HStack(spacing: 8) {
                        Capsule().fill(result.statusColor.opacity(0.15)).frame(width: 0).overlay(
                            Text(isCompleted ? "Completado" : (result.statusColor == .orange ? "Empate" : (result.statusColor == .blue || result.statusColor == theme.primary ? "En Curso" : "Finalizado")))
                                .appFont(size: 10, weight: .bold).foregroundColor(result.statusColor).padding(.horizontal, 8).padding(.vertical, 2)
                        ).fixedSize()
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - Compute Stats

    private struct GameStats {
        var total = 0, myWins = 0, partnerWins = 0, ties = 0, active = 0, coopWins = 0, coopLosses = 0, myTruths = 0, partnerTruths = 0, myDares = 0, partnerDares = 0
    }

    private struct ComputedStats {
        var totalGamesCount = 0, myTotalWins = 0, partnerTotalWins = 0, totalTies = 0
        var ttt = GameStats(), quiz = GameStats(), mem = GameStats(), rps = GameStats(), hangman = GameStats(), td = GameStats()
    }

    private func computeStats() -> ComputedStats {
        var s = ComputedStats()
        for g in games {
            let gameType = g["gameType"] as? String
            let spicyType = g["type"] as? String
            let status = g["status"] as? String ?? "pending"
            let sender = g["sender"] as? String ?? ""
            let winner = g["winner"] as? String ?? ""
            let isSender = myUid == (g["senderId"] as? String ?? "") || myName == sender

            if let gt = gameType, !gt.isEmpty {
                s.totalGamesCount += 1
                switch gt {
                case "tictactoe":
                    if winner.isEmpty { s.ttt.active += 1 }
                    else if winner == "Empate" { s.ttt.ties += 1; s.ttt.total += 1; s.totalTies += 1 }
                    else { s.ttt.total += 1; if winner == myName || winner == "Yo" { s.ttt.myWins += 1; s.myTotalWins += 1 } else { s.ttt.partnerWins += 1; s.partnerTotalWins += 1 } }
                case "quiz":
                    let sc = g["senderScore"] as? Int; let rc = g["receiverScore"] as? Int
                    if let sc, let rc { s.quiz.total += 1; let ms = isSender ? sc : rc; let ps = isSender ? rc : sc
                        if ms > ps { s.quiz.myWins += 1; s.myTotalWins += 1 } else if ps > ms { s.quiz.partnerWins += 1; s.partnerTotalWins += 1 } else { s.quiz.ties += 1; s.totalTies += 1 } }
                    else { s.quiz.active += 1 }
                case "memorama":
                    let sm = g["senderMoves"] as? Int; let rm = g["receiverMoves"] as? Int
                    if let sm, let rm { s.mem.total += 1; let mm = isSender ? sm : rm; let pm = isSender ? rm : sm
                        if mm < pm { s.mem.myWins += 1; s.myTotalWins += 1 } else if pm < mm { s.mem.partnerWins += 1; s.partnerTotalWins += 1 } else { s.mem.ties += 1; s.totalTies += 1 } }
                    else { s.mem.active += 1 }
                case "rps":
                    let sc = g["senderChoice"] as? String ?? ""; let rc = g["receiverChoice"] as? String ?? ""
                    if !sc.isEmpty && !rc.isEmpty { s.rps.total += 1; let mc = isSender ? sc : rc; let pc = isSender ? rc : sc
                        if mc == pc { s.rps.ties += 1; s.totalTies += 1 }
                        else if (mc=="Piedra"&&pc=="Tijera")||(mc=="Papel"&&pc=="Piedra")||(mc=="Tijera"&&pc=="Papel") { s.rps.myWins += 1; s.myTotalWins += 1 }
                        else { s.rps.partnerWins += 1; s.partnerTotalWins += 1 } }
                    else { s.rps.active += 1 }
                case "hangman":
                    let sw = g["secretWord"] as? String ?? ""; let wc = g["wrongCount"] as? Int ?? 0
                    let gl = g["guessedLetters"] as? [String] ?? []; let won = !sw.isEmpty && sw.allSatisfy { gl.contains(String($0)) }; let lost = wc >= 6
                    if won { s.hangman.coopWins += 1; s.hangman.total += 1 } else if lost { s.hangman.coopLosses += 1 } else { s.hangman.active += 1 }
                case "truth_dare":
                    let ps = g["photoStatus"] as? String ?? ""; let ch = g["challenger"] as? String ?? ""; let st = g["selectedType"] as? String ?? ""
                    if st == "Reto" && ps == "approved" { if ch == myName { s.td.partnerDares += 1 } else { s.td.myDares += 1 } }
                default: break
                }
            } else if let st = spicyType, !st.isEmpty {
                s.totalGamesCount += 1
                let ps = g["photoStatus"] as? String ?? ""
                let responded = status == "responded" || ps == "approved"
                if responded {
                    if st == "Verdad" { if isSender { s.td.partnerTruths += 1 } else { s.td.myTruths += 1 } }
                    else if st == "Reto" || st == "foto" { if isSender { s.td.partnerDares += 1 } else { s.td.myDares += 1 } }
                }
            }
        }
        return s
    }

    // MARK: - Helpers

    private struct GameOutcome { let text: String; let statusColor: Color }

    private func gameOutcome(_ g: [String: Any], gameType: String, spicyType: String, sender: String) -> GameOutcome {
        if !gameType.isEmpty {
            switch gameType {
            case "tictactoe":
                let w = g["winner"] as? String ?? ""
                if w.isEmpty { return GameOutcome(text: "Partida en curso 🎮", statusColor: theme.primary) }
                if w == "Empate" { return GameOutcome(text: "Empate 🤝", statusColor: .orange) }
                return GameOutcome(text: "Ganador: \(w) 🏆", statusColor: .green)
            case "quiz":
                let sc = g["senderScore"] as? Int; let rc = g["receiverScore"] as? Int
                if let sc, let rc {
                    let isMe = myName == sender; let ms = isMe ? sc : rc; let ps = isMe ? rc : sc
                    if ms > ps { return GameOutcome(text: "Ganaste (\(ms)-\(ps)) 🌟", statusColor: .green) }
                    if ps > ms { return GameOutcome(text: "Ganó \(partnerName) (\(ps)-\(ms)) 🏆", statusColor: .red) }
                    return GameOutcome(text: "Empate (\(ms)-\(ms)) 🤝", statusColor: .orange)
                }
                return GameOutcome(text: "Esperando puntuaciones ⌛", statusColor: .blue)
            case "memorama":
                let sm = g["senderMoves"] as? Int; let rm = g["receiverMoves"] as? Int
                if let sm, let rm {
                    let isMe = myName == sender; let mm = isMe ? sm : rm; let pm = isMe ? rm : sm
                    if mm < pm { return GameOutcome(text: "Ganaste (\(mm) vs \(pm) mov.) 🌟", statusColor: .green) }
                    if pm < mm { return GameOutcome(text: "Ganó \(partnerName) (\(pm) vs \(mm) mov.) 🏆", statusColor: .red) }
                    return GameOutcome(text: "Empate (\(mm) mov.) 🤝", statusColor: .orange)
                }
                return GameOutcome(text: "Esperando resolución ⌛", statusColor: .blue)
            case "rps":
                let sc = g["senderChoice"] as? String ?? ""; let rc = g["receiverChoice"] as? String ?? ""
                if !sc.isEmpty && !rc.isEmpty {
                    let isMe = myName == sender; let mc = isMe ? sc : rc; let pc = isMe ? rc : sc
                    if mc == pc { return GameOutcome(text: "Empate (\(mc)) 🤝", statusColor: .orange) }
                    if (mc=="Piedra"&&pc=="Tijera")||(mc=="Papel"&&pc=="Piedra")||(mc=="Tijera"&&pc=="Papel") { return GameOutcome(text: "Ganaste con \(mc) 🌟", statusColor: .green) }
                    return GameOutcome(text: "Ganó \(partnerName) con \(pc) 🏆", statusColor: .red)
                }
                return GameOutcome(text: "Esperando jugadas ⌛", statusColor: .blue)
            case "hangman":
                let sw = g["secretWord"] as? String ?? ""; let wc = g["wrongCount"] as? Int ?? 0
                let gl = g["guessedLetters"] as? [String] ?? []
                let won = !sw.isEmpty && sw.allSatisfy { gl.contains(String($0)) }; let lost = wc >= 6
                if won { return GameOutcome(text: "¡Palabra salvada: \(sw)! 🎉", statusColor: .green) }
                if lost { return GameOutcome(text: "Ahorcados (Palabra: \(sw)) 😢", statusColor: .red) }
                return GameOutcome(text: "Jugando... (Fallos: \(wc)/6) 🎮", statusColor: theme.primary)
            case "truth_dare":
                let ps = g["photoStatus"] as? String ?? ""; let ch = g["challenger"] as? String ?? ""; let st = g["selectedType"] as? String ?? ""
                if st.isEmpty { return GameOutcome(text: "Esperando elección ⌛", statusColor: .blue) }
                if st == "Verdad" { return GameOutcome(text: "\(ch) eligió Verdad 💬", statusColor: .green) }
                if ps == "approved" { return GameOutcome(text: "Reto Completado y Aprobado 🎉", statusColor: .green) }
                if ps == "rejected" { return GameOutcome(text: "Reto Rechazado 👎", statusColor: .red) }
                if ps == "pending" { return GameOutcome(text: "Reto subido, esperando aprobación 👀", statusColor: .orange) }
                return GameOutcome(text: "Esperando prueba del reto 📸", statusColor: .blue)
            default: return GameOutcome(text: "Juego", statusColor: .secondary)
            }
        } else if !spicyType.isEmpty {
            let ps = g["photoStatus"] as? String ?? ""; let content = g["content"] as? String ?? ""
            let responded = (g["status"] as? String) == "responded" || ps == "approved"
            if responded { let rn = (sender == myName) ? partnerName : myName; return GameOutcome(text: "\(rn) completó: \"\(content)\"", statusColor: .green) }
            return GameOutcome(text: "Reto enviado por \(sender) (Pendiente)", statusColor: .blue)
        }
        return GameOutcome(text: "", statusColor: .secondary)
    }

    private func gameLabel(_ type: String) -> String {
        switch type { case "quiz": return "Quiz"; case "truth_dare": return "Verdad o Reto"; case "memorama": return "Memorama"; case "tictactoe": return "Tres en Raya"; case "rps": return "PPT"; case "hangman": return "Ahorcado"; case "Verdad": return "Verdad Picante"; case "Reto": return "Reto Picante"; case "foto": return "Foto Reto"; default: return "Juego" }
    }

    private func gameIcon(_ type: String) -> String {
        switch type { case "quiz": return "questionmark.square.fill"; case "truth_dare": return "heart.fill"; case "memorama": return "rectangle.3.group.fill"; case "tictactoe": return "grid.3x3"; case "rps": return "hand.raised.fill"; case "hangman": return "person.fill.questionmark"; case "Verdad": return "face.smiling"; case "Reto": return "flame.fill"; case "foto": return "camera.fill"; default: return "gamecontroller.fill" }
    }

    private func gameColors(_ type: String) -> [Color] {
        switch type { case "quiz": return [Color(red: 1, green: 0.36, blue: 0.54), Color(red: 1, green: 0.54, blue: 0.67)]; case "truth_dare": return [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.77, green: 0.71, blue: 0.99)]; case "memorama": return [Color(red: 1, green: 0.72, blue: 0.3), Color(red: 1, green: 0.84, blue: 0.31)]; case "tictactoe": return [Color(red: 0.4, green: 0.73, blue: 0.42), Color(red: 0.65, green: 0.84, blue: 0.65)]; case "rps": return [Color(red: 0.26, green: 0.65, blue: 0.96), Color(red: 0.56, green: 0.79, blue: 0.98)]; case "hangman": return [Color(red: 0.94, green: 0.33, blue: 0.31), Color(red: 0.94, green: 0.6, blue: 0.6)]; case "Verdad": return [Color(red: 0.49, green: 0.51, blue: 1), Color(red: 0.61, green: 0.64, blue: 1)]; case "Reto", "foto": return [Color(red: 1, green: 0.36, blue: 0.54), Color(red: 1, green: 0.54, blue: 0.67)]; default: return [.gray, .gray.opacity(0.7)] }
    }

    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "dd/MM/yy HH:mm"; f.locale = Locale(identifier: "es")
        return f.string(from: d)
    }

    // MARK: - Firestore

    private func startListening() {
        snapshotListener = gamesRef.addSnapshotListener { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
            games = docs.map { var d = $0.data(); d["id"] = $0.documentID; return d }
                .sorted { a, b in
                    let ta = (a["timestamp"] as? Timestamp)?.dateValue() ?? (a["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let tb = (b["timestamp"] as? Timestamp)?.dateValue() ?? (b["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return ta > tb
                }
        }
    }

    private func stopListening() {
        snapshotListener?.remove(); snapshotListener = nil
    }
}
