import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/memory_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/firestore_image.dart';

class MemoryDetailScreen extends StatefulWidget {
  final MemoryModel memory;
  const MemoryDetailScreen({required this.memory, super.key});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _selectedDate;
  
  late String _decorStyle;
  late List<String> _decorStickers;
  late String? _decorFrameColor;
  late TabController _tabCtrl;

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

  final List<Color> _pastelColors = [
    Colors.white,
    const Color(0xFFFFF0F5), // Lavender Blush
    const Color(0xFFF0FFF0), // Honeydew
    const Color(0xFFF0F8FF), // Alice Blue
    const Color(0xFFFFF8DC), // Cornsilk
    const Color(0xFFFFE4E1), // Misty Rose
    const Color(0xFFE6E6FA), // Lavender
    const Color(0xFFE8F5E9), // Pastel Green
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.memory.title == 'Recuerdo sin título' ? '' : widget.memory.title);
    _descCtrl = TextEditingController(text: widget.memory.description);
    _selectedDate = widget.memory.date;
    _decorStyle = widget.memory.decorStyle ?? 'standard';
    _decorStickers = List<String>.from(widget.memory.decorStickers ?? []);
    _decorFrameColor = widget.memory.decorFrameColor;
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showFullScreenImage() {
    if (widget.memory.mediaPaths.isEmpty || widget.memory.mediaPaths.first.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'memory_image_${widget.memory.id}',
              child: FirestoreImage(
                path: widget.memory.mediaPaths.first,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _saveChanges() async {
    final updated = widget.memory.copyWith(
      title: _titleCtrl.text.trim().isEmpty ? 'Recuerdo sin título' : _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      date: _selectedDate,
      decorStyle: _decorStyle,
      decorStickers: _decorStickers,
      decorFrameColor: _decorFrameColor,
    );

    await FirebaseService().addMemory(updated);
    FirebaseService().sendActivityNotification('Decoró y actualizó un recuerdo: "${updated.title}" 🎨', 'photo', icon: 'photo');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Recuerdo guardado con éxito!')),
      );
      Navigator.pop(context);
    }
  }

  void _deleteMemory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Recuerdo?'),
          ],
        ),
        content: const Text('Esta accion borrara este recuerdo del album para ambos de forma permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await FirebaseService().deleteMemory(widget.memory.id);
              if (ok) {
                FirebaseService().sendActivityNotification('Elimino un recuerdo del album 🗑️', 'photo', icon: 'photo');
              }
              if (mounted) {
                if (ok) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar. Verifica tu conexion.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _toggleSticker(String id) {
    setState(() {
      if (_decorStickers.contains(id)) {
        _decorStickers.remove(id);
      } else {
        _decorStickers.add(id);
      }
    });
  }

  Color _getFrameColor() {
    if (_decorFrameColor != null) {
      try {
        return Color(int.parse(_decorFrameColor!));
      } catch (_) {}
    }
    if (_decorStyle == 'polaroid') return Colors.white;
    if (_decorStyle == 'romantic') return const Color(0xFFFFE4E1);
    if (_decorStyle == 'vintage') return const Color(0xFFE5D3B3);
    if (_decorStyle == 'ticket') return const Color(0xFFFFF8DC);
    return Colors.transparent;
  }

  void _setFrameColor(Color color) {
    setState(() {
      _decorFrameColor = '0x${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final frameColor = _getFrameColor();
    final dateStr = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Decorar Recuerdo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _deleteMemory,
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showFullScreenImage(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>('${_decorStyle}_${_decorStickers.join(',')}_${_decorFrameColor ?? ''}_${_titleCtrl.text}_${_descCtrl.text}'),
                    child: _buildDecoratedPreview(frameColor, dateStr),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_descCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _descCtrl.text,
                    style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  )
                ]
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: cs.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(icon: Icon(Icons.palette_outlined), text: 'Marcos'),
                      Tab(icon: Icon(Icons.face_outlined), text: 'Stickers'),
                      Tab(icon: Icon(Icons.edit_note_rounded), text: 'Texto'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildMarcosTab(cs),
                        _buildStickersTab(cs),
                        _buildTextTab(cs, dateStr),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecoratedPreview(Color frameColor, String dateStr) {
    final imageWidget = widget.memory.mediaPaths.isNotEmpty && widget.memory.mediaPaths.first.isNotEmpty
        ? _buildBaseImage(widget.memory.mediaPaths.first)
        : _placeholder();

    final title = _titleCtrl.text.trim().isEmpty ? 'Recuerdo Especial' : _titleCtrl.text.trim();

    if (_decorStyle == 'polaroid') {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 48),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              child: SizedBox(
                width: 256,
                child: Text(
                  title,
                  style: GoogleFonts.caveat(
                    fontSize: 22,
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
    }

    if (_decorStyle == 'romantic') {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: [
                        Positioned.fill(child: imageWidget),
                        ..._buildStickersOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.pacifico(
                    fontSize: 16,
                    color: Colors.pink.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const Positioned(top: -4, left: -4, child: Text('💖', style: TextStyle(fontSize: 16))),
            const Positioned(bottom: 24, right: -4, child: Text('✨', style: TextStyle(fontSize: 14))),
          ],
        ),
      );
    }

    if (_decorStyle == 'vintage') {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(2, 2),
            )
          ],
          border: Border.all(color: const Color(0xFFC8AD7F), width: 2),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: 1.0,
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
                    ..._buildStickersOverlay(),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dateStr,
                          style: GoogleFonts.shareTechMono(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.specialElite(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_decorStyle == 'ticket') {
      return Container(
        width: 290,
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(4, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade400.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TICKET DE AMOR', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  Text(dateStr, style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.grey.shade700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Stack(
                    children: [
                      Positioned.fill(child: imageWidget),
                      ..._buildStickersOverlay(),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(
                30,
                (i) => Expanded(
                  child: Container(
                    height: 1.5,
                    color: i % 2 == 0 ? Colors.grey : Colors.transparent,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.courierPrime(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_descCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _descCtrl.text.trim(),
                      style: GoogleFonts.courierPrime(fontSize: 10, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_decorStyle == 'heart_frame') {
      return Container(
        width: 280,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    if (_decorStyle == 'stars_frame') {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    if (_decorStyle == 'floral') {
      return Container(
        width: 280,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.caveat(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 16),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    if (_decorStyle == 'glow') {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00E5FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    ..._buildStickersOverlay(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF), fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 0.95,
          child: Stack(
            children: [
              Positioned.fill(child: imageWidget),
              ..._buildStickersOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBouncySticker(String emoji, double size) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(emoji),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
  }

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

  List<Widget> _buildStickersOverlay() {
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
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: _buildBouncySticker(_emojiForSticker(st), 26),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildBaseImage(String path) {
    return Hero(
      tag: 'memory_image_${widget.memory.id}',
      child: FirestoreImage(path: path, fit: BoxFit.cover),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 48),
      ),
    );
  }

  Widget _buildMarcosTab(ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stylesList.length,
              itemBuilder: (ctx, i) {
                final s = _stylesList[i];
                final isSelected = _decorStyle == s['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    avatar: Icon(s['icon'], size: 16, color: isSelected ? cs.onPrimary : cs.onSurface),
                    label: Text(s['name']),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _decorStyle = s['id']);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text('Color de Fondo del Marco', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pastelColors.length,
              itemBuilder: (ctx, i) {
                final c = _pastelColors[i];
                final hexStr = '0x${c.toARGB32().toRadixString(16).padLeft(8, '0')}';
                final isSelected = _decorFrameColor == hexStr;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _setFrameColor(c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: cs.primary, width: 3) : Border.all(color: Colors.grey.shade300),
                      ),
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

  Widget _buildStickersTab(ColorScheme cs) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _stickersList.length,
      itemBuilder: (ctx, i) {
        final st = _stickersList[i];
        final isSelected = _decorStickers.contains(st['id']);
        return GestureDetector(
          onTap: () => _toggleSticker(st['id']!),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? cs.primary : Colors.grey.shade300),
            ),
            child: Center(
              child: Text(st['emoji']!, style: const TextStyle(fontSize: 22)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextTab(ColorScheme cs, String dateStr) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Título del Recuerdo'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Detalles / Notas'),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today_rounded, color: cs.primary),
            title: const Text('Fecha del recuerdo', style: TextStyle(fontSize: 12)),
            subtitle: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: _pickDate,
          ),
        ],
      ),
    );
  }
}
