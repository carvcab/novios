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

  static const _channel = MethodChannel('com.novios/screen_share');
  static const _uploadInterval = Duration(seconds: 2);

  final _frameCtrl = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get frameStream => _frameCtrl.stream;

  bool _isSharing = false;
  bool get isSharing => _isSharing;

  DateTime? _lastUploadTime;
  int _lastFrameHash = 0;

  void init() {
    _channel.setMethodCallHandler((call) async {
      try {
        if (call.method == 'onFrame') {
          final bytes = call.arguments as Uint8List?;
          if (bytes != null && bytes.isNotEmpty) {
            if (!_frameCtrl.isClosed) _frameCtrl.add(bytes);
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

  Future<void> stopScreenShare() async {
    _isSharing = false;
    _lastUploadTime = null;
    _lastFrameHash = 0;
    await _markSharingActive(false);
    try { await _channel.invokeMethod('stopScreenShare'); } catch (_) {}
  }

  Future<void> _markSharingActive(bool active) async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'screenShareActive': active,
        'screenShareUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _uploadFrame(Uint8List bytes) async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;
    if (_lastUploadTime != null && DateTime.now().difference(_lastUploadTime!) < _uploadInterval) return;
    final hash = _hashBytes(bytes);
    if (hash == _lastFrameHash) return;
    _lastFrameHash = hash;
    try {
      final b64 = base64Encode(bytes);
      await _firestore.collection('screen_shares').doc(uid).collection('frames').doc('latest').set({
        'data': b64,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _lastUploadTime = DateTime.now();
    } catch (_) {}
  }

  int _hashBytes(Uint8List bytes) {
    int h = 0;
    for (int i = 0; i < bytes.length; i += 500) h = 31 * h + bytes[i];
    return h;
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  void dispose() {
    _frameCtrl.close();
  }
}
