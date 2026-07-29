import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

const _categories = [
  'Romantico',
  'Viajes',
  'Recuerdos',
  'Lugares',
  'Apodos',
  'Peliculas',
  'Personalizado',
];

const _letters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  final _gs = GameService();

  String? _selectedCategory;
  String _word = '';
  String _hint = '';
  final Set<String> _guessed = {};
  int _wrong = 0;
  int _score = 0;
  bool _gameOver = false;
  bool _won = false;
  bool _manageMode = false;

  final List<Map<String, dynamic>> _customWords = [];
  final _rand = Random();

  String get _userId => LocalStorage().getUserId() ?? '';

  List<String> get _filteredWords {
    final all = <String>[];
    for (final cw in _customWords) {
      final word = (cw['word'] as String?)?.toUpperCase();
      if (word != null && !all.contains(word)) {
        if (_selectedCategory == null || cw['category'] == _selectedCategory) {
          all.add(word);
        }
      }
    }
    return all;
  }

  @override
  void initState() {
    super.initState();
    _gs.streamHangman().listen((snap) {
      if (!mounted) return;
      setState(() {
        _customWords.clear();
        for (final doc in snap.docs) {
          final d = doc.data() as Map<String, dynamic>;
          _customWords.add({...d, 'docId': doc.id});
        }
      });
    });
    _newWord();
  }

  void _newWord() {
    final pool = _filteredWords;
    if (pool.isEmpty) {
      setState(() {
        _word = '';
        _hint = '';
        _guessed.clear();
        _wrong = 0;
        _gameOver = false;
        _won = false;
      });
      return;
    }
    String next;
    do {
      next = pool[_rand.nextInt(pool.length)];
    } while (next == _word && pool.length > 1);
    setState(() {
      _word = next;
      _hint = '';
      for (final cw in _customWords) {
        if ((cw['word'] as String?)?.toUpperCase() == next) {
          _hint = cw['hint'] as String? ?? '';
          break;
        }
      }
      _guessed.clear();
      _wrong = 0;
      _gameOver = false;
      _won = false;
    });
  }

  String get _display {
    return _word.split('').map((l) => _guessed.contains(l) ? l : '_').join(' ');
  }

  void _guess(String letter) {
    if (_gameOver || _guessed.contains(letter) || _word.isEmpty) return;
    setState(() {
      _guessed.add(letter);
      if (!_word.contains(letter)) _wrong++;
      _checkGameState();
    });
  }

  void _checkGameState() {
    if (_wrong >= 6) {
      _gameOver = true;
      _won = false;
      Future.delayed(const Duration(milliseconds: 300), _showResult);
    } else if (_word.split('').every((l) => _guessed.contains(l))) {
      _gameOver = true;
      _won = true;
      _score++;
      _gs.saveGameStats('ahorcado', {
        'word': _word,
        'result': 'win',
      });
      Future.delayed(const Duration(milliseconds: 300), _showResult);
    }
  }

  void _showResult() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Icon(
              _won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 48,
              color: _won ? Colors.amber : Colors.red.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              _won ? 'Ganaste' : 'Perdiste',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Theme.of(c).colorScheme.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'La palabra era:',
              style: GoogleFonts.outfit(color: Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              _word,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _newWord();
            },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  Future<void> _addWord({String? editDocId, String? editWord, String? editHint, String? editCategory}) async {
    final wordCtrl = TextEditingController(text: editWord);
    final hintCtrl = TextEditingController(text: editHint);
    String category = editCategory ?? _categories[0];
    String? validationError;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(editDocId != null ? 'Editar palabra' : 'Agregar palabra', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    labelText: 'Palabra',
                    labelStyle: GoogleFonts.outfit(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: validationError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hintCtrl,
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    labelText: 'Pista (opcional)',
                    labelStyle: GoogleFonts.outfit(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: GoogleFonts.outfit(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.outfit(),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: GoogleFonts.outfit()),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setDlgState(() => category = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.outfit()),
            ),
            ElevatedButton(
              onPressed: () {
                final word = wordCtrl.text.trim().toUpperCase();
                if (word.isEmpty || word.length < 2) {
                  setDlgState(() => validationError = 'Ingresa una palabra de al menos 2 letras');
                  return;
                }
                if (!RegExp(r'^[A-ZÑ]+$').hasMatch(word)) {
                  setDlgState(() => validationError = 'Solo letras A-Z y Ñ');
                  return;
                }
                Navigator.pop(ctx, {
                  'word': word,
                  'hint': hintCtrl.text.trim(),
                  'category': category,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.primary,
              ),
              child: Text('Guardar', style: GoogleFonts.outfit(color: Theme.of(ctx).colorScheme.onSurface)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final data = {
        'word': result['word'],
        'hint': result['hint'],
        'category': result['category'],
        'authorId': _userId,
      };
      if (editDocId != null) {
        await _gs.saveHangmanWord(data, id: editDocId);
      } else {
        await _gs.saveHangmanWord(data);
      }
    }
  }

  Future<void> _deleteWord(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar palabra', style: GoogleFonts.outfit()),
        content: Text('Seguro que quieres eliminar esta palabra?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _gs.deleteHangmanWord(docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ahorcado', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: cs.onSurface)),
        backgroundColor: cs.primary,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text('$_score pts', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          IconButton(
            icon: Icon(_manageMode ? Icons.play_arrow_rounded : Icons.edit_note_rounded, color: cs.onSurface),
            tooltip: _manageMode ? 'Jugar' : 'Administrar palabras',
            onPressed: () => setState(() => _manageMode = !_manageMode),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _manageMode ? _buildManageView(cs) : _buildGameView(cs),
      floatingActionButton: _manageMode
          ? FloatingActionButton(
              onPressed: () => _addWord(),
              backgroundColor: cs.primary,
              child: Icon(Icons.add, color: cs.onSurface),
            )
          : null,
    );
  }

  Widget _buildGameView(ColorScheme cs) {
    return Column(
      children: [
        _buildCategoryFilter(cs),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                if (_word.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('No hay palabras disponibles', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(height: 8),
                        Text('Agrega palabras desde el modo de edicion', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _HangmanPainter(_wrong, cs.primary),
                      size: const Size(double.infinity, 160),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_hint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Pista: $_hint',
                        style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                      ),
                    ),
                  Text(
                    _display,
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fallos: $_wrong / 6',
                    style: GoogleFonts.outfit(color: _wrong >= 5 ? Colors.red : cs.secondary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _buildKeyboard(cs),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      ),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('Todas', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() {
                  _selectedCategory = null;
                  _newWord();
                }),
                selectedColor: cs.primary,
                checkmarkColor: cs.onSurface,
                labelStyle: TextStyle(color: _selectedCategory == null ? cs.onSurface : cs.onSurface, fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                visualDensity: VisualDensity.compact,
              ),
            ),
            ..._categories.map((cat) {
              final sel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(cat, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                  selected: sel,
                  onSelected: (_) => setState(() {
                    _selectedCategory = cat;
                    _newWord();
                  }),
                  selectedColor: cs.primary,
                  checkmarkColor: cs.onSurface,
                  labelStyle: TextStyle(color: sel ? cs.onSurface : cs.onSurface.withValues(alpha: 0.7), fontSize: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard(ColorScheme cs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.3,
      ),
      itemCount: _letters.length,
      itemBuilder: (_, i) {
        final l = _letters[i];
        final used = _guessed.contains(l);
        final correct = used && _word.contains(l);
        final incorrect = used && !_word.contains(l);
        Color bg = cs.primary;
        if (correct) {
          bg = Colors.green.withValues(alpha: 0.2);
        } else if (incorrect) {
          bg = Colors.red.withValues(alpha: 0.15);
        }
        return Material(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: used || _gameOver || _word.isEmpty ? null : () => _guess(l),
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                l,
                style: GoogleFonts.outfit(
                  color: correct ? Colors.green : incorrect ? Colors.red.shade300 : cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildManageView(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary.withValues(alpha: 0.05), cs.surface],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _gs.streamHangman(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: ${snap.error}', style: GoogleFonts.outfit(), textAlign: TextAlign.center),
              ),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final customDocs = snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            d['docId'] = doc.id;
            return d;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              Text('Palabras personalizadas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (customDocs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.library_add_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        Text('No hay palabras personalizadas', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                )
              else
                ...customDocs.map((d) {
                  final word = d['word'] as String? ?? '';
                  final hint = d['hint'] as String? ?? '';
                  final category = d['category'] as String? ?? '';
                  final authorId = d['authorId'] as String? ?? '';
                  final isOwner = authorId == _userId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(word.isNotEmpty ? word[0] : '?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.primary)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(word, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                                if (hint.isNotEmpty)
                                  Text(hint, style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(category, style: GoogleFonts.outfit(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w600)),
                              ),
                              if (isOwner) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _addWord(
                                        editDocId: d['docId'],
                                        editWord: word,
                                        editHint: hint,
                                        editCategory: category,
                                      ),
                                      child: Icon(Icons.edit, size: 16, color: cs.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _deleteWord(d['docId'] as String),
                                      child: Icon(Icons.delete_outline, size: 16, color: Colors.red.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _HangmanPainter extends CustomPainter {
  final int stage;
  final Color color;
  _HangmanPainter(this.stage, this.color);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cx = s.width / 2, t = s.height * 0.05, b = s.height * 0.85, sc = min(s.width, s.height) / 180;
    c.drawLine(Offset(cx - 50 * sc, b), Offset(cx + 50 * sc, b), p);
    c.drawLine(Offset(cx - 30 * sc, b), Offset(cx - 30 * sc, t), p);
    c.drawLine(Offset(cx - 30 * sc, t), Offset(cx + 20 * sc, t), p);
    c.drawLine(Offset(cx + 20 * sc, t), Offset(cx + 20 * sc, t + 20 * sc), p);
    final hx = cx + 20 * sc, hy = t + 20 * sc;
    if (stage >= 1) c.drawCircle(Offset(hx, hy + 12 * sc), 10 * sc, p);
    if (stage >= 2) c.drawLine(Offset(hx, hy + 22 * sc), Offset(hx, hy + 50 * sc), p);
    if (stage >= 3) c.drawLine(Offset(hx, hy + 30 * sc), Offset(hx - 18 * sc, hy + 18 * sc), p);
    if (stage >= 4) c.drawLine(Offset(hx, hy + 30 * sc), Offset(hx + 18 * sc, hy + 18 * sc), p);
    if (stage >= 5) c.drawLine(Offset(hx, hy + 50 * sc), Offset(hx - 15 * sc, hy + 70 * sc), p);
    if (stage >= 6) c.drawLine(Offset(hx, hy + 50 * sc), Offset(hx + 15 * sc, hy + 70 * sc), p);
  }

  @override
  bool shouldRepaint(covariant _HangmanPainter o) => o.stage != stage;
}
