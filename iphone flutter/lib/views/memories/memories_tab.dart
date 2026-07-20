import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/memory_model.dart';
import '../../services/firebase_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/firestore_image.dart';
import 'memory_detail_screen.dart';

class MemoriesTab extends StatefulWidget {
  final bool isStandalone;
  const MemoriesTab({this.isStandalone = false, super.key});

  @override
  State<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<MemoriesTab> with SingleTickerProviderStateMixin {
  void _addPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.first.path;
    if (filePath == null || filePath.isEmpty) return;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemoryScreen(filePath: filePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget body = StreamBuilder<List<MemoryModel>>(
      stream: FirebaseService().streamMemories(),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 64, color: cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text('Álbum vacío',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Text('Agrega tus primeros recuerdos juntos', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addPhoto,
                  icon: const Icon(Icons.add_a_photo_rounded),
                  label: const Text('Agregar foto'),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final mem = list[index];
                    final heights = [1.0, 1.2, 0.9, 1.1];
                    final aspect = heights[index % heights.length];
                    return _MemoryTile(
                      memory: mem,
                      aspectRatio: aspect,
                      cs: cs,
                      index: index,
                    );
                  },
                  childCount: list.length,
                ),
              ),
            ),
          ],
        );
      },
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isStandalone
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Álbum de Recuerdos', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            )
          : null,
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        backgroundColor: const Color(0xFFFF4081),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_a_photo_rounded),
      ),
    );
  }
}

