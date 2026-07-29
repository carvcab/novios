import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_service.dart';
import '../../widgets/glass_card.dart';
import 'custom_quiz_screen.dart';
import 'truth_dare_custom_screen.dart';
import 'hangman_screen.dart';
import 'roulette_screen.dart';
import 'dice_screen.dart';
import 'never_have_i_ever_screen.dart';
import 'would_you_rather_screen.dart';
import 'love_game_screen.dart';
import 'collections_screen.dart';

class _GameInfo {
  final String name;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final Widget screen;
  final Stream<QuerySnapshot> Function()? countStream;

  const _GameInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.screen,
    this.countStream,
  });
}

class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {
  final _gs = GameService();
  int? _pressedIndex;

  void _navigate(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => screen,
      ),
    );
  }

  List<_GameInfo> get _games => [
    _GameInfo(
      name: 'Colecciones',
      description: 'Organiza tu contenido en carpetas',
      icon: Icons.folder_special_rounded,
      gradient: const [Color(0xFF607D8B), Color(0xFF90A4AE)],
      screen: const CollectionsScreen(),
      countStream: () => _gs.streamCollections(),
    ),
    _GameInfo(
      name: 'Quiz',
      description: 'Crea y juega cuestionarios personalizados',
      icon: Icons.quiz_rounded,
      gradient: const [Color(0xFF7C4DFF), Color(0xFFE040FB)],
      screen: const CustomQuizScreen(),
      countStream: () => _gs.streamQuizzes(),
    ),
    _GameInfo(
      name: 'Ruleta',
      description: 'Gira y descubre retos romanticos',
      icon: Icons.casino_rounded,
      gradient: const [Color(0xFFFF6F00), Color(0xFFFFAB00)],
      screen: const RouletteScreen(),
      countStream: () => _gs.streamRoulettes(),
    ),
    _GameInfo(
      name: 'Ahorcado',
      description: 'Adivina palabras de amor',
      icon: Icons.person_search_rounded,
      gradient: const [Color(0xFF00BCD4), Color(0xFF0288D1)],
      screen: const HangmanScreen(),
      countStream: () => _gs.streamHangman(),
    ),
    _GameInfo(
      name: 'Dados',
      description: 'Lanza los dados y cumple la mision',
      icon: Icons.casino_rounded,
      gradient: const [Color(0xFF4CAF50), Color(0xFF00E676)],
      screen: const DiceScreen(),
      countStream: () => _gs.streamDice(),
    ),
    _GameInfo(
      name: 'Que Prefieres',
      description: 'Elige entre dos opciones divertidas',
      icon: Icons.help_outline_rounded,
      gradient: const [Color(0xFFE91E63), Color(0xFFFF5722)],
      screen: const WouldYouRatherScreen(),
      countStream: () => _gs.streamPrefer(),
    ),
    _GameInfo(
      name: 'Yo Nunca Nunca',
      description: 'Confiesa tus secretos mas divertidos',
      icon: Icons.wine_bar_rounded,
      gradient: const [Color(0xFFD32F2F), Color(0xFFFF5252)],
      screen: const NeverHaveIEverScreen(),
      countStream: () => _gs.streamNever(),
    ),
    _GameInfo(
      name: 'Verdad o Reto',
      description: 'El clasico juego de pareja',
      icon: Icons.favorite_rounded,
      gradient: const [Color(0xFF3F51B5), Color(0xFF7C4DFF)],
      screen: const TruthDareCustomScreen(),
      countStream: () => _gs.streamTD('Verdad'),
    ),
    _GameInfo(
      name: 'El Amor',
      description: 'Preguntas para fortalecer el vinculo',
      icon: Icons.favorite_border_rounded,
      gradient: const [Color(0xFFE91E63), Color(0xFF9C27B0)],
      screen: const LoveGameScreen(),
      countStream: () => _gs.streamLoveQuestions(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Juegos',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.05),
              cs.secondary.withValues(alpha: 0.1),
              cs.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _games.length,
                itemBuilder: (_, i) => _buildGameCard(_games[i], i),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(_GameInfo game, int index) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) {
        setState(() => _pressedIndex = null);
        _navigate(game.screen);
      },
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: _pressedIndex == index
            ? (Matrix4.identity()..scale(0.95))
            : Matrix4.identity(),
        child: GlassCard(
          borderRadius: 20,
          color: Colors.transparent,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: game.gradient,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(game.icon, color: Colors.white, size: 32),
                const Spacer(),
                Text(
                  game.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  game.description,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: game.countStream?.call(),
                    builder: (_, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          count > 0 ? '$count' : '0',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
