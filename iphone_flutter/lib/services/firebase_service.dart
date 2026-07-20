import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/memory_model.dart';
import '../models/journal_model.dart';
import '../models/goal_model.dart';
import '../models/capsule_model.dart';
import '../models/place_model.dart';
import '../models/planner_model.dart';
import '../models/zone_model.dart';
import 'local_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static final StreamController<String> _listUpdateCtrl = StreamController<String>.broadcast();
  static Stream<String> get listUpdateStream => _listUpdateCtrl.stream;
  static void notifyListUpdated(String key) {
    _listUpdateCtrl.add(key);
  }

  bool _firebaseAvailable = false;
  bool get isFirebaseAvailable => _firebaseAvailable;

  static bool _usingBackup = false;
  static bool get isUsingBackup => _usingBackup;

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  FirebaseFirestore get _db => db;

  Future<void> _attemptRestore() async {
    try {
      await _db.collection('_health').doc('_check').get().timeout(const Duration(seconds: 5));
      _firebaseAvailable = true;
      _consecutiveErrors = 0;
      _restoreAttempt = 0;
      _resetHealth();
      debugPrint("[FBHealth] Firebase available again");
    } catch (e) {
      debugPrint("[FBHealth] Still unavailable: $e");
      _scheduleRestore();
    }
  }

  void _resetHealth() {
    _consecutiveErrors = 0;
    _restoreTimer?.cancel();
    _restoreAttempt = 0;
    if (_firebaseAvailable) {
      _healthCtrl.add(true);
    }
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // ─────────── Firestore health & backup ───────────
  static const int _maxConsecutiveErrors = 2;
  int _consecutiveErrors = 0;
  Timer? _restoreTimer;
  int _restoreAttempt = 0;
  static final StreamController<bool> _healthCtrl = StreamController<bool>.broadcast();
  static Stream<bool> get healthStream => _healthCtrl.stream;

  static void recordError(Object error) {
    _instance._recordFirestoreError(error);
  }

  void _recordFirestoreError(Object error) {
    _consecutiveErrors++;
    debugPrint("[FBHealth] Error #$_consecutiveErrors: $error");
    final errStr = error.toString();
    if (errStr.contains('RESOURCE_EXHAUSTED') || errStr.contains('Quota exceeded')) {
      if (!_usingBackup) {
        debugPrint("[FBHealth] QUOTA EXHAUSTED — switching to BACKUP project");
        _usingBackup = true;
        LocalStorage().setBool('firebase_use_backup', true);
        _consecutiveErrors = 0;
        _firebaseAvailable = true;
        _healthCtrl.add(true);
        return;
      } else {
        debugPrint("[FBHealth] BACKUP also exhausted — degrading");
      }
    }
    if (_consecutiveErrors >= _maxConsecutiveErrors && _firebaseAvailable) {
      _degradeFirebase();
    }
  }

  void _degradeFirebase() {
    debugPrint("[FBHealth] Degrading to unavailable");
    _firebaseAvailable = false;
    _healthCtrl.add(false);
    _listSub?.cancel();
    _listSub = null;
    _listRetryTimer?.cancel();
    _listRetryTimer = null;
    _restoreAttempt = 0;
    _scheduleRestore();
  }

  void _scheduleRestore() {
    _restoreTimer?.cancel();
    _restoreAttempt++;
    const delays = [30, 60, 120, 300, 900];
    final idx = (_restoreAttempt - 1).clamp(0, delays.length - 1);
    final delay = delays[idx];
    debugPrint("[FBHealth] Retry in ${delay}s (attempt $_restoreAttempt)");
    _restoreTimer = Timer(Duration(seconds: delay), _attemptRestore);
  }

  String get _coupleId {
    final myUid = _auth.currentUser?.uid;
    final partnerUid = LocalStorage().getString('partner_uid');
    if (myUid != null && partnerUid != null && partnerUid.isNotEmpty) {
      final ids = [myUid, partnerUid]..sort();
      return ids.join('_');
    }
    final id = LocalStorage().getString('couple_id');
    return (id != null && id.isNotEmpty) ? id : 'default_couple_id';
  }
  String get coupleId => _coupleId;

  Future<void> init() async {
    LocalStorage().onSaveList = _onSaveListToFirebase;
    final savedBackup = LocalStorage().getBool('firebase_use_backup');
    if (savedBackup == true) {
      _usingBackup = true;
      debugPrint("[FBHealth] Restored backup mode from storage");
    }
    _checkInitialReachability();
  }

  Future<void> _checkInitialReachability() async {
    try {
      _firebaseAvailable = true;
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
          debugPrint("[FirebaseService] Signed in anonymously: ${_auth.currentUser?.uid}");
        } catch (e) {
          debugPrint("[FirebaseService] Anonymous auth warning: $e");
        }
      }
      debugPrint("Firebase initialized and ready. User: ${_auth.currentUser?.uid ?? 'anonymous'}");
      _startListListener();
      _startHealthCheck();
    } catch (e) {
      _firebaseAvailable = true;
      debugPrint("Firebase initialized with fallback: $e");
    }
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 300), (_) async {
      if (_restoreTimer != null) return;
      try {
        await _db.collection('_health').doc('_check').get().timeout(const Duration(seconds: 5));
        if (!_firebaseAvailable) {
          _firebaseAvailable = true;
          _resetHealth();
          debugPrint("[FBHealth] Firebase available again");
          _startListListener();
        }
      } catch (e) {
        if (_firebaseAvailable) {
          _consecutiveErrors++;
          debugPrint("[FBHealth] Health check failed ($_consecutiveErrors): $e");
          if (_consecutiveErrors >= _maxConsecutiveErrors) {
            _degradeFirebase();
          }
        }
      }
    });
  }

  StreamSubscription? _listSub;
  Timer? _listRetryTimer;
  Timer? _healthCheckTimer;

  void restartListListener() {
    _startListListener();
  }

  void _startListListener() {
    _listSub?.cancel();
    _listRetryTimer?.cancel();
    final coupleId = _coupleId;
    if (coupleId == 'default_couple_id' || coupleId.isEmpty || !_firebaseAvailable) {
      _listRetryTimer = Timer(const Duration(seconds: 5), _startListListener);
      return;
    }
    try {
      _listSub = _db.collection('couples').doc(coupleId)
          .collection('lists').snapshots().listen((snap) async {
        for (final change in snap.docChanges) {
          if (change.type == DocumentChangeType.modified ||
              change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null && data.containsKey('items') && data['items'] is List) {
              final items = (data['items'] as List).cast<Map<String, dynamic>>();
              // Save to LocalStorage without triggering onSaveList callback (avoid loop)
              final prefs = LocalStorage();
              final savedCallback = prefs.onSaveList;
              prefs.onSaveList = null;
              await prefs.saveLocalList(change.doc.id, items);
              prefs.onSaveList = savedCallback;
              FirebaseService.notifyListUpdated(change.doc.id);
            }
          }
        }
      }, onError: (err) {
        debugPrint("List listener onError: $err");
        _recordFirestoreError(err);
        _listRetryTimer?.cancel();
        _listRetryTimer = Timer(const Duration(seconds: 10), _startListListener);
      });
    } catch (e) {
      debugPrint("Exception in _startListListener: $e");
      _recordFirestoreError(e);
      _listRetryTimer?.cancel();
      _listRetryTimer = Timer(const Duration(seconds: 10), _startListListener);
    }
  }

  Future<void> _onSaveListToFirebase(String key, List<Map<String, dynamic>> items) async {
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId == 'default_couple_id') return;
    try {
      await _db.collection('couples').doc(coupleId)
          .collection('lists').doc(key).set({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error syncing list $key to Firebase: $e");
    }
  }

  // --- Auth & Profile ---
  Future<void> ensureAnonymousAuth() async {
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        debugPrint("Error in anonymous auth: $e");
      }
    }
  }
  String _generateRandomCode() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer('CP-');
    for (int i = 0; i < 4; i++) {
      buffer.write(chars[(now + i) % chars.length]);
    }
    return buffer.toString();
  }

  Future<void> saveUserProfile(String uid, String name, String? partnerName) async {
    if (!_firebaseAvailable) return;
    try {
      final ls = LocalStorage();
      final coupleId = ls.getString('couple_id') ?? 'default_couple_id';
      ls.setString('user_id', uid);
      ls.setString('user_name', name);
      if (partnerName != null && partnerName.isNotEmpty) {
        ls.setString('partner_name', partnerName);
      }

      // Query Firestore for the partner's UID dynamically within the couple if possible, or by name
      String? partnerUid;
      
      // First try to look up via couple members
      if (coupleId != 'default_couple_id') {
        final coupleDoc = await _db.collection('couples').doc(coupleId).get();
        if (coupleDoc.exists && coupleDoc.data() != null) {
          final members = coupleDoc.data()!['members'] as List<dynamic>? ?? [];
          for (final m in members) {
            if (m.toString() != uid) {
              partnerUid = m.toString();
              ls.setString('partner_uid', partnerUid);
              break;
            }
          }
        }
      }
      
      // If not found yet and we have partner name, query by name
      if (partnerUid == null && partnerName != null && partnerName.isNotEmpty) {
        final partnerQuery = await _db.collection('users')
            .where('name', isEqualTo: partnerName)
            .get();
        if (partnerQuery.docs.isNotEmpty) {
          partnerUid = partnerQuery.docs.first.id;
          ls.setString('partner_uid', partnerUid);
        }
      }

      final userMap = <String, dynamic>{
        'id': uid,
        'name': name,
        'coupleId': coupleId,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (partnerName != null) {
        userMap['partnerName'] = partnerName;
      }
      if (partnerUid != null) {
        userMap['partnerUid'] = partnerUid;
      }
      
      // Merge other info from LocalStorage (anniversary, birthday)
      final ann = ls.getString('anniversary_date');
      if (ann != null) {
        userMap['anniversaryDate'] = ann;
      }
      final bday = ls.getString('birthday_date');
      if (bday != null) {
        userMap['birthdayDate'] = bday;
      }

      await _db.collection('users').doc(uid).set(userMap, SetOptions(merge: true));

      // If partner is found, perform bidirectional link in their document too
      if (partnerUid != null) {
        final partnerUpdate = <String, dynamic>{'partnerUid': uid};
        // If we don't have partner name locally, look it up from partner's doc
        if (partnerName == null || partnerName.isEmpty) {
          final partnerDoc = await _db.collection('users').doc(partnerUid).get();
          if (partnerDoc.exists && partnerDoc.data() != null) {
            final pData = partnerDoc.data()!;
            final pName = pData['name'] as String?;
            if (pName != null) {
              ls.setString('partner_name', pName);
              userMap['partnerName'] = pName;
              await _db.collection('users').doc(uid).set({'partnerName': pName}, SetOptions(merge: true));
            }
          }
        }
        await _db.collection('users').doc(partnerUid).set(partnerUpdate, SetOptions(merge: true));
      }

      // Initialize/update the couple document
      if (coupleId != 'default_couple_id') {
        final namesList = <String>[name];
        if (partnerName != null && partnerName.isNotEmpty) {
          namesList.add(partnerName);
        }
        final coupleData = <String, dynamic>{
          'members': FieldValue.arrayUnion([uid]),
          'names': FieldValue.arrayUnion(namesList),
        };
        if (ann != null) {
          coupleData['anniversaryDate'] = ann;
        }
        await _db.collection('couples').doc(coupleId).set(coupleData, SetOptions(merge: true));
        
        if (partnerUid != null) {
          await _db.collection('couples').doc(coupleId).update({
            'members': FieldValue.arrayUnion([partnerUid]),
          });
        }
      }
    } catch (e) {
      debugPrint("Error saving user profile: $e");
    }
  }

  Future<UserModel?> initRelationship({
    required String name,
    required String partnerName,
    required DateTime anniversaryDate,
    String? partnerCode,
  }) async {
    String coupleId;
    if (partnerCode != null && partnerCode.trim().isNotEmpty) {
      coupleId = partnerCode.trim().toUpperCase();
    } else {
      coupleId = _generateRandomCode();
    }

    await LocalStorage().setString('couple_id', coupleId);
    await LocalStorage().setString('user_name', name);
    await LocalStorage().setString('partner_name', partnerName);
    await LocalStorage().setString('anniversary_date', anniversaryDate.toIso8601String());

    final localId = _auth.currentUser?.uid ?? 'local_user_id';
    final model = UserModel(
      id: localId,
      name: name,
      partnerName: partnerName,
      anniversaryDate: anniversaryDate,
      mood: 'Feliz',
      moodReason: 'Hola, amor!',
      emotionalWeather: 'Soleado',
      themeName: LocalStorage().getString('theme') ?? 'pink',
      customPrimaryColor: '#FF69B4',
      customSecondaryColor: '#FFC0CB',
      lovePoints: 100,
      coupleId: coupleId,
    );

    if (_firebaseAvailable) {
      try {
        if (_auth.currentUser == null) {
          await _auth.signInAnonymously();
        }
        final uid = _auth.currentUser!.uid;
        final updatedModel = model.copyWith(id: uid);

        // Save user profile
        await _db.collection('users').doc(uid).set(updatedModel.toMap(), SetOptions(merge: true));

        // Save relationship details
        await _db.collection('couples').doc(coupleId).set({
          'anniversaryDate': anniversaryDate.toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'names': FieldValue.arrayUnion([name, partnerName]),
        }, SetOptions(merge: true));

        // Try bidirectional linking if partner already exists
        try {
          final existing = await _db.collection('users')
              .where('coupleId', isEqualTo: coupleId)
              .get();
          for (final u in existing.docs) {
            if (u.id != uid) {
              await _db.collection('users').doc(uid).set({'partnerUid': u.id}, SetOptions(merge: true));
              await _db.collection('users').doc(u.id).set({'partnerUid': uid}, SetOptions(merge: true));
              break;
            }
          }
        } catch (_) {}

        return updatedModel;
      } catch (e) {
        debugPrint("Error initializing relationship in Firebase: $e");
      }
    }
    return model;
  }

  Future<void> linkCoupleCode(String partnerCode) async {
    final cleanCode = partnerCode.trim().toUpperCase();
    await LocalStorage().setString('couple_id', cleanCode);

    if (_firebaseAvailable && _auth.currentUser != null) {
      try {
        final uid = _auth.currentUser!.uid;
        final name = LocalStorage().getUserName() ?? 'Tu';
        await _db.collection('users').doc(uid).update({'coupleId': cleanCode, 'name': name});

        await _db.collection('couples').doc(cleanCode).set({
          'names': FieldValue.arrayUnion([name]),
        }, SetOptions(merge: true));

        // Try to link with partner already in this couple
        final users = await _db.collection('users')
            .where('coupleId', isEqualTo: cleanCode)
            .get();
        for (final u in users.docs) {
          if (u.id != uid) {
            await _db.collection('users').doc(uid).set({'partnerUid': u.id}, SetOptions(merge: true));
            await _db.collection('users').doc(u.id).set({'partnerUid': uid}, SetOptions(merge: true));

            // Load partner's data and couple data into LocalStorage
            final partnerDoc = await _db.collection('users').doc(u.id).get();
            if (partnerDoc.exists && partnerDoc.data() != null) {
              final pData = partnerDoc.data()!;
              final ls = LocalStorage();
              // Partner's name is the other user's name
              if (pData.containsKey('name') && pData['name'] != null) {
                ls.setString('partner_name', pData['name'] as String);
              }
              // Copy all date fields from partner
              if (pData.containsKey('anniversaryDate') && pData['anniversaryDate'] != null) {
                ls.setString('anniversary_date', pData['anniversaryDate'] as String);
              }
              if (pData.containsKey('metDate') && pData['metDate'] != null) {
                ls.setString('met_date', pData['metDate'] as String);
              }
              if (pData.containsKey('datingDate') && pData['datingDate'] != null) {
                ls.setString('dating_date', pData['datingDate'] as String);
              }
              if (pData.containsKey('weddingDate') && pData['weddingDate'] != null) {
                ls.setString('wedding_date', pData['weddingDate'] as String);
              }

              // Also update partner's doc with this user's name
              await _db.collection('users').doc(u.id).set({
                'partnerName': name,
              }, SetOptions(merge: true));
            }

            // Also load from couples document
            final coupleDoc = await _db.collection('couples').doc(cleanCode).get();
            if (coupleDoc.exists && coupleDoc.data() != null) {
              final cData = coupleDoc.data()!;
              final ls = LocalStorage();
              if (cData.containsKey('anniversaryDate') && cData['anniversaryDate'] != null) {
                ls.setString('anniversary_date', cData['anniversaryDate'] as String);
              }
              if (cData.containsKey('metDate') && cData['metDate'] != null) {
                ls.setString('met_date', cData['metDate'] as String);
              }
              if (cData.containsKey('datingDate') && cData['datingDate'] != null) {
                ls.setString('dating_date', cData['datingDate'] as String);
              }
              if (cData.containsKey('weddingDate') && cData['weddingDate'] != null) {
                ls.setString('wedding_date', cData['weddingDate'] as String);
              }
            }

            // Load lists (timeline events, important dates, etc.) from partner
            await loadAllListsToLocal();

            break;
          }
        }
      } catch (e) {
        debugPrint("Error linking couple code in Firebase: $e");
      }
    }
  }

  Future<void> createCouple(String coupleId, String uid, String name) async {
    if (!_firebaseAvailable) return;
    try {
      await _db.collection('users').doc(uid).set({
        'name': name,
        'coupleId': coupleId,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      await _db.collection('couples').doc(coupleId).set({
        'createdAt': DateTime.now().toIso8601String(),
        'members': FieldValue.arrayUnion([uid]),
        'names': FieldValue.arrayUnion([name]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error creating couple: $e");
    }
  }

  Future<bool> joinCouple(String coupleId, String uid, String name) async {
    if (!_firebaseAvailable) return false;
    try {
      final coupleDoc = await _db.collection('couples').doc(coupleId).get()
          .timeout(const Duration(seconds: 10));
      if (!coupleDoc.exists) return false;

      await _db.collection('users').doc(uid).set({
        'name': name,
        'coupleId': coupleId,
        'createdAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await _db.collection('couples').doc(coupleId).set({
        'members': FieldValue.arrayUnion([uid]),
        'names': FieldValue.arrayUnion([name]),
      }, SetOptions(merge: true));

      // Bidirectional link
      final coupleData = coupleDoc.data()!;
      final members = coupleData['members'] as List<dynamic>? ?? [];
      for (final m in members) {
        if (m.toString() != uid) {
          await _db.collection('users').doc(uid).set({'partnerUid': m.toString()}, SetOptions(merge: true));
          await _db.collection('users').doc(m.toString()).set({'partnerUid': uid}, SetOptions(merge: true));
          break;
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error joining couple: $e");
      return false;
    }
  }

  Future<String?> getPartnerNameFromCouple(String coupleId) async {
    if (!_firebaseAvailable) return null;
    try {
      final doc = await _db.collection('couples').doc(coupleId).get();
      if (!doc.exists) return null;
      final names = doc.data()!['names'] as List<dynamic>? ?? [];
      final myName = LocalStorage().getUserName();
      for (final n in names) {
        if (n.toString() != myName) return n.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> endRelationship() async {
    final coupleId = _coupleId;
    final uid = _auth.currentUser?.uid;
    if (!_firebaseAvailable || coupleId.isEmpty || uid == null) return;
    try {
      // Remove user from couple
      await _db.collection('couples').doc(coupleId).set({
        'members': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
      // Clear user's couple data
      await _db.collection('users').doc(uid).set({
        'coupleId': FieldValue.delete(),
        'partnerUid': FieldValue.delete(),
      }, SetOptions(merge: true));
      LocalStorage().setString('couple_id', '');
    } catch (e) {
      debugPrint("Error ending relationship: $e");
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (user.id.isEmpty || user.id == 'local_user_id') return;
    await LocalStorage().setString('user_name', user.name);
    if (user.partnerName != null) await LocalStorage().setString('partner_name', user.partnerName!);
    if (user.anniversaryDate != null) await LocalStorage().setString('anniversary_date', user.anniversaryDate!.toIso8601String());
    if (user.metDate != null) await LocalStorage().setString('met_date', user.metDate!.toIso8601String());
    if (user.datingDate != null) await LocalStorage().setString('dating_date', user.datingDate!.toIso8601String());
    if (user.weddingDate != null) await LocalStorage().setString('wedding_date', user.weddingDate!.toIso8601String());
    await LocalStorage().setString('theme', user.themeName);
    await LocalStorage().setInt('love_points', user.lovePoints);

    if (_firebaseAvailable && _auth.currentUser != null) {
      try {
        final data = user.toMap();
        data.removeWhere((key, value) => value == null);
        data['id'] = user.id;
        await _db.collection('users').doc(user.id).set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating user in Firebase: $e");
      }
    }
  }

   Future<void> updateUserPosition(String userId, double lat, double lng, {double? speed}) async {
    if (!_firebaseAvailable || _auth.currentUser == null || userId.isEmpty) return;
    try {
      final Map<String, dynamic> data = {
        'latitude': lat,
        'longitude': lng,
        'lastLocationUpdate': DateTime.now().toIso8601String(),
      };
      if (speed != null) {
        data['speed'] = speed;
      }
      await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating position: $e");
    }
  }

  Future<void> updateBatteryLevel(String userId, int level) async {
    if (!_firebaseAvailable || _auth.currentUser == null || userId.isEmpty) return;
    try {
      await _db.collection('users').doc(userId).set({
        'batteryLevel': level,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating battery: $e");
    }
  }


  Future<void> sendCheckIn(String userId, String userName, String message, double lat, double lng) async {
    if (!_firebaseAvailable) return;
    try {
      await _db.collection('couples').doc(_coupleId).collection('checkins').add({
        'userId': userId,
        'userName': userName,
        'message': message,
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error sending check-in: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> streamCheckIns() {
    if (!_firebaseAvailable) {
      return const Stream.empty();
    }
    return _db.collection('couples').doc(_coupleId).collection('checkins')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<String?> getPartnerId() async {
    final userId = LocalStorage().getUserId();
    if (userId == null || !_firebaseAvailable) return null;
    try {
      // Try direct partnerUid field first
      final myDoc = await _db.collection('users').doc(userId).get();
      final myData = myDoc.data();
      if (myData == null) return null;

      if (myData.containsKey('partnerUid') && myData['partnerUid'] != null) {
        return myData['partnerUid'] as String;
      }

      // Fallback: find another user with same coupleId
      final coupleId = myData['coupleId'] ?? _coupleId;
      if (coupleId == null || coupleId.toString().isEmpty) return null;

      final users = await _db.collection('users')
          .where('coupleId', isEqualTo: coupleId)
          .get();

      for (final u in users.docs) {
        if (u.id != userId) {
          final partnerId = u.id;
          // Store for future lookups
          await _db.collection('users').doc(userId).set({
            'partnerUid': partnerId,
          }, SetOptions(merge: true));
          await _db.collection('users').doc(partnerId).set({
            'partnerUid': userId,
          }, SetOptions(merge: true));
          return partnerId;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _syncUserToLocalStorage(UserModel user) {
    if (user.id.isEmpty) return; // Prevent overwriting with default/empty maps
    final ls = LocalStorage();
    ls.setString('user_id', user.id);
    if (user.name.isNotEmpty) ls.setString('user_name', user.name);
    if (user.partnerName != null && user.partnerName!.isNotEmpty) ls.setString('partner_name', user.partnerName!);
    if (user.anniversaryDate != null) ls.setString('anniversary_date', user.anniversaryDate!.toIso8601String());
    if (user.birthdayDate != null) ls.setString('birthday_date', user.birthdayDate!.toIso8601String());
    if (user.metDate != null) ls.setString('met_date', user.metDate!.toIso8601String());
    if (user.datingDate != null) ls.setString('dating_date', user.datingDate!.toIso8601String());
    if (user.weddingDate != null) ls.setString('wedding_date', user.weddingDate!.toIso8601String());
    ls.setString('theme', user.themeName);
    ls.setInt('love_points', user.lovePoints);
    ls.setString('mood', user.mood);
    ls.setString('mood_reason', user.moodReason);
    ls.setString('emotional_weather', user.emotionalWeather);
    if (user.coupleId != null && user.coupleId!.isNotEmpty) ls.setString('couple_id', user.coupleId!);
    if (user.partnerUid != null && user.partnerUid!.isNotEmpty) ls.setString('partner_uid', user.partnerUid!);
  }

  void _syncSettingsToLocalStorage(Map<String, dynamic>? settings) {
    if (settings == null) return;
    final ls = LocalStorage();
    if (settings['isDarkMode'] is bool) ls.setBool('is_dark_mode', settings['isDarkMode'] as bool);
    if (settings['fontFamily'] is String) ls.setString('font_family', settings['fontFamily'] as String);
    if (settings['aiMode'] is String) ls.setString('ai_mode', settings['aiMode'] as String);
    if (settings['homeCoverPhoto'] is String) ls.setString('home_cover_photo', settings['homeCoverPhoto'] as String);
    if (settings['streakCount'] is int) ls.setInt('streak_count', settings['streakCount'] as int);
    if (settings['lastStreakDate'] is String) ls.setString('last_streak_date', settings['lastStreakDate'] as String);
  }

  Future<void> saveAllSettings({
    bool? isDarkMode,
    String? fontFamily,
    String? aiMode,
    String? homeCoverPhoto,
    int? streakCount,
    String? lastStreakDate,
    String? deepseekApiKey,
  }) async {
    final ls = LocalStorage();
    if (isDarkMode != null) ls.setBool('is_dark_mode', isDarkMode);
    if (fontFamily != null) ls.setString('font_family', fontFamily);
    if (aiMode != null) ls.setString('ai_mode', aiMode);
    if (homeCoverPhoto != null) ls.setString('home_cover_photo', homeCoverPhoto);
    if (streakCount != null) ls.setInt('streak_count', streakCount);
    if (lastStreakDate != null) ls.setString('last_streak_date', lastStreakDate);
    if (deepseekApiKey != null) ls.setString('deepseek_api_key', deepseekApiKey);

    if (!_firebaseAvailable || _auth.currentUser == null) return;
    final Map<String, dynamic> settings = {};
    if (isDarkMode != null) settings['isDarkMode'] = isDarkMode;
    if (fontFamily != null) settings['fontFamily'] = fontFamily;
    if (aiMode != null) settings['aiMode'] = aiMode;
    if (homeCoverPhoto != null) settings['homeCoverPhoto'] = homeCoverPhoto;
    if (streakCount != null) settings['streakCount'] = streakCount;
    if (lastStreakDate != null) settings['lastStreakDate'] = lastStreakDate;
    if (deepseekApiKey != null) settings['deepseekApiKey'] = deepseekApiKey;
    if (settings.isNotEmpty) {
      try {
        await _db.collection('users').doc(_auth.currentUser!.uid).set({
          'settings': settings,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error saving settings: $e");
      }
    }
  }

  Stream<UserModel> streamUser(String userId) {
    if (!_firebaseAvailable || userId.isEmpty) {
      return Stream.value(UserModel(
        id: userId,
        name: LocalStorage().getUserName() ?? 'Tú',
        partnerName: LocalStorage().getPartnerName() ?? 'Mi Amor',
        anniversaryDate: DateTime.tryParse(LocalStorage().getAnniversaryDate() ?? ''),
        mood: LocalStorage().getString('mood') ?? 'Feliz',
        moodReason: LocalStorage().getString('mood_reason') ?? '',
        emotionalWeather: LocalStorage().getString('emotional_weather') ?? 'Soleado',
        themeName: LocalStorage().getString('theme') ?? 'pink',
        customPrimaryColor: '#FF69B4',
        customSecondaryColor: '#FFC0CB',
        lovePoints: LocalStorage().getInt('love_points', defaultValue: 100),
        coupleId: _coupleId,
      ));
    }
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      final user = UserModel.fromMap(data);
      _syncUserToLocalStorage(user);
      final ls = LocalStorage();
      if (data.containsKey('privacySettings') && data['privacySettings'] is Map) {
        final ps = data['privacySettings'] as Map<String, dynamic>;
        if (ps['shareLocation'] is bool) ls.setBool('privacy_share_location', ps['shareLocation'] as bool);
        if (ps['shareHistory'] is bool) ls.setBool('privacy_share_history', ps['shareHistory'] as bool);
        if (ps['shareBattery'] is bool) ls.setBool('privacy_share_battery', ps['shareBattery'] as bool);
        if (ps['shareSpeed'] is bool) ls.setBool('privacy_share_speed', ps['shareSpeed'] as bool);
        if (ps['shareGeofences'] is bool) ls.setBool('privacy_share_geofences', ps['shareGeofences'] as bool);
        if (ps['shareArrival'] is bool) ls.setBool('privacy_share_arrival', ps['shareArrival'] as bool);
      }
      if (data.containsKey('settings') && data['settings'] is Map) {
        _syncSettingsToLocalStorage(data['settings'] as Map<String, dynamic>);
      }
      return user;
    });
  }

  Future<void> loadUserFromFirestore(String uid) async {
    if (!_firebaseAvailable) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final user = UserModel.fromMap(data);
        _syncUserToLocalStorage(user);

        final ls = LocalStorage();
        if (data.containsKey('username') && (data['username'] as String).isNotEmpty) {
          ls.setString('username', data['username'] as String);
        }
        if (data.containsKey('dob') && (data['dob'] as String).isNotEmpty) {
          ls.setString('dob', data['dob'] as String);
        }
        if (data.containsKey('privacySettings') && data['privacySettings'] is Map) {
          final ps = data['privacySettings'] as Map<String, dynamic>;
          if (ps['shareLocation'] is bool) ls.setBool('privacy_share_location', ps['shareLocation'] as bool);
          if (ps['shareHistory'] is bool) ls.setBool('privacy_share_history', ps['shareHistory'] as bool);
          if (ps['shareBattery'] is bool) ls.setBool('privacy_share_battery', ps['shareBattery'] as bool);
          if (ps['shareSpeed'] is bool) ls.setBool('privacy_share_speed', ps['shareSpeed'] as bool);
          if (ps['shareGeofences'] is bool) ls.setBool('privacy_share_geofences', ps['shareGeofences'] as bool);
          if (ps['shareArrival'] is bool) ls.setBool('privacy_share_arrival', ps['shareArrival'] as bool);
        }
        if (data.containsKey('settings') && data['settings'] is Map) {
          _syncSettingsToLocalStorage(data['settings'] as Map<String, dynamic>);
        }

        // 1. Fetch partner name & birthday dynamically from partner's document if partnerUid is present
        final partnerUid = user.partnerUid ?? data['partnerUid'] as String?;
        if (partnerUid != null && partnerUid.isNotEmpty) {
          final partnerDoc = await _db.collection('users').doc(partnerUid).get();
          if (partnerDoc.exists && partnerDoc.data() != null) {
            final pData = partnerDoc.data()!;
            final pName = pData['name'] as String?;
            if (pName != null && pName.isNotEmpty) {
              ls.setString('partner_name', pName);
            }
            final pBday = pData['birthdayDate'] as String?;
            if (pBday != null && pBday.isNotEmpty) {
              ls.setString('partner_birthday_date', pBday);
            }
          }
        }

        // 2. Fetch dates from couples doc
        final coupleId = _coupleId.isNotEmpty && _coupleId != 'default_couple_id'
            ? _coupleId
            : (user.coupleId ?? data['coupleId'] as String? ?? ls.getString('couple_id') ?? '');
        if (coupleId.isNotEmpty && coupleId != 'default_couple_id') {
          var coupleDoc = await _db.collection('couples').doc(coupleId).get();
          if (!coupleDoc.exists) {
            if (coupleId.contains('_')) {
              final parts = coupleId.split('_');
              final myName = ls.getString('user_name') ?? 'Tú';
              final partnerName = ls.getString('partner_name') ?? 'Pareja';
              await _db.collection('couples').doc(coupleId).set({
                'createdAt': DateTime.now().toIso8601String(),
                'members': parts,
                'names': [myName, partnerName],
              }, SetOptions(merge: true));
              coupleDoc = await _db.collection('couples').doc(coupleId).get();
              debugPrint("[SELF_HEAL] Created missing couple document $coupleId in Firestore!");
            }
          }
          if (coupleDoc.exists && coupleDoc.data() != null) {
            final cd = coupleDoc.data()!;
            if (cd['metDate'] is String) ls.setString('met_date', cd['metDate'] as String);
            if (cd['datingDate'] is String) ls.setString('dating_date', cd['datingDate'] as String);
            if (cd['anniversaryDate'] is String) ls.setString('anniversary_date', cd['anniversaryDate'] as String);
            if (cd['weddingDate'] is String) ls.setString('wedding_date', cd['weddingDate'] as String);
            
            // Also sync names in couple document if missing
            final namesList = cd['names'] as List<dynamic>? ?? [];
            final myName = user.name;
            final partnerName = ls.getString('partner_name');
            final updateNames = <String>[];
            if (myName.isNotEmpty && !namesList.contains(myName)) updateNames.add(myName);
            if (partnerName != null && partnerName.isNotEmpty && !namesList.contains(partnerName)) updateNames.add(partnerName);
            if (updateNames.isNotEmpty) {
              await _db.collection('couples').doc(coupleId).set({
                'names': FieldValue.arrayUnion(updateNames)
              }, SetOptions(merge: true));
            }
          }
        }
      }
      try {
        await checkForAndPerformMigration();
      } catch (e) {
        debugPrint("Error performing migration: $e");
      }
      restartListListener();
    } catch (e) {
      debugPrint("Error loading user from Firestore: $e");
    }
  }

  Future<void> checkForAndPerformMigration() async {
    if (!_firebaseAvailable) return;
    final myUid = _auth.currentUser?.uid;
    final partnerUid = LocalStorage().getString('partner_uid');
    if (myUid == null || partnerUid == null || partnerUid.isEmpty) return;

    final ids = [myUid, partnerUid]..sort();
    final newId = ids.join('_');

    String? oldId = LocalStorage().getString('couple_id');
    
    // Auto-discover old couple ID if they already migrated but missed collections
    if (oldId == null || oldId == newId || oldId == 'default_couple_id') {
      try {
        final snap = await _db.collection('couples')
            .where('members', arrayContains: myUid)
            .get();
        for (final doc in snap.docs) {
          if (doc.id != newId && doc.id != 'default_couple_id' && doc.id.length < 15) {
            oldId = doc.id;
            debugPrint("[FB_MIGRATE] Auto-discovered old couple ID: $oldId");
            break;
          }
        }
      } catch (e) {
        debugPrint("[FB_MIGRATE] Error auto-discovering old ID: $e");
      }
    }

    if (oldId != null && oldId.isNotEmpty && oldId != newId && oldId != 'default_couple_id') {
      debugPrint("[FB_MIGRATE] Migrating data from $oldId to $newId");
      
      try {
        final collections = [
          'messages', 'memories', 'games', 'wishlist', 'dreams', 'planner', 
          'notes', 'letters', 'playlist', 'gifts', 'music_history', 'activities',
          'timeline', 'lists', 'journals', 'goals', 'places', 'zones', 'capsules', 'checkins'
        ];
        
        for (final coll in collections) {
          final oldSnap = await _db.collection('couples').doc(oldId).collection(coll).get();
          if (oldSnap.docs.isNotEmpty) {
            final newSnap = await _db.collection('couples').doc(newId).collection(coll).get();
            final newDocIds = newSnap.docs.map((d) => d.id).toSet();
            for (final doc in oldSnap.docs) {
              if (!newDocIds.contains(doc.id)) {
                await _db.collection('couples').doc(newId).collection(coll).doc(doc.id).set(doc.data());
              }
            }
          }
        }
        
        final coupleDoc = await _db.collection('couples').doc(oldId).get();
        if (coupleDoc.exists && coupleDoc.data() != null) {
          await _db.collection('couples').doc(newId).set(coupleDoc.data()!, SetOptions(merge: true));
        }

        await _db.collection('users').doc(myUid).update({'coupleId': newId});
        await _db.collection('users').doc(partnerUid).update({'coupleId': newId});

        await LocalStorage().setString('couple_id', newId);
        
        // Save dates to LocalStorage immediately after migration
        final newCoupleDoc = await _db.collection('couples').doc(newId).get();
        if (newCoupleDoc.exists && newCoupleDoc.data() != null) {
          final cd = newCoupleDoc.data()!;
          if (cd['metDate'] is String) await LocalStorage().setString('met_date', cd['metDate'] as String);
          if (cd['datingDate'] is String) await LocalStorage().setString('dating_date', cd['datingDate'] as String);
          if (cd['anniversaryDate'] is String) await LocalStorage().setString('anniversary_date', cd['anniversaryDate'] as String);
          if (cd['weddingDate'] is String) await LocalStorage().setString('wedding_date', cd['weddingDate'] as String);
        }
        
        debugPrint("[FB_MIGRATE] Migration completed successfully!");
      } catch (e) {
        debugPrint("[FB_MIGRATE] Error migrating data: $e");
      }
    }
  }

  Future<void> savePrivacySettings(Map<String, bool> settings) async {
    await LocalStorage().setBool('privacy_share_location', settings['shareLocation'] ?? true);
    await LocalStorage().setBool('privacy_share_history', settings['shareHistory'] ?? false);
    await LocalStorage().setBool('privacy_share_battery', settings['shareBattery'] ?? true);
    await LocalStorage().setBool('privacy_share_speed', settings['shareSpeed'] ?? false);
    await LocalStorage().setBool('privacy_share_geofences', settings['shareGeofences'] ?? true);
    await LocalStorage().setBool('privacy_share_arrival', settings['shareArrival'] ?? true);

    if (_firebaseAvailable && _auth.currentUser != null) {
      try {
        await _db.collection('users').doc(_auth.currentUser!.uid).set({
          'privacySettings': settings,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error saving privacy settings: $e");
      }
    }
  }

  Map<String, bool> getPrivacySettings() {
    return {
      'shareLocation': LocalStorage().getBool('privacy_share_location', defaultValue: true),
      'shareHistory': LocalStorage().getBool('privacy_share_history'),
      'shareBattery': LocalStorage().getBool('privacy_share_battery', defaultValue: true),
      'shareSpeed': LocalStorage().getBool('privacy_share_speed'),
      'shareGeofences': LocalStorage().getBool('privacy_share_geofences', defaultValue: true),
      'shareArrival': LocalStorage().getBool('privacy_share_arrival', defaultValue: true),
    };
  }

  // --- List Data (importantDates, calendarEvents, etc.) ---
  Future<void> saveListData(String listName, List<Map<String, dynamic>> items) async {
    await LocalStorage().saveLocalList(listName, items);
    // Note: saveLocalList triggers onSaveList callback which saves to couples/{coupleId}/lists/{key}
    // This direct Firebase save is for legacy compatibility
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId == 'default_couple_id') return;
    try {
      await _db.collection('couples').doc(coupleId)
          .collection('lists').doc(listName).set({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving list $listName: $e");
    }
  }

  Future<List<Map<String, dynamic>>> loadListData(String listName) async {
    // First try Firestore from couples collection
    final coupleId = _coupleId;
    if (_firebaseAvailable && coupleId != 'default_couple_id') {
      try {
        final doc = await _db.collection('couples').doc(coupleId)
            .collection('lists').doc(listName).get();
        if (doc.exists && doc.data() != null && doc.data()!['items'] is List) {
          final items = (doc.data()!['items'] as List).cast<Map<String, dynamic>>();
          await LocalStorage().saveLocalList(listName, items);
          return items;
        }
      } catch (e) {
        debugPrint("Error loading list $listName from Firestore: $e");
      }
    }
    // Try legacy user path (old data that hasn't been migrated)
    if (_firebaseAvailable && _auth.currentUser != null) {
      try {
        final doc = await _db.collection('users').doc(_auth.currentUser!.uid)
            .collection('lists').doc(listName).get();
        if (doc.exists && doc.data() != null && doc.data()!['items'] is List) {
          final items = (doc.data()!['items'] as List).cast<Map<String, dynamic>>();
          await LocalStorage().saveLocalList(listName, items);
          // Migrate to new couples path
          if (coupleId != 'default_couple_id') {
            await _db.collection('couples').doc(coupleId)
                .collection('lists').doc(listName).set({
              'items': items,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          return items;
        }
      } catch (e) {
        debugPrint("Error loading list $listName from legacy path: $e");
      }
    }
    // Fallback to local
    return LocalStorage().getLocalList(listName);
  }

  Future<void> loadAllListsToLocal() async {
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId == 'default_couple_id') {
      // Fallback: try all known list keys from LocalStorage
      final knownKeys = [
        'important_dates', 'calendar_events', 'voice_mailbox',
        'favorite_gifs', 'sent_gifts', 'wishlist', 'letters',
        'dreams_list', 'timeline_events', 'notes_list'
      ];
      for (final key in knownKeys) {
        await loadListData(key);
      }
      return;
    }
    try {
      final docs = await _db.collection('couples').doc(coupleId)
          .collection('lists').get();
      for (final doc in docs.docs) {
        final data = doc.data();
        if (data.containsKey('items') && data['items'] is List) {
          final items = (data['items'] as List).cast<Map<String, dynamic>>();
          await LocalStorage().saveLocalList(doc.id, items);
        }
      }
    } catch (e) {
      debugPrint("Error loading all lists from Firestore: $e");
    }
  }

  // --- Shared Activity Notifications ---
  Future<void> sendActivityNotification(String text, String type, {String? icon}) async {
    if (!_firebaseAvailable) return;
    try {
      final name = LocalStorage().getUserName() ?? 'Tu pareja';
      await _db.collection('couples').doc(_coupleId).collection('activities').add({
        'title': name,
        'text': text,
        'type': type,
        'icon': icon ?? 'info',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> streamActivityNotifications() {
    if (!_firebaseAvailable) {
      return const Stream.empty();
    }
    return _db.collection('couples').doc(_coupleId).collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              // Format Timestamp to DateTime
              if (data['timestamp'] is Timestamp) {
                data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
              } else {
                data['timestamp'] = DateTime.now();
              }
              return data;
            }).toList());
  }

  // --- Realtime Chat ---
  Future<void> sendMessage(MessageModel msg) async {
    // Siempre guardar localmente como respaldo
    final localList = LocalStorage().getLocalList('messages');
    localList.add(msg.toMap());
    await LocalStorage().saveLocalList('messages', localList);
    FirebaseService.notifyListUpdated('messages');

    if (!_firebaseAvailable) {
      debugPrint("[sendMessage] Firebase NO disponible — mensaje solo LOCAL (senderId=${msg.senderId})");
      return;
    }
    try {
      debugPrint("[sendMessage] Enviando a Firestore: couples/$_coupleId/messages/${msg.id}");
      await _db.collection('couples').doc(_coupleId).collection('messages').doc(msg.id).set(msg.toMap());

      // También enviar notificación al partner via su documento de usuario
      _sendMessageNotificationToPartner(msg);
    } catch (e) {
      debugPrint("[sendMessage] Error en Firestore: $e — mensaje solo LOCAL");
    }
  }

  Future<void> _sendMessageNotificationToPartner(MessageModel msg) async {
    try {
      final partnerUid = LocalStorage().getString('partner_uid');
      if (partnerUid == null || partnerUid.isEmpty) return;
      String preview = msg.text;
      if (msg.type == 'voice') {
        preview = '🎤 Nota de voz';
      } else if (msg.type == 'photo' || msg.type == 'image') {
        preview = '🖼️ Foto';
      } else if (msg.type == 'video') {
        preview = '🎬 Video';
      }
      if (preview.length > 100) preview = '${preview.substring(0, 97)}...';
      await _db.collection('users').doc(partnerUid).set({
        'lastNotification': {
          'app': 'EverUs Chat',
          'title': LocalStorage().getUserName() ?? 'Tu pareja',
          'text': preview,
        },
        'lastNotificationTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> markMessageRead(String messageId) async {
    // 1. Update locally
    final list = LocalStorage().getLocalList('messages');
    var updated = false;
    final nowStr = DateTime.now().toIso8601String();
    for (var i = 0; i < list.length; i++) {
      if (list[i]['id'] == messageId) {
        list[i]['readTimestamp'] = nowStr;
        updated = true;
        break;
      }
    }
    if (updated) {
      await LocalStorage().saveLocalList('messages', list);
      notifyListUpdated('messages');
    }

    // 2. Update Firestore
    if (!_firebaseAvailable) return;
    try {
      await _db.collection('couples').doc(_coupleId).collection('messages').doc(messageId).update({
        'readTimestamp': nowStr,
      });
    } catch (e) {
      debugPrint("Error marking message read: $e");
    }
  }

  Future<void> reactToMessage(String messageId, String emoji, {bool remove = false}) async {
    final userId = LocalStorage().getUserId() ?? 'anon';
    final list = LocalStorage().getLocalList('messages');
    var updated = false;
    for (var i = 0; i < list.length; i++) {
      if (list[i]['id'] == messageId) {
        final reactions = Map<String, dynamic>.from(list[i]['reactions'] as Map? ?? {});
        if (remove) {
          reactions.remove(userId);
        } else {
          reactions[userId] = emoji;
        }
        list[i]['reactions'] = reactions;
        updated = true;
        break;
      }
    }
    if (updated) {
      await LocalStorage().saveLocalList('messages', list);
      notifyListUpdated('messages');
    }
    if (!_firebaseAvailable) return;
    try {
      await _db.collection('couples').doc(_coupleId).collection('messages').doc(messageId).update({
        'reactions.$userId': remove ? FieldValue.delete() : emoji,
      });
    } catch (e) {
      debugPrint("Error reacting to message: $e");
    }
  }

  Future<void> deleteExpiredMessages() async {
    if (!_firebaseAvailable) return;
    try {
      final now = DateTime.now();
      final snapshot = await _db.collection('couples').doc(_coupleId)
          .collection('messages')
          .where('isDisappearing', isEqualTo: true)
          .where('readTimestamp', isNotEqualTo: null)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        DateTime? readTs;
        final rawTs = data['readTimestamp'];
        if (rawTs is String) {
          readTs = DateTime.tryParse(rawTs);
        } else if (rawTs is Timestamp) {
          readTs = rawTs.toDate();
        }
        if (readTs == null) continue;
        
        final duration = data['disappearDurationSeconds'] ?? 0;
        if (now.isAfter(readTs.add(Duration(seconds: duration)))) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint("Error deleting expired messages: $e");
    }
  }

  Stream<int> streamUnreadMessagesCount() {
    final userId = LocalStorage().getUserId() ?? 'local_user_id';
    // Count from local data every 5s instead of a Firestore listener
    return Stream.periodic(const Duration(seconds: 5), (_) {
      final list = LocalStorage().getLocalList('messages');
      return list.where((m) {
        return m['senderId'] != userId && m['readTimestamp'] == null;
      }).length;
    }).distinct();
  }

  Stream<List<MessageModel>> streamMessages() {
    final controller = StreamController<List<MessageModel>>.broadcast();
    StreamSubscription? fsSub;
    StreamSubscription? localSub;

    List<MessageModel> getMergedList(List<MessageModel> firestoreMsgs) {
      final localList = LocalStorage().getLocalList('messages');
      final localMsgs = localList.map((m) => MessageModel.fromMap(m)).toList();
      final merged = <String, MessageModel>{};
      for (final m in firestoreMsgs) {
        merged[m.id] = m;
      }
      for (final m in localMsgs) {
        if (!merged.containsKey(m.id)) {
          merged[m.id] = m;
        }
      }
      return merged.values.toList()
        ..removeWhere((m) => m.shouldBeDeleted)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    void emitCurrent() {
      if (controller.isClosed) return;
      final list = LocalStorage().getLocalList('messages');
      final messages = list.map((m) => MessageModel.fromMap(m)).toList()
        ..removeWhere((m) => m.shouldBeDeleted)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      controller.add(messages.take(200).toList());
    }

    // Emit initial local data immediately so there is no blank screen
    emitCurrent();

    // Listen to local changes
    localSub = listUpdateStream.listen((key) {
      if (key == 'messages') {
        emitCurrent();
      }
    });

    // Periodic check every 2 seconds to delete expired disappearing messages locally and from Firestore
    Timer? cleanupTimer;
    cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (controller.isClosed) {
        cleanupTimer?.cancel();
        return;
      }
      final list = LocalStorage().getLocalList('messages');
      final msgs = list.map((m) => MessageModel.fromMap(m)).toList();
      final beforeCount = msgs.length;
      
      msgs.removeWhere((m) {
        if (m.shouldBeDeleted) {
          if (_firebaseAvailable) {
            _db.collection('couples').doc(_coupleId).collection('messages').doc(m.id).delete().catchError((_) {});
          }
          return true;
        }
        return false;
      });

      if (msgs.length != beforeCount) {
        LocalStorage().saveLocalList('messages', msgs.map((m) => m.toMap()).toList());
        emitCurrent();
      }
    });

    if (_firebaseAvailable) {
      try {
        fsSub = _db.collection('couples').doc(_coupleId).collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(200)
            .snapshots()
            .listen((snapshot) {
          final firestoreMsgs = snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
          
          // Sync readTimestamps and deletion states back to LocalStorage
          final localList = LocalStorage().getLocalList('messages');
          final localMsgs = localList.map((m) => MessageModel.fromMap(m)).toList();
          bool localUpdated = false;
          
          for (final fMsg in firestoreMsgs) {
            final lIndex = localMsgs.indexWhere((m) => m.id == fMsg.id);
            if (lIndex != -1) {
              if (localMsgs[lIndex].readTimestamp != fMsg.readTimestamp) {
                localMsgs[lIndex] = localMsgs[lIndex].copyWith(readTimestamp: fMsg.readTimestamp);
                localUpdated = true;
              }
            } else {
              localMsgs.add(fMsg);
              localUpdated = true;
            }
          }
          
          // If a disappearing message is no longer in Firestore (deleted by partner), delete it locally
          final firestoreIds = firestoreMsgs.map((m) => m.id).toSet();
          final beforeLength = localMsgs.length;
          localMsgs.removeWhere((m) => m.isDisappearing && !firestoreIds.contains(m.id));
          if (localMsgs.length != beforeLength) {
            localUpdated = true;
          }

          if (localUpdated) {
            LocalStorage().saveLocalList('messages', localMsgs.map((m) => m.toMap()).toList());
          }

          final merged = getMergedList(firestoreMsgs);
          if (!controller.isClosed) {
            controller.add(merged);
          }
        }, onError: (err) {
          debugPrint("[streamMessages] Error Firestore: $err");
          emitCurrent();
        });
      } catch (e) {
        debugPrint("[streamMessages] Exception: $e");
        emitCurrent();
      }
    }

    controller.onCancel = () {
      fsSub?.cancel();
      localSub?.cancel();
      cleanupTimer?.cancel();
    };

    return controller.stream;
  }

  // --- Memories ---
  Future<void> addMemory(MemoryModel memory) async {
    // Always save locally first
    final list = LocalStorage().getLocalList('memories');
    list.add(memory.toMap());
    await LocalStorage().saveLocalList('memories', list);

    // Try Firebase sync if available
    if (_firebaseAvailable) {
      try {
        await _db.collection('couples').doc(_coupleId).collection('memories').doc(memory.id).set(memory.toMap());
      } catch (_) {}
    }
  }

  Stream<List<MemoryModel>> streamMemories() {
    final controller = StreamController<List<MemoryModel>>();
    
    // Emit current local data immediately
    final localList = LocalStorage().getLocalList('memories')
        .map((m) => MemoryModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    controller.add(localList);

    StreamSubscription? sub;
    if (_firebaseAvailable) {
      sub = _db.collection('couples').doc(_coupleId).collection('memories')
          .snapshots()
          .listen((snapshot) {
        final firestoreList = snapshot.docs.map((doc) => MemoryModel.fromMap(doc.data())).toList();
        final currentLocal = LocalStorage().getLocalList('memories')
            .map((m) => MemoryModel.fromMap(m))
            .toList();
        final merged = <String, MemoryModel>{};
        for (final m in currentLocal) { merged[m.id] = m; }
        for (final m in firestoreList) { merged[m.id] = m; }
        final all = merged.values.toList()..sort((a, b) => b.date.compareTo(a.date));
        LocalStorage().saveLocalList('memories', all.map((m) => m.toMap()).toList());
        if (!controller.isClosed) {
          controller.add(all);
        }
      }, onError: (err) {
        debugPrint("Error streaming memories: $err");
      });
    }

    controller.onCancel = () {
      sub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<bool> deleteMemory(String id) async {
    final list = LocalStorage().getLocalList('memories');
    final memory = list.firstWhere((m) => m['id'] == id, orElse: () => <String, dynamic>{});
    list.removeWhere((m) => m['id'] == id);
    await LocalStorage().saveLocalList('memories', list);

    bool deleted = true;
    if (_firebaseAvailable) {
      try {
        await _db.collection('couples').doc(_coupleId).collection('memories').doc(id).delete();
      } catch (e) {
        debugPrint("Error deleting memory: $e");
        deleted = false;
      }

      // Limpiar archivos de foto asociados
      if (memory.containsKey('mediaPaths')) {
        final paths = List<String>.from(memory['mediaPaths'] ?? []);
        for (final path in paths) {
          if (path.startsWith('firestore://')) {
            try {
              final parts = path.replaceFirst('firestore://', '').split('/');
              if (parts.length >= 4) {
                await _db.collection(parts[0]).doc(parts[1]).collection(parts[2]).doc(parts[3]).delete();
              }
            } catch (_) {}
          }
        }
      }
    }

    FirebaseService.notifyListUpdated('memories');
    return deleted;
  }

  // --- Diario ---
  Future<void> saveJournal(JournalModel journal) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('journals');
      list.removeWhere((item) => item['dateKey'] == journal.dateKey && item['authorId'] == journal.authorId);
      list.add(journal.toMap());
      await LocalStorage().saveLocalList('journals', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('journals').doc('${journal.dateKey}_${journal.authorId}').set(journal.toMap());
    } catch (e) {
      debugPrint("Error saving journal: $e");
    }
  }

  Stream<List<JournalModel>> streamJournals() {
    if (!_firebaseAvailable) {
      return Stream.value(
        LocalStorage().getLocalList('journals')
            .map((j) => JournalModel.fromMap(j))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
      );
    }
    return _db.collection('couples').doc(_coupleId).collection('journals')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => JournalModel.fromMap(doc.data())).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  // --- Metas / Sueños ---
  Future<void> saveGoal(GoalModel goal) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('goals');
      list.removeWhere((item) => item['id'] == goal.id);
      list.add(goal.toMap());
      await LocalStorage().saveLocalList('goals', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('goals').doc(goal.id).set(goal.toMap());
    } catch (e) {
      debugPrint("Error saving goal: $e");
    }
  }

  Stream<List<GoalModel>> streamGoals() {
    if (!_firebaseAvailable) {
      final local = LocalStorage().getLocalList('goals');
      if (local.isEmpty) {
        final defaultGoals = [
          GoalModel(id: 'g1', title: 'Viajar a Japón ✈️', category: 'travel', progress: 0.1, dateCreated: DateTime.now(), notes: 'Ir en primavera para ver los cerezos.'),
          GoalModel(id: 'g2', title: 'Comprar nuestra casa 🏡', category: 'home', progress: 0.05, dateCreated: DateTime.now(), notes: 'Con un jardín grande para jugar.'),
          GoalModel(id: 'g3', title: 'Tener un perrito 🐶', category: 'pet', progress: 0.3, dateCreated: DateTime.now(), notes: 'Queremos un Golden Retriever.'),
          GoalModel(id: 'g4', title: 'Casarnos', category: 'marriage', progress: 0.0, dateCreated: DateTime.now(), notes: 'Una boda en la playa.'),
        ];
        LocalStorage().saveLocalList('goals', defaultGoals.map((g) => g.toMap()).toList());
        return Stream.value(defaultGoals);
      }
      return Stream.value(local.map((g) => GoalModel.fromMap(g)).toList());
    }
    return _db.collection('couples').doc(_coupleId).collection('goals').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => GoalModel.fromMap(doc.data())).toList();
    });
  }

  // --- Lugares / Mapa ---
  Future<void> savePlace(PlaceModel place) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('places');
      list.removeWhere((item) => item['id'] == place.id);
      list.add(place.toMap());
      await LocalStorage().saveLocalList('places', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('places').doc(place.id).set(place.toMap());
    } catch (e) {
      debugPrint("Error saving place: $e");
    }
  }

  Future<void> deletePlace(String placeId) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('places');
      list.removeWhere((item) => item['id'] == placeId);
      await LocalStorage().saveLocalList('places', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('places').doc(placeId).delete();
    } catch (e) {
      debugPrint("Error deleting place: $e");
    }
  }

  Stream<List<PlaceModel>> streamPlaces() {
    if (!_firebaseAvailable) {
      return Stream.value(
        LocalStorage().getLocalList('places').map((p) => PlaceModel.fromMap(p)).toList()
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded))
      );
    }
    return _db.collection('couples').doc(_coupleId).collection('places').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => PlaceModel.fromMap(doc.data())).toList();
      list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return list;
    });
  }

  // --- Zonas Geocercas ---
  Future<void> saveZone(ZoneModel zone) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('zones');
      list.removeWhere((item) => item['id'] == zone.id);
      list.add(zone.toMap());
      await LocalStorage().saveLocalList('zones', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('zones').doc(zone.id).set(zone.toMap());
    } catch (e) {
      debugPrint("Error saving zone: $e");
    }
  }

  Future<void> deleteZone(String zoneId) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('zones');
      list.removeWhere((item) => item['id'] == zoneId);
      await LocalStorage().saveLocalList('zones', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('zones').doc(zoneId).delete();
    } catch (e) {
      debugPrint("Error deleting zone: $e");
    }
  }

  Stream<List<ZoneModel>> streamZones() {
    if (!_firebaseAvailable) {
      return Stream.value(
        LocalStorage().getLocalList('zones').map((z) => ZoneModel.fromMap(z)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
      );
    }
    return _db.collection('couples').doc(_coupleId).collection('zones').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ZoneModel.fromMap(doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // --- Planificador ---
  Future<void> savePlanner(PlannerModel item) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('planner');
      list.removeWhere((el) => el['id'] == item.id);
      list.add(item.toMap());
      await LocalStorage().saveLocalList('planner', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('planner').doc(item.id).set(item.toMap());
    } catch (e) {
      debugPrint("Error saving planner item: $e");
    }
  }

  Future<void> deletePlanner(String id) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('planner');
      list.removeWhere((el) => el['id'] == id);
      await LocalStorage().saveLocalList('planner', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('planner').doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting planner item: $e");
    }
  }

  Stream<List<PlannerModel>> streamPlanner() {
    if (!_firebaseAvailable) {
      return Stream.value(
        LocalStorage().getLocalList('planner').map((p) => PlannerModel.fromMap(p)).toList()
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded))
      );
    }
    return _db.collection('couples').doc(_coupleId).collection('planner').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => PlannerModel.fromMap(doc.data())).toList();
      list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return list;
    });
  }

  // --- Cápsulas del Tiempo ---
  Future<void> saveCapsule(CapsuleModel capsule) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('capsules');
      list.add(capsule.toMap());
      await LocalStorage().saveLocalList('capsules', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('capsules').doc(capsule.id).set(capsule.toMap());
    } catch (e) {
      debugPrint("Error saving capsule: $e");
    }
  }

  Stream<List<CapsuleModel>> streamCapsules() {
    if (!_firebaseAvailable) {
      return Stream.value(
        LocalStorage().getLocalList('capsules')
            .map((c) => CapsuleModel.fromMap(c))
            .toList()
          ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated))
      );
    }
    return _db.collection('couples').doc(_coupleId).collection('capsules').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => CapsuleModel.fromMap(doc.data())).toList();
      list.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      return list;
    });
  }

  // --- Timeline ---
  Future<void> saveTimelineEvent(Map<String, String> event) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('timeline');
      list.removeWhere((e) => e['year'] == event['year']);
      list.add(event);
      await LocalStorage().saveLocalList('timeline', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('timeline').doc(event['year']).set(event);
    } catch (e) {
      debugPrint("Error saving timeline event: $e");
    }
  }

  Future<void> deleteTimelineEvent(String year) async {
    if (!_firebaseAvailable) {
      final list = LocalStorage().getLocalList('timeline');
      list.removeWhere((e) => e['year'] == year);
      await LocalStorage().saveLocalList('timeline', list);
      return;
    }
    try {
      await _db.collection('couples').doc(_coupleId).collection('timeline').doc(year).delete();
    } catch (e) {
      debugPrint("Error deleting timeline event: $e");
    }
  }

  Stream<List<Map<String, String>>> streamTimeline() {
    if (!_firebaseAvailable) {
      return Stream.value(
        LocalStorage().getLocalList('timeline').map((e) => Map<String, String>.from(e)).toList()
          ..sort((a, b) => a['year']!.compareTo(b['year'] ?? '')),
      );
    }
    return _db.collection('couples').doc(_coupleId).collection('timeline')
        .orderBy('year')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Map<String, String>.from(doc.data())).toList();
    });
  }

  // --- Counts for achievements ---
  Future<int> getMessageCount() async {
    if (!_firebaseAvailable) return 0;
    try {
      final snap = await _db.collection('couples').doc(_coupleId).collection('messages').count().get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getMemoryCount() async {
    if (!_firebaseAvailable) return 0;
    try {
      final snap = await _db.collection('couples').doc(_coupleId).collection('memories').count().get();
      return snap.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // --- App tracking ---
  Future<void> updateCurrentApp(String appName) async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;
    if (!_firebaseAvailable) return;
    try {
      await _db.collection('users').doc(uid).set({
        'currentApp': appName,
        'lastAppUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> addNotificationLog(Map<String, dynamic> notif) async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;
    if (!_firebaseAvailable) return;

    final now = DateTime.now();
    final docId = '${now.millisecondsSinceEpoch}_${notif['app']?.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') ?? 'unknown'}';

    try {
      await _db.collection('users').doc(uid).collection('notification_logs').doc(docId).set({
        ...notif,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': now.toIso8601String(),
      });
    } catch (_) {}

    try {
      await _db.collection('users').doc(uid).update({
        'lastNotification': {
          ...notif,
          'time': now.millisecondsSinceEpoch,
        },
        'lastNotificationTime': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      try {
        await _db.collection('users').doc(uid).set({
          'lastNotification': {
            ...notif,
            'time': now.millisecondsSinceEpoch,
          },
          'lastNotificationTime': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Stream<List<Map<String, dynamic>>> streamPartnerNotificationLogs({int limit = 50}) {
    final uid = LocalStorage().getUserId();
    if (uid == null || !_firebaseAvailable) {
      return Stream.value([]);
    }
    try {
      return _db.collection('users').doc(uid).snapshots().asyncExpand((snap) {
        if (!snap.exists) return Stream.value([]);
        final uData = snap.data();
        final partnerUid = uData != null && uData.containsKey('partnerUid') ? uData['partnerUid'] as String? : null;
        if (partnerUid == null || partnerUid.isEmpty) return Stream.value([]);

        return _db.collection('users').doc(partnerUid)
            .collection('notification_logs')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .map((logsSnap) {
          return logsSnap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  Future<Map<String, dynamic>?> getPartnerCurrentApp() async {
    final uid = LocalStorage().getUserId();
    if (uid == null || !_firebaseAvailable) return null;
    try {
      final userSnap = await _db.collection('users').doc(uid).get();
      if (!userSnap.exists) return null;
      final uData = userSnap.data();
      final partnerUid = uData != null && uData.containsKey('partnerUid') ? uData['partnerUid'] as String? : null;
      if (partnerUid == null || partnerUid.isEmpty) return null;
      final partnerSnap = await _db.collection('users').doc(partnerUid).get();
      if (!partnerSnap.exists) return null;
      final pData = partnerSnap.data() ?? {};
      return {
        'currentApp': pData.containsKey('currentApp') ? pData['currentApp'] ?? '' : '',
        'lastAppUpdate': pData.containsKey('lastAppUpdate') ? (pData['lastAppUpdate'] as Timestamp?)?.toDate() : null,
        'lastNotification': pData.containsKey('lastNotification') ? pData['lastNotification'] : null,
        'lastNotificationTime': pData.containsKey('lastNotificationTime') ? (pData['lastNotificationTime'] as Timestamp?)?.toDate() : null,
      };
    } catch (_) {
      return null;
    }
  }

  Stream<Map<String, dynamic>> streamPartnerCurrentApp() {
    final uid = LocalStorage().getUserId();
    if (uid == null || !_firebaseAvailable) {
      return Stream.value({});
    }
    try {
      return _db.collection('users').doc(uid).snapshots().asyncMap((snap) async {
        if (!snap.exists) return {};
        final uData = snap.data();
        final partnerUid = uData != null && uData.containsKey('partnerUid') ? uData['partnerUid'] as String? : null;
        if (partnerUid == null || partnerUid.isEmpty) return {};
        final pSnap = await _db.collection('users').doc(partnerUid).get();
        if (!pSnap.exists) return {};
        final pData = pSnap.data() ?? {};
        return {
          'currentApp': pData.containsKey('currentApp') ? pData['currentApp'] ?? '' : '',
          'lastAppUpdate': pData.containsKey('lastAppUpdate') ? (pData['lastAppUpdate'] as Timestamp?)?.toDate() : null,
          'lastNotification': pData.containsKey('lastNotification') ? pData['lastNotification'] : null,
          'lastNotificationTime': pData.containsKey('lastNotificationTime') ? (pData['lastNotificationTime'] as Timestamp?)?.toDate() : null,
        };
      });
    } catch (_) {
      return Stream.value({});
    }
  }

  Future<void> addSharedNote(Map<String, dynamic> note) async {
    if (!_firebaseAvailable) return;
    try {
      await _db
          .collection('couples')
          .doc(_coupleId)
          .collection('notes')
          .doc(note['id'])
          .set(note);
    } catch (_) {}
  }

  Future<void> deleteSharedNote(String noteId) async {
    if (!_firebaseAvailable) return;
    try {
      await _db
          .collection('couples')
          .doc(_coupleId)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> streamSharedNotes() {
    if (!_firebaseAvailable) {
      final local = LocalStorage().getLocalList('notes_list');
      return Stream.value(local);
    }
    return _db
        .collection('couples')
        .doc(_coupleId)
        .collection('notes')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => doc.data()).toList();
      list.sort((a, b) => (b['id'] as String? ?? '').compareTo(a['id'] as String? ?? ''));
      LocalStorage().saveLocalList('notes_list', list);
      return list;
    });
  }

  Future<void> createGameSession(String gameType, Map<String, dynamic> initialData) async {
    if (!_firebaseAvailable) return;
    try {
      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      final myName = LocalStorage().getUserName() ?? 'Yo';
      await _db
          .collection('couples')
          .doc(_coupleId)
          .collection('games')
          .doc(docId)
          .set({
        'id': docId,
        'gameType': gameType,
        'status': 'pending',
        'sender': myName,
        'senderId': LocalStorage().getUserId() ?? 'anon',
        'receiver': LocalStorage().getPartnerName() ?? 'Pareja',
        'createdAt': DateTime.now().toIso8601String(),
        ...initialData,
      });
    } catch (_) {}
  }

  Future<void> updateGameSession(String gameId, Map<String, dynamic> data) async {
    if (!_firebaseAvailable) return;
    try {
      await _db
          .collection('couples')
          .doc(_coupleId)
          .collection('games')
          .doc(gameId)
          .update(data);
    } catch (_) {}
  }

  Future<void> deleteGameSession(String gameId) async {
    if (!_firebaseAvailable) return;
    try {
      await _db
          .collection('couples')
          .doc(_coupleId)
          .collection('games')
          .doc(gameId)
          .delete();
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> streamActiveGames() {
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId.isEmpty || coupleId == 'default_couple_id') {
      return Stream.value([]);
    }
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('games')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((g) {
        // Solo partidas multijugador (excluir retos picantes que usan 'type')
        final gameType = g['gameType'];
        return gameType is String && gameType.isNotEmpty;
      }).toList();
      list.sort((a, b) => (b['id'] as String? ?? '').compareTo(a['id'] as String? ?? ''));
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> streamAllGames() {
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId.isEmpty || coupleId == 'default_couple_id') {
      return Stream.value([]);
    }
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('games')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      list.sort((a, b) {
        final ta = a['timestamp'] ?? a['responseTimestamp'] ?? a['createdAt'];
        final tb = b['timestamp'] ?? b['responseTimestamp'] ?? b['createdAt'];

        DateTime? dateA;
        if (ta is Timestamp) {
          dateA = ta.toDate();
        } else if (ta is String) {
          dateA = DateTime.tryParse(ta);
        } else {
          final idA = a['id'] as String?;
          if (idA != null) {
            final ms = int.tryParse(idA);
            if (ms != null) dateA = DateTime.fromMillisecondsSinceEpoch(ms);
          }
        }

        DateTime? dateB;
        if (tb is Timestamp) {
          dateB = tb.toDate();
        } else if (tb is String) {
          dateB = DateTime.tryParse(tb);
        } else {
          final idB = b['id'] as String?;
          if (idB != null) {
            final ms = int.tryParse(idB);
            if (ms != null) dateB = DateTime.fromMillisecondsSinceEpoch(ms);
          }
        }

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Stream en tiempo real del frame de pantalla compartida de la pareja.
  Stream<Uint8List?> streamPartnerScreenFrame() async* {
    final uid = LocalStorage().getUserId();
    if (uid == null || !_firebaseAvailable) {
      yield null;
      return;
    }

    String? partnerUid = LocalStorage().getString('partner_uid');
    if (partnerUid == null || partnerUid.isEmpty) {
      try {
        final userSnap = await _db.collection('users').doc(uid).get();
        if (!userSnap.exists) {
          yield null;
          return;
        }
        final data = userSnap.data() ?? {};
        partnerUid = data['partnerUid'] as String?;
        if (partnerUid == null || partnerUid.isEmpty) {
          final coupleId = data['coupleId'] as String? ?? _coupleId;
          if (coupleId.isNotEmpty && coupleId != 'default_couple_id') {
            final users = await _db.collection('users').where('coupleId', isEqualTo: coupleId).get();
            for (final u in users.docs) {
              if (u.id != uid) {
                partnerUid = u.id;
                break;
              }
            }
          }
        }
        if (partnerUid != null && partnerUid.isNotEmpty) {
          LocalStorage().setString('partner_uid', partnerUid);
        }
      } catch (_) {
        yield null;
        return;
      }
    }

    if (partnerUid == null || partnerUid.isEmpty) {
      yield null;
      return;
    }

    yield* _db
        .collection('screen_shares')
        .doc(partnerUid)
        .collection('frames')
        .doc('latest')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final frameData = doc.data();
      if (frameData == null) return null;
      final b64 = frameData['data'] as String?;
      if (b64 == null || b64.isEmpty) return null;

      try {
        return base64Decode(b64);
      } catch (_) {
        return null;
      }
    });
  }

  Future<bool> isPartnerScreenSharing() async {
    final uid = LocalStorage().getUserId();
    if (uid == null || !_firebaseAvailable) return false;
    try {
      final userSnap = await _db.collection('users').doc(uid).get();
      final partnerUid = userSnap.data()?['partnerUid'] as String?;
      if (partnerUid == null || partnerUid.isEmpty) return false;
      final partnerSnap = await _db.collection('users').doc(partnerUid).get();
      return partnerSnap.data()?['screenShareActive'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Spicy Games Online ───
  Future<String> sendGameChallenge({
    required String type,
    required String content,
    required String level,
    String? photoUrl,
  }) async {
    final uid = LocalStorage().getUserId() ?? 'anon';
    final name = LocalStorage().getUserName() ?? 'Tú';
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId == 'default_couple_id') return '';
    try {
      final docRef = await _db.collection('couples').doc(coupleId)
          .collection('games').add({
        'senderId': uid,
        'senderName': name,
        'type': type,
        'content': content,
        'level': level,
        'photoUrl': photoUrl ?? '',
        'response': '',
        'responsePhotoUrl': '',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint("Error sending game challenge: $e");
      return '';
    }
  }

  Future<void> respondToChallenge(String gameId, {
    String? response,
    String? responsePhotoUrl,
  }) async {
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId == 'default_couple_id') return;
    try {
      final data = <String, dynamic>{
        'status': 'responded',
        'responseTimestamp': FieldValue.serverTimestamp(),
      };
      if (response != null) data['response'] = response;
      if (responsePhotoUrl != null) data['responsePhotoUrl'] = responsePhotoUrl;
      await _db.collection('couples').doc(coupleId)
          .collection('games').doc(gameId).update(data);
    } catch (e) {
      debugPrint("Error responding to challenge: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> streamGameChallenges() {
    final coupleId = _coupleId;
    if (!_firebaseAvailable || coupleId == 'default_couple_id') {
      return const Stream.empty();
    }
    return _db.collection('couples').doc(coupleId)
        .collection('games')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          list.sort((a, b) {
            final ta = a['timestamp'] as Timestamp?;
            final tb = b['timestamp'] as Timestamp?;
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });
          return list.take(50).toList();
        });
  }
}
