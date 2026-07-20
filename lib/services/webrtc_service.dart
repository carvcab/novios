import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Servicio responsable de la señalización WebRTC y la captura de pantalla
/// mediante MediaProjection en Android y WebRTC PeerConnection en tiempo real.
class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _callerCandidatesSubscription;
  StreamSubscription? _calleeCandidatesSubscription;

  /// Configuración de servidores STUN públicos de Google para atravesar NAT/Firewalls
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ]
  };

  /// Iniciar la transmisión de pantalla (Sender / Compartir Pantalla)
  /// Crea una sala en Firestore ('rooms/$roomId') con el SDP Offer y envía ICE Candidates.
  Future<String> createRoom({
    required RTCVideoRenderer localRenderer,
    String? customRoomId,
  }) async {
    final roomId = customRoomId ?? _firestore.collection('rooms').doc().id;
    final roomRef = _firestore.collection('rooms').doc(roomId);

    _peerConnection = await createPeerConnection(_configuration);

    try {
      final mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'optional': [],
        }
      };
      _localStream = await navigator.mediaDevices
          .getDisplayMedia(mediaConstraints)
          .timeout(const Duration(seconds: 15));
      localRenderer.srcObject = _localStream;
    } catch (e) {
      debugPrint('[WebRTCService] Error al capturar pantalla: $e');
      await _peerConnection?.close();
      _peerConnection = null;
      rethrow;
    }

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    final callerCandidatesCollection = roomRef.collection('callerCandidates');
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate.isNotEmpty) {
        callerCandidatesCollection.add(candidate.toMap());
      }
    };

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await roomRef.set({
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    _answerSubscription = roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data != null && data['answer'] != null && _peerConnection?.getRemoteDescription() == null) {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
        );
      }
    });

    _calleeCandidatesSubscription = roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['candidate'] != null) {
            _peerConnection?.addCandidate(
              RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
            );
          }
        }
      }
    });

    return roomId;
  }

  /// Conectarse para visualizar una pantalla (Receiver / Ver Pantalla)
  /// Lee el SDP Offer desde Firestore ('rooms/$roomId'), genera el Answer y escucha ICE Candidates.
  Future<void> joinRoom({
    required String roomId,
    required RTCVideoRenderer remoteRenderer,
  }) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw Exception('La sala con ID "$roomId" no existe en Firestore.');
    }

    // 1. Crear PeerConnection
    _peerConnection = await createPeerConnection(_configuration);

    // 2. Asignar Stream remoto al renderizador cuando se reciba el track o stream
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };
    _peerConnection?.onAddStream = (MediaStream stream) {
      remoteRenderer.srcObject = stream;
    };

    // 3. Recolectar candidatos ICE del receptor y guardarlos en subcolección calleeCandidates
    final calleeCandidatesCollection = roomRef.collection('calleeCandidates');
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        calleeCandidatesCollection.add(candidate.toMap());
      }
    };

    // 4. Obtener Offer de Firestore y establecer la Descripción Remota
    final data = roomSnapshot.data();
    final offer = data?['offer'];
    if (offer == null) {
      throw Exception('La sala no contiene una oferta SDP válida.');
    }

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    // 5. Crear SDP Answer y establecer Descripción Local
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    final roomWithAnswer = <String, dynamic>{
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      }
    };
    await roomRef.update(roomWithAnswer);

    // 6. Escuchar candidatos ICE del emisor (callerCandidates)
    _callerCandidatesSubscription = roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final candidateData = change.doc.data();
          if (candidateData != null) {
            _peerConnection?.addCandidate(
              RTCIceCandidate(
                candidateData['candidate'],
                candidateData['sdpMid'],
                candidateData['sdpMLineIndex'],
              ),
            );
          }
        }
      }
    });
  }

  /// Finalizar la transmisión y limpiar recursos de renderizadores y Firestore
  Future<void> hangUp({
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
    String? roomId,
  }) async {
    _answerSubscription?.cancel();
    _callerCandidatesSubscription?.cancel();
    _calleeCandidatesSubscription?.cancel();

    if (localRenderer != null) {
      localRenderer.srcObject = null;
    }
    if (remoteRenderer != null) {
      remoteRenderer.srcObject = null;
    }

    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    await _localStream?.dispose();
    _localStream = null;

    await _peerConnection?.close();
    _peerConnection = null;

    if (roomId != null && roomId.isNotEmpty) {
      try {
        await _firestore.collection('rooms').doc(roomId).delete();
      } catch (e) {
        debugPrint('[WebRTCService] Error al limpiar sala $roomId: $e');
      }
    }
  }
}
