import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage.dart';
import 'couple_service.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._();
  factory UserService() => _instance;
  UserService._();

  String? get partnerName => CoupleService().partnerName;
  String? get partnerUid => CoupleService().partnerUid;
  bool get hasPartner => true;

  Future<void> syncFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('nombre')) LocalStorage().setString('user_name', data['nombre'] as String);
        if (data.containsKey('correo')) LocalStorage().setString('user_email', data['correo'] as String);
      }
    } catch (e) {
      debugPrint("[UserService] sync error: $e");
    }
    notifyListeners();
  }

  void startListening() {
    // CoupleService handles real-time sync
  }

  void stopListening() {}
}
