import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage.dart';

class CoupleService extends ChangeNotifier {
  static final CoupleService _instance = CoupleService._();
  factory CoupleService() => _instance;
  CoupleService._();

  static const String parejaId = 'pareja_001';
  static const String diegoUid = 'joeBcVn2o1hfXfU68rWNOyAZIqt2';
  static const String yosmariUid = 'Dd1X94n3gxg7leWtMtnLlxDVHcm2';

  static const String diegoEmail = 'diego@novios.com';
  static const String yosmariEmail = 'yosss@novios.com';
  static const String diegoName = 'Diego';
  static const String yosmariName = 'Yosmari';

  late final DocumentReference _parejaDoc = FirebaseFirestore.instance.collection('parejas').doc(parejaId);
  StreamSubscription? _parejaSub;
  Map<String, dynamic>? _parejaData;
  bool _loaded = false;

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get currentName => currentUid == diegoUid ? diegoName : yosmariName;
  String get partnerUid => currentUid == diegoUid ? yosmariUid : diegoUid;
  String get partnerName => currentUid == diegoUid ? yosmariName : diegoName;
  String get coupleDisplayName => 'Diego 💞 Yosmari';
  bool get isLoaded => _loaded;
  Map<String, dynamic>? get data => _parejaData;
  DocumentReference get ref => _parejaDoc;

  CollectionReference get chatRef => ref.collection('chat');
  CollectionReference get cartasRef => ref.collection('cartas');
  CollectionReference get albumRef => ref.collection('album');
  CollectionReference get recuerdosRef => ref.collection('recuerdos');
  CollectionReference get ubicacionRef => ref.collection('ubicacion');
  CollectionReference get lugaresRef => ref.collection('lugares');
  CollectionReference get calendarioRef => ref.collection('calendario');
  CollectionReference get eventosRef => ref.collection('eventos');
  CollectionReference get metasRef => ref.collection('metas');
  CollectionReference get logrosRef => ref.collection('logros');
  CollectionReference get estadisticasRef => ref.collection('estadisticas');
  CollectionReference get capsulaRef => ref.collection('capsula');
  CollectionReference get notificacionesRef => ref.collection('notificaciones');
  CollectionReference get configuracionRef => ref.collection('configuracion');
  CollectionReference get diarioRef => ref.collection('diario');
  CollectionReference get musicaRef => ref.collection('musica');
  CollectionReference get juegosRef => ref.collection('juegos');
  CollectionReference get citasRef => ref.collection('citas');
  CollectionReference get rutasRef => ref.collection('rutas');
  CollectionReference get todoRef => ref.collection('todo');

  Future<void> init() async {
    _startListening();
    await _loadOnce();
  }

