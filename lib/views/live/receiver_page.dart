import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/local_storage.dart';

class ReceiverPage extends StatefulWidget {
  final String? initialRoomId;
  const ReceiverPage({super.key, this.initialRoomId});

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage> {
  bool _isConnected = false;
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _remoteBytes;
  Timer? _pollTimer;
  String? _partnerUid;

  @override
  void initState() {
    super.initState();
    _findPartner();
  }

  Future<void> _findPartner() async {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final p = doc.data()!['partnerUid'] as String?;
      if (p != null && p.isNotEmpty) setState(() => _partnerUid = p);
    } catch (_) {}
  }

  Future<void> _connect() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    if (_partnerUid == null) {
      if (mounted) setState(() { _errorMessage = 'Vincula una pareja primero'; _isLoading = false; });
      return;
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollFrame());
    if (mounted) setState(() { _isConnected = true; _isLoading = false; });
  }

  Future<void> _pollFrame() async {
    if (_partnerUid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('screen_shares').doc(_partnerUid)
          .collection('frames').doc('latest').get();
      if (!doc.exists) return;
      final b64 = doc.get('data') as String?;
      if (b64 == null || b64.isEmpty) return;
      final bytes = base64Decode(b64);
      if (mounted) setState(() => _remoteBytes = bytes);
    } catch (_) {}
  }

  void _disconnect() {
    _pollTimer?.cancel();
    _pollTimer = null;
    setState(() { _isConnected = false; _remoteBytes = null; });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Ver Pantalla Remota', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                ),
              Expanded(
                child: _remoteBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_remoteBytes!, fit: BoxFit.contain))
                    : Container(
                        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.tv_rounded, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text(_isConnected ? 'Esperando transmisión...' : 'Conéctate para ver la pantalla de tu pareja',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14), textAlign: TextAlign.center),
                          ]),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : (_isConnected ? _disconnect : _connect),
                  icon: Icon(_isConnected ? Icons.call_end_rounded : Icons.play_arrow_rounded),
                  label: Text(_isConnected ? 'Desconectar' : 'Conectar y Ver Pantalla',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.redAccent : const Color(0xFFFF5C8A),
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
