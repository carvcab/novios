import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_storage.dart';
import 'couple_service.dart';

class GameService {
  static final GameService _instance = GameService._();
  factory GameService() => _instance;
  GameService._();

  final _db = FirebaseFirestore.instance;
  String get _coupleId => CoupleService.parejaId;

  // ─── Paths ───
  CollectionReference get _gamesRef =>
      _db.collection('parejas').doc(_coupleId).collection('juegos');

  CollectionReference _typeRef(String gameType) =>
      _gamesRef.doc(gameType).collection('items');

  // ─── Quizzes ───
  Stream<QuerySnapshot> streamQuizzes() =>
      _typeRef('quizzes').orderBy('createdAt', descending: true).snapshots();

  Future<void> saveQuiz(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('quizzes').doc(id) : _typeRef('quizzes').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'authorId': LocalStorage().getUserId() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteQuiz(String id) =>
      _typeRef('quizzes').doc(id).delete();

  // ─── Truth or Dare ───
  Stream<QuerySnapshot> streamTD(String category) =>
      _typeRef('verdad_reto').where('category', isEqualTo: category).snapshots();

  Future<void> saveTD(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('verdad_reto').doc(id) : _typeRef('verdad_reto').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteTD(String id) =>
      _typeRef('verdad_reto').doc(id).delete();

  // ─── Never Have I Ever ───
  Stream<QuerySnapshot> streamNever({String? category}) {
    Query q = _typeRef('yo_nunca');
    if (category != null) q = q.where('category', isEqualTo: category);
    return q.snapshots();
  }

  Future<void> saveNever(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('yo_nunca').doc(id) : _typeRef('yo_nunca').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteNever(String id) =>
      _typeRef('yo_nunca').doc(id).delete();

  // ─── Would You Rather ───
  Stream<QuerySnapshot> streamPrefer() =>
      _typeRef('que_prefieres').snapshots();

  Future<void> savePrefer(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('que_prefieres').doc(id) : _typeRef('que_prefieres').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePrefer(String id) =>
      _typeRef('que_prefieres').doc(id).delete();

  // ─── Roulettes ───
  Stream<QuerySnapshot> streamRoulettes() =>
      _typeRef('ruletas').snapshots();

  Future<void> saveRoulette(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('ruletas').doc(id) : _typeRef('ruletas').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteRoulette(String id) =>
      _typeRef('ruletas').doc(id).delete();

  // ─── Hangman ───
  Stream<QuerySnapshot> streamHangman() =>
      _typeRef('ahorcados').snapshots();

  Future<void> saveHangmanWord(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('ahorcados').doc(id) : _typeRef('ahorcados').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteHangmanWord(String id) =>
      _typeRef('ahorcados').doc(id).delete();

  // ─── Custom Dice ───
  Stream<QuerySnapshot> streamDice() =>
      _typeRef('dados').snapshots();

  Future<void> saveDice(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('dados').doc(id) : _typeRef('dados').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDice(String id) =>
      _typeRef('dados').doc(id).delete();

  // ─── Love / Compatibility ───
  Stream<QuerySnapshot> streamLoveQuestions() =>
      _typeRef('amor').snapshots();

  Future<void> saveLoveQuestion(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef('amor').doc(id) : _typeRef('amor').doc();
    await ref.set({
      ...data,
      'author': LocalStorage().getUserName() ?? 'Yo',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Stats ───
  Future<void> saveGameStats(String gameType, Map<String, dynamic> stats) async {
    await _gamesRef.doc(gameType).collection('stats').add({
      ...stats,
      'playerId': LocalStorage().getUserId() ?? '',
      'playerName': LocalStorage().getUserName() ?? 'Yo',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamGameStats(String gameType) =>
      _gamesRef.doc(gameType).collection('stats')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();

  // ─── Favorite / Duplicate ───
  Future<void> toggleFavorite(String gameType, String itemId) async {
    final doc = _typeRef(gameType).doc(itemId);
    final snap = await doc.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final currentFavs = List<String>.from(data['favoritedBy'] ?? []);
    final uid = LocalStorage().getUserId() ?? '';
    if (currentFavs.contains(uid)) {
      currentFavs.remove(uid);
    } else {
      currentFavs.add(uid);
    }
    await doc.update({'favoritedBy': currentFavs});
  }

  Future<void> duplicateItem(String gameType, String itemId) async {
    final doc = _typeRef(gameType).doc(itemId);
    final snap = await doc.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    final newData = Map<String, dynamic>.from(data)
      ..remove('createdAt')
      ..remove('updatedAt')
      ..remove('favoritedBy');
    newData['author'] = LocalStorage().getUserName() ?? 'Yo';
    newData['authorId'] = LocalStorage().getUserId() ?? '';
    newData['createdAt'] = FieldValue.serverTimestamp();
    newData['duplicatedFrom'] = itemId;
    await _typeRef(gameType).add(newData);
  }

  // ─── Generic stream all items for a game type ───
  Stream<QuerySnapshot> streamAll(String gameType) =>
      _typeRef(gameType).snapshots();

  // ─── Generic CRUD ───
  Future<void> saveItem(String gameType, Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _typeRef(gameType).doc(id) : _typeRef(gameType).doc();
    data['author'] = LocalStorage().getUserName() ?? 'Yo';
    data['authorId'] = LocalStorage().getUserId() ?? '';
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> deleteItem(String gameType, String id) =>
      _typeRef(gameType).doc(id).delete();

  // ─── Collections / Folders ───
  CollectionReference get _collectionsRef =>
      _gamesRef.doc('colecciones').collection('items');

  Stream<QuerySnapshot> streamCollections() =>
      _collectionsRef.snapshots();

  Future<void> saveCollection(Map<String, dynamic> data, {String? id}) async {
    final ref = id != null ? _collectionsRef.doc(id) : _collectionsRef.doc();
    data['author'] = LocalStorage().getUserName() ?? 'Yo';
    data['authorId'] = LocalStorage().getUserId() ?? '';
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> deleteCollection(String id) =>
      _collectionsRef.doc(id).delete();
}
