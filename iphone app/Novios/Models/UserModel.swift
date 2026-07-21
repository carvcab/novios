import Foundation
import CoreLocation

public struct UserModel: Identifiable, Codable, Equatable {
    public var id: String // UID
    public var nombre: String
    public var correo: String
    public var foto: String
    public var PIN: String
    public var ultimaConexion: Date?
    public var ultimoAcceso: Date?
    public var tokenFCM: String
    public var configuracionPersonal: String
    public var parejaId: String

    public init(
        id: String,
        nombre: String = "",
        correo: String = "",
        foto: String = "",
        PIN: String = "",
        ultimaConexion: Date? = Date(),
        ultimoAcceso: Date? = Date(),
        tokenFCM: String = "",
        configuracionPersonal: String = "{}",
        parejaId: String = "pareja_001"
    ) {
        self.id = id
        self.nombre = nombre
        self.correo = correo
        self.foto = foto
        self.PIN = PIN
        self.ultimaConexion = ultimaConexion
        self.ultimoAcceso = ultimoAcceso
        self.tokenFCM = tokenFCM
        self.configuracionPersonal = configuracionPersonal
        self.parejaId = parejaId
    }

    // Helper compatibility getters for UI display
    public var displayName: String { nombre.isEmpty ? (id == "joeBcVn2o1hfXfU68rWNOyAZIqt2" ? "Diego" : "Yosmari") : nombre }
    public var email: String { correo }

    public func firestoreDictionary() -> [String: Any] {
        let df = ISO8601DateFormatter()
        return [
            "nombre": nombre,
            "correo": correo,
            "foto": foto,
            "PIN": PIN,
            "ultimaConexion": df.string(from: ultimaConexion ?? Date()),
            "ultimoAcceso": df.string(from: ultimoAcceso ?? Date()),
            "tokenFCM": tokenFCM,
            "configuracionPersonal": configuracionPersonal,
            "parejaId": parejaId
        ]
    }

    public static func fromFirestore(_ id: String, fields: [String: Any]) -> UserModel {
        let df = ISO8601DateFormatter()
        let s = { (k: String) -> String in
            if let v = fields[k] as? String { return v }
            return ((fields[k] as? [String: Any])?["stringValue"] as? String) ?? ""
        }
        let dateVal = { (k: String) -> Date? in
            let str = s(k)
            return str.isEmpty ? nil : df.date(from: str)
        }

        return UserModel(
            id: id,
            nombre: s("nombre"),
            correo: s("correo"),
            foto: s("foto"),
            PIN: s("PIN"),
            ultimaConexion: dateVal("ultimaConexion"),
            ultimoAcceso: dateVal("ultimoAcceso"),
            tokenFCM: s("tokenFCM"),
            configuracionPersonal: s("configuracionPersonal"),
            parejaId: s("parejaId").isEmpty ? "pareja_001" : s("parejaId")
        )
    }
}
