import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage.dart';
import 'firebase_service.dart';
import 'chat_notification_service.dart';

enum AddPartnerResult { success, alreadyHasPartner, targetHasPartner, notFound, error }
enum CreateProfileResult { success, usernameTaken, error }

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._();
  factory UserService() => _instance;
  UserService._();

  String? get username => LocalStorage().getString('username');
  String? get dob => LocalStorage().getString('dob') ?? LocalStorage().getString('birthday_date');
  bool get hasProfile => LocalStorage().getBool('has_firestore_profile') == true || (LocalStorage().getUserName() != null && (username != null || dob != null));

  String? get partnerUid => LocalStorage().getString('partner_uid');
  String? get partnerUsername => LocalStorage().getString('partner_username');
  bool get hasPartner => partnerUid != null && partnerUid!.isNotEmpty;

  String? get pairId {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final pUid = partnerUid;
    if (myUid == null || pUid == null || pUid.isEmpty) return null;
    final ids = [myUid, pUid]..sort();
    return ids.join('_');
  }

  String? get partnerName => LocalStorage().getPartnerName();
  bool get partnerSkipped => LocalStorage().getBool('partner_skipped') == true;

  Future<void> didSkipPartner() async {
    await LocalStorage().setBool('partner_skipped', true);
    notifyListeners();
  }

  Future<void> _clearSkippedFlag() async {
    await LocalStorage().remove('partner_skipped');
  }

  Future<String> getOrGeneratePairCode() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        user = cred.user;
      } catch (e) {
        debugPrint("[UserService] Anonymous auth error: $e");
      }
    }
    final uid = user?.uid ?? LocalStorage().getUserId() ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(uid).get();
      final data = userDoc.data();
      String? existingCode = data?['pairCode'] as String?;

      if (existingCode != null && existingCode.isNotEmpty) {
        return existingCode;
      }

      final rnd = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
      final code = 'LOVE-$rnd';

      await db.collection('users').doc(uid).set({'pairCode': code}, SetOptions(merge: true));
      await db.collection('pair_codes').doc(code).set({'uid': uid}, SetOptions(merge: true));
      return code;
    } catch (e) {
      debugPrint("[UserService] getOrGeneratePairCode error: $e");
      final rnd = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
      return 'LOVE-$rnd';
    }
  }

  Future<CreateProfileResult> createProfile(String newUsername, String newDob) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        user = cred.user;
      } catch (e) {
        debugPrint("[UserService] Anonymous auth error: $e");
      }
    }
    final uid = user?.uid ?? LocalStorage().getUserId() ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    await LocalStorage().setString('user_id', uid);

    final cleanUsername = newUsername.trim().toLowerCase();
    if (cleanUsername.length < 3) return CreateProfileResult.error;

    try {
      try {
        final existing = await FirebaseFirestore.instance.collection('usernames').doc(cleanUsername).get();
        if (existing.exists) {
          final existingData = existing.data();
          if (existingData?['uid'] != uid) {
            return CreateProfileResult.usernameTaken;
          }
        }
      } catch (e) {
        debugPrint("[UserService] Username check warning: $e");
      }

      final pairCode = await getOrGeneratePairCode();

      try {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          tx.set(FirebaseFirestore.instance.collection('usernames').doc(cleanUsername), {'uid': uid});
          tx.set(FirebaseFirestore.instance.collection('users').doc(uid), {
            'username': cleanUsername,
            'displayName': LocalStorage().getUserName() ?? '',
            'photoUrl': LocalStorage().getString('google_photo_url') ?? '',
            'email': LocalStorage().getString('google_current_email') ?? '',
            'dob': newDob,
            'pairCode': pairCode,
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        });
      } catch (_) {
        try {
          await FirebaseFirestore.instance.collection('usernames').doc(cleanUsername).set({'uid': uid});
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'username': cleanUsername,
            'displayName': LocalStorage().getUserName() ?? '',
            'photoUrl': LocalStorage().getString('google_photo_url') ?? '',
            'email': LocalStorage().getString('google_current_email') ?? '',
            'dob': newDob,
            'name': LocalStorage().getUserName() ?? '',
            'birthdayDate': newDob,
            'pairCode': pairCode,
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("[UserService] Firestore direct write warning: $e");
        }
      }

      await LocalStorage().setString('username', cleanUsername);
      await LocalStorage().setString('dob', newDob);
      await LocalStorage().setString('birthday_date', newDob);
      await LocalStorage().setBool('has_firestore_profile', true);
      notifyListeners();
      return CreateProfileResult.success;
    } catch (e) {
      debugPrint("[UserService] createProfile error: $e");
      await LocalStorage().setString('username', cleanUsername);
      await LocalStorage().setString('dob', newDob);
      await LocalStorage().setString('birthday_date', newDob);
      await LocalStorage().setBool('has_firestore_profile', true);
      notifyListeners();
      return CreateProfileResult.success;
    }
  }

  Future<Map<String, dynamic>?> searchUser(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final db = FirebaseFirestore.instance;

    try {
      // 1. Search by Pair Code (e.g. LOVE-8492 or LOVE8492)
      final upperCode = clean.toUpperCase();
      final formattedCode = upperCode.contains('LOVE-') ? upperCode : 'LOVE-$upperCode';
      final codeDoc = await db.collection('pair_codes').doc(formattedCode).get();
      if (codeDoc.exists) {
        final uid = codeDoc.data()?['uid'] as String?;
        if (uid != null && uid != myUid) {
          final userDoc = await db.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            data['uid'] = uid;
            return data;
          }
        }
      }

      // 2. Search by Username
      final usernameDoc = await db.collection('usernames').doc(clean).get();
      if (usernameDoc.exists) {
        final uid = usernameDoc.data()?['uid'] as String?;
        if (uid != null && uid != myUid) {
          final userDoc = await db.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            data['uid'] = uid;
            return data;
          }
        }
      }

      // 3. Search by Email
      final emailSnap = await db.collection('users').where('email', isEqualTo: clean).limit(1).get();
      if (emailSnap.docs.isNotEmpty) {
        final userDoc = emailSnap.docs.first;
        if (userDoc.id != myUid) {
          final data = userDoc.data();
          data['uid'] = userDoc.id;
          return data;
        }
      }

      return null;
    } catch (e) {
      debugPrint("[UserService] searchUser error: $e");
      return null;
    }
  }

  Future<AddPartnerResult> addPartner(String query) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return AddPartnerResult.error;

    try {
      final targetData = await searchUser(query);
      if (targetData == null) return AddPartnerResult.notFound;

      final targetUid = targetData['uid'] as String? ?? targetData['userId'] as String?;
      final targetUsername = targetData['username'] as String? ?? '';
      final targetName = targetData['displayName'] as String? ?? targetData['name'] as String? ?? targetUsername;

      if (targetUid == null || targetUid == myUid) return AddPartnerResult.notFound;

      final db = FirebaseFirestore.instance;
      final ids = [myUid, targetUid]..sort();
      final coupleId = ids.join('_');

      final result = await db.runTransaction((tx) async {
        final myDoc = await tx.get(db.collection('users').doc(myUid));
        final targetDoc = await tx.get(db.collection('users').doc(targetUid));

        final existingMyPartner = myDoc.data()?['partnerUid'] as String?;
        final existingTargetPartner = targetDoc.data()?['partnerUid'] as String?;

        if (existingMyPartner != null && existingMyPartner.isNotEmpty && existingMyPartner != targetUid) {
          return AddPartnerResult.alreadyHasPartner;
        }
        if (existingTargetPartner != null && existingTargetPartner.isNotEmpty && existingTargetPartner != myUid) {
          return AddPartnerResult.targetHasPartner;
        }

        final myName = LocalStorage().getUserName() ?? myDoc.data()?['displayName'] as String? ?? 'Mi Pareja';
        final myUsername = LocalStorage().getString('username') ?? myDoc.data()?['username'] as String? ?? '';

        tx.update(db.collection('users').doc(myUid), {
          'partnerUid': targetUid,
          'partnerUsername': targetUsername,
          'partnerDisplayName': targetName,
          'coupleId': coupleId,
        });

        tx.update(db.collection('users').doc(targetUid), {
          'partnerUid': myUid,
          'partnerUsername': myUsername,
          'partnerDisplayName': myName,
          'coupleId': coupleId,
        });

        tx.set(db.collection('couples').doc(coupleId), {
          'active': true,
          'members': [myUid, targetUid],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userNames': {
            myUid: myName,
            targetUid: targetName,
          }
        }, SetOptions(merge: true));

        return AddPartnerResult.success;
      });

      if (result == AddPartnerResult.success) {
        await LocalStorage().setString('partner_uid', targetUid);
        await LocalStorage().setString('partner_username', targetUsername);
        await LocalStorage().setString('partner_name', targetName);
        await LocalStorage().setString('pair_id', coupleId);
        await LocalStorage().setString('couple_id', coupleId);
        await _clearSkippedFlag();

        FirebaseService().loadUserFromFirestore(myUid).catchError((e) {
          debugPrint("[UserService] background loadUserFromFirestore error: $e");
        });
        
        ChatNotificationService().restartListening();
        FirebaseService().sendActivityNotification('¡Se ha vinculado como tu pareja! 💖', 'love', icon: 'heart');

        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint("[UserService] addPartner error: $e");
      return AddPartnerResult.error;
    }
  }

  Future<void> removePartner() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final pUid = partnerUid ?? LocalStorage().getString('partner_uid');
    if (myUid == null) return;

    final db = FirebaseFirestore.instance;

    try {
      // 1. Remove relationship from my doc
      await db.collection('users').doc(myUid).set({
        'partnerUid': FieldValue.delete(),
        'partnerUsername': FieldValue.delete(),
        'partnerDisplayName': FieldValue.delete(),
      }, SetOptions(merge: true));

      // 2. Remove relationship from partner doc
      if (pUid != null && pUid.isNotEmpty) {
        await db.collection('users').doc(pUid).set({
          'partnerUid': FieldValue.delete(),
          'partnerUsername': FieldValue.delete(),
          'partnerDisplayName': FieldValue.delete(),
        }, SetOptions(merge: true));

        // 3. Deactivate the couple document so self-heal won't re-link
        final ids = [myUid, pUid]..sort();
        final coupleId = ids.join('_');
        await db.collection('couples').doc(coupleId).set({
          'active': false,
          'unlinkedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("[UserService] removePartner error: $e");
    }

    await _clearPartnerState();
  }

  Future<void> _clearPartnerState() async {
    await LocalStorage().remove('partner_uid');
    await LocalStorage().remove('partner_username');
    await LocalStorage().remove('partner_name');
    await LocalStorage().remove('pair_id');
    await LocalStorage().setString('couple_id', 'default_couple_id');
    notifyListeners();
  }

  Future<void> syncFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final data = doc.data()!;

      final localUsername = LocalStorage().getString('username');
      final localDob = LocalStorage().getString('dob');
      final remoteUsername = data['username'] as String?;
      final remoteDob = data['dob'] as String? ?? data['birthdayDate'] as String?;

      if (remoteUsername != null && remoteUsername.isNotEmpty && localUsername == null) {
        await LocalStorage().setString('username', remoteUsername);
      }
      if (remoteDob != null && remoteDob.isNotEmpty && localDob == null) {
        await LocalStorage().setString('dob', remoteDob);
      }

      final remotePartnerUid = data['partnerUid'] as String?;
      await _healRelationship(uid, remotePartnerUid, data);
    } catch (e) {
      debugPrint("[UserService] syncFromFirestore error: $e");
    }
  }

  Future<void> _healRelationship(String uid, String? remotePartnerUid, Map<String, dynamic> userData) async {
    if (remotePartnerUid == null || remotePartnerUid.isEmpty) {
      final localPartner = LocalStorage().getString('partner_uid');
      final skipped = LocalStorage().getBool('partner_skipped') == true;
      if (localPartner != null && localPartner.isNotEmpty) {
        if (!skipped) {
          debugPrint("[SELF_HEAL] Remote partnerUid is null. Clearing local partner state.");
          await _clearPartnerState();
        }
      }
      return;
    }

    // 2. If remote partnerUid is non-null, sync to local state
    final localPartnerUid = LocalStorage().getString('partner_uid');
    if (remotePartnerUid != localPartnerUid) {
      debugPrint("[SELF_HEAL] Syncing partnerUid from Firestore: $remotePartnerUid");
      await _savePartnerState(uid, remotePartnerUid, userData);
    }
  }

  Future<void> _savePartnerState(String myUid, String partnerUid, Map<String, dynamic> userData) async {
    final ids = [myUid, partnerUid]..sort();
    final pId = ids.join('_');
    await LocalStorage().setString('partner_uid', partnerUid);
    await LocalStorage().setString('partner_username', userData['partnerUsername'] as String? ?? '');
    await LocalStorage().setString('partner_name', userData['partnerDisplayName'] as String? ?? '');
    await LocalStorage().setString('pair_id', pId);
    await LocalStorage().setString('couple_id', pId);

    try {
      await FirebaseService().loadUserFromFirestore(myUid);
    } catch (_) {}

    notifyListeners();
  }

  StreamSubscription? _authSub;
  StreamSubscription? _userDocSub;

  void startListening() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _userDocSub?.cancel();
      if (user == null) {
        _userDocSub = null;
        return;
      }
      final uid = user.uid;
      _userDocSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) async {
        if (!snap.exists) return;
        final data = snap.data()!;

        final remotePartnerUid = data['partnerUid'] as String?;
        await _healRelationship(uid, remotePartnerUid, data);
      });
    });
  }

  void stopListening() {
    _authSub?.cancel();
    _authSub = null;
    _userDocSub?.cancel();
    _userDocSub = null;
  }

  Future<void> clear() async {
    await removePartner();
    await LocalStorage().remove('username');
    await LocalStorage().remove('dob');
    await LocalStorage().remove('partner_skipped');
    notifyListeners();
  }
}
