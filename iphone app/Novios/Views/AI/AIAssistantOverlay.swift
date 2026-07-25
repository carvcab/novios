import SwiftUI

public struct AIAssistantOverlay: View {
    @ObservedObject private var ai = LocalAIService.shared
    @ObservedObject private var memory = AIMemoryService.shared
    @ObservedObject private var theme = ThemeManager.shared
    let screenContext: String

    @State private var showChat = false
    @State private var messageText = ""
    @State private var messages: [(isUser: Bool, text: String)] = []
    @State private var isThinking = false
    @State private var pulseScale: CGFloat = 1.0

    public init(screenContext: String = "general") {
        self.screenContext = screenContext
    }

    public var body: some View {
        ZStack {
            if showChat {
                chatOverlay
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingButton
                }
            }
        }
    }

    private var floatingButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showChat.toggle()
            }
        } label: {
            Image(systemName: showChat ? "xmark" : "sparkle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(theme.primary)
                .clipShape(Circle())
                .shadow(color: theme.primary.opacity(0.4), radius: 12)
                .scaleEffect(pulseScale)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }

    private var chatOverlay: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(theme.primary)
                Text("Asistente IA")
                    .appFont(size: 14, weight: .bold)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Circle()
                    .fill(ai.isInitialized ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(ai.isInitialized ? "En linea" : "Sin conexion")
                    .appFont(size: 10)
                    .foregroundColor(theme.textSecondary)
            }
            .padding(16)
            .background(theme.primary.opacity(0.1))

            // Messages
            ScrollViewReader { scroll in
                ScrollView {
                    if messages.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.3))
                            Text(contextHint())
                                .appFont(size: 13)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                                HStack {
                                    if msg.isUser { Spacer() }
                                    Text(msg.text)
                                        .appFont(size: 13)
                                        .foregroundColor(msg.isUser ? .white : theme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(msg.isUser ? theme.primary : Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    if !msg.isUser { Spacer() }
                                }
                            }
                            if isThinking {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(10)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    Spacer()
                                }
                            }
                        }
                        .padding(12)
                    }
                }
                .onChange(of: messages.count) { _ in
                    withAnimation { scroll.scrollTo("bottom", anchor: .bottom) }
                }
                Color.clear.frame(height: 1).id("bottom")
            }

            // Input
            if ai.isInitialized {
                HStack(spacing: 8) {
                    TextField("Escribe aqui...", text: $messageText)
                        .textFieldStyle(.plain)
                        .appFont(size: 13)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .onSubmit { send() }
                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(theme.primary)
                            .frame(width: 36, height: 36)
                            .background(theme.primary.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            } else {
                Text("Modelo de IA no instalado. Ve a Ajustes > IA para descargarlo.")
                    .appFont(size: 11)
                    .foregroundColor(.orange)
                    .padding(12)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.5)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 20)
        .padding(.bottom, 72)
    }

    private func contextHint() -> String {
        switch screenContext {
        case "location": return "Puedo ayudarte con direcciones, lugares cercanos o estados de ubicacion"
        case "chat": return "Puedo ayudarte a escribir mensajes romanticos, corregir o traducir"
        case "letters": return "Puedo ayudarte a escribir cartas de amor, poemas o dedicatorias"
        case "memories": return "Puedo ayudarte a crear historias con tus recuerdos"
        case "goals": return "Puedo ayudarte a planificar metas y sugerir pasos"
        default: return "Preguntame lo que quieras"
        }
    }

    private func send() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messageText = ""
        messages.append((true, text))
        isThinking = true

        let memContext = memory.buildContextPrompt()
        let prompt = """
        \(memContext)
        Contexto actual: \(screenContext)
        Pregunta: \(text)
        Responde en espanol de forma carinosa y util. Maximo 3 parrafos.
        """

        // Use fallback since we don't have the actual LLM running locally
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let response = fallbackResponse(text)
            DispatchQueue.main.async {
                messages.append((false, response))
                isThinking = false
            }
        }
    }

    private func fallbackResponse(_ q: String) -> String {
        let ql = q.lowercased()
        if ql.contains("hola") || ql.contains("buenos") {
            return "Hola amor! Como estas hoy? En que puedo ayudarte?"
        }
        if ql.contains("te amo") || ql.contains("quiero") {
            return "Yo tambien te quiero mucho! Eres la persona mas especial del mundo."
        }
        if ql.contains("cita") || ql.contains("plan") {
            return "Que tal un picnic al atardecer? Preparen algo rico y busquen un lugar bonito al aire libre."
        }
        if ql.contains("regalo") || ql.contains("sorprender") {
            return "Un frasco con 100 razones por las que la amas nunca falla. O un mapa de rascadito con sus proximos viajes."
        }
        if ql.contains("recuerdo") || ql.contains("recordar") {
            let mems = memory.memories
            if !mems.isEmpty {
                let m = mems[Int.random(in: 0..<mems.count)]
                return "Me acuerdo de \"\(m.key)\". Fue un momento especial para ustedes."
            }
            return "Aun estan creando sus recuerdos. Cada dia es una oportunidad para guardar un momento especial."
        }
        let responses = [
            "El amor es un viaje, no un destino. Disfruten cada paso del camino juntos.",
            "La comunicacion es la llave maestra de toda relacion exitosa.",
            "Los pequenos gestos de amor diario construyen un amor inquebrantable.",
            "Lo mas valioso que pueden regalarse es tiempo de calidad juntos.",
        ]
        return responses.randomElement() ?? responses[0]
    }
}
