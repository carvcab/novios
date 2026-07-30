import Foundation
import Combine
import FirebaseFirestore

struct AIMemory: Codable {
    var key: String
    var value: String
    var category: String
    var updatedAt: String
}

class AIMemoryService: ObservableObject {
    static let shared = AIMemoryService()

    @Published var memories: [AIMemory] = []
    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard

    private var coupleId: String { CoupleService.coupleId }

    func load() {
        if let data = defaults.data(forKey: "ai_memories"),
           let cached = try? JSONDecoder().decode([AIMemory].self, from: data) {
            memories = cached
        }
        // Load from Firestore
        db.collection("parejas").document(coupleId).collection("ai").document("memoria").getDocument { [weak self] snap, _ in
            guard let data = snap?.data() else { return }
            for (key, val) in data {
                if let dict = val as? [String: Any],
                   let value = dict["value"] as? String,
                   let category = dict["category"] as? String {
                    let mem = AIMemory(key: key, value: value, category: category, updatedAt: dict["updatedAt"] as? String ?? "")
                    self?.memories.append(mem)
                }
            }
            self?.saveLocal()
        }
    }

    func setMemory(key: String, value: String, category: String = "general") {
        memories.removeAll { $0.key == key }
        let mem = AIMemory(key: key, value: value, category: category, updatedAt: ISO8601DateFormatter().string(from: Date()))
        memories.append(mem)
        saveLocal()
        // Sync to Firestore
        db.collection("parejas").document(coupleId).collection("ai").document("memoria").setData([
            key: ["value": value, "category": category, "updatedAt": mem.updatedAt]
        ], merge: true)
    }

    func getMemory(_ key: String) -> String? {
        memories.first { $0.key == key }?.value
    }

    func buildContextPrompt() -> String {
        memories.map { "- \($0.key): \($0.value)" }.joined(separator: "\n")
    }

    private func saveLocal() {
        if let data = try? JSONEncoder().encode(memories) {
            defaults.set(data, forKey: "ai_memories")
        }
    }
}