  void _startListening() {
    _parejaSub?.cancel();
    _parejaSub = _parejaDoc.snapshots().listen((snap) {
      if (snap.exists) {
        _parejaData = snap.data() as Map<String, dynamic>?;
        if (_parejaData != null) _parejaData!['id'] = snap.id;
        _cacheLocally();
        _loaded = true;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('[CoupleService] Stream error: $e');
    });
  }

  Future<void> _loadOnce() async {
    try {
      final snap = await _parejaDoc.get();
      if (snap.exists) {
        _parejaData = snap.data() as Map<String, dynamic>?;
        if (_parejaData != null) _parejaData!['id'] = snap.id;
        _cacheLocally();
        _loaded = true;
        notifyListeners();
      } else {
        await ensureParejaDocExists();
      }
    } catch (e) {
      debugPrint('[CoupleService] Load error: $e');
      _loadFromCache();
    }
  }

  void _cacheLocally() {
    if (_parejaData == null) return;
    LocalStorage().setString('cached_pareja_data', _parejaData.toString());
  }

  void _loadFromCache() {
    final cached = LocalStorage().getString('cached_pareja_data');
    if (cached != null) {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> ensureParejaDocExists() async {
    try {
      final snap = await _parejaDoc.get();
      if (!snap.exists) {
        await _parejaDoc.set({
          'nombre': coupleDisplayName,
          'fechaRelacion': DateTime.now().toIso8601String(),
          'miembros': [diegoUid, yosmariUid],
          'creado': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[CoupleService] Error ensuring doc: $e');
    }
  }

  Future<void> migrateOldData() async {
    final db = FirebaseFirestore.instance;
    try {
      final ids = [diegoUid, yosmariUid]..sort();
      final oldCoupleId = ids.join('_');
      final oldCouplesRef = db.collection('couples').doc(oldCoupleId);

      final oldSnap = await oldCouplesRef.get();
      if (!oldSnap.exists) return;

      final oldMessages = await oldCouplesRef.collection('messages').limit(500).get();
      for (final doc in oldMessages.docs) {
        final newRef = chatRef.doc(doc.id);
        final newSnap = await newRef.get();
        if (!newSnap.exists) {
          await newRef.set(doc.data(), SetOptions(merge: true));
        }
      }

      final oldLists = await oldCouplesRef.collection('lists').get();
      for (final listDoc in oldLists.docs) {
        final data = listDoc.data();
        if (data.containsKey('items')) {
          await db.collection('parejas').doc(parejaId)
              .collection('listas').doc(listDoc.id)
              .set(data, SetOptions(merge: true));
        }
      }

      final oldGames = await oldCouplesRef.collection('games').limit(100).get();
      for (final doc in oldGames.docs) {
        final newRef = juegosRef.doc(doc.id);
        final newSnap = await newRef.get();
        if (!newSnap.exists) {
          await newRef.set(doc.data(), SetOptions(merge: true));
        }
      }

      final oldActivities = await oldCouplesRef.collection('activities').limit(100).get();
      for (final doc in oldActivities.docs) {
        final newRef = notificacionesRef.doc(doc.id);
        final newSnap = await newRef.get();
        if (!newSnap.exists) {
          await newRef.set(doc.data(), SetOptions(merge: true));
        }
      }

      final oldData = oldSnap.data()!;
      final dateFields = ['metDate', 'datingDate', 'anniversaryDate', 'weddingDate'];
      final updateData = <String, dynamic>{};
      for (final field in dateFields) {
        if (oldData.containsKey(field)) {
          updateData[field] = oldData[field];
        }
      }
      if (oldData.containsKey('names')) updateData['names'] = oldData['names'];
      if (updateData.isNotEmpty) {
        await _parejaDoc.set(updateData, SetOptions(merge: true));
      }

      for (final uid in [diegoUid, yosmariUid]) {
        final oldUserDoc = await db.collection('users').doc(uid).get();
        if (oldUserDoc.exists) {
          final userData = oldUserDoc.data()!;
          final usuarioData = <String, dynamic>{
            'nombre': userData['name'] ?? (uid == diegoUid ? diegoName : yosmariName),
            'correo': userData['email'] ?? (uid == diegoUid ? diegoEmail : yosmariEmail),
            'parejaId': parejaId,
          };
          if (userData.containsKey('birthdayDate')) usuarioData['fechaNacimiento'] = userData['birthdayDate'];
          if (userData.containsKey('profilePhotoUrl')) usuarioData['foto'] = userData['profilePhotoUrl'];
          await db.collection('usuarios').doc(uid).set(usuarioData, SetOptions(merge: true));
        }
      }

      debugPrint('[CoupleService] Migration completed');
    } catch (e) {
      debugPrint('[CoupleService] Migration error: $e');
    }
  }

  Stream<DocumentSnapshot> streamPareja() => _parejaDoc.snapshots();

  Stream<QuerySnapshot> streamCollection(CollectionReference ref) => ref.snapshots();

  Future<void> addDocument(CollectionReference ref, Map<String, dynamic> data) async {
    await ref.add({
      ...data,
      'creadoPor': currentUid,
      'creado': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDocument(DocumentReference ref, Map<String, dynamic> data) async {
    await ref.set({
      ...data,
      'actualizadoPor': currentUid,
      'actualizado': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDocument(DocumentReference ref) async {
    await ref.delete();
  }

  // ─── Ubicación en tiempo real ───
  DocumentReference get myUbicacionRef => ubicacionRef.doc(currentUid);
  DocumentReference get partnerUbicacionRef => ubicacionRef.doc(partnerUid);

  Future<void> updateUbicacion({
    required double lat,
    required double lng,
    double? speed,
    int? battery,
  }) async {
    try {
      await myUbicacionRef.set({
        'lat': lat,
        'lng': lng,
        'latitude': lat,
        'longitude': lng,
        'speed': speed ?? 0,
        'battery': battery ?? -1,
        'batteryLevel': battery ?? -1,
        'isOnline': true,
        'timestamp': FieldValue.serverTimestamp(),
        'lastLocationUpdate': DateTime.now().toIso8601String(),
        'uid': currentUid,
        'nombre': currentName,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CoupleService] Error updating ubicacion: $e');
    }
  }

  Future<void> setOffline() async {
    try {
      await myUbicacionRef.set({'isOnline': false}, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<DocumentSnapshot> streamPartnerUbicacion() =>
      partnerUbicacionRef.snapshots();

  Stream<DocumentSnapshot> streamUbicacion(String uid) =>
      ubicacionRef.doc(uid).snapshots();

  // ─── Usuarios ───
  DocumentReference get myUserRef =>
      FirebaseFirestore.instance.collection('usuarios').doc(currentUid);

  DocumentReference get partnerUserRef =>
      FirebaseFirestore.instance.collection('usuarios').doc(partnerUid);

  Stream<DocumentSnapshot> streamPartnerUser() => partnerUserRef.snapshots();

  Future<void> updateMyUser(Map<String, dynamic> data) async {
    try {
      await myUserRef.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CoupleService] Error updating user: $e');
    }
  }

  // ─── Chat ───
  Future<void> sendMessage(Map<String, dynamic> msg) async {
    try {
      await chatRef.add({
        ...msg,
        'senderId': currentUid,
        'senderName': currentName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[CoupleService] Error sending message: $e');
    }
  }

  Stream<QuerySnapshot> streamMessages() =>
      chatRef.orderBy('timestamp', descending: true).snapshots();

  @override
  void dispose() {
    _parejaSub?.cancel();
    super.dispose();
  }
}
