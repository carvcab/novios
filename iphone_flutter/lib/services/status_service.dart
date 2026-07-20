import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:battery_plus/battery_plus.dart';
import 'local_storage.dart';
import 'firebase_service.dart';
import '../models/user_model.dart';

class StatusService with WidgetsBindingObserver {
  static final StatusService _instance = StatusService._internal();
  factory StatusService() => _instance;
  StatusService._internal();

  String? _currentScreen;
  bool _initialized = false;
  final Battery _battery = Battery();
  Timer? _presenceTimer;
  String? _currentListeningPartnerUid;

  String? get currentScreen => _currentScreen;
  bool get isOnline => _initialized;

  final _statusCtrl = StreamController<Map<String, dynamic>>.broadcast();
  
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _myDocSub;
  StreamSubscription<DocumentSnapshot>? _partnerDocSub;
  StreamSubscription<bool>? _healthSub;

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    // React to Firebase health changes
    _healthSub = FirebaseService.healthStream.listen((available) {
      if (available) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _saveUidForNative(user.uid);
          _listenToPartner(user.uid);
          _presenceTimer?.cancel();
          _presenceTimer = Timer.periodic(const Duration(seconds: 120), (_) {
            _updatePresence('online');
          });
        }
      }
    });

    // Listen to Firebase Auth state changes reactively
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        if (!FirebaseService().isFirebaseAvailable) return;
        // User logged in! Start presence and listen to partner
        _saveUidForNative(user.uid);
        _updatePresence('online');
        _listenToPartner(user.uid);

        _presenceTimer?.cancel();
        _presenceTimer = Timer.periodic(const Duration(seconds: 120), (_) {
          _updatePresence('online');
        });
      } else {
        // User logged out! Clean up all listeners
        _presenceTimer?.cancel();
        _presenceTimer = null;
        _myDocSub?.cancel();
        _myDocSub = null;
        _partnerDocSub?.cancel();
        _partnerDocSub = null;
        _currentListeningPartnerUid = null;
      }
    });
  }

  void _saveUidForNative(String uid) {
    LocalStorage().setString('user_uid', uid).then((_) {
      debugPrint("[StatusService] UID saved for native: $uid");
    });
  }

  void setScreen(String screen) {
    _currentScreen = screen;
    _updatePresence('online', screen: screen);
  }

  void clearScreen() {
    _currentScreen = null;
  }

  void _syncUserToLocalStorage(UserModel user) {
    if (user.id.isEmpty) return;
    final ls = LocalStorage();
    ls.setString('user_id', user.id);
    ls.setString('user_name', user.name);
    if (user.partnerName != null) ls.setString('partner_name', user.partnerName!);
    if (user.anniversaryDate != null) ls.setString('anniversary_date', user.anniversaryDate!.toIso8601String());
    if (user.metDate != null) ls.setString('met_date', user.metDate!.toIso8601String());
    if (user.datingDate != null) ls.setString('dating_date', user.datingDate!.toIso8601String());
    if (user.weddingDate != null) ls.setString('wedding_date', user.weddingDate!.toIso8601String());
    ls.setString('theme', user.themeName);
    ls.setInt('love_points', user.lovePoints);
    ls.setString('mood', user.mood);
    ls.setString('mood_reason', user.moodReason);
    ls.setString('emotional_weather', user.emotionalWeather);
    if (user.coupleId != null) ls.setString('couple_id', user.coupleId!);
    if (user.partnerUid != null) ls.setString('partner_uid', user.partnerUid!);
  }

  void _listenToPartner(String uid) {
    if (!FirebaseService().isFirebaseAvailable) return;
    _myDocSub?.cancel();
    _myDocSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
      if (!snap.exists) return;
      
      final Map<String, dynamic>? data = snap.data();
      if (data != null) {
        final user = UserModel.fromMap(data);
        _syncUserToLocalStorage(user);
      }

      final partnerUid = data != null && data.containsKey('partnerUid') ? data['partnerUid'] as String? : null;
      if (partnerUid == null || partnerUid.isEmpty) {
        _partnerDocSub?.cancel();
        _partnerDocSub = null;
        _currentListeningPartnerUid = null;
        return;
      }

      if (_currentListeningPartnerUid != partnerUid) {
        _currentListeningPartnerUid = partnerUid;
        _partnerDocSub?.cancel();
        _partnerDocSub = FirebaseFirestore.instance.collection('users').doc(partnerUid).snapshots().listen((pSnap) {
          if (!pSnap.exists) return;
          final Map<String, dynamic>? pData = pSnap.data();
          if (pData == null) return;

          final ls = LocalStorage();
          if (pData.containsKey('name')) {
            ls.setString('partner_name', pData['name'] as String);
          }
          if (pData.containsKey('profilePhotoUrl')) {
            ls.setString('partner_profile_photo', pData['profilePhotoUrl'] as String? ?? '');
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

  Stream<Map<String, dynamic>> get partnerStatusStream => _statusCtrl.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence('online');
    } else if (state == AppLifecycleState.paused) {
      _updatePresence('online');
    } else if (state == AppLifecycleState.inactive) {
      _updatePresence('online');
    } else if (state == AppLifecycleState.detached) {
      _updatePresence('offline');
    }
  }

  Future<void> _updatePresence(String status, {String? screen}) async {
    if (!FirebaseService().isFirebaseAvailable) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      int batteryLevel = -1;
      bool isCharging = false;
      try {
        batteryLevel = await _battery.batteryLevel;
        final state = await _battery.batteryState;
        isCharging = state == BatteryState.charging;
      } catch (_) {}

      final data = <String, dynamic>{
        'isOnline': status == 'online',
        'currentScreen': screen ?? _currentScreen ?? '',
        'lastSeenDate': FieldValue.serverTimestamp(),
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
      };
      if (status == 'offline') {
        data['phoneState'] = 'apagado';
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
    } catch (e) {
      FirebaseService.recordError(e);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _healthSub?.cancel();
    _myDocSub?.cancel();
    _partnerDocSub?.cancel();
    _presenceTimer?.cancel();
    _updatePresence('offline');
    _statusCtrl.close();
  }
}
