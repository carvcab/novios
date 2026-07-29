import Foundation
import FirebaseFirestore

public class GameService: ObservableObject {
    public static let shared = GameService()

    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard

    private var coupleId: String {
        [CoupleService.diegoUid, CoupleService.yosmariUid].sorted().joined(separator: "_")
    }

    private var juegosRef: CollectionReference {
        db.collection("parejas").document(coupleId).collection("juegos")
    }

    private func typeRef(_ gameType: String) -> CollectionReference {
        juegosRef.document(gameType).collection("items")
    }

    // MARK: - Quizzes
    public func streamQuizzes() -> Query {
        typeRef("quizzes").order(by: "createdAt", descending: true)
    }

    public func saveQuiz(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("quizzes").document($0) } ?? typeRef("quizzes").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["authorId"] = defaults.string(forKey: "user_id") ?? ""
        d["createdAt"] = FieldValue.serverTimestamp()
        d["updatedAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteQuiz(_ id: String) {
        typeRef("quizzes").document(id).delete()
    }

    // MARK: - Truth or Dare
    public func streamTD(category: String) -> Query {
        typeRef("verdad_reto").whereField("category", isEqualTo: category)
    }

    public func saveTD(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("verdad_reto").document($0) } ?? typeRef("verdad_reto").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteTD(_ id: String) {
        typeRef("verdad_reto").document(id).delete()
    }

    // MARK: - Never Have I Ever
    public func streamNever(category: String? = nil) -> Query {
        var q: Query = typeRef("yo_nunca")
        if let cat = category { q = q.whereField("category", isEqualTo: cat) }
        return q
    }

    public func saveNever(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("yo_nunca").document($0) } ?? typeRef("yo_nunca").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteNever(_ id: String) {
        typeRef("yo_nunca").document(id).delete()
    }

    // MARK: - Would You Rather
    public func streamPrefer() -> Query {
        typeRef("que_prefieres")
    }

    public func savePrefer(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("que_prefieres").document($0) } ?? typeRef("que_prefieres").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deletePrefer(_ id: String) {
        typeRef("que_prefieres").document(id).delete()
    }

    // MARK: - Roulettes
    public func streamRoulettes() -> Query {
        typeRef("ruletas")
    }

    public func saveRoulette(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("ruletas").document($0) } ?? typeRef("ruletas").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteRoulette(_ id: String) {
        typeRef("ruletas").document(id).delete()
    }

    // MARK: - Hangman
    public func streamHangman() -> Query {
        typeRef("ahorcados")
    }

    public func saveHangmanWord(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("ahorcados").document($0) } ?? typeRef("ahorcados").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteHangmanWord(_ id: String) {
        typeRef("ahorcados").document(id).delete()
    }

    // MARK: - Dice
    public func streamDice() -> Query {
        typeRef("dados")
    }

    public func saveDice(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("dados").document($0) } ?? typeRef("dados").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteDice(_ id: String) {
        typeRef("dados").document(id).delete()
    }

    // MARK: - Love / Compatibility
    public func streamLoveQuestions() -> Query {
        typeRef("amor")
    }

    public func saveLoveQuestion(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef("amor").document($0) } ?? typeRef("amor").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    // MARK: - Stats
    public func saveGameStats(_ gameType: String, _ stats: [String: Any]) {
        var d = stats
        d["playerId"] = defaults.string(forKey: "user_id") ?? ""
        d["playerName"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["timestamp"] = FieldValue.serverTimestamp()
        juegosRef.document(gameType).collection("stats").addDocument(data: d)
    }

    public func streamGameStats(_ gameType: String) -> Query {
        juegosRef.document(gameType).collection("stats")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
    }

    // MARK: - Favorite / Duplicate
    public func toggleFavorite(gameType: String, itemId: String) {
        let ref = typeRef(gameType).document(itemId)
        ref.getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            var favs = data["favoritedBy"] as? [String] ?? []
            let uid = self.defaults.string(forKey: "user_id") ?? ""
            if let idx = favs.firstIndex(of: uid) {
                favs.remove(at: idx)
            } else {
                favs.append(uid)
            }
            ref.updateData(["favoritedBy": favs])
        }
    }

    public func duplicateItem(gameType: String, itemId: String) {
        let ref = typeRef(gameType).document(itemId)
        ref.getDocument { snapshot, _ in
            guard var data = snapshot?.data() else { return }
            data.removeValue(forKey: "createdAt")
            data.removeValue(forKey: "updatedAt")
            data.removeValue(forKey: "favoritedBy")
            data["author"] = self.defaults.string(forKey: "user_name") ?? "Yo"
            data["authorId"] = self.defaults.string(forKey: "user_id") ?? ""
            data["createdAt"] = FieldValue.serverTimestamp()
            data["duplicatedFrom"] = itemId
            self.typeRef(gameType).addDocument(data: data)
        }
    }

    // MARK: - Collections
    public func streamCollections() -> Query {
        juegosRef.document("colecciones").collection("items")
    }

    public func saveCollection(_ data: [String: Any], id: String? = nil) {
        let ref = id.map { juegosRef.document("colecciones").collection("items").document($0) }
            ?? juegosRef.document("colecciones").collection("items").document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteCollection(_ id: String) {
        juegosRef.document("colecciones").collection("items").document(id).delete()
    }

    // MARK: - Generic
    public func streamAll(gameType: String) -> Query {
        typeRef(gameType)
    }

    public func saveItem(gameType: String, data: [String: Any], id: String? = nil) {
        let ref = id.map { typeRef(gameType).document($0) } ?? typeRef(gameType).document()
        var d = data
        d["author"] = defaults.string(forKey: "user_name") ?? "Yo"
        d["authorId"] = defaults.string(forKey: "user_id") ?? ""
        d["createdAt"] = FieldValue.serverTimestamp()
        ref.setData(d, merge: true)
    }

    public func deleteItem(gameType: String, id: String) {
        typeRef(gameType).document(id).delete()
    }
}
