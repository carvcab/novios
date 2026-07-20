import SwiftUI

private let truthQuestions: [String: [String]] = [
    "suave": [
        "¿Cuál fue tu primera impresión de mí?",
        "¿Qué es lo que más te gusta de nuestra relación?",
        "¿Cuál es tu recuerdo favorito juntos?",
    ],
    "picante": [
        "¿Qué parte de mi cuerpo te vuelve loco?",
        "¿Cuál es tu fantasía secreta conmigo?",
        "¿Dónde es el lugar más atrevido donde quieres besarme?",
    ],
    "extremo": [
        "¿Qué cosa prohibida te gustaría probar conmigo?",
        "¿Cuál es tu mayor fetiche secreto?",
        "¿Qué harías si estuviéramos solos 24 horas sin ropa?",
    ],
    "xxx": [
        "Descríbeme tu escenario sexual perfecto conmigo",
        "¿Qué juguete o accesorio te gustaría incorporar?",
        "¿Cuál es tu posición favorita y por qué?",
    ],
]

private let dareChallenges: [String: [String]] = [
    "suave": [
        "Dame un masaje en los hombros por 2 minutos",
        "Baila una canción sexy para mí",
        "Susurra algo dulce a mi oído",
    ],
    "picante": [
        "Quítame una prenda con los dientes",
        "Hazme un striptease de 30 segundos",
        "Besa mi cuello durante 15 segundos",
    ],
    "extremo": [
        "Déjame atarte las manos con una corbata",
        "Hazme una demostración de tu movimiento favorito",
        "Deja que te explore el cuerpo con los ojos vendados",
    ],
    "xxx": [
        "Simula tu posición favorita con la ropa puesta",
        "Graba un audio con tu gemido más sexy para mí",
        "Sigue cualquier orden que te dé por los próximos 5 minutos",
    ],
]

private let levelColors: [SpicyLevel: Color] = [
    .suave: .green,
    .picante: .orange,
    .extremo: .pink,
    .xxx: Color(red: 0.6, green: 0.0, blue: 0.0),
]

private let levelIcons: [SpicyLevel: String] = [
    .suave: "leaf.fill",
    .picante: "flame.fill",
    .extremo: "flame.fill",
    .xxx: "sparkles",
]

private struct ChallengeCard: Identifiable {
    let id = UUID()
    let type: ChallengeType
    let icon: String
    let title: String
    let description: String
}

private let sendCards: [ChallengeCard] = [
    ChallengeCard(type: .truth, icon: "bubble.left.and.text.bubble.fill", title: "Verdad", description: "Pregunta íntima generada por IA para conocer más a tu pareja"),
    ChallengeCard(type: .dare, icon: "figure.strengthtraining.traditional", title: "Reto", description: "Desafío atrevido para avivar la chispa"),
    ChallengeCard(type: .photo, icon: "camera.fill", title: "Foto Reto", description: "Desafío fotográfico para compartir momentos picantes 📸"),
]

public struct SpicyGamesView: View {
    @State private var selectedLevel: SpicyLevel = .suave
    @State private var selectedTab = 0
    @State private var challenges: [SpicyChallenge] = sampleChallenges
    @State private var responseText: String = ""
    @State private var respondingTo: String? = nil

