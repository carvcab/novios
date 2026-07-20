import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/entrance_animation.dart';

class NewGameScreen extends StatelessWidget {
  final String gameType;

  const NewGameScreen({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    switch (gameType) {
      case 'dice':
        return const LoveDiceGame();
      case 'cards':
        return const HigherCardGame();
      case 'prefer':
        return const WouldYouRatherGame();
      case 'roulette':
        return const LoveRouletteGame();
      case 'never':
        return const NeverHaveIEverGame();
      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Juego')),
          body: const Center(child: Text('Juego no encontrado')),
        );
    }
  }
}

// ──────────────────────────────────────────────────────────
// 1. DADOS DEL AMOR (LOVE DICE)
// ──────────────────────────────────────────────────────────
class LoveDiceGame extends StatefulWidget {
  const LoveDiceGame({super.key});

  @override
  State<LoveDiceGame> createState() => _LoveDiceGameState();
}

class _LoveDiceGameState extends State<LoveDiceGame> with TickerProviderStateMixin {
  final List<String> _actions = [
    "Besar 💋",
    "Acariciar 👋",
    "Morder suave 🦷",
    "Masaje 💆",
    "Soplar 💨",
    "Hacer cosquillas 🧸",
    "Susurrar 🤫",
    "Lamer 👅"
  ];

  final List<String> _bodyParts = [
    "en el Cuello",
    "en los Labios",
    "en la Espalda",
    "en las Manos",
    "en la Oreja",
    "en la Mejilla",
    "en la Frente",
    "en el Abdomen"
  ];

  int _actionIdx = 0;
  int _bodyPartIdx = 0;
  bool _rolling = false;
  double _diceRotation = 0;

