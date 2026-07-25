import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/aimodel_manager.dart';
import '../../services/local_storage.dart';
import '../home_navigation.dart';

class AiDownloadScreen extends StatefulWidget {
  final bool showSkip;
  const AiDownloadScreen({super.key, this.showSkip = true});

  @override
  State<AiDownloadScreen> createState() => _AiDownloadScreenState();
}

class _AiDownloadScreenState extends State<AiDownloadScreen>
    with WidgetsBindingObserver {
  final _manager = AimodelManager();
  bool _installing = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _manager.addListener(_onStateChange);
    _manager.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manager.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {
        _installing = _manager.isDownloading || _manager.isInstalling;
        if (_manager.state == ModelState.error) {
          _errorMsg = _manager.errorDetail;
        } else if (_manager.state == ModelState.ready) {
          _errorMsg = null;
        }
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() => _errorMsg = null);
    final ok = await _manager.downloadModel();
    if (!ok && mounted) {
      setState(() => _errorMsg = _manager.errorDetail);
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
    final model = _manager.currentModel;
    final isReady = _manager.state == ModelState.ready;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  isReady ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                  size: 72,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  isReady ? 'IA instalada correctamente' : 'Descargar IA',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                if (model != null) ...[
                  _infoRow('Modelo', model.name, theme),
                  _infoRow('Version', model.version, theme),
                  _infoRow('Tamano', '${model.sizeMB} MB', theme),
                  _infoRow('Espacio requerido', '${model.requiredSpaceMB} MB', theme),
                ],
                const SizedBox(height: 24),

                // Progress
                if (_installing) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _manager.progress > 0 ? _manager.progress : null,
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _manager.progressText,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (_manager.totalBytes > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(_manager.downloadedBytes / (1024 * 1024)).round()} MB / ${(_manager.totalBytes / (1024 * 1024)).round()} MB',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],

                // Error
                if (_errorMsg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Error',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMsg!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startDownload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Reintentar',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Actions
                if (!_installing && _errorMsg == null) ...[
                  if (isReady) ...[
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
                        child: Text('Comenzar',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: _startDownload,
                        icon: const Icon(Icons.download_rounded),
                        label: Text('Descargar',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (widget.showSkip) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Mas tarde',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