    public var body: some View {
        ZStack {
            ThemeManager.shared.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                levelPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                tabPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ScrollView {
                    if selectedTab == 0 {
                        sendTab
                    } else {
                        receivedTab
                    }
                }
            }
        }
        .navigationTitle("Zona Picante")
    }

    private var levelPicker: some View {
        HStack(spacing: 6) {
            ForEach(SpicyLevel.allCases, id: \.self) { level in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedLevel = level
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: levelIcons[level] ?? "circle.fill")
                            .font(.system(size: 14))
                        Text(level.rawValue.capitalized)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(selectedLevel == level ? .white : levelColors[level] ?? .primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedLevel == level ? (levelColors[level] ?? .gray) : Color.gray.opacity(0.12))
                    )
                }
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation { selectedTab = 0 }
            } label: {
                Text("Enviar")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedTab == 0 ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(selectedTab == 0 ? ThemeManager.shared.primaryPink : Color.clear)
                    .cornerRadius(12)
            }

            Button {
                withAnimation { selectedTab = 1 }
            } label: {
                Text("Recibidos")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedTab == 1 ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(selectedTab == 1 ? ThemeManager.shared.primaryPink : Color.clear)
                    .cornerRadius(12)
            }
        }
        .background(Color.gray.opacity(0.12))
        .cornerRadius(12)
    }

    private var sendTab: some View {
        VStack(spacing: 14) {
            ForEach(sendCards) { card in
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: card.icon)
                            .font(.system(size: 36))
                            .foregroundColor(levelColors[selectedLevel] ?? .pink)

                        Text(card.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)

                        Text(card.description)
                            .font(.system(size: 12))
                            .foregroundColor(ThemeManager.shared.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        Button {
                            let text = pickText(for: card.type)
                            let challenge = SpicyChallenge(
                                id: UUID().uuidString,
                                level: selectedLevel,
                                type: card.type,
                                text: text,
                                status: .pending,
                                fromPartner: false
                            )
                            challenges.insert(challenge, at: 0)
                        } label: {
                            Text("Enviar a mi pareja")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(levelColors[selectedLevel] ?? ThemeManager.shared.primaryPink)
                                .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }

    private var receivedTab: some View {
        VStack(spacing: 12) {
            if challenges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                    Text("No hay desafíos recibidos")
                        .font(.system(size: 15))
                        .foregroundColor(ThemeManager.shared.textSecondary)
                }
                .padding(.top, 60)
            } else {
                ForEach(challenges) { challenge in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(levelColors[challenge.level] ?? .gray)
                                        .frame(width: 8, height: 8)
                                    Text(challenge.level.rawValue.capitalized)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(levelColors[challenge.level] ?? .primary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(levelColors[challenge.level]?.opacity(0.15) ?? Color.gray.opacity(0.15))
                                .cornerRadius(8)

                                Spacer()

                                Text(challenge.type.rawValue.capitalized)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ThemeManager.shared.primaryPink)

                                Spacer()

                                Text(challenge.status.rawValue.capitalized)
                                    .font(.system(size: 10))
                                    .foregroundColor(challenge.status == .pending ? .orange : .green)
                            }

                            Text(challenge.text)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)

                            if challenge.fromPartner && challenge.status == .pending {
                                if respondingTo == challenge.id {
                                    VStack(spacing: 8) {
                                        TextField("Escribe tu respuesta...", text: $responseText)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                            .padding(12)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(12)

                                        Button {
                                            if let idx = challenges.firstIndex(where: { $0.id == challenge.id }) {
                                                challenges[idx].status = .responded
                                            }
                                            responseText = ""
                                            respondingTo = nil
                                        } label: {
                                            Text("Enviar respuesta")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 38)
                                                .background(ThemeManager.shared.neonGlowGradient)
                                                .cornerRadius(12)
                                        }
                                    }
                                } else {
                                    Button {
                                        respondingTo = challenge.id
                                    } label: {
                                        Text("Responder")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 38)
                                            .background(ThemeManager.shared.primaryPink)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private func pickText(for type: ChallengeType) -> String {
        let key = selectedLevel.rawValue
        switch type {
        case .truth:
            return truthQuestions[key]?.randomElement() ?? "¿Cuál es tu secreto más profundo?"
        case .dare:
            return dareChallenges[key]?.randomElement() ?? "Haz algo atrevido ahora mismo"
        case .photo:
            return "Tómate una foto sugerente con la pose que más te guste y envíala"
        }
    }
}

private let sampleChallenges: [SpicyChallenge] = [
    SpicyChallenge(id: "c1", level: .suave, type: .truth, text: "¿Qué fue lo que te hizo enamorarte de mí?", status: .pending, fromPartner: true),
    SpicyChallenge(id: "c2", level: .picante, type: .dare, text: "Besa apasionadamente a tu pareja por 10 segundos", status: .responded, fromPartner: true),
    SpicyChallenge(id: "c3", level: .extremo, type: .truth, text: "¿Cuál es tu fantasía más salvaje?", status: .pending, fromPartner: true),
]
