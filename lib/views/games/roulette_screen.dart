import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _customRoulettes = [];
  Map<String, dynamic>? _selectedRoulette;
  StreamSubscription? _sub;

  late AnimationController _ctrl;
  double _startAngle = 0, _endAngle = 0, _currentAngle = 0;
  bool _spinning = false;
  String? _result;

  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    _sub = GameService().streamRoulettes().listen((snap) {
      if (!mounted) return;
      setState(() {
        _customRoulettes = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {'id': d.id, ...data};
        }).toList();
      });
    });
  }

  List<String> get _currentItems {
    if (_selectedRoulette == null) return [];
    return List<String>.from(_selectedRoulette!['items'] ?? []);
  }

  void _onTick() {
    setState(() {
      final t = Curves.easeOut.transform(_ctrl.value);
      _currentAngle = _startAngle + (_endAngle - _startAngle) * t;
    });
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      setState(() {
        _spinning = false;
        _result = _winner();
      });
      _saveStats();
    }
  }

  String _winner() {
    final items = _currentItems;
    if (items.isEmpty) return '';
    final sa = 2 * pi / items.length;
    final da = ((3 * pi / 2 - _currentAngle) % (2 * pi) + 2 * pi) % (2 * pi);
    return items[(da / sa).floor() % items.length];
  }

  void _spin() {
    final items = _currentItems;
    if (_spinning || items.isEmpty) return;
    _startAngle = _currentAngle;
    _endAngle = _startAngle + 6 * pi + Random().nextDouble() * 4 * pi;
    _result = null;
    setState(() => _spinning = true);
    _ctrl.forward(from: 0);
  }

  void _saveStats() {
    GameService().saveGameStats('ruleta', {
      'result': _result,
      'items': _currentItems,
    });
  }

  void _selectRoulette(Map<String, dynamic> r) {
    setState(() {
      _selectedRoulette = r;
      _result = null;
      _currentAngle = 0;
    });
  }

  void _showCreateDialog({Map<String, dynamic>? edit}) {
    final nameCtrl = TextEditingController(text: edit?['name'] ?? '');
    final itemCtrl = TextEditingController();
    final items = ValueNotifier<List<String>>(
      edit != null ? List<String>.from(edit['items']) : [],
    );
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(edit != null ? 'Editar ruleta' : 'Nueva ruleta',
              style: GoogleFonts.outfit()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre', border: OutlineInputBorder()),
                  style: GoogleFonts.outfit(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: itemCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Agregar item',
                            border: OutlineInputBorder()),
                        style: GoogleFonts.outfit(),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            items.value = [...items.value, v.trim()];
                            itemCtrl.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        if (itemCtrl.text.trim().isNotEmpty) {
                          items.value = [...items.value, itemCtrl.text.trim()];
                          itemCtrl.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<String>>(
                  valueListenable: items,
                  builder: (_, list, __) => Column(
                    children: list.asMap().entries.map((e) => ListTile(
                      dense: true,
                      title: Text(e.value, style: GoogleFonts.outfit()),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          items.value = List.from(list)..removeAt(e.key);
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancelar', style: GoogleFonts.outfit())),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || items.value.isEmpty) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'items': items.value,
                };
                if (edit != null) {
                  await GameService().saveRoulette(data, id: edit['id']);
                } else {
                  await GameService().saveRoulette(data);
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

  void _deleteRoulette(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar', style: GoogleFonts.outfit()),
        content: Text('Eliminar esta ruleta personalizada?',
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () {
              GameService().deleteRoulette(id);
              if (_selectedRoulette?['id'] == id) {
                setState(() {
                  _selectedRoulette = null;
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('Eliminar',
                style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _currentItems;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ruleta', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.play_arrow_rounded : Icons.edit_note_rounded, color: cs.onSurface),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: _editMode ? _buildEditMode(cs) : _buildGameMode(cs, items),
    );
  }

  Widget _buildGameMode(ColorScheme cs, List<String> items) {
    return Column(
      children: [
        if (_customRoulettes.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _customRoulettes.map((r) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(r['name'] ?? '', style: GoogleFonts.outfit()),
                  selected: _selectedRoulette?['id'] == r['id'],
                  onSelected: (_) => _selectRoulette(r),
                ),
              )).toList(),
            ),
          ),
        if (_customRoulettes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Crea tu primera ruleta!',
                style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.6))),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _spinning ? null : _spin,
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26, blurRadius: 12)
                      ]),
                  child: Transform.rotate(
                    angle: _currentAngle,
                    child: CustomPaint(
                      painter: _WheelPainter(
                          items, cs.primary, cs.secondary),
                      size: const Size(280, 280),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26, blurRadius: 6)
                      ]),
                  child:
                      Icon(Icons.favorite, color: cs.primary, size: 28),
                ),
                Positioned(
                  top: -12,
                  left: 128,
                  child: Icon(Icons.arrow_drop_down,
                      color: Colors.red, size: 40),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result != null)
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: cs.secondary.withValues(alpha: 0.2),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(_result!,
                  style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.primary)),
            ),
          ),
        const SizedBox(height: 12),
        if (!_spinning)
          ElevatedButton(
            onPressed: items.isEmpty ? null : _spin,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Girar',
                style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        if (_spinning) const CircularProgressIndicator(),
        const SizedBox(height: 8),
        Text('Toca la rueda para girar',
            style: GoogleFonts.outfit(
                color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 16),
        if (_selectedRoulette != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showCreateDialog(edit: _selectedRoulette)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _deleteRoulette(_selectedRoulette!['id'])),
            ],
          ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _result == items[i]
                      ? cs.primary
                      : Colors.transparent,
                  child: Text('${i + 1}',
                      style: GoogleFonts.outfit(
                          color: _result == items[i]
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.6))),
                ),
                title: Text(items[i],
                    style: GoogleFonts.outfit(
                        fontWeight: _result == items[i]
                            ? FontWeight.bold
                            : FontWeight.normal)),
                trailing: _result == items[i]
                    ? Icon(Icons.star, color: cs.primary)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(ColorScheme cs) {
    if (_customRoulettes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino_rounded, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No hay ruletas', style: GoogleFonts.outfit(fontSize: 18, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Crea la primera con +', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _customRoulettes.length,
      itemBuilder: (_, i) {
        final r = _customRoulettes[i];
        final isOwner = r['authorId'] == LocalStorage().getUserId();
        final itemCount = (r['items'] as List?)?.length ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(Icons.casino_rounded, color: cs.primary),
            title: Text(r['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text('$itemCount items', style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            trailing: isOwner ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: cs.primary),
                  onPressed: () => _showCreateDialog(edit: r),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deleteRoulette(r['id']),
                ),
              ],
            ) : null,
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> items;
  final Color c1, c2;
  _WheelPainter(this.items, this.c1, this.c2);

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sa = 2 * pi / items.length;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (int i = 0; i < items.length; i++) {
      paint.color = i % 2 == 0 ? c1 : c2;
      canvas.drawArc(rect, i * sa - pi / 2, sa, true, paint);
      final mid = i * sa + sa / 2 - pi / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(mid);
      final tp = TextPainter(
        text: TextSpan(
            text: items[i],
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: radius * 0.5);
      tp.paint(canvas, Offset(radius * 0.2, -tp.height / 2));
      canvas.restore();
    }
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.white.withValues(alpha: 0.3);
    paint.strokeWidth = 1;
    for (int i = 0; i < items.length; i++) {
      canvas.drawLine(
          center,
          Offset(center.dx + radius * cos(i * sa - pi / 2),
              center.dy + radius * sin(i * sa - pi / 2)),
          paint);
    }
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.12, paint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => true;
}
