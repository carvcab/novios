import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:convert';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> with SingleTickerProviderStateMixin {
  List<String> _items = ["Beso", "Abrazo", "Masaje", "Cumplido", "Baile", "Sorpresa", "Confesion", "Selfie"];
  late AnimationController _ctrl;
  double _startAngle = 0, _endAngle = 0, _currentAngle = 0;
  bool _spinning = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
    _load();
  }

  Future<void> _load() async {
    final s = await LocalStorage().getString('roulette_items');
    if (s != null) {
      try {
        final list = List<String>.from(jsonDecode(s));
        setState(() => _items = list);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    await LocalStorage().setString('roulette_items', jsonEncode(_items));
  }

  void _onTick() {
    setState(() {
      final t = Curves.easeOut.transform(_ctrl.value);
      _currentAngle = _startAngle + (_endAngle - _startAngle) * t;
    });
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) {
      setState(() { _spinning = false; _result = _winner(); });
    }
  }

  String _winner() {
    if (_items.isEmpty) return '';
    final sa = 2 * pi / _items.length;
    final da = ((3 * pi / 2 - _currentAngle) % (2 * pi) + 2 * pi) % (2 * pi);
    return _items[(da / sa).floor() % _items.length];
  }

  void _spin() {
    if (_spinning || _items.isEmpty) return;
    _startAngle = _currentAngle;
    _endAngle = _startAngle + 6 * pi + Random().nextDouble() * 4 * pi;
    _result = null;
    setState(() => _spinning = true);
    _ctrl.forward(from: 0);
  }

  void _add() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Agregar opcion', style: GoogleFonts.outfit()),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Nueva opcion')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                setState(() => _items.add(c.text.trim()));
                _save();
              }
              Navigator.pop(ctx);
            },
            child: Text('Agregar', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ruleta', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _spinning ? null : _spin,
            child: SizedBox(
              width: 280, height: 280,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)]),
                    child: Transform.rotate(
                      angle: _currentAngle,
                      child: CustomPaint(painter: _WheelPainter(_items, cs.primary, cs.secondary), size: const Size(280, 280)),
                    ),
                  ),
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)]),
                    child: Icon(Icons.favorite, color: cs.primary, size: 28),
                  ),
                  Positioned(
                    top: -12,
                    left: 128,
                    child: Icon(Icons.arrow_drop_down, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_result != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: cs.secondary,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Text(_result!, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface)),
              ),
            ),
          const SizedBox(height: 16),
          if (!_spinning)
            ElevatedButton(
              onPressed: _spin,
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
              child: Text('Girar', style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 18)),
            ),
          if (_spinning)
            const CircularProgressIndicator(),
          const SizedBox(height: 4),
          Text('Toca la rueda para girar', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(_items[i], style: GoogleFonts.outfit()),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () { setState(() => _items.removeAt(i)); _save(); },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
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
        text: TextSpan(text: items[i], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: radius * 0.5);
      tp.paint(canvas, Offset(radius * 0.2, -tp.height / 2));
      canvas.restore();
    }
    for (int i = 0; i < items.length; i++) {
      paint.color = Colors.white.withValues(alpha: 0.3);
      paint.strokeWidth = 1;
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(center, Offset(center.dx + radius * cos(i * sa - pi / 2), center.dy + radius * sin(i * sa - pi / 2)), paint);
    }
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.12, paint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => true;
}
