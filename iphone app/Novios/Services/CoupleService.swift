import Foundation

public class CoupleService: ObservableObject {
    public static let shared = CoupleService()

    public static let parejaId = "pareja_001"
    public static let diegoUid = "joeBcVn2o1hfXfU68rWNOyAZIqt2"
    public static let yosmariUid = "Dd1X94n3gxg7leWtMtnLlxDVHcm2"
    public static let diegoEmail = "diego@novios.com"
    public static let yosmariEmail = "yosmari@novios.com"
    public static let diegoName = "Diego"
    public static let yosmariName = "Yosmari"

    @Published public var coupleName = "Diego ♡ Yosmari"
    @Published public var members: [String] = []
    @Published public var isLoaded = false
    @Published public var data: [String: Any]?

    public var currentUid: String { AuthService.shared.currentUser?.id ?? "" }
    public var currentName: String { currentUid == Self.diegoUid ? Self.diegoName : Self.yosmariName }
    public var partnerUid: String { currentUid == Self.diegoUid ? Self.yosmariUid : Self.diegoUid }
    public var partnerName: String { currentUid == Self.diegoUid ? Self.yosmariName : Self.diegoName }
    public var coupleDisplayName: String { "Diego ♡ Yosmari" }

    public var parejaPath: String { "parejas/\(Self.parejaId)" }

    // All subcollections
    public var chatPath: String { "\(parejaPath)/chat" }
    public var cartasPath: String { "\(parejaPath)/cartas" }
    public var albumPath: String { "\(parejaPath)/album" }
    public var recuerdosPath: String { "\(parejaPath)/recuerdos" }
    public var ubicacionPath: String { "\(parejaPath)/ubicacion" }
    public var lugaresPath: String { "\(parejaPath)/lugares" }
    public var calendarioPath: String { "\(parejaPath)/calendario" }
    public var metasPath: String { "\(parejaPath)/metas" }
    public var logrosPath: String { "\(parejaPath)/logros" }
    public var capsulaPath: String { "\(parejaPath)/capsula" }
    public var notificacionesPath: String { "\(parejaPath)/notificaciones" }
    public var diarioPath: String { "\(parejaPath)/diario" }
    public var musicaPath: String { "\(parejaPath)/musica" }
    public var juegosPath: String { "\(parejaPath)/juegos" }
    public var citasPath: String { "\(parejaPath)/citas" }
    public var rutasPath: String { "\(parejaPath)/rutas" }
    public var todoPath: String { "\(parejaPath)/todo" }

    private var pollingTimer: Timer?
    private let defaults = UserDefaults.standard

    private init() {}

    public func loadCouple() async {
        let path = parejaPath
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: path),
           let fields = doc["fields"] as? [String: Any] {
            let s = { (k: String) -> String? in (fields[k] as? [String: Any])?["stringValue"] as? String }
            if let name = s("nombre") { await MainActor.run { self.coupleName = name } }
            if let membersArr = (fields["miembros"] as? [String: Any])?["arrayValue"] as? [String: Any],
               let values = membersArr["values"] as? [[String: Any]] {
                let ids = values.compactMap { ($0["stringValue"] as? [String: Any])?["stringValue"] as? String }
                await MainActor.run { self.members = ids }
            }
            await MainActor.run { self.data = fields; self.isLoaded = true }
        }
    }

    public func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { await self.loadCouple() }
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - CRUD Helpers

    public func addDocument(path: String, data: [String: Any]) async {
        let docId = UUID().uuidString
        var fullData = data
        fullData["creadoPor"] = currentUid
        fullData["creado"] = ISO8601DateFormatter().string(from: Date())
        try? await FirebaseRESTService.shared.firestoreSet(path: "\(path)/\(docId)", fields: fullData)
    }

    public func setDocument(path: String, data: [String: Any]) async {
        var fullData = data
        fullData["actualizadoPor"] = currentUid
        fullData["actualizado"] = ISO8601DateFormatter().string(from: Date())
        try? await FirebaseRESTService.shared.firestoreSet(path: path, fields: fullData)
    }

    public func deleteDocument(path: String) async {
        try? await FirebaseRESTService.shared.firestoreDelete(path: path)
    }

    public func ensureParejaDocExists() async {
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: parejaPath) {
            if doc == nil {
                try? await FirebaseRESTService.shared.firestoreSet(path: parejaPath, fields: [
                    "nombre": coupleDisplayName,
                    "fechaRelacion": "",
                    "miembros": [Self.diegoUid, Self.yosmariUid],
                    "creado": ISO8601DateFormatter().string(from: Date()),
                ])
            }
        } else {
            try? await FirebaseRESTService.shared.firestoreSet(path: parejaPath, fields: [
                "nombre": coupleDisplayName,
                "fechaRelacion": "",
                "miembros": [Self.diegoUid, Self.yosmariUid],
                "creado": ISO8601DateFormatter().string(from: Date()),
            ])
        }
    }
}
