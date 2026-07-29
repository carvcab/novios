import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

class NeverHaveIEverScreen extends StatefulWidget {
  const NeverHaveIEverScreen({super.key});

  @override
  State<NeverHaveIEverScreen> createState() => _NeverHaveIEverScreenState();
}

class _NeverHaveIEverScreenState extends State<NeverHaveIEverScreen> {
  static const _categories = [
    'Todas', 'Romantico', 'Divertido', 'Parejas',
    'Viajes', 'Universidad', 'Infancia', 'Picante'
  ];

  List<Map<String, dynamic>> _allStatements = [];
  String _selectedCategory = 'Todas';
  int _currentIndex = 0;
  int _playerTurn = 1;
  bool _gameOver = false;

  Map<String, int> _p1CategoryScores = {};
  Map<String, int> _p2CategoryScores = {};
  int _p1Total = 0;
  int _p2Total = 0;

  StreamSubscription? _sub;
  List<Map<String, dynamic>> _customStatements = [];

  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _sub = GameService().streamNever().listen((snap) {
      if (!mounted) return;
      setState(() {
        _customStatements = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {'id': d.id, 'text': data['text'], 'category': data['category'] ?? 'Personalizado', ...data};
        }).toList();
      });
    });
    _startGame();
  }

  List<Map<String, dynamic>> get _filteredStatements {
    if (_selectedCategory == 'Todas') return _customStatements;
    return _customStatements.where((s) => s['category'] == _selectedCategory).toList();
  }

  void _startGame() {
    final filtered = List<Map<String, dynamic>>.from(_filteredStatements)..shuffle(Random());
    setState(() {
      _allStatements = filtered;
      _currentIndex = 0;
      _playerTurn = 1;
      _gameOver = false;
      _p1CategoryScores = {};
      _p2CategoryScores = {};
      _p1Total = 0;
      _p2Total = 0;
    });
  }

  void _answer(bool done) {
    if (_gameOver || _currentIndex >= _allStatements.length) return;
    final statement = _allStatements[_currentIndex];
    final cat = statement['category'] as String? ?? 'General';
    setState(() {
      if (_playerTurn == 1) {
        if (done) {
          _p1CategoryScores[cat] = (_p1CategoryScores[cat] ?? 0) + 1;
          _p1Total++;
        }
        _playerTurn = 2;
      } else {
        if (done) {
          _p2CategoryScores[cat] = (_p2CategoryScores[cat] ?? 0) + 1;
          _p2Total++;
        }
        if (_currentIndex >= _allStatements.length - 1) {
          _gameOver = true;
          _showResult();
        } else {
          _currentIndex++;
          _playerTurn = 1;
        }
      }
    });
    if (_gameOver) _saveStats();
  }

  void _saveStats() {
    GameService().saveGameStats('yo_nunca', {
      'p1Score': _p1Total,
      'p2Score': _p2Total,
      'total': _allStatements.length,
      'category': _selectedCategory,
    });
  }

  void _showResult() {
    final cs = Theme.of(context).colorScheme;
    final allCats = <String>{};
    allCats.addAll(_p1CategoryScores.keys);
    allCats.addAll(_p2CategoryScores.keys);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Resultado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.primary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Jugador 1: $_p1Total  |  Jugador 2: $_p2Total',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...allCats.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat, style: GoogleFonts.outfit(fontSize: 14)),
                    Text('${_p1CategoryScores[cat] ?? 0} - ${_p2CategoryScores[cat] ?? 0}',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Text(
                _p1Total > _p2Total
                    ? 'Gana Jugador 1!'
                    : _p2Total > _p1Total
                        ? 'Gana Jugador 2!'
                        : 'Empate!',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: cs.secondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(c); _startGame(); },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showAddDialog({String? editId, String? editText, String? editCategory}) {
    final textCtrl = TextEditingController(text: editText);
    String selectedCat = editCategory ?? _categories[1];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(editId != null ? 'Editar declaracion' : 'Agregar declaracion', style: GoogleFonts.outfit()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                decoration: const InputDecoration(labelText: 'Yo nunca...', border: OutlineInputBorder()),
                style: GoogleFonts.outfit(),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCat,
                items: _categories.where((c) => c != 'Todas').map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit()))).toList(),
                onChanged: (v) { if (v != null) selectedCat = v; },
                decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
            TextButton(
              onPressed: () async {
                if (textCtrl.text.trim().isEmpty) return;
                final data = {
                  'text': 'Yo nunca ${textCtrl.text.trim()}',
                  'category': selectedCat,
                };
                if (editId != null) {
                  await GameService().saveNever(data, id: editId);
                } else {
                  await GameService().saveNever(data);
                }
                Navigator.pop(ctx);
              },
              child: Text('Guardar', style: GoogleFonts.outfit()),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteStatement(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar', style: GoogleFonts.outfit()),
        content: Text('Eliminar esta declaracion?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () { Navigator.pop(ctx); GameService().deleteNever(id); },
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nunca he...', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          if (!_editMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('P1: $_p1Total  P2: $_p2Total',
                    style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          IconButton(
            icon: Icon(_editMode ? Icons.play_arrow_rounded : Icons.edit_note_rounded, color: cs.onSurface),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: _editMode ? _buildEditMode(cs) : _buildGameMode(cs),
      floatingActionButton: _editMode
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(),
              backgroundColor: cs.primary,
              child: Icon(Icons.add, color: cs.onSurface),
            )
          : null,
    );
  }

  Widget _buildGameMode(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat, style: GoogleFonts.outfit(fontSize: 12)),
                  selected: _selectedCategory == cat,
                  onSelected: (v) {
                    setState(() => _selectedCategory = cat);
                    _startGame();
                  },
                ),
              )).toList(),
            ),
          ),
        ),
        if (_allStatements.isEmpty)
          Expanded(
            child: Center(
              child: Text('No hay declaraciones para esta categoria',
                  style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Turno: Jugador $_playerTurn',
                          style: GoogleFonts.outfit(fontSize: 14, color: cs.secondary, fontWeight: FontWeight.bold)),
                      Text('${_currentIndex + 1} de ${_allStatements.length}',
                          style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _allStatements[_currentIndex]['text'] ?? '',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _allStatements[_currentIndex]['category'] ?? '',
                          style: GoogleFonts.outfit(fontSize: 12, color: cs.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          onPressed: _gameOver ? null : () => _answer(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('He hecho', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          onPressed: _gameOver ? null : () => _answer(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Nunca', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_gameOver)
                  ElevatedButton(
                    onPressed: _showResult,
                    style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
                    child: Text('Ver resultado', style: GoogleFonts.outfit(color: cs.onSurface)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditMode(ColorScheme cs) {
    if (_customStatements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wine_bar_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No hay declaraciones', style: GoogleFonts.outfit(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Agrega la primera con +', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _customStatements.length,
      itemBuilder: (_, i) {
        final s = _customStatements[i];
        final isOwner = s['authorId'] == LocalStorage().getUserId();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(s['text'] ?? '', style: GoogleFonts.outfit(fontSize: 14)),
            subtitle: Text(s['category'] ?? '', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            trailing: isOwner ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: cs.primary),
                  onPressed: () => _showAddDialog(
                    editId: s['id'],
                    editText: (s['text'] as String).replaceFirst('Yo nunca ', ''),
                    editCategory: s['category'],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteStatement(s['id']),
                ),
              ],
            ) : null,
          ),
        );
      },
    );
  }
}
