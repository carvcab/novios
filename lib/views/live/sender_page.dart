import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/screen_share_service.dart';

class SenderPage extends StatefulWidget {
  final String? customRoomId;
  const SenderPage({super.key, this.customRoomId});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {
  final _service = ScreenShareService();
  bool _isSharing = false;
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _previewBytes;
  DateTime _lastPreview = DateTime(2000);
  StreamSubscription? _frameSub;

  Future<void> _startSharing() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final r = await _service.requestScreenShare();
      if (r != 'granted') {
        if (mounted) setState(() { _errorMessage = r.contains('error') ? r : 'Permiso denegado'; _isLoading = false; });
        return;
      }
      _frameSub = _service.frameStream.listen((bytes) {
        if (!mounted) return;
        final now = DateTime.now();
        if (now.difference(_lastPreview).inMilliseconds < 1000) return;
        _lastPreview = now;
        setState(() => _previewBytes = bytes);
      });
      if (mounted) setState(() { _isSharing = true; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Error: $e'; _isLoading = false; });
    }
  }

  Future<void> _stopSharing() async {
    setState(() => _isLoading = true);
    _frameSub?.cancel();
    await _service.stopScreenShare();
    if (mounted) setState(() { _isSharing = false; _isLoading = false; _previewBytes = null; });
  }

  @override
  void dispose() {
    _frameSub?.cancel();
    _service.stopScreenShare();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Compartir Mi Pantalla', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: _previewBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_previewBytes!, fit: BoxFit.contain))
                    : Container(
                        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.screen_share_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('Presiona "Iniciar" para compartir tu pantalla',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14), textAlign: TextAlign.center),
                          ]),
                        ),
                      ),
              ),
              if (_errorMessage != null)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : (_isSharing ? _stopSharing : _startSharing),
                  icon: Icon(_isSharing ? Icons.stop_rounded : Icons.screen_share_rounded),
                  label: Text(_isSharing ? 'Detener Transmisión' : 'Iniciar Transmisión de Pantalla',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSharing ? Colors.redAccent : const Color(0xFFFF5C8A),
                    foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
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
