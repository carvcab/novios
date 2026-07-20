import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription? _answerSub;
  StreamSubscription? _calleeCandidateSub;

  Future<String> requestScreenShare() async {
    try {
      final result = await _channel.invokeMethod('requestScreenShare');
      if (result == 'granted') {
        _isSharing = true;
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
    try {
      await _channel.invokeMethod('stopScreenShare');
    } catch (_) {}
  }

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

  Future<String> startWebRTCShare({
    required RTCVideoRenderer localRenderer,
    String? roomId,
  }) async {
    if (roomId == null || roomId.isEmpty) roomId = _firestore.collection('rooms').doc().id;
    final roomRef = _firestore.collection('rooms').doc(roomId);

    _peerConnection = await createPeerConnection(_iceConfig);

    try {
      _localStream = await navigator.mediaDevices
          .getDisplayMedia({'audio': false, 'video': {'mandatory': {'minWidth': '640', 'minHeight': '480', 'minFrameRate': '30'}}})
          .timeout(const Duration(seconds: 15));
      localRenderer.srcObject = _localStream;
    } catch (e) {
      debugPrint('[WebRTC] getDisplayMedia error: $e');
      _peerConnection?.close();
      _peerConnection = null;
      rethrow;
    }

    _localStream?.getTracks().forEach((t) => _peerConnection?.addTrack(t, _localStream!));

    _peerConnection!.onIceCandidate = (c) {
      if (c.candidate != null && c.candidate!.isNotEmpty) {
        roomRef.collection('callerCandidates').add(c.toMap());
      }
    };

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await roomRef.set({
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    _answerSub = roomRef.snapshots().listen((s) async {
      if (!s.exists) return;
      final d = s.data();
      if (d != null && d['answer'] != null && _peerConnection?.getRemoteDescription() == null) {
        await _peerConnection?.setRemoteDescription(RTCSessionDescription(d['answer']['sdp'], d['answer']['type']));
      }
    });

    _calleeCandidateSub = roomRef.collection('calleeCandidates').snapshots().listen((s) {
      for (final c in s.docChanges) {
        if (c.type == DocumentChangeType.added) {
          final d = c.doc.data();
          if (d != null && d['candidate'] != null) {
            _peerConnection?.addCandidate(RTCIceCandidate(d['candidate'], d['sdpMid'], d['sdpMLineIndex']));
          }
        }
      }
    });

    return roomId;
  }

  Future<void> joinWebRTC(String roomId, RTCVideoRenderer remoteRenderer) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final snap = await roomRef.get();
    if (!snap.exists) throw Exception('La sala no existe');

    _peerConnection = await createPeerConnection(_iceConfig);

    _peerConnection!.onTrack = (e) {
      if (e.streams.isNotEmpty) remoteRenderer.srcObject = e.streams[0];
    };

    _peerConnection!.onIceCandidate = (c) {
      if (c.candidate != null && c.candidate!.isNotEmpty) {
        roomRef.collection('calleeCandidates').add(c.toMap());
      }
    };

    final data = snap.data()!;
    final offer = data['offer'];
    if (offer == null) throw Exception('Sin oferta SDP');

    await _peerConnection!.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    await roomRef.update({'answer': {'type': answer.type, 'sdp': answer.sdp}});

    roomRef.collection('callerCandidates').snapshots().listen((s) {
      for (final c in s.docChanges) {
        if (c.type == DocumentChangeType.added) {
          final d = c.doc.data();
          if (d != null && d['candidate'] != null) {
            _peerConnection?.addCandidate(RTCIceCandidate(d['candidate'], d['sdpMid'], d['sdpMLineIndex']));
          }
        }
      }
    });
  }

  Future<void> hangUpWebRTC({RTCVideoRenderer? local, RTCVideoRenderer? remote, String? roomId}) async {
    _answerSub?.cancel();
    _calleeCandidateSub?.cancel();
    local?.srcObject = null;
    remote?.srcObject = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    if (roomId != null && roomId.isNotEmpty) {
      try { await _firestore.collection('rooms').doc(roomId).delete(); } catch (_) {}
    }
  }

  void dispose() {
    _frameCtrl.close();
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

  Future<String?> getPartnerFrameUrl() async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return null;
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      if (!snap.exists) return null;
      final data = snap.data()!;
      final partnerUid = data['partnerUid'] as String?;
      if (partnerUid == null || partnerUid.isEmpty) return null;
      final partnerDoc = await _firestore.collection('users').doc(partnerUid).get();
      if (partnerDoc.data()?['screenShareActive'] != true) return null;
      final frameDoc = await _firestore.collection('screen_shares').doc(partnerUid).collection('frames').doc('latest').get();
      if (!frameDoc.exists) return null;
      if (frameDoc.get('data') == null) return null;
      return 'firestore://screen_shares/$partnerUid/frames/latest';
    } catch (_) { return null; }
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Map<String, dynamic> get _iceConfig => {
    'iceServers': [{'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']}]
  };
}
