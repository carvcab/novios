import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_storage.dart';
import 'couple_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String get userId => _auth.currentUser?.uid ?? '';

  bool get isDiego => _auth.currentUser?.uid == CoupleService.diegoUid;
  bool get isYosmari => _auth.currentUser?.uid == CoupleService.yosmariUid;
  String get myName => isDiego ? CoupleService.diegoName : CoupleService.yosmariName;
  String get partnerName => isDiego ? CoupleService.yosmariName : CoupleService.diegoName;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _afterSignIn(userCredential.user);
      return userCredential;
    } catch (e) {
      debugPrint("Sign-in error: $e");
      rethrow;
    }
  }

  Future<void> _afterSignIn(User? user) async {
    if (user == null) return;
    final uid = user.uid;
    final storage = LocalStorage();
    storage.setString('user_id', uid);
    storage.setString('user_name', myName);
    storage.setString('partner_name', partnerName);
    storage.setBool('has_firestore_profile', true);
    storage.setBool('profile_complete', true);
    if (user.email != null) storage.setString('user_email', user.email!);

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': myName,
        'correo': user.email,
        'ultimaConexion': DateTime.now().toIso8601String(),
        'parejaId': CoupleService.parejaId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving user profile: $e");
    }

    await CoupleService().ensureParejaDocExists();
    await CoupleService().init();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await LocalStorage().clear();
  }
}
