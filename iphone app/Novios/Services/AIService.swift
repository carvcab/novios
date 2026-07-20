import Foundation

public class AIService {
    public static let shared = AIService()
    
    public var useLocalModel = false
    public var localModelDownloaded = false
    public var downloadProgress: Double = 0
    
    public func generateLetter(tone: String, keywords: String) -> String {
        let letters: [String: [String]] = [
            "Romántico": ["Mi amor,\n\nCada día que pasa me enamoro más de ti. Eres la luz que ilumina mi camino, la razón de mis sonrisas y el dueño de mi corazón. \(keywords) es solo una pequeña muestra de lo que siento por ti.\n\nSiempre tuyo/a,", "Querido/a \(keywords),\n\nEl amor que siento por ti crece más cada día. Eres mi pensamiento constante, mi alegría eterna."],
            "Apasionado": ["Amor mío,\n\n\(keywords) me hace pensar en lo mucho que te deseo. Cada momento a tu lado es una explosión de emociones."],
        ]
        return letters[tone]?.randomElement() ?? "Escribe algo hermoso para tu pareja..."
    }
    
    public func generatePoem(style: String, topic: String) -> String {
        let poems = ["En tus ojos encuentro el mar,\ndonde mis sueños navegan sin cesar.\n\(topic) es mi cantar,\nun amor que no deja de brillar.",
                    "Eres poesía hecha persona,\n\(topic) que mi alma emociona."]
        return poems.randomElement()!
    }
    
    public func suggestDate(type: String, budget: String) -> String {
        let dates = ["Cena romántica en casa con velas y música", "Picnic al atardecer en el parque", "Noche de películas con palomitas", "Paseo por la playa de noche"]
        return "\(dates.randomElement()!). Presupuesto: \(budget)"
    }
    
    public func suggestGift(occasion: String) -> String {
        let gifts = ["Un álbum de fotos personalizado", "Una carta escrita a mano", "Un viaje sorpresa", "Joyas personalizadas"]
        return "Para \(occasion): \(gifts.randomElement()!)"
    }
    
    public func generateSong(genre: String, details: String) -> String {
        return "\(details) - Una canción de \(genre)\n\nVerso 1:\n\(details) en mi mente,\ntu amor es mi presente.\n\nCoro:\nEres todo lo que siento,\neres mi mejor momento."
    }
    
    public func generateStory(title: String, details: String) -> String {
        return "\(title)\n\nHabía una vez una pareja que \(details). Su amor crecía cada día..."
    }
    
    public func answerRelationshipQuestion(question: String) -> String {
        let answers = ["El amor se demuestra con acciones pequeñas cada día.", "La comunicación es la clave.", "Lo más importante es la confianza y el respeto mutuo."]
        return answers.randomElement()!
    }
    
    public func downloadLocalModel() {
        downloadProgress = 0
        useLocalModel = true
    }
}
