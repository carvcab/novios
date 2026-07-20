import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_storage.dart';

class ScreenShareService {
  static final ScreenShareService _instance = ScreenShareService._internal();
  factory ScreenShareService() => _instance;
  ScreenShareService._internal();

  static final GlobalKey screenshotKey = GlobalKey();

  static const _channel = MethodChannel('com.novios/screen_share');
  static const _uploadInterval = Duration(seconds: 2);

  final _frameCtrl = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get frameStream => _frameCtrl.stream;

  bool _isSharing = false;
  bool get isSharing => _isSharing;

  DateTime? _lastUploadTime;
  int _lastFrameHash = 0;
  Timer? _healthTimer;

  void init() {
    _channel.setMethodCallHandler((call) async {
      try {
        if (call.method == 'onFrame') {
          final bytes = call.arguments as Uint8List?;
          if (bytes != null && bytes.isNotEmpty) {
            if (!_frameCtrl.isClosed) {
              _frameCtrl.add(bytes);
            }
            _uploadFrame(bytes);
          }
        } else if (call.method == 'onSharingStopped') {
          _isSharing = false;
          _lastUploadTime = null;
          _lastFrameHash = 0;
        }
      } catch (e) {
        debugPrint("ScreenShare handler error: $e");
      }
      return null;
    });

    _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkHealth();
    });
  }

  Future<void> _checkHealth() async {
    if (!_isSharing) return;
    try {
      final running = await _channel.invokeMethod('isScreenSharing') ?? false;
      if (!running) {
        debugPrint("[ScreenShare] Health check: sharing stopped, attempting restart...");
        _lastUploadTime = null;
        _lastFrameHash = 0;
        try {
          final result = await _channel.invokeMethod('restartScreenShare');
          if (result == true) {
            await Future.delayed(const Duration(seconds: 2));
            final restarted = await _channel.invokeMethod('isScreenSharing') ?? false;
            if (restarted) {
              _isSharing = true;
              await _markSharingActive(true);
              debugPrint("[ScreenShare] Restart successful");
            }
          }
        } catch (e) {
          debugPrint("[ScreenShare] Auto-restart failed: $e");
        }
      }
    } catch (_) {}
  }

  Future<String> requestScreenShare() async {
    try {
      final result = await _channel.invokeMethod('requestScreenShare');
      if (result == 'granted') {
        _isSharing = true;
        await _markSharingActive(true);
        return 'granted';
      }
      return result as String? ?? 'denied';
    } catch (e) {
      return 'error: $e';
    }
  }

  Future<void> _markSharingActive(bool active) async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'screenShareActive': active,
        'screenShareUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> stopScreenShare() async {
    _isSharing = false;
    _lastUploadTime = null;
    _lastFrameHash = 0;
    await _markSharingActive(false);
    try {
      await _channel.invokeMethod('stopScreenShare');
    } catch (_) {}
  }

  Future<bool> isScreenSharing() async {
    try {
      final running = await _channel.invokeMethod('isScreenSharing') ?? false;
      _isSharing = running;
      if (running) {
        await _markSharingActive(true);
      }
      return running;
    } catch (_) {
      // Fallback: check Firestore flag
      final uid = LocalStorage().getUserId();
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          _isSharing = doc.data()?['screenShareActive'] == true;
          return _isSharing;
        } catch (_) {}
      }
      _isSharing = false;
      return false;
    }
  }

  Future<void> _uploadFrame(Uint8List bytes) async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;

    if (_lastUploadTime != null &&
        DateTime.now().difference(_lastUploadTime!) < _uploadInterval) {
      return;
    }

    final hash = _hashBytes(bytes);
    if (hash == _lastFrameHash) return;
    _lastFrameHash = hash;

    try {
      final b64 = base64Encode(bytes);
      await FirebaseFirestore.instance.collection('screen_shares').doc(uid)
          .collection('frames').doc('latest').set({
        'data': b64,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _lastUploadTime = DateTime.now();
    } catch (e) {
      // ignore upload errors
    }
  }

  int _hashBytes(Uint8List bytes) {
    const step = 500;
    int hash = 0;
    for (int i = 0; i < bytes.length; i += step) {
      hash = 31 * hash + bytes[i];
    }
    return hash;
  }

  void dispose() {
    _healthTimer?.cancel();
    _frameCtrl.close();
  }

  Future<String?> getPartnerFrameUrl() async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return null;

    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists) return null;
      final data = snap.data()!;
      String? partnerUid = data['partnerUid'] as String?;

      // Fallback: if partnerUid is not set, find by coupleId
      if (partnerUid == null) {
        final coupleId = data['coupleId'] as String?;
        if (coupleId != null && coupleId.isNotEmpty) {
          final users = await FirebaseFirestore.instance
              .collection('users').where('coupleId', isEqualTo: coupleId).get();
          for (final u in users.docs) {
            if (u.id != uid) {
              partnerUid = u.id;
              break;
            }
          }
        }
      }

      if (partnerUid == null) return null;

      // Verificar que la pareja tiene compartir pantalla activo
      final partnerUserDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUid).get();
      if (partnerUserDoc.data()?['screenShareActive'] != true) return null;

      final frameDoc = await FirebaseFirestore.instance
          .collection('screen_shares').doc(partnerUid)
          .collection('frames').doc('latest').get();
      if (!frameDoc.exists) return null;

      final frameData = frameDoc.get('data') as String?;
      if (frameData == null || frameData.isEmpty) return null;

      return 'firestore://screen_shares/$partnerUid/frames/latest?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return null;
    }
  }
}
