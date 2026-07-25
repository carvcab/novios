import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_ai_service.dart';
import '../home_navigation.dart';

class AiDownloadScreen extends StatefulWidget {
  final bool showSkip;
  const AiDownloadScreen({super.key, this.showSkip = true});

  @override
  State<AiDownloadScreen> createState() => _AiDownloadScreenState();
}

class _AiDownloadScreenState extends State<AiDownloadScreen> {
  final _ai = LocalAIService();
  Timer? _statusTimer;
  bool _downloading = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (_ai.isInitialized) {
      _done = true;
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() => _downloading = true);
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
    await _ai.initialize();
    _statusTimer?.cancel();
    if (mounted) {
      setState(() {
        _downloading = false;
        _done = _ai.isInitialized;
      });
    }
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Icon(Icons.auto_awesome_rounded, size: 72, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'IA de EverUs',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _done
                      ? 'IA instalada correctamente'
                      : 'Descarga el modelo de IA para obtener respuestas inteligentes, romanticas y offline',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tamaño: 1.1 GB',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              if (_downloading) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: _ai.downloadProgress > 0 ? _ai.downloadProgress : null,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_ai.downloadProgress * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _ai.status,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ] else if (_done) ...[
                const Icon(Icons.check_circle_rounded, size: 56, color: Colors.white),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Comenzar', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download_rounded),
                    label: Text('Descargar', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                if (widget.showSkip) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Mas tarde',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ],
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
