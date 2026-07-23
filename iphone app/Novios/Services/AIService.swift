import Foundation

public enum AIMode: String {
    case deepseek = "deepseek"
    case local = "local"
}

public class AIService: ObservableObject {
    public static let shared = AIService()

    @Published public var currentMode: AIMode = .deepseek
    @Published public var hasApiKey: Bool = false

    private let defaults = UserDefaults.standard

    private init() {
        let modeStr = defaults.string(forKey: "ai_mode") ?? "deepseek"
        currentMode = AIMode(rawValue: modeStr) ?? .deepseek
        hasApiKey = !(defaults.string(forKey: "deepseek_api_key") ?? "").isEmpty
    }

    public func setMode(_ mode: AIMode) {
        currentMode = mode
        defaults.set(mode.rawValue, forKey: "ai_mode")
    }

    public func saveApiKey(_ key: String) {
        defaults.set(key, forKey: "deepseek_api_key")
        hasApiKey = !key.isEmpty
    }

    public func getApiKey() -> String {
        defaults.string(forKey: "deepseek_api_key") ?? ""
    }

    // MARK: - DeepSeek API

    private func deepseekRequest(messages: [[String: String]], temperature: Double = 0.8) async throws -> String {
        let key = getApiKey()
        guard !key.isEmpty else { throw AIError.noApiKey }

        let url = URL(string: "https://api.deepseek.com/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": messages,
            "temperature": temperature,
            "max_tokens": 1024
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw AIError.serverError
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var canGenerate: Bool {
        switch currentMode {
        case .deepseek: return hasApiKey
        case .local: return true
        }
    }

    // MARK: - AI Functions

    public func generateLetter(tone: String, keywords: String) async throws -> String {
        switch currentMode {
        case .deepseek:
            return try await deepseekRequest(messages: [
                ["role": "system", "content": "Eres un asistente romántico que escribe cartas de amor personalizadas. Responde SOLO con la carta, sin explicaciones."],
                ["role": "user", "content": "Escribe una carta de amor con tono \(tone) que incluya estas palabras clave: \(keywords)"]
            ], temperature: 0.9)
        case .local:
            return LocalAIService.shared.fallbackLetter(tone: tone)
        }
    }

    public func chat(prompt: String) async throws -> String {
        switch currentMode {
        case .deepseek:
            return try await deepseekRequest(messages: [
                ["role": "system", "content": "Eres un asistente de pareja amigable y romántico. Ayudas a parejas a comunicarse mejor y a tener ideas creativas para su relación."],
                ["role": "user", "content": prompt]
            ])
        case .local:
            return LocalAIService.shared.fallbackQuestion(question: prompt)
        }
    }

    public func suggestDate(type: String, budget: String) async throws -> String {
        switch currentMode {
        case .deepseek:
            return try await deepseekRequest(messages: [
                ["role": "system", "content": "Eres un experto en planes románticos para parejas. Sugiere ideas creativas y detalladas."],
                ["role": "user", "content": "Sugiere una cita \(type) con presupuesto \(budget). Incluye detalles como lugar, actividades y consejos."]
            ])
        case .local:
            return LocalAIService.shared.fallbackDate(type: type, budget: budget)
        }
    }

    public func suggestGift(occasion: String) async throws -> String {
        switch currentMode {
        case .deepseek:
            return try await deepseekRequest(messages: [
                ["role": "system", "content": "Eres un experto en regalos románticos. Sugiere ideas originales y significativas."],
                ["role": "user", "content": "Sugiere un regalo romántico para \(occasion). Explica por qué es especial."]
            ])
        case .local:
            return LocalAIService.shared.fallbackGift(occasion: occasion)
        }
    }

    public func generatePoem(style: String, topic: String) async throws -> String {
        switch currentMode {
        case .deepseek:
            return try await deepseekRequest(messages: [
                ["role": "system", "content": "Eres un poeta romántico. Escribe poemas originales y emotivos."],
                ["role": "user", "content": "Escribe un poema de amor en estilo \(style) sobre \(topic)"]
            ], temperature: 0.95)
        case .local:
            return LocalAIService.shared.fallbackPoem(style: style, topic: topic)
        }
    }
}

public enum AIError: Error, LocalizedError {
    case noApiKey
    case serverError
    case invalidResponse
    case noInternet

    public var errorDescription: String? {
        switch self {
        case .noApiKey: return "No hay API key configurada. Ve a Ajustes > IA para configurarla."
        case .serverError: return "Error del servidor de DeepSeek. Intenta más tarde."
        case .invalidResponse: return "Respuesta inválida del servidor."
        case .noInternet: return "Sin conexión a internet."
        }
    }
}
