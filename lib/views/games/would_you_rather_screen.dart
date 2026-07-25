import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class WouldYouRatherScreen extends StatefulWidget {
  const WouldYouRatherScreen({super.key});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  static const _dilemmas = [
    ["perder la memoria y olvidar nuestro primer beso", "perder la habilidad de crear nuevos recuerdos juntos"],
    ["una cita en un restaurante elegante cada mes", "una aventura sorpresa cada semana"],
    ["vivir en una ciudad diferente cada ano", "vivir en el mismo pueblo acogedor para siempre"],
    ["que tu pareja te cante en publico", "que te escriba un poema cada dia"],
    ["no poder decir 'te quiero' nunca mas", "tener que decirlo cada 5 minutos"],
    ["una cena romantica en casa", "una cita en un lugar exotico"],
    ["besos apasionados todas las mananas", "abrazos largos cada noche"],
    ["un viaje espontaneo de fin de semana", "unas vacaciones perfectas de dos semanas"],
    ["una conversacion profunda cada noche", "reir juntos sin parar"],
    ["que tu pareja sea tu mejor amigo", "tu amante apasionado"],
    ["una discusion honesta que duele", "una mentira piadosa que protege"],
    ["una gran historia de amor en un ano", "una historia tranquila por 50 anos"],
    ["cocinar juntos todas las noches", "pedir comida y ver peliculas"],
    ["un masaje relajante de 30 minutos", "un baile sensual de 10 minutos"],
    ["recibir flores cada semana", "mensajes romanticos cada dia"],
    ["una cita sorpresa preparada por tu pareja", "planear juntos cada detalle"],
    ["poder leer la mente de tu pareja", "que tu pareja pueda leer la tuya"],
    ["tener el mismo sueno cada noche", "poder sonar con tu pareja cuando quieras"],
    ["un fin de semana romantico en la montana", "en la playa"],
    ["un beso bajo la lluvia", "un abrazo frente a la chimenea"],
    ["pasar un dia entero sin hablar", "un dia entero sin tocarse"],
    ["que te hagan cosquillas", "un masaje en los pies"],
    ["una serenata en tu ventana", "un picnic bajo las estrellas"],
    ["descubrir un talento oculto de tu pareja", "que tu pareja descubra el tuyo"],
    ["una cita en un concierto", "en una obra de teatro romantica"],
    ["hacer un album de fotos juntos", "escribir un diario de pareja"],
    ["bailar bajo la lluvia", "hacer un muneco de nieve juntos"],
    ["despertar con un beso cada manana", "dormir abrazados cada noche"],
    ["hablar con tu yo del pasado", "con tu yo del futuro"],
    ["grabar un video de confesiones", "escribir cartas que nunca enviaran"],
    ["una cita en un globo aerostatico", "un paseo en barco al atardecer"],
    ["que tu pareja sepa lo que piensas", "que te sorprenda siempre"],
  ];

  late List<List<String>> _shuffled;
  int _currentIndex = 0;
  int _currentPlayer = 1;
  final List<int> _p1Choices = [];
  final List<int> _p2Choices = [];
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _shuffled = List.from(_dilemmas)..shuffle(Random());
  }

  void _pick(int choice) {
    if (_gameOver) return;
    setState(() {
      if (_currentPlayer == 1) {
        _p1Choices.add(choice);
        _currentPlayer = 2;
      } else {
        _p2Choices.add(choice);
        if (_currentIndex >= _shuffled.length - 1) {
          _gameOver = true;
          _showResult();
        } else {
          _currentIndex++;
          _currentPlayer = 1;
        }
      }
    });
  }

  double get _matchPercentage {
    if (_p1Choices.isEmpty) return 0;
    int matches = 0;
    for (int i = 0; i < _p1Choices.length; i++) {
      if (_p1Choices[i] == _p2Choices[i]) matches++;
    }
    return (matches / _p1Choices.length) * 100;
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Compatibilidad', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_matchPercentage.toStringAsFixed(0)}% de coincidencia', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 12),
            Text('Respondieron ${_p1Choices.length} preguntas', style: GoogleFonts.outfit()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              setState(() {
                _shuffled = List.from(_dilemmas)..shuffle(Random());
                _currentIndex = 0;
                _currentPlayer = 1;
                _p1Choices.clear();
                _p2Choices.clear();
                _gameOver = false;
              });
            },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dilemma = _shuffled[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Que prefieres...', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Jugador $_currentPlayer', style: GoogleFonts.outfit(fontSize: 14, color: cs.secondary)),
            const SizedBox(height: 4),
            Text('${_p1Choices.length + 1} de ${_shuffled.length}', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            Text('Que prefieres...', style: GoogleFonts.outfit(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OptionCard(0, dilemma[0], cs.primary, cs.onSurface, _gameOver, () => _pick(0)),
                  const SizedBox(height: 16),
                  Text('O', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: cs.secondary)),
                  const SizedBox(height: 16),
                  _OptionCard(1, dilemma[1], cs.secondary, cs.onSurface, _gameOver, () => _pick(1)),
                ],
              ),
            ),
            if (_gameOver)
              ElevatedButton(
                onPressed: _showResult,
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
                child: Text('Ver resultado', style: GoogleFonts.outfit(color: cs.onSurface)),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final int index;
  final String text;
  final Color bg;
  final Color fg;
  final bool disabled;
  final VoidCallback onTap;
  const _OptionCard(this.index, this.text, this.bg, this.fg, this.disabled, this.onTap);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: GoogleFonts.outfit(color: fg, fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ),
    );
  }
}
