import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/webrtc_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/video_renderer.dart';

/// Pantalla del Emisor (Sender / Compartir Pantalla)
/// Permite capturar la pantalla del dispositivo Android mediante MediaProjection,
/// generar la oferta WebRTC y compartir el ID de sala con la pareja.
class SenderPage extends StatefulWidget {
  final String? customRoomId;

  const SenderPage({super.key, this.customRoomId});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {
  final _webRTCService = WebRTCService();
  final _localRenderer = RTCVideoRenderer();

  bool _isInitialized = false;
  bool _isSharing = false;
  bool _isLoading = false;
  String? _roomId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _startSharing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final defaultCoupleId = FirebaseService().coupleId;
      final roomIdToUse = widget.customRoomId ?? (defaultCoupleId.isNotEmpty ? defaultCoupleId : null);

      final createdRoomId = await _webRTCService.createRoom(
        localRenderer: _localRenderer,
        customRoomId: roomIdToUse,
      );

      if (mounted) {
        setState(() {
          _roomId = createdRoomId;
          _isSharing = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al iniciar la captura de pantalla: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _stopSharing() async {
    setState(() => _isLoading = true);
    await _webRTCService.hangUp(
      localRenderer: _localRenderer,
      roomId: _roomId,
    );
    if (mounted) {
      setState(() {
        _isSharing = false;
        _isLoading = false;
        _roomId = null;
      });
    }
  }

  @override
  void dispose() {
    _webRTCService.hangUp(
      localRenderer: _localRenderer,
      roomId: _roomId,
    );
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Compartir Mi Pantalla', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Vista Previa de la Transmisión de Pantalla
              Expanded(
                child: _isInitialized
                    ? RTCVideoRendererWidget(
                        renderer: _localRenderer,
                        placeholderText: _isSharing
                            ? 'Transmitiendo pantalla en vivo...'
                            : 'Presiona "Iniciar Transmisión" para compartir tu pantalla',
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF5C8A)),
                      ),
              ),
              const SizedBox(height: 20),

              // Alerta de Error
              if (_errorMessage != null)
                Container(
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

              // Tarjeta con ID de Sala
              if (_roomId != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF5C8A).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.meeting_room_rounded, color: Color(0xFFFF5C8A)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ID de Sala para tu pareja',
                              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _roomId!,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFFFF5C8A)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _roomId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID de sala copiado al portapapeles!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              // Botón Principal de Acción
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : (_isSharing ? _stopSharing : _startSharing),
                  icon: Icon(_isSharing ? Icons.stop_rounded : Icons.screen_share_rounded),
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
