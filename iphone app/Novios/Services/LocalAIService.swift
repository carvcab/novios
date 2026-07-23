import Foundation
import Combine

public class LocalAIService: ObservableObject {
    public static let shared = LocalAIService()

    @Published public var isInitialized = false
    @Published public var isLoading = false
    @Published public var downloadProgress: Double = 0
    @Published public var statusText = ""

    private let defaults = UserDefaults.standard
    private let modelFileName = "DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf"
    private let modelURL = URL(string: "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf")!
    private let expectedSize: Int64 = 1120 * 1024 * 1024

    private var downloadTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?

    private init() {
        isInitialized = defaults.bool(forKey: "model_downloaded")
        if isInitialized {
            statusText = "Modelo listo"
            downloadProgress = 1.0
        }
    }

    public var modelFilePath: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = docs.appendingPathComponent("models").appendingPathComponent(modelFileName)
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    public var isDownloaded: Bool {
        modelFilePath != nil
    }

    public func startDownload() {
        guard !isLoading else { return }
        isLoading = true
        downloadProgress = 0
        statusText = "Iniciando descarga..."

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDir = docs.appendingPathComponent("models")
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)

        let session = URLSession(configuration: .default, delegate: DownloadDelegate.shared, delegateQueue: nil)
        downloadTask = session.downloadTask(with: modelURL)
        DownloadDelegate.shared.onProgress = { [weak self] progress in
            DispatchQueue.main.async {
                self?.downloadProgress = progress
                self?.statusText = "Descargando... \(Int(progress * 100))%"
            }
        }
        DownloadDelegate.shared.onCompletion = { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let tempURL):
                    let dest = modelsDir.appendingPathComponent(self?.modelFileName ?? "model.gguf")
                    try? FileManager.default.removeItem(at: dest)
                    do {
                        try FileManager.default.moveItem(at: tempURL, to: dest)
                        self?.isInitialized = true
                        self?.downloadProgress = 1.0
                        self?.statusText = "Modelo listo"
                        self?.defaults.set(true, forKey: "model_downloaded")
                    } catch {
                        self?.statusText = "Error al guardar el modelo"
                        self?.downloadProgress = 0
                    }
                case .failure(let error):
                    self?.statusText = "Error: \(error.localizedDescription)"
                    self?.downloadProgress = 0
                }
            }
        }
        downloadTask?.resume()
    }

    public func cancelDownload() {
        downloadTask?.cancel()
        isLoading = false
        downloadProgress = 0
        statusText = "Descarga cancelada"
    }

    public func deleteModel() {
        if let path = modelFilePath {
            try? FileManager.default.removeItem(at: path)
        }
        isInitialized = false
        downloadProgress = 0
        statusText = ""
        defaults.set(false, forKey: "model_downloaded")
    }

    // MARK: - Fallback Responses (same as Android)

    public func fallbackLetter(tone: String) -> String {
        let letters = [
            """
Mi amor,

Hoy, mientras el silencio abraza la habitación, no puedo dejar de pensar en lo afortunado que soy de tenerte en mi vida. Cada día a tu lado es un regalo que atesoro en lo más profundo de mi corazón.

Recuerdo cuando nos conocimos, cómo el universo conspiró para que nuestros caminos se cruzaran. Desde entonces, cada momento contigo ha sido una página escrita con tinta de estrellas en el libro de nuestra historia.

Tus ojos son mi refugio, tu sonrisa mi alegría más grande. En tus abrazos encuentro la paz que buscaba, y en tus besos, la promesa de un amor eterno.

Gracias por ser mi compañera, mi amiga, mi amor. Por caminar a mi lado en las tormentas y bailar conmigo bajo la lluvia. Eres mi hogar, mi lugar seguro.

Te amo más de lo que las palabras pueden expresar. Eres mi ayer, mi hoy y mi siempre.

Con todo mi amor,
Tu pareja
""",
            """
Amor de mi vida,

Eres la casualidad más hermosa que jamás me haya pasado. Como una estrella fugaz que iluminó mi cielo oscuro, llegaste y cambiaste mi mundo por completo.

Cada día descubro algo nuevo que amar de ti: tu forma de reír, tu mirada cuando hablas de tus sueños, la manera en que tu mano encaja perfectamente en la mía.

Contigo aprendí que el amor no es solo un sentimiento, es una decisión que tomamos cada mañana al despertar. Y yo elijo amarte hoy, mañana y siempre.

Eres mi mejor poema, mi canción favorita, mi historia preferida.

Siempre tuyo,
Tu amor
"""
        ]
        return letters.randomElement() ?? letters[0]
    }

    public func fallbackPoem(style: String, topic: String) -> String {
        return """
"\(topic)"

En el jardín de tus ojos me pierdo,
donde florecen sueños de primavera,
cada mirada tuya es un recuerdo
que en mi pecho dulcemente prospera.

Tus labios son versos que el viento susurra,
tu piel es el lienzo de mi inspiración,
cada caricia tuya es una dulce murmura
que despierta en mi alma la más bella canción.

Eres el faro que guía mi destino,
la estrella que brilla en mi oscuridad,
en tus brazos encuentro mi camino,
y en tu amor, mi más pura verdad.
"""
    }

    public func fallbackDate(type: String, budget: String) -> String {
        let ideas: [String: String] = [
            "Aventura": "🌄 Una caminata al amanecer: Levantense temprano, preparen un termo de café y diríjanse al mirador o parque más cercano. Vean el amanecer juntos y compartan sus sueños para el futuro.",
            "Hogareña": "🏠 Noche de cine con mantas: Preparen palomitas, chocolate caliente y vean su película romántica favorita acurrucados en el sofá. Bonus: masaje de pies durante la película.",
            "Cultural": "🎭 Visita a un museo o galería local: Descubran arte juntos y compartan qué les gusta de cada obra. Terminen con un café en una terraza bonita.",
            "Económica": "🧺 Picnic en el parque: Preparen sándwiches, frutas y una limonada. Lleven una manta, música y pasen la tarde conversando y riendo.",
            "Sorpresa": "🎁 Cita a ciegas organizada por el otro: Cada uno planea media cita sin que el otro sepa. El primero elige el lugar de encuentro, el segundo la actividad sorpresa."
        ]
        return ideas[type] ?? ideas["Romántica"] ?? "Cena sorpresa con velas y música romántica en casa. Preparen su platillo favorito juntos."
    }

    public func fallbackGift(occasion: String) -> String {
        let gifts = [
            "🎁 Un álbum de fotos personalizado: Reúna sus mejores fotos juntos, agregue notas escritas a mano y recuerdos de cada momento. Es un regalo que atesorarán para siempre.",
            "🎁 Experiencia sorpresa: Planee un día especial completo - desde el desayuno hasta la cena - con actividades que ella/él ame. No necesita ser caro, solo significativo.",
            "🎁 Carta de amor + detalle: Escriba una carta sincera expresando todo lo que siente, acompañada de un detalle simbólico como una pulsera con iniciales o su perfume favorito."
        ]
        return gifts.randomElement() ?? gifts[0]
    }

    public func fallbackSong(genre: String, details: String) -> String {
        return """
Título: "Eres Tú"
Género: \(genre)

(Verso 1)
En un mundo de colores, llegaste tú,
pintando mi vida con luz de alba y juventud,
cada paso que das es música para mí,
cada latido tuyo lo siento aquí.

(Coro)
Eres tú, la melodía que mi alma quiere oír,
la canción que no termina, que me hace sonreír,
en tus brazos encontré mi lugar,
y en tu amor aprendí a amar.

(Verso 2)
Recuerdo aquel día cuando te conocí,
el tiempo se detuvo, solo existías tú y yo,
desde entonces mi corazón te pertenece,
y este amor con cada día más crece.
"""
    }

    public func fallbackStory(title: String, details: String) -> String {
        return """
"\(title)"

Había una vez dos almas que el destino decidió unir. En un mundo lleno de casualidades, \(details). Lo que comenzó como un encuentro fortuito se convirtió en una historia de amor que trascendería el tiempo.

Cada momento compartido fue como un pétalo de flor que caía suavemente, formando un jardín de recuerdos eternos. Las miradas cómplices, las risas compartidas, los silencios que hablaban más que mil palabras...

Y así, entre sueños y realidades, construyeron su propio universo, donde el amor era el idioma universal y la felicidad, su destino perpetuo.

Esta es su historia, una que apenas comienza y que promete ser tan infinita como el amor que los une.
"""
    }

    public func fallbackQuestion(question: String) -> String {
        let q = question.lowercased()
        if q.contains("viaje") || q.contains("viajar") || q.contains("luna de miel") || q.contains("destino") {
            return "¡Qué emoción! Viajar juntos es una de las experiencias más hermosas que pueden compartir. Les recomiendo planificar juntos: investiguen destinos, hagan una lista de deseos y sueños por cumplir. Los viajes fortalecen la conexión y crean recuerdos inolvidables. ¿Qué tal si empiezan con un destino cercano y van subiendo la dificultad?"
        }
        if q.contains("sorpresa") || q.contains("sorprender") || q.contains("detalle") {
            return "Los detalles pequeños son los que más llegan al corazón. Puedes sorprender a tu pareja con: una nota inesperada en su bolso, su snack favorito después de un día difícil, una cita sorpresa en un lugar significativo para ustedes, o simplemente recordarle lo mucho que la/lo amas sin razón aparente. ¡Lo espontáneo siempre gana!"
        }
        if q.contains("pelea") || q.contains("discusión") || q.contains("enojado") || q.contains("problema") {
            return "Todas las parejas pasan por momentos difíciles. Lo importante es comunicarse con respeto y amor. Recuerden que no son tú contra yo, sino los dos contra el problema. Tómense un momento para respirar, expresen cómo se sienten sin culpar al otro, y busquen juntos una solución. El amor verdadero no significa nunca pelear, sino saber reconciliarse."
        }
        let randomResponses = [
            "El amor es un viaje, no un destino. Disfruten cada paso del camino juntos.",
            "La comunicación es la llave maestra de toda relación exitosa. Nunca dejen de hablarse.",
            "Los pequeños gestos de amor diario construyen un amor inquebrantable. Un 'te amo' sincero, un abrazo inesperado, una caricia al pasar...",
            "Lo más valioso que pueden regalarse es tiempo de calidad juntos, sin distracciones, conectando de verdad.",
            "La confianza es la base del amor. Cuando confías, amas sin miedo y te entregas por completo.",
            "Amar no es mirarse el uno al otro, es mirar juntos en la misma dirección hacia un futuro compartido.",
            "La paciencia es el arte de esperar sin desesperar. En el amor, todo llega a su debido tiempo."
        ]
        return randomResponses.randomElement() ?? randomResponses[0]
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    static let shared = DownloadDelegate()
    var onProgress: ((Double) -> Void)?
    var onCompletion: ((Result<URL, Error>) -> Void)?

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress?(progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        onCompletion?(.success(location))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onCompletion?(.failure(error))
        }
    }
}
