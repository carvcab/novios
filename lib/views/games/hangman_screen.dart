import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  static const _words = [
    "AMOR", "BESO", "ABRAZO", "CORAZON", "PAREJA", "ROMANTICO", "CARINO",
    "PASION", "SENTIMIENTO", "ALMA", "BONITO", "QUERER", "DULCE", "FELIZ",
    "SONRISA", "DESTINO", "SUENO", "BODA", "CIELO", "ETERNO"
  ];

  late String _word;
  final Set<String> _guessed = {};
  int _wrong = 0;
  int _score = 0;
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _word = _words[Random().nextInt(_words.length)];
      _guessed.clear();
      _wrong = 0;
      _over = false;
    });
  }

  String get _display => _word.split('').map((l) => _guessed.contains(l) ? l : '_').join(' ');

  void _guess(String l) {
    if (_over || _guessed.contains(l)) return;
    setState(() {
      _guessed.add(l);
      if (!_word.contains(l)) _wrong++;
      _check();
    });
  }

  void _check() {
    if (_wrong >= 6) {
      _over = true;
      _end(false);
    } else if (_word.split('').every((l) => _guessed.contains(l))) {
      _over = true;
      _score++;
      _end(true);
    }
  }

  void _end(bool w) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(w ? 'Ganaste' : 'Perdiste', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        content: Text('La palabra era: $_word', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(c); _reset(); },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ahorcado', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('$_score pts', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 18))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: CustomPaint(painter: _HangmanPainter(_wrong, cs.primary), size: const Size(double.infinity, 150)),
            ),
            const SizedBox(height: 16),
            Text(_display, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 6)),
            const SizedBox(height: 8),
            Text('Fallos: $_wrong / 6', style: GoogleFonts.outfit(color: cs.secondary, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              flex: 3,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
                itemCount: 26,
                itemBuilder: (_, i) {
                  final l = String.fromCharCode(65 + i);
                  final u = _guessed.contains(l);
                  return Material(
                    color: u ? Colors.grey.shade300 : cs.primary,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: u || _over ? null : () => _guess(l),
                      borderRadius: BorderRadius.circular(8),
                      child: Center(child: Text(l, style: GoogleFonts.outfit(color: u ? Colors.grey : cs.onSurface, fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
