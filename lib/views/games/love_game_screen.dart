import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

class LoveGameScreen extends StatefulWidget {
  const LoveGameScreen({super.key});

  @override
  State<LoveGameScreen> createState() => _LoveGameScreenState();
}

class _LoveGameScreenState extends State<LoveGameScreen> {
  final _gs = GameService();

  List<Map<String, dynamic>> _allCards = [];
  List<Map<String, dynamic>> _remaining = [];
  Map<String, dynamic>? _currentCard;
  bool _revealed = false;
  int _intimacyScore = 0;

  bool _editMode = false;
  StreamSubscription? _sub;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _sub = _gs.streamLoveQuestions().listen((snap) {
      if (!mounted) return;
      setState(() {
        _allCards = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {'id': d.id, ...data};
        }).toList();
      });
      if (_remaining.isEmpty && _allCards.isNotEmpty) {
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _remaining = List.from(_allCards)..shuffle(_rand);
      _currentCard = null;
      _revealed = false;
      _intimacyScore = 0;
    });
    _nextCard();
  }

  void _nextCard() {
    if (_remaining.isEmpty) {
      _showEnd();
      return;
    }
    setState(() {
      _currentCard = _remaining.removeAt(0);
      _revealed = false;
    });
  }

  void _reveal() {
    setState(() => _revealed = true);
  }

  void _dismiss() {
    if (!_revealed) return;
    setState(() => _intimacyScore += (_currentCard?['points'] as int? ?? 1));
    _nextCard();
  }

  void _showEnd() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Completado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Puntaje de intimidad: $_intimacyScore', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 8),
            Text('Completaron todas las cartas!', style: GoogleFonts.outfit()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _startGame();
            },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showCardDialog({String? editId, String? editCategory, String? editContent, int? editPoints}) {
    final categoryCtrl = TextEditingController(text: editCategory ?? 'Romanticas');
    final contentCtrl = TextEditingController(text: editContent);
    final pointsCtrl = TextEditingController(text: (editPoints ?? 1).toString());
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(editId != null ? 'Editar carta' : 'Nueva carta', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.outfit(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  decoration: InputDecoration(
                    labelText: 'Contenido',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.outfit(),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Puntos',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.outfit(),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
            TextButton(
              onPressed: () async {
                if (contentCtrl.text.trim().isEmpty) return;
                final data = {
                  'category': categoryCtrl.text.trim(),
                  'content': contentCtrl.text.trim(),
                  'points': int.tryParse(pointsCtrl.text) ?? 1,
                };
                if (editId != null) {
                  await _gs.saveLoveQuestion(data, id: editId);
                } else {
                  await _gs.saveLoveQuestion(data);
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

  void _deleteCard(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar', style: GoogleFonts.outfit()),
        content: Text('Eliminar esta carta?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _gs.saveLoveQuestion({}, id: id);
              _gs.deleteItem('amor', id);
            },
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Romanticas': return const Color(0xFFE91E63);
      case 'Atrevidas': return const Color(0xFFFF9800);
      case 'Curiosas': return const Color(0xFF2196F3);
      case 'Acciones': return const Color(0xFF4CAF50);
      default: return const Color(0xFF9C27B0);
    }
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
        title: Text('Love Game', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          if (!_editMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('$_intimacyScore pts', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
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
              onPressed: () => _showCardDialog(),
              backgroundColor: cs.primary,
              child: Icon(Icons.add, color: cs.onSurface),
            )
          : null,
    );
  }

  Widget _buildGameMode(ColorScheme cs) {
    if (_allCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No hay cartas disponibles', style: GoogleFonts.outfit(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Agrega cartas desde el modo de edicion', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    if (_currentCard == null) {
      _startGame();
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('${_allCards.length - _remaining.length} de ${_allCards.length}',
              style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 16),
          Expanded(
            child: Dismissible(
              key: ValueKey(_currentCard),
              direction: _revealed ? DismissDirection.endToStart : DismissDirection.none,
              onDismissed: (_) => _dismiss(),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(16)),
                child: Text('Siguiente', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold)),
              ),
              child: GestureDetector(
                onTap: _revealed ? null : _reveal,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _revealed
                      ? _CardFront(_currentCard!, cs)
                      : _CardBack(_currentCard!, cs),
                ),
              ),
            ),
          ),
          if (_revealed) ...[
            const SizedBox(height: 16),
            Text('Desliza para la siguiente carta',
                style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (!_revealed) ...[
            const SizedBox(height: 16),
            Text('Toca para revelar',
                style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _allCards.isEmpty ? 0 : (_allCards.length - _remaining.length) / _allCards.length,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(ColorScheme cs) {
    if (_allCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No hay cartas', style: GoogleFonts.outfit(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Agrega la primera con +', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _allCards.length,
      itemBuilder: (_, i) {
        final c = _allCards[i];
        final isOwner = c['authorId'] == LocalStorage().getUserId();
        final cat = c['category'] as String? ?? 'Romanticas';
        final color = _catColor(cat);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.favorite, color: Colors.white, size: 20),
            ),
            title: Text(c['content'] as String? ?? '', style: GoogleFonts.outfit(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('$cat  |  +${c['points'] ?? 1} pts', style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
            trailing: isOwner ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: cs.primary),
                  onPressed: () => _showCardDialog(
                    editId: c['id'],
                    editCategory: cat,
                    editContent: c['content'],
                    editPoints: c['points'] as int?,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteCard(c['id']),
                ),
              ],
            ) : null,
          ),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  final Map<String, dynamic> card;
  final ColorScheme cs;
  const _CardBack(this.card, this.cs);

  Color get _color {
    final cat = card['category'] as String? ?? 'Romanticas';
    switch (cat) {
      case 'Atrevidas': return const Color(0xFFFF9800);
      case 'Curiosas': return const Color(0xFF2196F3);
      case 'Acciones': return const Color(0xFF4CAF50);
      default: return const Color(0xFFE91E63);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('back_${card['content']}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _color,
      elevation: 6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 48),
            const SizedBox(height: 20),
            Text(card['category'] as String? ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Toca para revelar', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final Map<String, dynamic> card;
  final ColorScheme cs;
  const _CardFront(this.card, this.cs);

  Color get _color {
    final cat = card['category'] as String? ?? 'Romanticas';
    switch (cat) {
      case 'Atrevidas': return const Color(0xFFFF9800);
      case 'Curiosas': return const Color(0xFF2196F3);
      case 'Acciones': return const Color(0xFF4CAF50);
      default: return const Color(0xFFE91E63);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('front_${card['content']}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surface,
      elevation: 6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(20)),
              child: Text(card['category'] as String? ?? '', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 24),
            Text(card['content'] as String? ?? '', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('+${card['points'] ?? 1} pts', style: GoogleFonts.outfit(color: _color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
