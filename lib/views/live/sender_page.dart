import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/screen_share_service.dart';
import '../../services/local_storage.dart';

class SenderPage extends StatefulWidget {
  final String? customRoomId;
  const SenderPage({super.key, this.customRoomId});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> {
  final _screenShareService = ScreenShareService();
  bool _isSharing = false;
  bool _isLoading = false;
  String? _errorMessage;
  ImageProvider? _previewImage;

  Future<void> _startSharing() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await _screenShareService.requestScreenShare();
      if (result != 'granted') {
        setState(() {
          _errorMessage = result.contains('error') ? 'Error al iniciar captura: $result' : 'Permiso denegado';
          _isLoading = false;
        });
        return;
      }

      setState(() => _isSharing = true);
      _screenShareService.frameStream.listen((bytes) {
        if (!mounted) return;
        setState(() => _previewImage = MemoryImage(bytes));
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _stopSharing() async {
    setState(() => _isLoading = true);
    await _screenShareService.stopScreenShare();
    if (mounted) setState(() {
      _isSharing = false;
      _isLoading = false;
      _previewImage = null;
    });
  }

  @override
  void dispose() {
    _screenShareService.stopScreenShare();
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
                child: _previewImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image(image: _previewImage!, fit: BoxFit.contain),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.screen_share_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text('Presiona "Iniciar" para compartir tu pantalla',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              if (_errorMessage != null)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
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
