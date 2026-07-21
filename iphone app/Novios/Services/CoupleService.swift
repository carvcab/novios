import Foundation
import Combine

public class CoupleService: ObservableObject {
    public static let shared = CoupleService()

    public static let parejaId = "pareja_001"
    public static let diegoUid = "joeBcVn2o1hfXfU68rWNOyAZIqt2"
    public static let yosmariUid = "Dd1X94n3gxg7leWtMtnLlxDVHcm2"
    public static let diegoName = "Diego"
    public static let yosmariName = "Yosmari"

    @Published public var coupleName = "Diego 💞 Yosmari"
    @Published public var members: [String] = [diegoUid, yosmariUid]
    @Published public var isLoaded = false
    @Published public var data: [String: Any]?

    // Subcollections state for real-time reactivity
    @Published public var cartas: [LetterModel] = []
    @Published public var recuerdos: [MemoryModel] = []
    @Published public var eventos: [EventModel] = []
    @Published public var logros: [GoalModel] = []
    @Published public var diarioEntries: [JournalModel] = []
    @Published public var musica: [SongModel] = []
    @Published public var citas: [DateIdeaModel] = []
    @Published public var todoItems: [TodoItemModel] = []
    @Published public var capsulas: [CapsuleModel] = []

    public var currentUid: String { AuthService.shared.currentUser?.id ?? "" }
    public var currentName: String { currentUid == Self.diegoUid ? Self.diegoName : Self.yosmariName }
    public var partnerUid: String { currentUid == Self.diegoUid ? Self.yosmariUid : Self.diegoUid }
    public var partnerName: String { currentUid == Self.diegoUid ? Self.yosmariName : Self.diegoName }
    public var coupleDisplayName: String { "Diego 💞 Yosmari" }

    public var parejaPath: String { "parejas/\(Self.parejaId)" }

    // All 16 subcollection paths
    public var chatPath: String { "\(parejaPath)/chat" }
    public var cartasPath: String { "\(parejaPath)/cartas" }
    public var albumPath: String { "\(parejaPath)/album" }
    public var recuerdosPath: String { "\(parejaPath)/recuerdos" }
    public var ubicacionPath: String { "\(parejaPath)/ubicacion" }
    public var lugaresPath: String { "\(parejaPath)/lugares" }
    public var calendarioPath: String { "\(parejaPath)/calendario" }
    public var eventosPath: String { "\(parejaPath)/eventos" }
    public var metasPath: String { "\(parejaPath)/metas" }
    public var logrosPath: String { "\(parejaPath)/logros" }
    public var estadisticasPath: String { "\(parejaPath)/estadisticas" }
    public var capsulaPath: String { "\(parejaPath)/capsula" }
    public var notificacionesPath: String { "\(parejaPath)/notificaciones" }
    public var configuracionPath: String { "\(parejaPath)/configuracion" }
    public var diarioPath: String { "\(parejaPath)/diario" }
    public var musicaPath: String { "\(parejaPath)/musica" }
    public var juegosPath: String { "\(parejaPath)/juegos" }
    public var citasPath: String { "\(parejaPath)/citas" }
    public var rutasPath: String { "\(parejaPath)/rutas" }
    public var todoPath: String { "\(parejaPath)/todo" }

    private var pollingTimer: Timer?

    private init() {}

    public func loadCouple() async {
        let path = parejaPath
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
           let fields = doc["fields"] as? [String: Any] {
            let s = { (k: String) -> String? in (fields[k] as? [String: Any])?["stringValue"] as? String }
            if let name = s("nombre") { await MainActor.run { self.coupleName = name } }
            await MainActor.run { self.data = fields; self.isLoaded = true }
        } else {
            await ensureParejaDocExists()
            await MainActor.run { self.isLoaded = true }
        }
        await refreshSubcollections()
    }

    public func refreshSubcollections() async {
        await fetchCartas()
        await fetchRecuerdos()
        await fetchEventos()
        await fetchLogros()
        await fetchDiario()
        await fetchMusica()
        await fetchCitas()
        await fetchTodo()
        await fetchCapsulas()
    }