class AddMemoryScreen extends StatefulWidget {
  final String filePath;
  const AddMemoryScreen({required this.filePath, super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _decorStyle = 'standard';
  final List<String> _decorStickers = [];
  bool _isSaving = false;

  final List<Map<String, dynamic>> _stylesList = [
    {'id': 'standard', 'name': 'Estándar', 'icon': Icons.crop_original_rounded},
    {'id': 'polaroid', 'name': 'Polaroid', 'icon': Icons.picture_in_picture_rounded},
    {'id': 'romantic', 'name': 'Romántico', 'icon': Icons.favorite_rounded},
    {'id': 'vintage', 'name': 'Vintage', 'icon': Icons.history_edu_rounded},
    {'id': 'ticket', 'name': 'Boleto', 'icon': Icons.local_activity_rounded},
    {'id': 'heart_frame', 'name': 'Corazones', 'icon': Icons.favorite_border_rounded},
    {'id': 'stars_frame', 'name': 'Estrellado', 'icon': Icons.star_border_rounded},
    {'id': 'floral', 'name': 'Floral', 'icon': Icons.local_florist_rounded},
    {'id': 'glow', 'name': 'Neón', 'icon': Icons.wb_twilight_rounded},
  ];

  final List<Map<String, String>> _stickersList = [
    {'id': 'heart', 'emoji': '❤️'},
    {'id': 'star', 'emoji': '⭐'},
    {'id': 'flower', 'emoji': '🌸'},
    {'id': 'cat', 'emoji': '🐱'},
    {'id': 'kiss', 'emoji': '💋'},
    {'id': 'party', 'emoji': '🎉'},
    {'id': 'bear', 'emoji': '🧸'},
    {'id': 'ring', 'emoji': '💍'},
    {'id': 'sparkles', 'emoji': '✨'},
    {'id': 'rainbow', 'emoji': '🌈'},
    {'id': 'chocolate', 'emoji': '🍫'},
    {'id': 'music', 'emoji': '🎵'},
    {'id': 'popcorn', 'emoji': '🍿'},
    {'id': 'airplane', 'emoji': '✈️'},
    {'id': 'house', 'emoji': '🏠'},
  ];

  String _emojiForSticker(String id) {
    for (final st in _stickersList) {
      if (st['id'] == id) return st['emoji']!;
    }
    return '✨';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveMemory() async {
    setState(() => _isSaving = true);

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/photos');
    if (!await photosDir.exists()) await photosDir.create(recursive: true);
    final ext = widget.filePath.split('.').last;
    final localPath = '${photosDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(widget.filePath).copy(localPath);

    String? url;
    try {
      url = await StorageService().uploadPhoto(widget.filePath);
    } catch (e) {
      debugPrint("Error uploading photo to storage: $e");
    }

    final titleText = _titleCtrl.text.trim().isEmpty ? 'Recuerdo Especial' : _titleCtrl.text.trim();
    final mem = MemoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleText,
      description: _descCtrl.text.trim(),
      date: _selectedDate,
      type: 'photo',
      mediaPaths: [url ?? localPath],
      decorStyle: _decorStyle,
      decorStickers: _decorStickers,
    );

    await FirebaseService().addMemory(mem);
    FirebaseService().sendActivityNotification('Subió una nueva foto decorada al álbum 📸', 'photo', icon: 'photo');

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Recuerdo guardado con éxito! 💖')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fileImage = FileImage(File(widget.filePath));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Publicar Recuerdo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _buildPreview(cs, fileImage)),
                const SizedBox(height: 24),
                Text('Detalles del Recuerdo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titulo'),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripcion / Anecdota'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today_rounded, color: cs.primary),
                  title: Text('Fecha del Recuerdo', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                  subtitle: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.5)),
                  onTap: _pickDate,
                ),
                Divider(color: cs.onSurface.withValues(alpha: 0.08)),
                const SizedBox(height: 12),
                Text('Estilo de Marco:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _stylesList.length,
                    itemBuilder: (ctx, i) {
                      final style = _stylesList[i];
                      final isSel = _decorStyle == style['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(style['icon'] as IconData, size: 16, color: isSel ? cs.onPrimary : cs.onSurface),
                          label: Text(style['name'] as String),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _decorStyle = style['id']!);
                          },
                        ),
                      );
                    },
                  ),
                ),
                Divider(color: cs.onSurface.withValues(alpha: 0.08)),
                const SizedBox(height: 12),
                Text('Pegar Stickers:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _stickersList.map((st) {
                    final has = _decorStickers.contains(st['id']);
                    return FilterChip(
                      label: Text('${st['emoji']} ${st['name'] ?? st['id']!.toUpperCase()}'),
                      selected: has,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _decorStickers.add(st['id']!);
                          } else {
                            _decorStickers.remove(st['id']!);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveMemory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(_isSaving ? 'Guardando...' : 'Colgar en el Album 💖', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFF4081)),
                    const SizedBox(height: 20),
                    Text('Guardando tu recuerdo especial... 💖', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview(ColorScheme cs, ImageProvider image) {
    final frameColor = _frameColorForStyle(_decorStyle);

    return Container(
      width: 280,
      height: 320,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildFramedPhoto(image, _decorStyle, frameColor),
            if (_titleCtrl.text.isNotEmpty)
              Positioned(
                bottom: 8, left: 12, right: 12,
                child: Text(
                  _titleCtrl.text,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
            ..._buildStickersOverlay(28),
          ],
        ),
      ),
    );
  }

  Widget _buildFramedPhoto(ImageProvider image, String style, Color frameColor) {
    Widget photo = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(image: DecorationImage(image: image, fit: BoxFit.cover)),
    );

    switch (style) {
      case 'polaroid':
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 36),
          child: photo,
        );
      case 'romantic':
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE4E1), Color(0xFFFFC0CB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFFFF69B4).withValues(alpha: 0.3), blurRadius: 10)],
          ),
          padding: const EdgeInsets.all(12),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: photo),
        );
      case 'vintage':
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE5D3B3), Color(0xFFD2B48C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(10),
          child: ClipRRect(borderRadius: BorderRadius.circular(4), child: photo),
        );
      case 'ticket':
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8DC),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                photo,
                Positioned(left: -8, top: 0, bottom: 0, child: Container(width: 8, decoration: BoxDecoration(color: frameColor, borderRadius: BorderRadius.circular(4)))),
                Positioned(right: -8, top: 0, bottom: 0, child: Container(width: 8, decoration: BoxDecoration(color: frameColor, borderRadius: BorderRadius.circular(4)))),
              ],
            ),
          ),
        );
      case 'heart_frame':
        return Container(
          color: const Color(0xFFFFC0CB).withValues(alpha: 0.2),
          padding: const EdgeInsets.all(8),
          child: Center(
            child: ClipPath(
              clipper: HeartClipper(),
              child: photo,
            ),
          ),
        );
      case 'stars_frame':
        return Container(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
          padding: const EdgeInsets.all(8),
          child: Center(
            child: ClipPath(
              clipper: StarClipper(),
              child: photo,
            ),
          ),
        );
      case 'floral':
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF69B4), width: 5),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(borderRadius: BorderRadius.circular(20), child: photo),
        );
      case 'glow':
        return Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: const Color(0xFFFF1493).withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 6)],
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: photo),
        );
      default:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: frameColor, width: 6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: photo),
        );
    }
  }

  List<Widget> _buildStickersOverlay(double size) {
    final widgets = <Widget>[];
    final List<Alignment> alignList = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
      Alignment.centerLeft,
      Alignment.centerRight,
      Alignment.topCenter,
      Alignment.bottomCenter,
    ];

    for (int i = 0; i < _decorStickers.length; i++) {
      final st = _decorStickers[i];
      final align = alignList[i % alignList.length];
      widgets.add(
        Align(
          alignment: align,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(_emojiForSticker(st), style: TextStyle(fontSize: size)),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Color _frameColorForStyle(String style) {
    switch (style) {
      case 'polaroid': return Colors.white;
      case 'romantic': return const Color(0xFFFFE4E1);
      case 'vintage': return const Color(0xFFE5D3B3);
      case 'ticket': return const Color(0xFFFFF8DC);
      case 'heart_frame': return const Color(0xFFFFC0CB);
      case 'stars_frame': return const Color(0xFFFFD700);
      case 'floral': return const Color(0xFFFF69B4);
      case 'glow': return const Color(0xFFFF1493);
      default: return Colors.white;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}

class _MemoryTile extends StatefulWidget {
  final MemoryModel memory;
  final double aspectRatio;
  final ColorScheme cs;
  final int index;

  const _MemoryTile({
    required this.memory,
    required this.aspectRatio,
    required this.cs,
    required this.index,
  });

  @override
  State<_MemoryTile> createState() => _MemoryTileState();
}

class _MemoryTileState extends State<_MemoryTile> {
  bool _isPressed = false;

  String _emojiForSticker(String id) {
    switch (id) {
      case 'heart': return '❤️';
      case 'star': return '⭐';
      case 'flower': return '🌸';
      case 'cat': return '🐱';
      case 'kiss': return '💋';
      case 'party': return '🎉';
      case 'bear': return '🧸';
      case 'ring': return '💍';
      case 'sparkles': return '✨';
      case 'rainbow': return '🌈';
      case 'chocolate': return '🍫';
      case 'music': return '🎵';
      case 'popcorn': return '🍿';
      case 'airplane': return '✈️';
      case 'house': return '🏠';
      default: return '✨';
    }
  }

  List<Widget> _buildStickersOverlay(double size) {
    final widgets = <Widget>[];
    final stickers = widget.memory.decorStickers ?? [];

    final Map<String, Offset> positions = {
      'heart': const Offset(4, 4),
      'star': Offset(size * 1.5, 4),
      'sparkles': Offset(4, size * 1.5),
      'flower': const Offset(4, -4),
      'cat': const Offset(-4, -4),
      'kiss': const Offset(-4, 4),
      'party': Offset(-4, size * 1.5),
      'bear': Offset(size * 1.5, -4),
      'ring': Offset(size * 0.8, size * 0.8),
      'rainbow': Offset(size * 0.5, size * 2.0),
      'chocolate': Offset(size * 2.0, size * 0.5),
      'music': Offset(size * 2.2, size * 2.2),
      'popcorn': Offset(size * 1.0, size * 1.5),
      'airplane': Offset(size * 1.5, size * 1.0),
      'house': Offset(size * 0.3, size * 2.5),
    };

    for (final st in stickers) {
      final pos = positions[st];
      if (pos != null) {
        final isTop = pos.dy >= 0;
        final isLeft = pos.dx >= 0;

        widgets.add(
          Positioned(
            top: isTop ? pos.dy : null,
            bottom: !isTop ? -pos.dy : null,
            left: isLeft ? pos.dx : null,
            right: !isLeft ? -pos.dx : null,
            child: Text(_emojiForSticker(st), style: TextStyle(fontSize: size)),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.memory.mediaPaths.isNotEmpty && widget.memory.mediaPaths.first.isNotEmpty;
    final imageWidget = hasImage ? _buildImage(widget.memory.mediaPaths.first) : _placeholder();
    final style = widget.memory.decorStyle ?? 'standard';
    final title = widget.memory.title == 'Recuerdo sin título' ? '' : widget.memory.title;

    Color frameColor = Colors.white;
    if (widget.memory.decorFrameColor != null) {
      try {
        frameColor = Color(int.parse(widget.memory.decorFrameColor!));
      } catch (_) {}
    } else {
      if (style == 'polaroid') frameColor = Colors.white;
      if (style == 'romantic') frameColor = const Color(0xFFFFE4E1);
      if (style == 'vintage') frameColor = const Color(0xFFE5D3B3);
      if (style == 'ticket') frameColor = const Color(0xFFFFF8DC);
    }

    Widget content;
    if (style == 'polaroid') {
      content = Container(
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.only(top: 6, left: 6, right: 6, bottom: 26),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Positioned.fill(child: imageWidget),
                  ..._buildStickersOverlay(12),
                ],
              ),
            ),
            Positioned(
              bottom: -22,
              child: SizedBox(
                width: 120,
                child: Text(
                  title,
                  style: GoogleFonts.caveat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (style == 'romantic') {
      content = Container(
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title.isEmpty ? 'Amor' : title,
              style: GoogleFonts.pacifico(
                fontSize: 10,
                color: Colors.pink.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else if (style == 'vintage') {
      final dateStr = "${widget.memory.date.day}/${widget.memory.date.month}";
      content = Container(
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(1, 1),
            )
          ],
          border: Border.all(color: const Color(0xFFC8AD7F), width: 1),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.393, 0.769, 0.189, 0, 0,
                          0.349, 0.686, 0.168, 0, 0,
                          0.272, 0.534, 0.131, 0, 0,
                          0,     0,     0,     1, 0,
                        ]),
                        child: imageWidget,
                      ),
                    ),
                    ..._buildStickersOverlay(12),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                        color: Colors.black54,
                        child: Text(
                          dateStr,
                          style: GoogleFonts.shareTechMono(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title.isEmpty ? 'Memorias' : title,
              style: GoogleFonts.specialElite(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade900,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else if (style == 'ticket') {
      content = Container(
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(1, 1),
            )
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              ),
              alignment: Alignment.center,
              child: Text(
                'ADMIT DOS',
                style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Positioned.fill(child: imageWidget),
                      ..._buildStickersOverlay(12),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
              child: Text(
                title.isEmpty ? 'TICKET' : title.toUpperCase(),
                style: GoogleFonts.courierPrime(fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else if (style == 'heart_frame') {
      content = Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 3),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.isEmpty ? 'Con Amor' : title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else if (style == 'stars_frame') {
      content = Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.isEmpty ? 'Destello' : title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else if (style == 'floral') {
      content = Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade300, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.isEmpty ? 'Naturaleza' : title,
              style: GoogleFonts.caveat(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else if (style == 'glow') {
      content = Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00E5FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.isEmpty ? 'Neón' : title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF), fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      // Estándar
      content = Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(child: imageWidget),
                ..._buildStickersOverlay(14),
              ],
            ),
          ),
          if (widget.memory.title.isNotEmpty && widget.memory.title != 'Recuerdo sin título')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Text(
                widget.memory.title,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    }

    final rotation = ((widget.index % 3) - 1) * 0.035;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            reverseTransitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => MemoryDetailScreen(memory: widget.memory),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            margin: const EdgeInsets.all(2),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    return Hero(
      tag: 'memory_image_${widget.memory.id}',
      child: FirestoreImage(path: path, height: double.infinity, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _placeholder() {
    return Container(
      color: widget.cs.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.favorite_rounded, color: widget.cs.primary.withValues(alpha: 0.2), size: 32),
      ),
    );
  }
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    path.moveTo(width / 2, height / 5);
    path.cubicTo(5 * width / 6, 0, width, height / 3, width / 2, height);
    path.cubicTo(0, height / 3, width / 6, 0, width / 2, height / 5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius / 2.2;
    final int points = 5;

    double angle = -3.1415926535897932 / 2;
    final double step = 3.1415926535897932 / points;

    path.moveTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));

    for (int i = 0; i < points; i++) {
      angle += step;
      path.lineTo(cx + innerRadius * cos(angle), cy + innerRadius * sin(angle));
      angle += step;
      path.lineTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
