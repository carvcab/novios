import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/webrtc_screen_share_service.dart';
import '../auth/login_screen.dart';

class SenderPage extends StatefulWidget {
  final String? customRoomId;
  const SenderPage({super.key, this.customRoomId});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {
  final _service = WebRTCScreenShareService();
  bool _isSharing = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeRoomId;

  @override
  void initState() {
    super.initState();
    _checkAuth();
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

  Future<void> _startSharing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _checkAuth();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final roomId = await _service.createRoomAndShareScreen(customRoomId: widget.customRoomId);
      if (mounted) {
        setState(() {
          _isSharing = true;
          _isLoading = false;
          _activeRoomId = roomId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _stopSharing() async {
    setState(() => _isLoading = true);
    await _service.stopAll();
    if (mounted) {
      setState(() {
        _isSharing = false;
        _isLoading = false;
        _activeRoomId = null;
      });
    }
  }

  @override
  void dispose() {
    if (_isSharing) {
      _service.stopAll();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isSharing
                          ? const Color(0xFFFF5C8A).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSharing ? Icons.sensors_rounded : Icons.screen_share_rounded,
                            size: 72,
                            color: _isSharing ? const Color(0xFFFF5C8A) : Colors.white24,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isSharing ? 'Transmitiendo Pantalla en Vivo' : 'Compartir Pantalla',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isSharing
                                ? 'Tu pareja puede ver tu pantalla en tiempo real.'
                                : 'Presiona el botón para solicitar permiso de captura e iniciar la transmisión WebRTC P2P.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          if (_isSharing && _activeRoomId != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Host: ${user?.email ?? "Usuario"}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    'Sala: $_activeRoomId',
                                    style: const TextStyle(color: Color(0xFFFF5C8A), fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 16),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : (_isSharing ? _stopSharing : _startSharing),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_isSharing ? Icons.stop_rounded : Icons.screen_share_rounded),
                  label: Text(
                    _isSharing ? 'Detener Transmisión' : 'Iniciar Transmisión de Pantalla',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSharing ? Colors.redAccent : const Color(0xFFFF5C8A),
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
