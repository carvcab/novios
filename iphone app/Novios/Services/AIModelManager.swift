import Foundation
import CommonCrypto

public enum AIState: String {
    case notInstalled = "No instalada"
    case downloading = "Descargando..."
    case verifying = "Verificando..."
    case installing = "Instalando..."
    case ready = "Instalada"
    case error = "Error"
    case updating = "Actualizando..."
}

public enum ModelError: LocalizedError {
    case noSpace(available: Int64, required: Int64)
    case downloadFailed(String)
    case verificationFailed(expected: String, got: String)
    case networkError
    case noModelInfo
    case installFailed(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .noSpace(let avail, let req):
            return "Espacio insuficiente. Necesitas \(req) MB libres. Disponible: \(avail) MB"
        case .downloadFailed(let detail):
            return "Error al descargar: \(detail)"
        case .verificationFailed(let exp, let got):
            return "SHA-256 no coincide. Esperado: \(exp), obtenido: \(got)"
        case .networkError:
            return "Error de conexion. Verifica tu internet."
        case .noModelInfo:
            return "No hay informacion del modelo"
        case .installFailed(let detail):
            return "Error al instalar: \(detail)"
        case .unknown(let detail):
            return "Error: \(detail)"
        }
    }
}

public struct ModelInfoData: Codable {
    let id: String
    let name: String
    let fileName: String
    let downloadUrl: String
    let sizeBytes: Int64
    let sha256: String
    let version: String
    let minRamMB: Int
    let contextLength: Int

    var sizeMB: Int { Int(sizeBytes / (1024 * 1024)) }
    var requiredSpaceMB: Int { Int(Double(sizeMB) * 1.3) }
}

public class AIModelManager: ObservableObject {
    public static let shared = AIModelManager()

    @Published public var state: AIState = .notInstalled
    @Published public var progress: Double = 0
    @Published public var progressText = ""
    @Published public var downloadedBytes: Int64 = 0
    @Published public var totalBytes: Int64 = 0
    @Published public var errorMessage: String?
    @Published public var currentModel: ModelInfoData?

    private let defaults = UserDefaults.standard
    private var downloadTask: URLSessionDownloadTask?
    private var downloadSession: URLSession?

    private let versionKey = "ai_model_version"
    private let modelInfoURL = URL(string: "https://raw.githubusercontent.com/carvcab/novios/main/ai/model_info.json")!

    private var modelsDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("ai_models")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var modelPath: URL? {
        guard let name = currentModel?.fileName else { return nil }
        return modelsDir.appendingPathComponent(name)
    }

    private var tempPath: URL? {
        guard let path = modelPath else { return nil }
        return path.appendingPathExtension("download")
    }

    private var infoPath: URL {
        modelsDir.appendingPathComponent("model_info.json")
    }

    private init() {
        if let version = defaults.string(forKey: versionKey), !version.isEmpty {
            loadLocalInfo()
            if modelFileExists() {
                state = .ready
            }
        }
    }

    public func initModel() {
        fetchModelInfo()
    }

    // MARK: - Model Info

    private func fetchModelInfo() {
        URLSession.shared.dataTask(with: modelInfoURL) { [weak self] data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let m = json["model"] as? [String: Any] else { return }
            let model = ModelInfoData(
                id: m["id"] as? String ?? "",
                name: m["name"] as? String ?? "Modelo",
                fileName: m["fileName"] as? String ?? "",
                downloadUrl: m["downloadUrl"] as? String ?? "",
                sizeBytes: m["sizeBytes"] as? Int64 ?? 0,
                sha256: m["sha256"] as? String ?? "",
                version: m["version"] as? String ?? "1.0",
                minRamMB: m["minRamMB"] as? Int ?? 2048,
                contextLength: m["contextLength"] as? Int ?? 8192
            )
            DispatchQueue.main.async {
                self?.currentModel = model
                if let installed = self?.defaults.string(forKey: self?.versionKey ?? ""),
                   installed != model.version {
                    self?.state = .updating
                }
            }
        }.resume()
    }

    private func loadLocalInfo() {
        guard let data = try? Data(contentsOf: infoPath),
              let info = try? JSONDecoder().decode(ModelInfoData.self, from: data) else { return }
        currentModel = info
    }

    private func saveLocalInfo() {
        guard let model = currentModel,
              let data = try? JSONEncoder().encode(model) else { return }
        try? data.write(to: infoPath)
    }

    private func modelFileExists() -> Bool {
        guard let path = modelPath else { return false }
        return FileManager.default.fileExists(atPath: path.path)
    }

    // MARK: - Download

