import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Servicio para compartir pantalla usando WebRTC y la colección 'rooms' en Firestore.
class WebRTCScreenShareService {
  static final WebRTCScreenShareService _instance = WebRTCScreenShareService._internal();
  factory WebRTCScreenShareService() => _instance;
  WebRTCScreenShareService._internal();

  static const _appChannel = MethodChannel('com.novios/app');

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer? _remoteRenderer;

  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  StreamSubscription<QuerySnapshot>? _candidatesSubscription;

  bool _isSharing = false;
  bool _isViewing = false;
  String? _currentRoomId;

  bool get isSharing => _isSharing;
  bool get isViewing => _isViewing;
  String? get currentRoomId => _currentRoomId;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

  /// 1. CREAR SALA Y COMPARTIR PANTALLA (HOST / CALLER)
  Future<String> createRoomAndShareScreen({String? customRoomId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. Inicia sesión primero.');
    }

    await stopAll();

    final roomId = (customRoomId != null && customRoomId.isNotEmpty)
        ? customRoomId
        : 'room_${user.uid}';
    _currentRoomId = roomId;

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    // Limpiar sala previa si existía
    await _deleteRoomFirestore(roomRef);

    // 1. Iniciar servicio Foreground para Android 14+ (MediaProjection requirement)
    try {
      await _appChannel.invokeMethod('startScreenShareService');
    } catch (e) {
      debugPrint('startScreenShareService error: $e');
    }

    // 2. Obtener captura de pantalla con resolución y FPS optimizados para Android (720p 15fps)
    try {
      _localStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'width': 720,
          'height': 1280,
          'frameRate': 15,
        },
        'audio': false,
      });
    } catch (e) {
      debugPrint('Fallback getDisplayMedia: $e');
      _localStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });
    }

    if (_localStream == null) {
      throw Exception('No se otorgó permiso para capturar la pantalla.');
    }

    // 2. Crear RTCPeerConnection
    _peerConnection = await createPeerConnection(_iceServers);

    // 3. Agregar Pistas de Video y escuchar la finalización por parte del sistema OS
    for (var track in _localStream!.getTracks()) {
      track.onEnded = () {
        debugPrint('[WebRTC] MediaProjection track finalizada por el sistema.');
        stopAll();
      };
      _peerConnection!.addTrack(track, _localStream!);
    }

    // 4. Enviar ICE Candidates (callerCandidates)
    final callerCandidatesCol = roomRef.collection('callerCandidates');
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        callerCandidatesCol.add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // 5. Crear Oferta SDP
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // 6. Guardar Sala en Firestore (solo SDP y metadata)
    await roomRef.set({
      'ownerUid': user.uid,
      'ownerEmail': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'offer': {
        'sdp': offer.sdp,
        'type': offer.type,
      },
    });

    // 7. Escuchar respuesta (Answer SDP) del Callee
    bool remoteDescriptionSet = false;
    _roomSubscription = roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null && data['answer'] != null && !remoteDescriptionSet) {
        remoteDescriptionSet = true;
        final answerMap = data['answer'] as Map<String, dynamic>;
        final answer = RTCSessionDescription(
          answerMap['sdp'] as String,
          answerMap['type'] as String,
        );
        await _peerConnection?.setRemoteDescription(answer);
      }
    });

    // 8. Escuchar ICE Candidates del Callee
    final processedDocs = <String>{};
    _candidatesSubscription = roomRef
        .collection('calleeCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          if (!processedDocs.contains(docId)) {
            processedDocs.add(docId);
            final data = change.doc.data();
            if (data != null) {
              final candidate = RTCIceCandidate(
                data['candidate'] as String?,
                data['sdpMid'] as String?,
                data['sdpMLineIndex'] as int?,
              );
              _peerConnection?.addCandidate(candidate);
            }
          }
        }
      }
    });

    _isSharing = true;
    return roomId;
  }

  /// 2. UNIRSE A SALA Y VER PANTALLA (VIEWER / CALLEE)
  Future<void> joinRoomAndWatchScreen({
    required String roomId,
    required RTCVideoRenderer remoteRenderer,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. Inicia sesión primero.');
    }

    await stopAll();

    _currentRoomId = roomId;
    _remoteRenderer = remoteRenderer;

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('La sala no existe o la transmisión ya ha finalizado.');
    }

    final roomData = roomSnapshot.data() as Map<String, dynamic>;
    if (roomData['offer'] == null) {
      throw Exception('La sala no contiene una oferta SDP válida.');
    }

    // 1. Crear RTCPeerConnection
    _peerConnection = await createPeerConnection(_iceServers);

    // 2. Escuchar Pistas de Video del Remote Stream
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    // 3. Enviar ICE Candidates (calleeCandidates)
    final calleeCandidatesCol = roomRef.collection('calleeCandidates');
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        calleeCandidatesCol.add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // 4. Establecer Oferta Remota
    final offerMap = roomData['offer'] as Map<String, dynamic>;
    final offer = RTCSessionDescription(
      offerMap['sdp'] as String,
      offerMap['type'] as String,
    );
    await _peerConnection!.setRemoteDescription(offer);

    // 5. Crear Respuesta SDP
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // 6. Actualizar Firestore con la Respuesta SDP
    await roomRef.update({
      'answer': {
        'sdp': answer.sdp,
        'type': answer.type,
      },
    });

    // 7. Escuchar ICE Candidates del Host (callerCandidates)
    final processedDocs = <String>{};
    _candidatesSubscription = roomRef
        .collection('callerCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          if (!processedDocs.contains(docId)) {
            processedDocs.add(docId);
            final data = change.doc.data();
            if (data != null) {
              final candidate = RTCIceCandidate(
                data['candidate'] as String?,
                data['sdpMid'] as String?,
                data['sdpMLineIndex'] as int?,
              );
              _peerConnection?.addCandidate(candidate);
            }
          }
        }
      }
    });

    // 8. Escuchar si la sala es eliminada por el dueño
    _roomSubscription = roomRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        stopAll();
      }
    });

    _isViewing = true;
  }

  /// 3. DETENER TRANSMISIÓN Y LIMPIAR
  Future<void> stopAll() async {
    _roomSubscription?.cancel();
    _roomSubscription = null;

    _candidatesSubscription?.cancel();
    _candidatesSubscription = null;

    if (_currentRoomId != null && _isSharing) {
      final user = FirebaseAuth.instance.currentUser;
      final roomId = _currentRoomId!;
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);

      try {
        final snap = await roomRef.get();
        if (snap.exists) {
          final data = snap.data();
          // Solo el propietario autenticado puede eliminar la sala
          if (user != null && data != null && data['ownerUid'] == user.uid) {
            await _deleteRoomFirestore(roomRef);
          }
        }
      } catch (e) {
        debugPrint('Error al eliminar sala en Firestore: $e');
      }
    }

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = null;
      _remoteRenderer = null;
    }

    await _peerConnection?.close();
    _peerConnection = null;

    try {
      await _appChannel.invokeMethod('stopScreenShareService');
    } catch (_) {}

    _isSharing = false;
    _isViewing = false;
    _currentRoomId = null;
  }

  Future<void> _deleteRoomFirestore(DocumentReference roomRef) async {
    try {
      final callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var doc in callerCandidates.docs) {
        await doc.reference.delete();
      }
      final calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var doc in calleeCandidates.docs) {
        await doc.reference.delete();
      }
      await roomRef.delete();
    } catch (e) {
      debugPrint('Error al borrar sala previa: $e');
    }
  }
}