  void _roll() {
    if (_rolling) return;
    setState(() {
      _rolling = true;
    });

    int count = 0;
    final r = Random();
    
    // Animate rolling effect
    Stream.periodic(const Duration(milliseconds: 100), (c) => c)
        .take(12)
        .listen((event) {
      setState(() {
        _actionIdx = r.nextInt(_actions.length);
        _bodyPartIdx = r.nextInt(_bodyParts.length);
        _diceRotation += 0.5;
      });
      count++;
      if (count == 12) {
        setState(() {
          _rolling = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Dados del Amor', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanza los dados y cumple el reto con tu pareja 🎲🔥',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Action die
                  AnimatedRotation(
                    turns: _diceRotation,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5C8A), Color(0xFFFF8AAB)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5C8A).withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _actions[_actionIdx],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Body part die
                  AnimatedRotation(
                    turns: -_diceRotation,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA78BFA), Color(0xFFC4B5FD)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA78BFA).withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _bodyParts[_bodyPartIdx],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              if (!_rolling)
                EntranceAnimation(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Debes hacer: ${_actions[_actionIdx]} ${_bodyParts[_bodyPartIdx]} 💖',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 60),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _rolling ? null : _roll,
                  icon: const Icon(Icons.casino_rounded),
                  label: Text(
                    _rolling ? 'Lanzando...' : 'Lanzar Dados 🎲',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// 2. CARTA MAYOR / CALIENTE (HIGHER CARD)
// ──────────────────────────────────────────────────────────
class HigherCardGame extends StatefulWidget {
  const HigherCardGame({super.key});

  @override
  State<HigherCardGame> createState() => _HigherCardGameState();
}

class _HigherCardGameState extends State<HigherCardGame> {
  int? _myCard;
  int? _partnerCard;
  bool _revealed = false;
  bool _animating = false;

  final List<String> _suits = ["♥️", "♦️", "♣️", "♠️"];
  

  void _draw() {
    if (_animating) return;
    setState(() {
      _animating = true;
      _revealed = false;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      final r = Random();
      setState(() {
        _myCard = r.nextInt(13) + 1;
        _partnerCard = r.nextInt(13) + 1;
        // Avoid equal cards for simplicity
        if (_myCard == _partnerCard) {
          _partnerCard = (_partnerCard! % 13) + 1;
        }
        _revealed = true;
        _animating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = Random();
    final mySuit = _suits[r.nextInt(4)];
    final partnerSuit = _suits[r.nextInt(4)];

    return Scaffold(
      appBar: AppBar(
        title: Text('Carta Mayor Caliente', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quien saque la carta más alta manda y pone un reto picante al otro 🃏🌶️',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Player 1 Card
                  Column(
                    children: [
                      Text('Tú', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.primary)),
                      const SizedBox(height: 12),
                      _CardWidget(
                        value: _myCard,
                        suit: mySuit,
                        revealed: _revealed,
                        animating: _animating,
                        cs: cs,
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                  
                  // Player 2 Card
                  Column(
                    children: [
                      Text('Tu Pareja', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.secondary)),
                      const SizedBox(height: 12),
                      _CardWidget(
                        value: _partnerCard,
                        suit: partnerSuit,
                        revealed: _revealed,
                        animating: _animating,
                        cs: cs,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 50),

              if (_revealed && _myCard != null && _partnerCard != null)
                EntranceAnimation(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: (_myCard! > _partnerCard! ? cs.primary : cs.secondary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: (_myCard! > _partnerCard! ? cs.primary : cs.secondary).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _myCard! > _partnerCard!
                          ? '¡Ganaste! Ponle un reto picante a tu pareja 😈'
                          : '¡Tu pareja gana! Te toca cumplir su reto 😳',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _myCard! > _partnerCard! ? cs.primary : cs.secondary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _animating ? null : _draw,
                  icon: const Icon(Icons.style_rounded),
                  label: Text(
                    _animating ? 'Barajando...' : 'Sacar Cartas 🃏',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final int? value;
  final String suit;
  final bool revealed;
  final bool animating;
  final ColorScheme cs;

  const _CardWidget({
    required this.value,
    required this.suit,
    required this.revealed,
    required this.animating,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isRed = suit == "♥️" || suit == "♦️";
    
    if (animating) {
      return Container(
        width: 110,
        height: 160,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.2), width: 2),
        ),
        child: const Center(
          child: SizedBox(
            width: 30, height: 30,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!revealed || value == null) {
      return Container(
        width: 110,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(
          child: Icon(Icons.favorite_rounded, color: Colors.white, size: 40),
        ),
      );
    }

    String label = value == 1 ? 'A' : value == 11 ? 'J' : value == 12 ? 'Q' : value == 13 ? 'K' : value.toString();

    return Container(
      width: 110,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isRed ? Colors.red : Colors.black,
              ),
            ),
          ),
          Text(
            suit,
            style: TextStyle(fontSize: 40, color: isRed ? Colors.red : Colors.black),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isRed ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// 3. ¿QUÉ PREFIERES? (WOULD YOU RATHER?)
// ──────────────────────────────────────────────────────────
class WouldYouRatherGame extends StatefulWidget {
  const WouldYouRatherGame({super.key});

  @override
  State<WouldYouRatherGame> createState() => _WouldYouRatherGameState();
}

class _WouldYouRatherGameState extends State<WouldYouRatherGame> {
  final List<Map<String, String>> _questions = [
    {
      "a": "Viajar juntos a una isla desierta 🏝️",
      "b": "Fin de semana entero abrazados con lluvia en casa 🌧️"
    },
    {
      "a": "Un masaje sensual de 1 hora de tu pareja 💆",
      "b": "Una cena gourmet cocinada por tu pareja a la luz de velas 🕯️"
    },
    {
      "a": "Que tu pareja te bese apasionadamente en público 💋",
      "b": "Un susurro atrevido al oído en privado 🤫"
    },
    {
      "a": "Dormir completamente abrazados toda la noche 🤗",
      "b": "Dormir separados pero tomados de la mano 🤝"
    },
    {
      "a": "Hacer un divertido juego de rol atrevido 🎭",
      "b": "Una larga sesión de besos con los ojos vendados 🙈"
    },
    {
      "a": "Besos infinitos en el cuello 👄",
      "b": "Caricias y cosquillas por todo el cuerpo ✨"
    }
  ];

  int _currentIdx = 0;
  String? _selected;

  void _next() {
    setState(() {
      _selected = null;
      _currentIdx = (_currentIdx + 1) % _questions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = _questions[_currentIdx];

    return Scaffold(
      appBar: AppBar(
        title: Text('¿Qué Prefieres?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elijan individualmente y comparen sus respuestas para conocerse mejor 🤔💬',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 40),
              
              // Option A (Red/Pink gradient)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = 'A'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selected == 'A'
                            ? [const Color(0xFFFF5C8A), const Color(0xFFFF8AAB)]
                            : [const Color(0xFFFF5C8A).withValues(alpha: 0.2), const Color(0xFFFF8AAB).withValues(alpha: 0.2)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _selected == 'A' ? Colors.white : const Color(0xFFFF5C8A).withValues(alpha: 0.3),
                        width: _selected == 'A' ? 3 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          q['a']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _selected == 'A' ? Colors.white : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Ó',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
              const SizedBox(height: 16),

              // Option B (Blue/Purple gradient)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = 'B'),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selected == 'B'
                            ? [const Color(0xFF42A5F5), const Color(0xFF90CAF9)]
                            : [const Color(0xFF42A5F5).withValues(alpha: 0.2), const Color(0xFF90CAF9).withValues(alpha: 0.2)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _selected == 'B' ? Colors.white : const Color(0xFF42A5F5).withValues(alpha: 0.3),
                        width: _selected == 'B' ? 3 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          q['b']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _selected == 'B' ? Colors.white : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (_selected != null)
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Siguiente Pregunta ➡️',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// 4. RULETA DEL DESTINO (LOVE ROULETTE)
// ──────────────────────────────────────────────────────────
class LoveRouletteGame extends StatefulWidget {
  const LoveRouletteGame({super.key});

  @override
  State<LoveRouletteGame> createState() => _LoveRouletteGameState();
}

class _LoveRouletteGameState extends State<LoveRouletteGame> {
  final List<Map<String, dynamic>> _sectors = [
    {"label": "Abrazo de 30s 🤗", "color": const Color(0xFFFF5C8A)},
    {"label": "Secreto Íntimo 🤫", "color": const Color(0xFFA78BFA)},
    {"label": "Beso en el cuello 💋", "color": const Color(0xFFFFB74D)},
    {"label": "Cumplido Picante 🔥", "color": const Color(0xFF42A5F5)},
    {"label": "Beso apasionado 👄", "color": const Color(0xFFEF5350)},
    {"label": "Masaje express 💆", "color": const Color(0xFF66BB6A)},
  ];

  double _rotation = 0;
  bool _spinning = false;
  String? _result;

  void _spin() {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _result = null;
    });

    final r = Random();
    // Spin at least 5 full rotations, up to 10
    final extraSpins = r.nextInt(5) + 5;
    // Target random sector
    final targetSector = r.nextInt(_sectors.length);
    final sectorAngle = (2 * pi) / _sectors.length;
    // Calculate final rotation
    final finalRotation = _rotation + (extraSpins * 2 * pi) + (targetSector * sectorAngle);

    setState(() {
      _rotation = finalRotation;
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _spinning = false;
          // Determine resulting sector (accounting for direction)
          final finalIndex = (_sectors.length - targetSector) % _sectors.length;
          _result = _sectors[finalIndex]['label'] as String;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ruleta del Amor', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Giren la ruleta y cumplan lo que el destino elija 🎡💕',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 40),
              
              // Spinning wheel representation
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedRotation(
                    turns: _rotation / (2 * pi),
                    duration: const Duration(milliseconds: 3000),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.surfaceContainerHighest,
                        border: Border.all(color: cs.onSurface.withValues(alpha: 0.2), width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Stack(
                        children: _sectors.asMap().entries.map((e) {
                          final idx = e.key;
                          final angle = (2 * pi / _sectors.length) * idx;
                          return Transform.rotate(
                            angle: angle,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                margin: const EdgeInsets.only(top: 24),
                                child: Transform.rotate(
                                  angle: pi / 2, // Keep labels radial
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: e.value['color'] as Color,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      e.value['label'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Pointer arrow pointing down
                  Positioned(
                    top: 0,
                    child: Icon(Icons.arrow_drop_down_rounded, size: 54, color: cs.primary),
                  ),
                  // Center pin
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),

              if (_result != null)
                EntranceAnimation(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '¡Te tocó: $_result! 🔥',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _spinning ? null : _spin,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _spinning ? 'Girando...' : 'Girar Ruleta 🎡',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// 5. YO NUNCA NUNCA (NEVER HAVE I EVER)
// ──────────────────────────────────────────────────────────
class NeverHaveIEverGame extends StatefulWidget {
  const NeverHaveIEverGame({super.key});

  @override
  State<NeverHaveIEverGame> createState() => _NeverHaveIEverGameState();
}

class _NeverHaveIEverGameState extends State<NeverHaveIEverGame> {
  final List<String> _questions = [
    "Nunca nunca me he puesto celoso/a sin decirlo.",
    "Nunca nunca he tenido una fantasía atrevida con mi pareja en el trabajo.",
    "Nunca nunca he fingido estar dormido/a para no hablar.",
    "Nunca nunca he tomado una foto atrevida para enviársela a mi pareja.",
    "Nunca nunca he mirado el celular de mi pareja mientras dormía.",
    "Nunca nunca he querido repetir nuestra primera cita exactamente igual.",
    "Nunca nunca he soñado algo picante con mi pareja y no se lo he contado.",
    "Nunca nunca he mentido sobre que me gusta un regalo de mi pareja.",
    "Nunca nunca me he reído durante un momento romántico o íntimo.",
    "Nunca nunca he buscado el nombre de mi pareja en Google."
  ];

  int _currentIdx = 0;
  bool _answered = false;
  String? _choice;

  void _next() {
    setState(() {
      _answered = false;
      _choice = null;
      _currentIdx = (_currentIdx + 1) % _questions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statement = _questions[_currentIdx];

    return Scaffold(
      appBar: AppBar(
        title: Text('Yo Nunca Nunca', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sean honestos y respondan juntos. ¡Quien lo haya hecho bebe un trago! 🍷😈',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 40),
              
              // Statement card
              Expanded(
                child: GlassCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        statement,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (!_answered)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _answered = true;
                              _choice = "Yo Nunca 😇";
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Yo Nunca 😇',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _answered = true;
                              _choice = "¡Yo Sí! 😈";
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            '¡Yo Sí! 😈',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _choice == "¡Yo Sí! 😈" ? Colors.redAccent.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _choice == "¡Yo Sí! 😈" ? Colors.redAccent : Colors.green),
                      ),
                      child: Text(
                        'Elegiste: $_choice',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _choice == "¡Yo Sí! 😈" ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Siguiente Frase ➡️',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