    public func downloadModel() {
        guard let model = currentModel else {
                errorMessage = ModelError.noModelInfo.localizedDescription
            state = .error
            return
        }

        let freeBytes = freeDiskSpace()
        let required = Int64(model.requiredSpaceMB) * 1024 * 1024
        if freeBytes < required {
            errorMessage = ModelError.noSpace(available: freeBytes / (1024*1024), required: model.requiredSpaceMB).localizedDescription
            state = .error
            return
        }

        state = .downloading
        errorMessage = nil
        progress = 0
        progressText = "Iniciando descarga..."
        downloadedBytes = 0
        totalBytes = model.sizeBytes

        guard let url = URL(string: model.downloadUrl) else {
            setError(.downloadFailed("URL invalida"))
            return
        }

        let delegate = AIURLDelegate.shared
        delegate.reset()
        delegate.destURL = tempPath

        downloadSession?.invalidateAndCancel()
        downloadSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        downloadTask = downloadSession?.downloadTask(with: url)

        delegate.onProgress = { [weak self] bytes, total in
            DispatchQueue.main.async {
                self?.downloadedBytes = bytes
                self?.totalBytes = total
                self?.progress = total > 0 ? Double(bytes) / Double(total) : 0
                self?.progressText = "Descargando... \(Int(self?.progress ?? 0 * 100))%"
            }
        }

        delegate.onComplete = { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let tempURL):
                    self.verifyAndInstall(tempURL)
                case .failure(let error):
                    self.setError(.downloadFailed(error.localizedDescription))
                }
            }
        }

        downloadTask?.resume()
    }

    private func verifyAndInstall(_ tempURL: URL) {
        state = .verifying
        progressText = "Verificando integridad..."
        objectWillChange.send()

        guard let dest = modelPath else {
            setError(.unknown("No se pudo determinar la ruta"))
            return
        }

        // SHA-256 verification
        let hash = sha256OfFile(at: tempURL)
        if let expected = currentModel?.sha256, !expected.isEmpty, hash.lowercased() != expected.lowercased() {
            try? FileManager.default.removeItem(at: tempURL)
            setError(.verificationFailed(expected: expected, got: hash))
            return
        }

        state = .installing
        progressText = "Instalando modelo..."
        objectWillChange.send()

        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: tempURL, to: dest)
            state = .ready
            progress = 1.0
            progressText = "Modelo instalado correctamente"
            defaults.set(currentModel?.version ?? "1.0", forKey: versionKey)
            saveLocalInfo()
        } catch {
            setError(.installFailed(error.localizedDescription))
        }
    }

    public func deleteModel() {
        if let path = modelPath { try? FileManager.default.removeItem(at: path) }
        if let path = tempPath { try? FileManager.default.removeItem(at: path) }
        defaults.removeObject(forKey: versionKey)
        state = .notInstalled
        progress = 0
        progressText = ""
        errorMessage = nil
    }

    public func updateModel() {
        deleteModel()
        downloadModel()
    }

    public func cancelDownload() {
        downloadTask?.cancel()
        downloadSession?.invalidateAndCancel()
        downloadSession = nil
        downloadTask = nil
        state = .notInstalled
        progress = 0
        progressText = "Descarga cancelada"
    }

    // MARK: - Helpers

    private func setError(_ error: ModelError) {
        errorMessage = error.localizedDescription
        state = .error
        progress = 0
    }

    private func freeDiskSpace() -> Int64 {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path),
           let free = attrs[.systemFreeSize] as? Int64 {
            return free
        }
        return 10 * 1024 * 1024 * 1024
    }

    private func sha256OfFile(at url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return "" }
        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)
        let chunkSize = 1024 * 1024
        while true {
            let data = handle.readData(ofLength: chunkSize)
            if data.isEmpty { break }
            data.withUnsafeBytes { buf in
                _ = CC_SHA256_Update(&context, buf.baseAddress, CC_LONG(data.count))
            }
        }
        handle.closeFile()
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - URLSession Delegate

private class AIURLDelegate: NSObject, URLSessionDownloadDelegate {
    static let shared = AIURLDelegate()
    var onProgress: ((Int64, Int64) -> Void)?
    var onComplete: ((Result<URL, Error>) -> Void)?
    var destURL: URL?

    func reset() {
        onProgress = nil
        onComplete = nil
        destURL = nil
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        onProgress?(totalBytesWritten, max(totalBytesExpectedToWrite, 1))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let dest = destURL else {
            onComplete?(.failure(NSError(domain: "AI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No destination"])))
            return
        }
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            onComplete?(.success(dest))
        } catch {
            onComplete?(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onComplete?(.failure(error))
        }
    }
}
