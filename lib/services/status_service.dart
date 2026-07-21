import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage.dart';
import 'firebase_service.dart';
import 'couple_service.dart';
import '../models/user_model.dart';

class StatusService {
  static final StatusService _instance = StatusService._internal();
  factory StatusService() => _instance;
  StatusService._internal();

  final _statusCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get partnerStatusStream => _statusCtrl.stream;

  StreamSubscription? _myDocSub;
  StreamSubscription? _partnerDocSub;
  String? _currentListeningPartnerUid;

  void init() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _listenToPartner(uid);
    }
  }

  void _syncUserToLocalStorage(UserModel user) {
    final ls = LocalStorage();
    if (user.name.isNotEmpty) ls.setString('user_name', user.name);
    if (user.partnerName != null && user.partnerName!.isNotEmpty) ls.setString('partner_name', user.partnerName!);
    if (user.profilePhotoUrl != null) ls.setString('profile_photo', user.profilePhotoUrl!);
    if (user.partnerProfilePhotoUrl != null) ls.setString('partner_profile_photo', user.partnerProfilePhotoUrl!);
    if (user.anniversaryDate != null) ls.setString('anniversary_date', user.anniversaryDate!.toIso8601String());
    if (user.metDate != null) ls.setString('met_date', user.metDate!.toIso8601String());
    if (user.datingDate != null) ls.setString('dating_date', user.datingDate!.toIso8601String());
    if (user.weddingDate != null) ls.setString('wedding_date', user.weddingDate!.toIso8601String());
    ls.setString('theme', user.themeName);
    ls.setInt('love_points', user.lovePoints);
    ls.setString('mood', user.mood);
    ls.setString('mood_reason', user.moodReason);
    ls.setString('emotional_weather', user.emotionalWeather);
    ls.setString('couple_id', CoupleService.parejaId);
    ls.setString('partner_uid', CoupleService().partnerUid);
    ls.setString('partner_name', CoupleService().partnerName);
  }

  void _listenToPartner(String uid) {
    if (!FirebaseService().isFirebaseAvailable) return;
    _myDocSub?.cancel();
    _myDocSub = FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots().listen((snap) {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final name = data['nombre'] as String? ?? (uid == CoupleService.diegoUid ? 'Diego' : 'Yosmari');
        LocalStorage().setString('user_name', name);
      }

      final partnerUid = CoupleService().partnerUid;
      final partnerName = CoupleService().partnerName;
      LocalStorage().setString('partner_uid', partnerUid);
      LocalStorage().setString('partner_name', partnerName);

      if (_currentListeningPartnerUid != partnerUid) {
        _currentListeningPartnerUid = partnerUid;
        _partnerDocSub?.cancel();
        _partnerDocSub = FirebaseFirestore.instance.collection('usuarios').doc(partnerUid).snapshots().listen((pSnap) {
          if (!pSnap.exists) return;
          final Map<String, dynamic>? pData = pSnap.data();
          if (pData == null) return;

          final ls = LocalStorage();
          final pName = pData['nombre'] as String? ?? pData['name'] as String? ?? partnerName;
          ls.setString('partner_name', pName);

          if (pData.containsKey('foto')) {
            ls.setString('partner_profile_photo', pData['foto'] as String? ?? '');
          }

          _statusCtrl.add({
            'isOnline': pData.containsKey('isOnline') == true ? pData['isOnline'] : false,
            'currentScreen': pData.containsKey('currentScreen') == true ? pData['currentScreen'] : '',
            'lastSeenDate': pData.containsKey('lastSeenDate') == true ? (pData['lastSeenDate'] as Timestamp?)?.toDate() : null,
            'batteryLevel': pData.containsKey('batteryLevel') == true ? pData['batteryLevel'] : -1,
            'isCharging': pData.containsKey('isCharging') == true ? pData['isCharging'] : false,
            'currentApp': pData.containsKey('currentApp') == true ? pData['currentApp'] : '',
            'currentAppLabel': pData.containsKey('currentAppLabel') == true ? pData['currentAppLabel'] : '',
            'lastAppUpdate': pData.containsKey('lastAppUpdate') == true ? (pData['lastAppUpdate'] as Timestamp?)?.toDate() : null,
            'lastNotification': pData.containsKey('lastNotification') == true ? pData['lastNotification'] : null,
            'lastNotificationTime': pData.containsKey('lastNotificationTime') == true ? (pData['lastNotificationTime'] as Timestamp?)?.toDate() : null,
            'latitude': pData.containsKey('latitude') == true ? pData['latitude'] : null,
            'longitude': pData.containsKey('longitude') == true ? pData['longitude'] : null,
            'phoneState': pData.containsKey('phoneState') == true ? pData['phoneState'] : 'activo',
          });
        }, onError: (err) {
          debugPrint("[StatusService] Partner doc listener error: $err");
          FirebaseService.recordError(err);
        });
      }
    }, onError: (err) {
      debugPrint("[StatusService] My doc listener error: $err");
      FirebaseService.recordError(err);
    });
  }

  void setScreen(String screenName) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (!FirebaseService().isFirebaseAvailable) return;

    FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'currentScreen': screenName,
      'lastSeenDate': FieldValue.serverTimestamp(),
      'isOnline': true,
    }, SetOptions(merge: true)).catchError((e) {
      debugPrint("Error updating screen: $e");
    });
  }

  void setOffline() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (!FirebaseService().isFirebaseAvailable) return;

    FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'isOnline': false,
      'currentScreen': '',
      'lastSeenDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) {
      debugPrint("Error set offline: $e");
    });
  }

  void updateLocation(double lat, double lon) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (!FirebaseService().isFirebaseAvailable) return;

    FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'latitude': lat,
      'longitude': lon,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) {
      debugPrint("Error update location: $e");
    });
  }

  void updateAppUsage(String packageName, String appLabel) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (!FirebaseService().isFirebaseAvailable) return;

    FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
      'currentApp': packageName,
      'currentAppLabel': appLabel,
      'lastAppUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) {
      debugPrint("Error update app usage: $e");
    });
  }

  void dispose() {
    _myDocSub?.cancel();
    _partnerDocSub?.cancel();
    _statusCtrl.close();
  }
}
