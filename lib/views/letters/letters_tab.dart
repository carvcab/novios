import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_storage.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';

class LettersTab extends StatefulWidget {
  const LettersTab({super.key});

  @override
  State<LettersTab> createState() => _LettersTabState();
}

class _LettersTabState extends State<LettersTab> {
  final List<Map<String, dynamic>> _letters = [];

  static const _letterFonts = <String, String>{
    'Sans': 'Normal',
    'Serif': 'Elegante',
    'Cursive': 'Manuscrita',
  };

  static const _letterStickers = <String>[
    '💌', '❤️', '🌸', '🧸', '🍫', '💍', '🌟', '🧁', '🍷'
  ];

  StreamSubscription? _updateSub;

  @override
  void initState() {
    super.initState();
    _letters.addAll(LocalStorage().getLocalList('letters'));
    _updateSub = FirebaseService.listUpdateStream.listen((key) {
      if (key == 'letters' && mounted) {
        setState(() {
          _letters.clear();
          _letters.addAll(LocalStorage().getLocalList('letters'));
        });
      }
    });
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    super.dispose();
  }

  void _save() => FirebaseService().saveListData('letters', _letters);

  void _createLetter() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    Color selectedColor = const Color(0xFFFF7F7F);
    String selectedFont = 'Sans';
    String selectedSticker = '💌';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text('Escribir Carta', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(labelText: 'Mensaje de amor'),
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Color de papel:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorDot(const Color(0xFFFFEAEA), selectedColor == const Color(0xFFFFEAEA), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFFFEAEA));
                      }),
                      _colorDot(const Color(0xFFEAEAFF), selectedColor == const Color(0xFFEAEAFF), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFEAEAFF));
                      }),
                      _colorDot(const Color(0xFFEAFFEA), selectedColor == const Color(0xFFEAFFEA), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFEAFFEA));
                      }),
                      _colorDot(const Color(0xFFFFFAEA), selectedColor == const Color(0xFFFFFAEA), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFFFFAEA));
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Sello / Sticker:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _letterStickers.map((sticker) {
                      final isSelected = selectedSticker == sticker;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedSticker = sticker),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? cs.primary : Colors.transparent),
                          ),
                          child: Text(sticker, style: const TextStyle(fontSize: 18)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Estilo de letra:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _letterFonts.entries.map((entry) {
                      final isSelected = selectedFont == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedFont = entry.key);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final titleText = titleCtrl.text.trim();
                  setState(() {
                    _letters.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleText,
                      'date': '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                      'opened': false,
                      'color': '#${selectedColor.toARGB32().toRadixString(16).substring(2)}',
                      'message': msgCtrl.text.trim(),
                      'font': selectedFont,
                      'sticker': selectedSticker,
                      'authorId': LocalStorage().getUserId(),
                    });
                    _save();
                  });
                  FirebaseService().sendActivityNotification('Escribió una nueva carta de amor: "$titleText" 💌', 'letter', icon: 'mail');
                  Navigator.pop(ctx);
                },
                child: const Text('Enviar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editOrDeleteLetter(int index) {
    final letter = _letters[index];
    final titleCtrl = TextEditingController(text: letter['title']);
    final msgCtrl = TextEditingController(text: letter['message']);
    Color selectedColor = _parseColor(letter['color'] as String? ?? 'FFFF7F7F');
    String selectedFont = letter['font'] as String? ?? 'Sans';
    String selectedSticker = letter['sticker'] as String? ?? '💌';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.edit_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text('Editar Carta', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(labelText: 'Mensaje de amor'),
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  const Text('Color de papel:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorDot(const Color(0xFFFFEAEA), selectedColor == const Color(0xFFFFEAEA), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFFFEAEA));
                      }),
                      _colorDot(const Color(0xFFEAEAFF), selectedColor == const Color(0xFFEAEAFF), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFEAEAFF));
                      }),
                      _colorDot(const Color(0xFFEAFFEA), selectedColor == const Color(0xFFEAFFEA), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFEAFFEA));
                      }),
                      _colorDot(const Color(0xFFFFFAEA), selectedColor == const Color(0xFFFFFAEA), (c) {
                        setDialogState(() => selectedColor = const Color(0xFFFFFAEA));
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Sello / Sticker:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _letterStickers.map((sticker) {
                      final isSelected = selectedSticker == sticker;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedSticker = sticker),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? cs.primary : Colors.transparent),
                          ),
                          child: Text(sticker, style: const TextStyle(fontSize: 18)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Estilo de letra:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _letterFonts.entries.map((entry) {
                      final isSelected = selectedFont == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedFont = entry.key);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _delete(index);
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final titleText = titleCtrl.text.trim();
                  setState(() {
                    _letters[index] = {
                      'id': letter['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleText,
                      'date': letter['date'] ?? '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                      'opened': letter['opened'] ?? false,
                      'color': '#${selectedColor.toARGB32().toRadixString(16).substring(2)}',
                      'message': msgCtrl.text.trim(),
                      'font': selectedFont,
                      'sticker': selectedSticker,
                      'authorId': letter['authorId'] ?? LocalStorage().getUserId(),
                    };
                    _save();
                  });
                  FirebaseService().sendActivityNotification('Actualizó la carta: "$titleText" 📝', 'letter', icon: 'mail');
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _delete(int index) {
    setState(() => _letters.removeAt(index));
    _save();
    FirebaseService().sendActivityNotification('Eliminó una carta de amor 🗑️', 'letter', icon: 'mail');
  }

  String _monthName(int m) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[m - 1];
  }

  Widget _colorDot(Color c, bool selected, void Function(Color) onTap) {
    return GestureDetector(
      onTap: () => onTap(c),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.black, width: 3) : Border.all(color: Colors.white10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    if (hex.startsWith('#')) hex = hex.substring(1);
    try {
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse('0x$hex'));
    } catch (_) {
      return const Color(0xFFFF7F7F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = LocalStorage().getUserId();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF140D0F) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text('Cartas de Amor 💌', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.onSurface)),
      ),
      body: _letters.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded, size: 64, color: cs.primary.withValues(alpha: 0.25)),
                  const SizedBox(height: 16),
                  Text('Buzón de cartas vacío',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  Text('Escribe tu primera carta de amor', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: _letters.length,
              itemBuilder: (ctx, i) {
                final letter = _letters[i];
                final opened = letter['opened'] == true;
                final color = _parseColor(letter['color'] as String? ?? 'FFFF7F7F');
                final date = letter['date'] as String? ?? '';
                final sticker = letter['sticker'] as String? ?? '💌';
                final isMyLetter = letter['authorId'] == userId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () {
                        setState(() => letter['opened'] = true);
                        _save();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _LetterReaderScreen(
                              letter: letter,
                              color: color,
                            ),
                          ),
                        );
                      },
                      onLongPress: () => _editOrDeleteLetter(i),
                      borderRadius: BorderRadius.circular(24),
                      child: Row(
                        children: [
                          // Envelope-like left icon container
                          Container(
                            width: 80,
                            height: 100,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.mail_rounded, color: color.withValues(alpha: 0.6), size: 48),
                                  Text(sticker, style: const TextStyle(fontSize: 20)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          letter['title'] as String? ?? '',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: opened ? Colors.white.withValues(alpha: 0.05) : cs.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          opened ? 'Leída' : 'Sin leer',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: opened ? Colors.white38 : cs.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(date, style: const TextStyle(fontSize: 11, color: Colors.white38)),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isMyLetter ? Colors.blue.withValues(alpha: 0.1) : Colors.pink.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isMyLetter ? 'Para mi pareja 👩‍❤️‍👨' : 'De mi pareja 👨‍❤️‍👨',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isMyLetter ? Colors.blue : Colors.pinkAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createLetter,
        backgroundColor: isDark ? const Color(0xFFFF4081) : cs.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.mail_rounded),
      ),
    );
  }
}

class _LetterReaderScreen extends StatefulWidget {
  final Map<String, dynamic> letter;
  final Color color;

  const _LetterReaderScreen({
    required this.letter,
    required this.color,
  });

  @override
  State<_LetterReaderScreen> createState() => _LetterReaderScreenState();
}

class _LetterReaderScreenState extends State<_LetterReaderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flapAnimation;
  late Animation<double> _slideAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _flapAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openEnvelope() {
    if (_isOpen) return;
    setState(() {
      _isOpen = true;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final fontStyle = widget.letter['font'] as String? ?? 'Sans';
    final sticker = widget.letter['sticker'] as String? ?? '💌';
    final title = widget.letter['title'] as String? ?? '';
    final message = widget.letter['message'] as String? ?? '';
    final date = widget.letter['date'] as String? ?? '';
    final authorId = widget.letter['authorId'] as String?;

    TextStyle messageStyle;
    if (fontStyle == 'Serif') {
      messageStyle = GoogleFonts.playfairDisplay(fontSize: 16, height: 1.6, color: Colors.black87, fontStyle: FontStyle.italic);
    } else if (fontStyle == 'Cursive') {
      messageStyle = GoogleFonts.dancingScript(fontSize: 22, height: 1.4, color: Colors.black87, fontWeight: FontWeight.bold);
    } else {
      messageStyle = GoogleFonts.outfit(fontSize: 15, height: 1.5, color: Colors.black87);
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B181E) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ── 1. LETTER CONTENT (slides up when envelope opens) ──
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final s = _slideAnimation.value;
              return Transform.translate(
                offset: Offset(0, 200 * (1.0 - s)),
                child: Transform.scale(
                  scale: 0.8 + 0.2 * s,
                  child: Opacity(opacity: s),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 520),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sticker, style: const TextStyle(fontSize: 44)),
                      const SizedBox(height: 14),
                      Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('💞 ', style: TextStyle(fontSize: 11)),
                          if (authorId != null)
                            Text('Para ti', style: GoogleFonts.outfit(fontSize: 12, color: Colors.pink.shade600, fontWeight: FontWeight.bold)),
                          Text('  $date', style: TextStyle(fontSize: 11, color: Colors.black38)),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black12)),
                      Text(message, style: messageStyle, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 2. ENVELOPE ──
          if (!_isOpen || _slideAnimation.value < 0.85)
            IgnorePointer(
              ignoring: _isOpen,
              child: AnimatedBuilder(
                animation: _flapAnimation,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(-_flapAnimation.value * 1.5),
                    child: child,
                  );
                },
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E1C20),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(size: const Size(300, 200), painter: _EnvelopePainter()),
                      GestureDetector(
                        onTap: _openEnvelope,
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(colors: [Color(0xFFFF6B6B), Color(0xFF8B0000)]),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 3))],
                            border: Border.all(color: const Color(0xFFD4A017), width: 2),
                          ),
                          child: const Center(child: Icon(Icons.favorite_rounded, color: Colors.white, size: 22)),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Text('Toca el sello 💌', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Background
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(16)), Paint()..color = const Color(0xFF3F262B));

    // Bottom flap triangle (darker)
    final bottomPath = Path()
      ..moveTo(0, h)
      ..lineTo(cx, cy + 10)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bottomPath, Paint()..color = const Color(0xFF2E1C20));
    canvas.drawPath(bottomPath, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1);

    // Left flap triangle
    final leftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(cx, cy)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = const Color(0xFF4C2F34));
    canvas.drawPath(leftPath, Paint()..color = Colors.black12..style = PaintingStyle.stroke..strokeWidth = 1);

    // Right flap triangle
    final rightPath = Path()
      ..moveTo(w, 0)
      ..lineTo(cx, cy)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = const Color(0xFF4C2F34));
    canvas.drawPath(rightPath, Paint()..color = Colors.black12..style = PaintingStyle.stroke..strokeWidth = 1);

    // Top flap (lighter, will be rotated by animation)
    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(cx, cy - 15)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(topPath, Paint()..color = const Color(0xFF5C3A40));
    canvas.drawPath(topPath, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
