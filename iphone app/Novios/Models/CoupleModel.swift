import Foundation

public struct CoupleModel: Identifiable, Codable, Equatable {
    public var id: String
    public var nombre: String
    public var fechaRelacion: String
    public var miembros: [String]

    public init(
        id: String = "pareja_001",
        nombre: String = "Diego 💞 Yosmari",
        fechaRelacion: String = "",
        miembros: [String] = ["joeBcVn2o1hfXfU68rWNOyAZIqt2", "Dd1X94n3gxg7leWtMtnLlxDVHcm2"]
    ) {
        self.id = id
        self.nombre = nombre
        self.fechaRelacion = fechaRelacion
        self.miembros = miembros
    }
}

// MARK: - Subcollection Models

public struct LetterModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var contenido: String
    public var fecha: Date
    public var deUid: String
    public var paraUid: String
    public var leida: Bool

    public init(id: String = UUID().uuidString, titulo: String, contenido: String, fecha: Date = Date(), deUid: String, paraUid: String, leida: Bool = false) {
        self.id = id
        self.titulo = titulo
        self.contenido = contenido
        self.fecha = fecha
        self.deUid = deUid
        self.paraUid = paraUid
        self.leida = leida
    }
}

public struct MemoryModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var descripcion: String
    public var fotoUrl: String
    public var fecha: Date
    public var lugar: String

    public init(id: String = UUID().uuidString, titulo: String, descripcion: String = "", fotoUrl: String = "", fecha: Date = Date(), lugar: String = "") {
        self.id = id
        self.titulo = titulo
        self.descripcion = descripcion
        self.fotoUrl = fotoUrl
        self.fecha = fecha
        self.lugar = lugar
    }
}

public struct EventModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var fecha: Date
    public var categoria: String
    public var descripcion: String

    public init(id: String = UUID().uuidString, titulo: String, fecha: Date = Date(), categoria: String = "Especial", descripcion: String = "") {
        self.id = id
        self.titulo = titulo
        self.fecha = fecha
        self.categoria = categoria
        self.descripcion = descripcion
    }
}

public struct GoalModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var descripcion: String
    public var completado: Bool
    public var fechaObjetivo: Date?

    public init(id: String = UUID().uuidString, titulo: String, descripcion: String = "", completado: Bool = false, fechaObjetivo: Date? = nil) {
        self.id = id
        self.titulo = titulo
        self.descripcion = descripcion
        self.completado = completado
        self.fechaObjetivo = fechaObjetivo
    }
}

public struct JournalModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var contenido: String
    public var fecha: Date
    public var autorUid: String
    public var emocion: String

    public init(id: String = UUID().uuidString, titulo: String, contenido: String, fecha: Date = Date(), autorUid: String, emocion: String = "❤️") {
        self.id = id
        self.titulo = titulo
        self.contenido = contenido
        self.fecha = fecha
        self.autorUid = autorUid
        self.emocion = emocion
    }
}

public struct SongModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var artista: String
    public var url: String
    public var agregadoPor: String

    public init(id: String = UUID().uuidString, titulo: String, artista: String, url: String = "", agregadoPor: String = "") {
        self.id = id
        self.titulo = titulo
        self.artista = artista
        self.url = url
        self.agregadoPor = agregadoPor
    }
}

public struct DateIdeaModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var descripcion: String
    public var realizada: Bool

    public init(id: String = UUID().uuidString, titulo: String, descripcion: String = "", realizada: Bool = false) {
        self.id = id
        self.titulo = titulo
        self.descripcion = descripcion
        self.realizada = realizada
    }
}

public struct TodoItemModel: Identifiable, Codable, Equatable {
    public var id: String
    public var tarea: String
    public var completada: Bool
    public var asignadoA: String

    public init(id: String = UUID().uuidString, tarea: String, completada: Bool = false, asignadoA: String = "Ambos") {
        self.id = id
        self.tarea = tarea
        self.completada = completada
        self.asignadoA = asignadoA
    }
}

public struct CapsuleModel: Identifiable, Codable, Equatable {
    public var id: String
    public var titulo: String
    public var mensaje: String
    public var fechaApertura: Date
    public var revelada: Bool

    public init(id: String = UUID().uuidString, titulo: String, mensaje: String, fechaApertura: Date, revelada: Bool = false) {
        self.id = id
        self.titulo = titulo
        self.mensaje = mensaje
        self.fechaApertura = fechaApertura
        self.revelada = revelada
    }
}
