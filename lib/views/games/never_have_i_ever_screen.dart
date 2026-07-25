import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class NeverHaveIEverScreen extends StatefulWidget {
  const NeverHaveIEverScreen({super.key});

  @override
  State<NeverHaveIEverScreen> createState() => _NeverHaveIEverScreenState();
}

class _NeverHaveIEverScreenState extends State<NeverHaveIEverScreen> {
  static const _statements = [
    "He fingido un orgasmo",
    "He escrito una carta de amor",
    "He llorado viendo una pelicula romantica",
    "He tenido una cita a ciegas",
    "Me he enamorado a primera vista",
    "He bailado bajo la lluvia",
    "He dicho 'te quiero' primero",
    "He tenido una relacion a distancia",
    "He besado a alguien en la primera cita",
    "He preparado una cena romantica",
    "He cantado una cancion de amor a alguien",
    "He tenido una pelea por celos",
    "He viajado por amor",
    "He mirado el telefono de mi pareja",
    "He hecho un regalo sorpresa",
    "He dicho 'te amo' sin sentirlo",
    "He tenido una cita virtual",
    "Me he sonrojado por un cumplido",
    "He tenido un romance en el trabajo",
    "He visto el amanecer con alguien especial",
    "He tenido una discusion tonta",
    "He cocinado para mi pareja",
    "He mentido sobre mis sentimientos",
    "He guardado cartas o mensajes de amor",
    "Me he arrepentido de terminar una relacion",
    "He tenido una cita que duro mas de 24 horas",
    "He hecho una promesa que no cumpli",
    "He tenido una reconciliacion apasionada",
    "He compartido mi comida favorita con mi pareja",
    "He planeado una escapada romantica",
    "He tenido una conversacion profunda toda la noche",
    "Me he sentido completamente vulnerable con alguien",
    "He hecho el amor en un lugar publico",
  ];

  late List<String> _shuffled;
  int _currentIndex = 0;
  int _player1Score = 0, _player2Score = 0;
  bool _p1Answered = false, _gameOver = false;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    _shuffled = List.from(_statements)..shuffle(Random());
    setState(() {
      _currentIndex = 0;
      _player1Score = _player2Score = 0;
      _p1Answered = false;
      _gameOver = false;
    });
  }

  void _answer(bool done) {
    if (_gameOver) return;
    setState(() {
      if (!_p1Answered) {
        if (done) _player1Score++;
        _p1Answered = true;
      } else {
        if (done) _player2Score++;
        if (_currentIndex >= _shuffled.length - 1) {
          _gameOver = true;
        } else {
          _currentIndex++;
          _p1Answered = false;
        }
      }
    });
    if (_gameOver) _showResult();
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Resultado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Jugador 1: $_player1Score', style: GoogleFonts.outfit(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Jugador 2: $_player2Score', style: GoogleFonts.outfit(fontSize: 18)),
            const SizedBox(height: 16),
            Text(
              _player1Score > _player2Score
                  ? 'Gana Jugador 1!'
                  : _player2Score > _player1Score
                      ? 'Gana Jugador 2!'
                      : 'Empate!',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(c); _shuffle(); },
            child: Text('Jugar de nuevo', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final player = _p1Answered ? 2 : 1;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nunca he...', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text('P1: $_player1Score  P2: $_player2Score',
                style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Turno: Jugador $player', style: GoogleFonts.outfit(fontSize: 14, color: cs.secondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_currentIndex + 1} de ${_shuffled.length}', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Text(
                  _shuffled[_currentIndex],
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40),
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
            const SizedBox(height: 24),
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
