import Foundation
import Combine

public struct AIMessage: Identifiable, Codable {
    public var id: String = UUID().uuidString
    public var text: String
    public var isUser: Bool
    public var timestamp: Date = Date()
}

public class AIService: ObservableObject {
    public static let shared = AIService()
    
    @Published public var aiConversation: [AIMessage] = []
    @Published public var isGenerating: Bool = false
    
    private init() {
        aiConversation = [
            AIMessage(text: "¡Hola! Soy tu asistente de pareja Gemini AI. 💖 ¿En qué les puedo ayudar hoy? ¿Buscan una idea para una cita romántica, resolver un desacuerdo o un poema de amor?", isUser: false)
        ]
    }
    
    public func sendQuery(_ query: String) async {
        let userMsg = AIMessage(text: query, isUser: true)
        await MainActor.run {
            self.aiConversation.append(userMsg)
            self.isGenerating = true
        }
        
        try? await Task.sleep(nanoseconds: 1_200_000_000) // Simulate Gemini AI latency
        
        let responseText = generateMockAIResponse(for: query)
        let aiMsg = AIMessage(text: responseText, isUser: false)
        
        await MainActor.run {
            self.aiConversation.append(aiMsg)
            self.isGenerating = false
        }
    }
    
    private func generateMockAIResponse(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("cita") || lower.contains("plan") || lower.contains("hacer") {
            return "💡 **Idea de Cita Romántica:**\n1. **Noche de Picnic Estelar:** Preparen bocadillos, una manta cómoda y busquen un lugar al aire libre o la terraza para mirar las estrellas.\n2. **Cocina a Ciegas:** Elijan una receta nueva y cocinen juntos escuchando música suave."
        } else if lower.contains("poema") || lower.contains("carta") || lower.contains("mensaje") {
            return "🌹 **Carta de Amor:**\n'Cada momento a tu lado hace que el tiempo se detenga y el mundo desaparezca. Eres mi lugar favorito en el universo y la razón de mis sonrisas diarias. Te amo hoy y siempre.'"
        } else if lower.contains("consejo") || lower.contains("pelea") || lower.contains("discusión") {
            return "🕊️ **Consejo de Relaciones:**\nRecuerden siempre escuchar con empatía antes de responder. Un pequeño gesto de cariño o un abrazo sincero puede calmar cualquier tensión. ¡El amor en equipo siempre gana!"
        } else {
            return "✨ Me encanta su energía como pareja. Recuerden expresar lo mucho que se aprecian a diario. ¿Les gustaría probar un juego divertido juntos?"
        }
    }
}
