import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

class TruthDareCustomScreen extends StatefulWidget {
  const TruthDareCustomScreen({super.key});

  @override
  State<TruthDareCustomScreen> createState() => _TruthDareCustomScreenState();
}

class _TruthDareCustomScreenState extends State<TruthDareCustomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _gs = GameService();
  final _counts = <String, int>{};

  static const _categories = [
    'Verdad',
    'Reto',
    'Foto',
    'Video',
    'Picante',
    'Romanico',
    'Divertido',
    'Personalizado',
  ];

  static const _gradients = {
    'Verdad': [Color(0xFF6366F1), Color(0xFF818CF8)],
    'Reto': [Color(0xFFF97316), Color(0xFFFB923C)],
    'Foto': [Color(0xFF10B981), Color(0xFF34D399)],
    'Video': [Color(0xFFEC4899), Color(0xFFF472B6)],
    'Picante': [Color(0xFFEF4444), Color(0xFFF87171)],
    'Romanico': [Color(0xFFE91E63), Color(0xFFFF6B9D)],
    'Divertido': [Color(0xFFEAB308), Color(0xFFFDE047)],
    'Personalizado': [Color(0xFF6B7280), Color(0xFF9CA3AF)],
  };

  static const _icons = {
    'Verdad': Icons.psychology_rounded,
    'Reto': Icons.fitness_center_rounded,
    'Foto': Icons.camera_alt_rounded,
    'Video': Icons.videocam_rounded,
    'Picante': Icons.whatshot_rounded,
    'Romanico': Icons.favorite_rounded,
    'Divertido': Icons.celebration_rounded,
    'Personalizado': Icons.person_rounded,
  };

  String get _userId => LocalStorage().getUserId() ?? '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem(String currentCat) async {
    final result = await _showItemDialog(currentCat, null);
    if (result != null) {
      final data = {
        'text': result['text'],
        'category': result['category'],
        'authorId': _userId,
      };
      if (result['collection'] != null && result['collection']!.isNotEmpty) {
        data['collection'] = result['collection'];
      }
      await _gs.saveTD(data);
      if (result['category'] != currentCat) {
        setState(() {});
      }
    }
  }

  Future<void> _editItem(String docId, String currentText, String currentCat) async {
    final result = await _showItemDialog(currentCat, currentText);
    if (result != null) {
      final data = {
        'text': result['text'],
        'category': result['category'],
      };
      if (result['collection'] != null && result['collection']!.isNotEmpty) {
        data['collection'] = result['collection'];
      }
      await _gs.saveTD(data, id: docId);
      if (result['category'] != currentCat) {
        setState(() {});
      }
    }
  }

  Future<Map<String, String>?> _showItemDialog(String initialCat, String? existingText) async {
    final textCtrl = TextEditingController(text: existingText);
    String selectedCat = initialCat;
    String selectedCollection = '';
    List<String> names = [];
    try {
      final collSnap = await _gs.streamCollections().first;
      names = collSnap.docs.map((d) => (d.data() as Map<String, dynamic>)['name'] as String? ?? '').where((n) => n.isNotEmpty).toList();
    } catch (_) {}
    if (!mounted) return null;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existingText != null ? 'Editar entrada' : 'Nueva entrada', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCat,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  labelStyle: GoogleFonts.outfit(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: GoogleFonts.outfit()),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => selectedCat = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: 3,
                style: GoogleFonts.outfit(),
                decoration: InputDecoration(
                  hintText: 'Escribe tu entrada...',
                  hintStyle: GoogleFonts.outfit(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCollection.isEmpty ? null : selectedCollection,
                  decoration: InputDecoration(
                    labelText: 'Coleccion (opcional)',
                    labelStyle: GoogleFonts.outfit(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: '', child: Text('Sin coleccion', style: GoogleFonts.outfit())),
                    ...names.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: GoogleFonts.outfit()),
                    )),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedCollection = v);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.outfit()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, {
                'text': textCtrl.text.trim(),
                'category': selectedCat,
                'collection': selectedCollection,
              }),
              style: FilledButton.styleFrom(
                backgroundColor: _gradients[selectedCat]![0],
              ),
              child: Text('Guardar', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(String docId, String text) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar', style: GoogleFonts.outfit()),
        content: Text(
          'Eliminar "${text.length > 40 ? '${text.substring(0, 40)}...' : text}"?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.outfit()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _gs.deleteTD(docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentCat = _categories[_tabCtrl.index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Verdad o Reto', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
          tabs: _categories.map((cat) {
            final total = _counts[cat] ?? 0;
            return Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icons[cat]!, size: 16),
                  const SizedBox(height: 2),
                  Text(cat, style: GoogleFonts.outfit(fontSize: 10)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: _gradients[cat]![0].withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$total',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _gradients[cat]![0],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              _gradients[currentCat]![0].withValues(alpha: 0.04),
              _gradients[currentCat]![1].withValues(alpha: 0.08),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabCtrl,
          children: _categories.map((cat) => _CategoryTabBody(
            key: ValueKey(cat),
            category: cat,
            gradient: _gradients[cat]!,
            icon: _icons[cat]!,
            userId: _userId,
            gs: _gs,
            onAdd: () => _addItem(cat),
            onEdit: (id, text) => _editItem(id, text, cat),
            onDelete: (id, text) => _deleteItem(id, text),
            onCountChanged: (c) {
              if (_counts[cat] != c) setState(() => _counts[cat] = c);
            },
          )).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(currentCat),
        backgroundColor: _gradients[currentCat]![0],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryTabBody extends StatefulWidget {
  final String category;
  final List<Color> gradient;
  final IconData icon;
  final String userId;
  final GameService gs;
  final VoidCallback onAdd;
  final Future<void> Function(String id, String text) onEdit;
  final Future<void> Function(String id, String text) onDelete;
  final ValueChanged<int> onCountChanged;

  const _CategoryTabBody({
    super.key,
    required this.category,
    required this.gradient,
    required this.icon,
    required this.userId,
    required this.gs,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onCountChanged,
  });

  @override
  State<_CategoryTabBody> createState() => _CategoryTabBodyState();
}

class _CategoryTabBodyState extends State<_CategoryTabBody> {
  final _rand = Random();
  int _currentIndex = 0;
  bool _revealed = false;
  List<Map<String, dynamic>> _items = [];

  void _pickRandom(int total) {
    if (total <= 1) return;
    int next;
    do {
      next = _rand.nextInt(total);
    } while (next == _currentIndex);
    setState(() {
      _currentIndex = next;
      _revealed = false;
    });
  }

  void _reveal() {
    if (!_revealed) {
      setState(() => _revealed = true);
      widget.gs.saveGameStats('verdad_reto', {
        'action': 'view',
        'category': widget.category,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: widget.gs.streamTD(widget.category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        _items = docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          d['docId'] = doc.id;
          return d;
        }).toList();

        widget.onCountChanged(_items.length);

        if (_items.isEmpty) {
          return _buildEmptyState(cs);
        }

        final idx = _currentIndex < _items.length ? _currentIndex : 0;
        final current = _items[idx];
        final isOwner = current['authorId'] == widget.userId;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              _buildHeader(cs, _items.length),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _revealed ? null : _reveal,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    if (details.primaryVelocity!.abs() > 200) {
                      _pickRandom(_items.length);
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: _revealed
                        ? _buildRevealedCard(cs, current, isOwner)
                        : _buildHiddenCard(cs),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildControls(cs, _items.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme cs, int total) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          widget.category,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          '$total entradas',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildHiddenCard(ColorScheme cs) {
    return Container(
      key: const ValueKey('hidden'),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.gradient[0].withValues(alpha: 0.9),
            widget.gradient[1].withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.gradient[0].withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            Text('?', style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
            )),
            const SizedBox(height: 12),
            Text('Toca para revelar', style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            )),
            const SizedBox(height: 6),
            Text('Desliza para siguiente', style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealedCard(ColorScheme cs, Map<String, dynamic> current, bool isOwner) {
    final text = current['text'] as String? ?? '';
    final docId = current['docId'] as String? ?? '';
    final favoritedBy = List<String>.from(current['favoritedBy'] ?? []);
    final isFav = favoritedBy.contains(widget.userId);

    return Container(
      key: ValueKey('revealed_$text'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.gradient[0].withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.gradient[0].withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: widget.gradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              widget.category.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.gradient[0],
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe_vertical_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(width: 4),
                Text('Desliza para siguiente',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.3))),
                if (isOwner) ...[
                  const Spacer(),
                  if (docId.isNotEmpty)
                    IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          size: 20, color: isFav ? Colors.red : cs.onSurface.withValues(alpha: 0.4)),
                      onPressed: () => widget.gs.toggleFavorite('verdad_reto', docId),
                      tooltip: 'Favorito',
                    ),
                  if (docId.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.content_copy, size: 20,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      onPressed: () => widget.gs.duplicateItem('verdad_reto', docId),
                      tooltip: 'Duplicar',
                    ),
                  if (docId.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.edit, size: 20,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      onPressed: () => widget.onEdit(docId, text),
                      tooltip: 'Editar',
                    ),
                  if (docId.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20,
                          color: Colors.red.withValues(alpha: 0.6)),
                      onPressed: () => widget.onDelete(docId, text),
                      tooltip: 'Eliminar',
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ColorScheme cs, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: total > 0 ? () => _pickRandom(total) : null,
          icon: const Icon(Icons.shuffle_rounded, size: 18),
          label: Text('Siguiente', style: GoogleFonts.outfit()),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(color: widget.gradient[0].withValues(alpha: 0.4)),
            foregroundColor: widget.gradient[0],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: widget.gradient[0]),
          onPressed: widget.onAdd,
          tooltip: 'Agregar entrada',
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon,
                size: 72, color: widget.gradient[0].withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'No hay entradas disponibles',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la primera con el boton +',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add, size: 20),
              label: Text('Agregar entrada', style: GoogleFonts.outfit()),
              style: FilledButton.styleFrom(
                backgroundColor: widget.gradient[0],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
