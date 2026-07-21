import Foundation
import Combine

public class CoupleService: ObservableObject {
    public static let shared = CoupleService()

    @Published public var coupleId: String = "pareja_001"
    @Published public var coupleName: String = "Diego 💞 Yosmari"
    @Published public var members: [String] = []
    @Published public var isLoaded = false

    public let diegoUID = "joeBcVn2o1hfXfU68rWNOyAZIqt2"
    public let yosmariUID = "Dd1X94n3gxg7leWtMtnLlxDVHcm2"

    public var myUID: String { AuthService.shared.currentUser?.id ?? "" }
    public var partnerUID: String {
        myUID == diegoUID ? yosmariUID : diegoUID
    }
    public var myName: String { myUID == diegoUID ? "Diego" : "Yosmari" }
    public var partnerName: String { myUID == diegoUID ? "Yosmari" : "Diego" }

    private var pollingTimer: Timer?
    private let defaults = UserDefaults.standard

    private init() {}

    public func loadCouple() async {
        if let doc = try? await FirebaseRESTService.shared.firestoreGet(path: "parejas/\(coupleId)"),
           let fields = doc["fields"] as? [String: Any] {
            let s = { (k: String) -> String? in (fields[k] as? [String: Any])?["stringValue"] as? String }
            if let name = s("nombre") { await MainActor.run { self.coupleName = name } }
            if let membersArr = (fields["miembros"] as? [String: Any])?["arrayValue"] as? [String: Any],
               let values = membersArr["values"] as? [[String: Any]] {
                let ids = values.compactMap { ($0["stringValue"] as? [String: Any])?["stringValue"] as? String }
                await MainActor.run { self.members = ids }
            }
            await MainActor.run { self.isLoaded = true }
        }
    }

    public func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { await self.loadCouple() }
        }
    }

    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}
