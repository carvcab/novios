import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/entrance_animation.dart';
import 'hangman_screen.dart';
import 'love_game_screen.dart';
import 'custom_quiz_screen.dart';
import 'truth_dare_custom_screen.dart';
import 'dice_screen.dart';
import 'roulette_screen.dart';
import 'never_have_i_ever_screen.dart';
import 'would_you_rather_screen.dart';

class NewGameScreen extends StatelessWidget {
  final String gameType;

  const NewGameScreen({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    switch (gameType) {
      case 'dice':
        return const DiceScreen();
      case 'cards':
        return const HigherCardGame();
      case 'prefer':
        return const WouldYouRatherScreen();
      case 'roulette':
        return const RouletteScreen();
      case 'never':
        return const NeverHaveIEverScreen();
      case 'hangman':
        return const HangmanScreen();
      case 'love_game':
        return const LoveGameScreen();
      case 'custom_quiz':
        return const CustomQuizScreen();
      case 'custom_td':
      case 'truth_dare':
      case 'picante':
        return const TruthDareCustomScreen();
      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Juego')),
          body: const Center(child: Text('Juego no encontrado')),
        );
    }
  }
}

// ──────────────────────────────────────────────────────────
// 1. CARTA MAYOR / CALIENTE (HIGHER CARD)
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


