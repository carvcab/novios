import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/webrtc_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/video_renderer.dart';

/// Pantalla del Receptor (Receiver / Ver Pantalla)
/// Conecta con la sala mediante WebRTC en Firestore para recibir y renderizar
/// la transmisión de pantalla remota en tiempo real.
class ReceiverPage extends StatefulWidget {
  final String? initialRoomId;

  const ReceiverPage({super.key, this.initialRoomId});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  final _webRTCService = WebRTCService();
  final _remoteRenderer = RTCVideoRenderer();
  final _roomIdController = TextEditingController();

  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
    final coupleId = FirebaseService().coupleId;
    final defaultId = widget.initialRoomId ?? (coupleId.isNotEmpty ? coupleId : '');
    _roomIdController.text = defaultId;

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa un ID de sala válido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _webRTCService.joinRoom(
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
          _errorMessage = 'No se pudo conectar a la sala: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _webRTCService.hangUp(
      remoteRenderer: _remoteRenderer,
    );
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _webRTCService.hangUp(
      remoteRenderer: _remoteRenderer,
    );
    _remoteRenderer.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Ver Pantalla Remota', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Campo de Entrada para ID de Sala si no está conectado
              if (!_isConnected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: _roomIdController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Ingresa el ID de sala o código de tu pareja',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      icon: Icon(Icons.vpn_key_rounded, color: Color(0xFFFF5C8A)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mensaje de Error
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

              // Renderizador de Video WebRTC Remoto
              Expanded(
                child: _isInitialized
                    ? RTCVideoRendererWidget(
                        renderer: _remoteRenderer,
                        placeholderText: _isConnected
                            ? 'Sintonizando transmisión de video en vivo...'
                            : 'Ingresa el ID de sala y presiona "Conectar" para ver la pantalla',
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF5C8A)),
                      ),
              ),
              const SizedBox(height: 20),

              // Botón Principal de Conectar / Desconectar
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : (_isConnected ? _disconnect : _joinRoom),
                  icon: Icon(_isConnected ? Icons.call_end_rounded : Icons.play_arrow_rounded),
                  label: Text(
                    _isConnected ? 'Desconectar Transmisión' : 'Conectar y Ver Pantalla',
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
