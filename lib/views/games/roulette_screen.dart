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
  static const _classicItems = [
    "Beso", "Abrazo", "Masaje", "Cumplido",
    "Baile", "Sorpresa", "Confesion", "Selfie"
  ];

  bool _isClassic = true;
  List<String> _currentItems = List.from(_classicItems);
  List<Map<String, dynamic>> _customRoulettes = [];
  Map<String, dynamic>? _selectedRoulette;
  StreamSubscription? _sub;

  late AnimationController _ctrl;
  double _startAngle = 0, _endAngle = 0, _currentAngle = 0;
  bool _spinning = false;
  String? _result;

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
    if (_currentItems.isEmpty) return '';
    final sa = 2 * pi / _currentItems.length;
    final da = ((3 * pi / 2 - _currentAngle) % (2 * pi) + 2 * pi) % (2 * pi);
    return _currentItems[(da / sa).floor() % _currentItems.length];
  }

  void _spin() {
    if (_spinning || _currentItems.isEmpty) return;
    _startAngle = _currentAngle;
    _endAngle = _startAngle + 6 * pi + Random().nextDouble() * 4 * pi;
    _result = null;
    setState(() => _spinning = true);
    _ctrl.forward(from: 0);
  }

  void _saveStats() {
    GameService().saveGameStats('ruleta', {
      'result': _result,
      'mode': _isClassic ? 'classic' : 'custom',
      'items': _currentItems,
    });
  }

  void _selectRoulette(Map<String, dynamic> r) {
    setState(() {
      _selectedRoulette = r;
      _currentItems = List<String>.from(r['items'] ?? []);
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
                  _currentItems = List.from(_classicItems);
                  _isClassic = true;
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
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Ruleta', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: true,
                    label: Text('Clasica', style: GoogleFonts.outfit())),
                ButtonSegment(
                    value: false,
                    label: Text('Personalizada', style: GoogleFonts.outfit())),
              ],
              selected: {_isClassic},
              onSelectionChanged: (v) {
                setState(() {
                  _isClassic = v.first;
                  _result = null;
                  _currentAngle = 0;
                  if (_isClassic) {
                    _currentItems = List.from(_classicItems);
                    _selectedRoulette = null;
                  }
                });
              },
            ),
          ),
          if (!_isClassic && _customRoulettes.isNotEmpty)
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
          if (!_isClassic && _customRoulettes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Crea tu primera ruleta personalizada!',
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
                            _currentItems, cs.primary, cs.secondary),
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
              onPressed: _currentItems.isEmpty ? null : _spin,
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
          if (!_isClassic && _selectedRoulette != null)
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
              itemCount: _currentItems.length,
              itemBuilder: (_, i) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _result == _currentItems[i]
                        ? cs.primary
                        : Colors.transparent,
                    child: Text('${i + 1}',
                        style: GoogleFonts.outfit(
                            color: _result == _currentItems[i]
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.6))),
                  ),
                  title: Text(_currentItems[i],
                      style: GoogleFonts.outfit(
                          fontWeight: _result == _currentItems[i]
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  trailing: _result == _currentItems[i]
                      ? Icon(Icons.star, color: cs.primary)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isClassic
          ? null
          : FloatingActionButton(
              onPressed: () => _showCreateDialog(),
              backgroundColor: cs.primary,
              child: Icon(Icons.add, color: cs.onSurface),
            ),
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
