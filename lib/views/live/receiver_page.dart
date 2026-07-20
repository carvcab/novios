import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/webrtc_screen_share_service.dart';
import '../../services/local_storage.dart';
import '../auth/login_screen.dart';

class ReceiverPage extends StatefulWidget {
  final String? initialRoomId;
  const ReceiverPage({super.key, this.customRoomId, this.initialRoomId});
  final String? customRoomId;

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  final _service = WebRTCScreenShareService();
  final _remoteRenderer = RTCVideoRenderer();
  bool _isRendererInitialized = false;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _partnerUid;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _initRenderer();
    _findPartner();
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
    if (mounted) {
      setState(() => _isRendererInitialized = true);
    }
  }

  Future<void> _findPartner() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? LocalStorage().getUserId();
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final p = doc.data()?['partnerUid'] as String?;
      if (p != null && p.isNotEmpty && mounted) {
        setState(() => _partnerUid = p);
      }
    } catch (_) {}
  }

  String _getRoomId() {
    if (widget.initialRoomId != null && widget.initialRoomId!.isNotEmpty) {
      return widget.initialRoomId!;
    }
    if (widget.customRoomId != null && widget.customRoomId!.isNotEmpty) {
      return widget.customRoomId!;
    }
    final coupleId = LocalStorage().getString('couple_id');
    if (coupleId != null && coupleId.isNotEmpty && coupleId != 'default_couple_id') {
      return coupleId;
    }
    if (_partnerUid != null) {
      return 'room_$_partnerUid';
    }
    return 'room_${FirebaseAuth.instance.currentUser?.uid}';
  }

  Future<void> _connect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _checkAuth();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final roomId = _getRoomId();

    try {
      await _service.joinRoomAndWatchScreen(
        roomId: roomId,
        remoteRenderer: _remoteRenderer,
      );
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
          _isConnected = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _service.stopAll();
    _remoteRenderer.srcObject = null;
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _service.stopAll();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isConnected
                          ? const Color(0xFFFF5C8A).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _isConnected && _isRendererInitialized
                        ? RTCVideoView(
                            _remoteRenderer,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tv_rounded,
                                    size: 72,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isConnected
                                        ? 'Conectando a la señal en vivo...'
                                        : 'Ver Pantalla Remota',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Conéctate a la sala de tu pareja para transmitir video directamente en tiempo real mediante WebRTC.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : (_isConnected ? _disconnect : _connect),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_isConnected ? Icons.call_end_rounded : Icons.play_arrow_rounded),
                  label: Text(
                    _isConnected ? 'Desconectar' : 'Conectar y Ver Pantalla',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.redAccent : const Color(0xFFFF5C8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
