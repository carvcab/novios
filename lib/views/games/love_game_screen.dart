import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoveGameScreen extends StatefulWidget {
  const LoveGameScreen({super.key});

  @override
  State<LoveGameScreen> createState() => _LoveGameScreenState();
}

class _LoveGameScreenState extends State<LoveGameScreen> {
  static final _cards = [
    _GameCard('Romanticas', 'Susurra algo dulce al oido de tu pareja', const Color(0xFFE91E63), 1),
    _GameCard('Romanticas', 'Di 3 cosas que amas de tu pareja', const Color(0xFFE91E63), 1),
    _GameCard('Romanticas', 'Besa lentamente a tu pareja durante 10 segundos', const Color(0xFFE91E63), 1),
    _GameCard('Romanticas', 'Toma las manos de tu pareja y miralo/a a los ojos', const Color(0xFFE91E63), 1),
    _GameCard('Romanticas', 'Comparte tu recuerdo favorito como pareja', const Color(0xFFE91E63), 1),
    _GameCard('Romanticas', 'Describe como te sientes en este momento', const Color(0xFFE91E63), 1),
    _GameCard('Romanticas', 'Di que fue lo que te atrio de tu pareja', const Color(0xFFE91E63), 1),
    _GameCard('Atrevidas', 'Da un beso apasionado de 10 segundos', const Color(0xFFFF9800), 2),
    _GameCard('Atrevidas', 'Susurra algo atrevido al oido de tu pareja', const Color(0xFFFF9800), 2),
    _GameCard('Atrevidas', 'Masajea los hombros de tu pareja por 1 minuto', const Color(0xFFFF9800), 2),
    _GameCard('Atrevidas', 'Besa el cuello de tu pareja suavemente', const Color(0xFFFF9800), 2),
    _GameCard('Atrevidas', 'Quitate una prenda de ropa', const Color(0xFFFF9800), 2),
    _GameCard('Atrevidas', 'Baila una cancion sensual para tu pareja', const Color(0xFFFF9800), 2),
    _GameCard('Atrevidas', 'Comparte una fantasia secreta', const Color(0xFFFF9800), 2),
    _GameCard('Curiosas', 'Cual fue tu primera impresion de mi?', const Color(0xFF2196F3), 1),
    _GameCard('Curiosas', 'Que es lo que mas te gusta de nuestra relacion?', const Color(0xFF2196F3), 1),
    _GameCard('Curiosas', 'Cual es tu mayor miedo en la relacion?', const Color(0xFF2196F3), 1),
    _GameCard('Curiosas', 'Que cancion te recuerda a mi?', const Color(0xFF2196F3), 1),
    _GameCard('Curiosas', 'Que lugar del mundo te gustaria visitar conmigo?', const Color(0xFF2196F3), 1),
    _GameCard('Curiosas', 'Que es lo que mas valoras de nuestra comunicacion?', const Color(0xFF2196F3), 1),
    _GameCard('Acciones', 'Haganse cosquillas durante 30 segundos', const Color(0xFF4CAF50), 2),
    _GameCard('Acciones', 'Bailen juntos la cancion que esta sonando', const Color(0xFF4CAF50), 2),
    _GameCard('Acciones', 'Tomense una selfie juntos ahora mismo', const Color(0xFF4CAF50), 2),
    _GameCard('Acciones', 'Preparen un snack juntos', const Color(0xFF4CAF50), 2),
    _GameCard('Acciones', 'Escriban una meta de pareja para este ano', const Color(0xFF4CAF50), 2),
    _GameCard('Acciones', 'Mirense a los ojos sin reir por 30 segundos', const Color(0xFF4CAF50), 2),
  ];

  late List<_GameCard> _remaining;
  _GameCard? _currentCard;
  bool _revealed = false;
  int _intimacyScore = 0;

  @override
  void initState() {
    super.initState();
    _remaining = List.from(_cards)..shuffle();
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
    setState(() => _intimacyScore += _currentCard!.points);
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
            Text('Completaron las 26 cartas!', style: GoogleFonts.outfit()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              setState(() {
                _remaining = List.from(_cards)..shuffle();
                _intimacyScore = 0;
                _nextCard();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Love Game', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('$_intimacyScore pts', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
        ],
      ),
      body: _currentCard == null
          ? const Center(child: Text('No hay mas cartas'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('${_cards.length - _remaining.length - 1} de ${_cards.length}', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
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
                          child: _revealed ? _CardFront(_currentCard!, cs) : _CardBack(_currentCard!, cs),
                        ),
                      ),
                    ),
                  ),
                  if (_revealed) ...[
                    const SizedBox(height: 16),
                    Text('Desliza para la siguiente carta', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                  if (!_revealed) ...[
                    const SizedBox(height: 16),
                    Text('Toca para revelar', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_cards.length - _remaining.length) / _cards.length,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GameCard {
  final String category;
  final String content;
  final Color color;
  final int points;
  const _GameCard(this.category, this.content, this.color, this.points);
}

class _CardBack extends StatelessWidget {
  final _GameCard card;
  final ColorScheme cs;
  const _CardBack(this.card, this.cs);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('back_${card.content}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: card.color,
      elevation: 6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 48),
            const SizedBox(height: 20),
            Text(card.category, style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Toca para revelar', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  final _GameCard card;
  final ColorScheme cs;
  const _CardFront(this.card, this.cs);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('front_${card.content}'),
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
              decoration: BoxDecoration(color: card.color, borderRadius: BorderRadius.circular(20)),
              child: Text(card.category, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 24),
            Text(card.content, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('+${card.points} pts', style: GoogleFonts.outfit(color: card.color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
