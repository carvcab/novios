import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with SingleTickerProviderStateMixin {
  static const _bodyParts = ["Labios", "Cuello", "Manos", "Frente", "Mejilla", "Hombros", "Espalda", "Cintura"];
  static const _actions = ["Besar", "Acariciar", "Abrazar", "Masajear", "Susurrar", "Morder suave", "Soplar", "Cosquillas"];
  static const _places = ["Sofa", "Cocina", "Balcon", "Cama", "Ducha", "Espejo", "Suelo", "Silla"];

  late AnimationController _shakeCtrl;
  String _bodyPart = '', _action = '', _place = '';
  String _tempBody = '', _tempAction = '', _tempPlace = '';
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  void _roll() {
    if (_rolling) return;
    setState(() => _rolling = true);
    _shakeCtrl.repeat(reverse: true);
    int count = 0;
    Timer.periodic(const Duration(milliseconds: 80), (timer) {
      count++;
      setState(() {
        _tempBody = _bodyParts[Random().nextInt(_bodyParts.length)];
        _tempAction = _actions[Random().nextInt(_actions.length)];
        _tempPlace = _places[Random().nextInt(_places.length)];
      });
      if (count >= 12) {
        timer.cancel();
        _shakeCtrl.stop();
        _shakeCtrl.reset();
        setState(() {
          _bodyPart = _bodyParts[Random().nextInt(_bodyParts.length)];
          _action = _actions[Random().nextInt(_actions.length)];
          _place = _places[Random().nextInt(_places.length)];
          _rolling = false;
        });
      }
    });
  }

  @override
  void dispose() { _shakeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showingBody = _rolling ? _tempBody : _bodyPart;
    final showingAction = _rolling ? _tempAction : _action;
    final showingPlace = _rolling ? _tempPlace : _place;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dados Romanticos', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DiceWidget(showingBody, _shakeCtrl, cs),
                _DiceWidget(showingAction, _shakeCtrl, cs),
              ],
            ),
            const SizedBox(height: 32),
            if (!_rolling && _bodyPart.isNotEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: cs.secondary.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Resultado', style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 8),
                      Text(
                        '$_bodyPart + $_action + $_place',
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('${_bodyPart.toLowerCase()} en $_place', style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _rolling ? null : _roll,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_rolling ? '...' : 'Lanzar dados', style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DiceWidget extends StatelessWidget {
  final String text;
  final AnimationController shakeCtrl;
  final ColorScheme cs;
  const _DiceWidget(this.text, this.shakeCtrl, this.cs);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeCtrl,
      builder: (_, child) {
        final offset = shakeCtrl.isAnimating ? (Random().nextDouble() - 0.5) * 4 : 0.0;
        return Transform.translate(
          offset: Offset(offset, offset),
          child: child,
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(2, 4))],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(text, style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
