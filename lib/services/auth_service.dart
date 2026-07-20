import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_storage.dart';
import 'firebase_service.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String get userId => _auth.currentUser?.uid ?? 'local_user_id';

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential;
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        userCredential = await _auth.currentUser!.linkWithCredential(credential);
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }
      await _afterSignIn(userCredential.user);
      return userCredential;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      await _afterSignIn(userCredential.user);
      return userCredential;
    } catch (e) {
      debugPrint("Email sign-up error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _afterSignIn(userCredential.user);
      return userCredential;
    } catch (e) {
      debugPrint("Email sign-in error: $e");
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Anonymous sign-in error: $e");
    }
  }

  /// Restores the full account from Firestore (used after login or reinstall).
  /// Returns true when the user already has a linked couple profile.
  Future<bool> restoreSession(User user) async {
    final storage = LocalStorage();
    storage.setString('firebase_uid', user.uid);
    storage.setString('user_id', user.uid);

    // Propagate profile load errors so we don't proceed to onboarding on network failure
    await FirebaseService()
        .loadUserFromFirestore(user.uid)
        .timeout(const Duration(seconds: 8));
    
    try {
      await FirebaseService()
          .loadAllListsToLocal()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('restoreSession load lists error (non-fatal): $e');
    }

    var existingName = storage.getUserName();
    if (existingName == null || existingName.isEmpty) {
      await _migrateFromEmail(user);
      existingName = storage.getUserName();
    }

    final displayName = user.displayName;
    if ((existingName == null || existingName.isEmpty) &&
        displayName != null &&
        displayName.isNotEmpty) {
      storage.setString('user_name', displayName);
    }

    try {
      final email = user.email;
      if (email != null && email.isNotEmpty) {
        storage.setString('user_email', email);
        await FirebaseFirestore.instance.collection('user_emails').doc(email).set({
          'uid': user.uid,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    FirebaseService().restartListListener();

    final coupleId = storage.getString('couple_id');
    final name = storage.getUserName();
    if (name != null && name.isNotEmpty) {
      try {
        await FirebaseService()
            .saveUserProfile(user.uid, name, storage.getPartnerName())
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }

    return coupleId != null &&
        coupleId.isNotEmpty &&
        coupleId != 'default_couple_id' &&
        name != null &&
        name.isNotEmpty;
  }

  Future<void> _afterSignIn(User? user) async {
    if (user == null) return;
    await restoreSession(user);
  }

  Future<void> _migrateFromEmail(User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) return;

    try {
      // Check if there's a previous UID for this email
      final emailDoc = await FirebaseFirestore.instance
          .collection('user_emails').doc(email).get();

      if (!emailDoc.exists) return;
      final oldUid = emailDoc.get('uid') as String?;
      if (oldUid == null || oldUid == user.uid) return;

      // Check if old UID has data
      final oldUserDoc = await FirebaseFirestore.instance
          .collection('users').doc(oldUid).get();
      if (!oldUserDoc.exists || oldUserDoc.data() == null) return;

      debugPrint("Migrating data from UID $oldUid to ${user.uid}");

      // Copy user data to new UID
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .set(oldUserDoc.data()!, SetOptions(merge: true));

      // Copy lists from old UID
      final listsSnap = await FirebaseFirestore.instance
          .collection('users').doc(oldUid).collection('lists').get();
      for (final listDoc in listsSnap.docs) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('lists').doc(listDoc.id)
            .set(listDoc.data());
      }

      // Update partner's partnerUid if needed
      final oldData = oldUserDoc.data()!;
      if (oldData.containsKey('partnerUid') && oldData['partnerUid'] != null) {
        final partnerUid = oldData['partnerUid'] as String;
        await FirebaseFirestore.instance.collection('users').doc(partnerUid)
            .set({'partnerUid': user.uid}, SetOptions(merge: true));
      }

      // Reload data into LocalStorage
      await FirebaseService().loadUserFromFirestore(user.uid);
      await FirebaseService().loadAllListsToLocal();
    } catch (e) {
      debugPrint("Error migrating data from email: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await LocalStorage().clear();
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      debugPrint("Delete account error: $e");
    }
  }
}
