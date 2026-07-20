import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../services/storage_service.dart';

class VoiceMailboxScreen extends StatefulWidget {
  const VoiceMailboxScreen({super.key});

  @override
  State<VoiceMailboxScreen> createState() => _VoiceMailboxScreenState();
}

class _VoiceMailboxScreenState extends State<VoiceMailboxScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  final List<Map<String, dynamic>> _messages = [];
  final _noteCtrl = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  String? _nowPlaying;
  Uint8List? _cachedBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _loadMessages();
  }

  void _loadMessages() async {
    try {
      final list = await FirebaseService().loadListData('voice_mailbox');
      if (mounted) {
        setState(() {
          _messages.addAll(list);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _noteCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se necesita permiso del micrófono')),
        );
      }
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        bitRate: 12000,
        numChannels: 1,
      ),
      path: '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    setState(() {
      _isRecording = true;
    });
    _spinController.repeat();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _spinController.stop();
    setState(() {
      _isRecording = false;
    });
    if (path == null) return;

    // Show loading indicator in SnackBar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subiendo nota de voz... 🎙️')),
      );
    }

    final url = await StorageService().uploadAudio(path);
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir el audio')),
        );
      }
      return;
    }

    final myName = LocalStorage().getUserName() ?? 'Yo';
    final msg = {
      'title': 'Voz de $myName (${_messages.length + 1})',
      'date': DateTime.now().toIso8601String(),
      'audioUrl': url,
      'type': 'audio',
      'addedBy': myName,
    };

    setState(() {
      _messages.add(msg);
    });

    await FirebaseService().saveListData('voice_mailbox', _messages);
    await FirebaseService().sendActivityNotification(
      'dejó una nota de voz en el buzón 🎙️💌',
      'music',
      icon: 'music',
    );
  }

  Future<void> _playAudio(String url) async {
    if (_nowPlaying == url) {
      await _player.stop();
      _spinController.stop();
      setState(() => _nowPlaying = null);
      return;
    }

    await _player.stop();
    _spinController.repeat();

    if (url.startsWith('firestore://')) {
      final bytes = _cachedBytes ?? await StorageService().loadAudioBytes(url);
      if (bytes != null) {
        _cachedBytes = bytes;
        await _player.play(BytesSource(bytes));
      }
    } else {
      await _player.play(UrlSource(url));
    }

    setState(() => _nowPlaying = url);
    _player.onPlayerComplete.first.then((_) {
      if (mounted) {
        setState(() {
          _nowPlaying = null;
          _spinController.stop();
        });
      }
    });
  }

  void _addTextNote() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Mensaje en cápsula'),
          ],
        ),
        content: TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Tu mensaje para el futuro',
            hintText: 'Ej: ¡Te amo hoy y siempre!',
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_noteCtrl.text.trim().isEmpty) return;
              final myName = LocalStorage().getUserName() ?? 'Yo';
              final msg = {
                'title': 'Carta de $myName (${_messages.length + 1})',
                'date': DateTime.now().toIso8601String(),
                'note': _noteCtrl.text.trim(),
                'type': 'text',
                'addedBy': myName,
              };

              setState(() {
                _messages.add(msg);
              });

              await FirebaseService().saveListData('voice_mailbox', _messages);
              await FirebaseService().sendActivityNotification(
                'escribió una nota para el futuro 📝📬',
                'music',
                icon: 'music',
              );

              _noteCtrl.clear();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(int index) async {
    final msg = _messages[index];
    if (msg['type'] == 'audio' && msg['audioUrl'] != null) {
      await StorageService().deleteFile(msg['audioUrl'] as String);
    }
    setState(() {
      _messages.removeAt(index);
    });
    await FirebaseService().saveListData('voice_mailbox', _messages);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Buzón del Futuro', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Escribir nota',
            onPressed: _addTextNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── CASSETTE / GRABADORA CONTAINER ──
          _buildCassettePlayer(cs),

          const Divider(height: 1),

          // ── LISTA DE MENSAJES ──
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_rounded, size: 48, color: cs.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Buzón vacío',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Graba un audio o escribe una nota para el futuro.',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      DateTime? date;
                      final rawDate = msg['date'];
                      if (rawDate is String) {
                        date = DateTime.tryParse(rawDate);
                      } else if (rawDate is Timestamp) {
                        date = rawDate.toDate();
                      }
                      date ??= DateTime.now();

                      final isAudio = msg['type'] == 'audio';
                      final isPlaying = isAudio && _nowPlaying == msg['audioUrl'];
                      final author = msg['addedBy'] as String? ?? 'Pareja';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isPlaying ? cs.primary : cs.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isAudio ? Icons.volume_up_rounded : Icons.mark_email_unread_rounded,
                              color: isPlaying ? Colors.white : cs.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            msg['title'] as String? ?? (isAudio ? 'Mensaje de voz' : 'Nota escrita'),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Por $author • ${date.day}/${date.month}/${date.year}',
                            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAudio)
                                IconButton(
                                  icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: Colors.blue, size: 28),
                                  onPressed: () => _playAudio(msg['audioUrl'] as String),
                                ),
                              if (!isAudio)
                                IconButton(
                                  icon: const Icon(Icons.visibility_rounded, color: Colors.blue),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        title: Text(msg['title'] as String? ?? 'Nota escrita'),
                                        content: Text(
                                          msg['note'] as String? ?? '',
                                          style: GoogleFonts.caveat(fontSize: 22, fontWeight: FontWeight.w600),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteMessage(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // WIDGET INTERACTIVO DE CASSETE RETRO
  Widget _buildCassettePlayer(ColorScheme cs) {
    return Container(
      width: double.infinity,
      color: cs.primaryContainer.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Cassette Card
          Container(
            width: 280,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2F33), // Cassette dark body
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2124), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Etiqueta superior del casete
                Container(
                  width: double.infinity,
                  height: 36,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _isRecording ? '• GRABANDO AUDIO' : (_nowPlaying != null ? 'REPRODUCIENDO...' : 'CASSETTE TAPE C-90'),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Reels del casete (Carretes)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReel(),
                    Container(
                      width: 48,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'AMOR',
                          style: TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    _buildReel(),
                  ],
                ),
                const Spacer(),
                // Línea inferior de decoración
                Container(
                  height: 12,
                  width: double.infinity,
                  color: Colors.black26,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => Container(width: 8, height: 4, color: Colors.white12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Botón gigante para grabar
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : cs.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : cs.primary).withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? 'Toca para detener' : 'Toca para grabar nota de voz',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _isRecording ? Colors.red : cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReel() {
    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _spinController.value * 2 * pi,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.grey.shade700, width: 3),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radios de los engranajes
                ...List.generate(6, (i) {
                  final angle = i * pi / 3;
                  return Transform.rotate(
                    angle: angle,
                    child: Container(
                      width: 2,
                      height: 36,
                      color: Colors.grey.shade800,
                    ),
                  );
                }),
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