    public func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.loadCouple()
            }
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Cartas (Love Letters)

    public func fetchCartas() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: cartasPath) else { return }
        let items: [LetterModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            let b = { (k: String) -> Bool in ((f[k] as? [String: Any])?["booleanValue"] as? Bool) ?? false }
            return LetterModel(id: id, titulo: s("titulo"), contenido: s("contenido"), deUid: s("deUid"), paraUid: s("paraUid"), leida: b("leida"))
        }
        await MainActor.run { self.cartas = items }
    }

    public func addCarta(titulo: String, contenido: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "contenido": contenido,
            "deUid": currentUid,
            "paraUid": partnerUid,
            "leida": false,
            "fecha": ISO8601DateFormatter().string(from: Date())
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(cartasPath)/\(id)", fields: fields)
        await fetchCartas()
    }

    // MARK: - Recuerdos (Album)

    public func fetchRecuerdos() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: recuerdosPath) else { return }
        let items: [MemoryModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            return MemoryModel(id: id, titulo: s("titulo"), descripcion: s("descripcion"), fotoUrl: s("fotoUrl"), lugar: s("lugar"))
        }
        await MainActor.run { self.recuerdos = items }
    }

    public func addRecuerdo(titulo: String, descripcion: String, fotoBase64: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "descripcion": descripcion,
            "fotoUrl": fotoBase64,
            "lugar": "Nuestro lugar",
            "fecha": ISO8601DateFormatter().string(from: Date())
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(recuerdosPath)/\(id)", fields: fields)
        await fetchRecuerdos()
    }

    // MARK: - Eventos (Calendario)

    public func fetchEventos() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: eventosPath) else { return }
        let items: [EventModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            return EventModel(id: id, titulo: s("titulo"), categoria: s("categoria"), descripcion: s("descripcion"))
        }
        await MainActor.run { self.eventos = items }
    }

    public func addEvento(titulo: String, categoria: String, descripcion: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "categoria": categoria,
            "descripcion": descripcion,
            "fecha": ISO8601DateFormatter().string(from: Date())
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(eventosPath)/\(id)", fields: fields)
        await fetchEventos()
    }

    // MARK: - Logros (Metas)

    public func fetchLogros() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: logrosPath) else { return }
        let items: [GoalModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            let b = { (k: String) -> Bool in ((f[k] as? [String: Any])?["booleanValue"] as? Bool) ?? false }
            return GoalModel(id: id, titulo: s("titulo"), descripcion: s("descripcion"), completado: b("completado"))
        }
        await MainActor.run { self.logros = items }
    }

    public func addLogro(titulo: String, descripcion: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "descripcion": descripcion,
            "completado": false,
            "fecha": ISO8601DateFormatter().string(from: Date())
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(logrosPath)/\(id)", fields: fields)
        await fetchLogros()
    }

    public func toggleLogro(id: String, completado: Bool) async {
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(logrosPath)/\(id)", fields: ["completado": !completado])
        await fetchLogros()
    }

    // MARK: - Diario

    public func fetchDiario() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: diarioPath) else { return }
        let items: [JournalModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            return JournalModel(id: id, titulo: s("titulo"), contenido: s("contenido"), autorUid: s("autorUid"), emocion: s("emocion"))
        }
        await MainActor.run { self.diarioEntries = items }
    }

    public func addDiarioEntry(titulo: String, contenido: String, emocion: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "contenido": contenido,
            "emocion": emocion,
            "autorUid": currentUid,
            "fecha": ISO8601DateFormatter().string(from: Date())
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(diarioPath)/\(id)", fields: fields)
        await fetchDiario()
    }

    // MARK: - Musica

    public func fetchMusica() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: musicaPath) else { return }
        let items: [SongModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            return SongModel(id: id, titulo: s("titulo"), artista: s("artista"), url: s("url"), agregadoPor: s("agregadoPor"))
        }
        await MainActor.run { self.musica = items }
    }

    public func addSong(titulo: String, artista: String, url: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "artista": artista,
            "url": url,
            "agregadoPor": currentName,
            "fecha": ISO8601DateFormatter().string(from: Date())
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(musicaPath)/\(id)", fields: fields)
        await fetchMusica()
    }

    // MARK: - Citas

    public func fetchCitas() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: citasPath) else { return }
        let items: [DateIdeaModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            let b = { (k: String) -> Bool in ((f[k] as? [String: Any])?["booleanValue"] as? Bool) ?? false }
            return DateIdeaModel(id: id, titulo: s("titulo"), descripcion: s("descripcion"), realizada: b("realizada"))
        }
        await MainActor.run { self.citas = items }
    }

    public func addCita(titulo: String, descripcion: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "descripcion": descripcion,
            "realizada": false
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(citasPath)/\(id)", fields: fields)
        await fetchCitas()
    }

    // MARK: - Todo

    public func fetchTodo() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: todoPath) else { return }
        let items: [TodoItemModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            let b = { (k: String) -> Bool in ((f[k] as? [String: Any])?["booleanValue"] as? Bool) ?? false }
            return TodoItemModel(id: id, tarea: s("tarea"), completada: b("completada"), asignadoA: s("asignadoA"))
        }
        await MainActor.run { self.todoItems = items }
    }

    public func addTodoItem(tarea: String, asignadoA: String) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "tarea": tarea,
            "completada": false,
            "asignadoA": asignadoA
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(todoPath)/\(id)", fields: fields)
        await fetchTodo()
    }

    // MARK: - Capsula

    public func fetchCapsulas() async {
        guard let docs = try? await FirebaseRESTService.shared.firestoreList(path: capsulaPath) else { return }
        let items: [CapsuleModel] = docs.compactMap { doc in
            guard let f = doc["fields"] as? [String: Any],
                  let name = doc["name"] as? String,
                  let id = name.split(separator: "/").last.map(String.init) else { return nil }
            let s = { (k: String) -> String in ((f[k] as? [String: Any])?["stringValue"] as? String) ?? "" }
            let b = { (k: String) -> Bool in ((f[k] as? [String: Any])?["booleanValue"] as? Bool) ?? false }
            return CapsuleModel(id: id, titulo: s("titulo"), mensaje: s("mensaje"), fechaApertura: Date(), revelada: b("revelada"))
        }
        await MainActor.run { self.capsulas = items }
    }

    public func addCapsula(titulo: String, mensaje: String, fechaApertura: Date) async {
        let id = UUID().uuidString
        let fields: [String: Any] = [
            "titulo": titulo,
            "mensaje": mensaje,
            "fechaApertura": ISO8601DateFormatter().string(from: fechaApertura),
            "revelada": false
        ]
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(capsulaPath)/\(id)", fields: fields)
        await fetchCapsulas()
    }

    public func ensureParejaDocExists() async {
        let now = ISO8601DateFormatter().string(from: Date())
        try? await FirebaseRESTService.shared.firestoreSet(path: parejaPath, fields: [
            "nombre": coupleDisplayName,
            "fechaRelacion": now,
            "miembros": [Self.diegoUid, Self.yosmariUid],
            "creado": now,
        ])
    }
}
