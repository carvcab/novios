import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../widgets/confetti_overlay.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import '../../services/ai_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'spicy_games_screen.dart';
import '../../widgets/firestore_image.dart';
import 'game_history_screen.dart';
import 'new_games_flow.dart';

class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab> {

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firebase = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juegos de Pareja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded),
            tooltip: 'Estadísticas e Historial',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Icon(Icons.sports_esports_rounded, size: 32, color: cs.primary),
                  const SizedBox(height: 8),
                  Text('Juegos de Pareja',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Diviértanse juntos online o en el mismo celular',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Shared multiplayer active/pending games ──
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: firebase.streamActiveGames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final games = snapshot.data ?? [];
                if (games.isEmpty) return const SizedBox();
                
                final myName = LocalStorage().getUserName() ?? 'Yo';
                final myId = LocalStorage().getUserId() ?? '';
                final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_rounded, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Partidas en Tiempo Real',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final g = games[index];
                          final id = g['id']?.toString() ?? '';
                          final type = g['gameType']?.toString() ?? '';
                          final status = g['status']?.toString() ?? 'pending';
                          final sender = g['sender']?.toString() ?? '';
                          final senderId = g['senderId']?.toString() ?? '';

                          final gameLabel = _getGameLabel(type);
                          final isSender = senderId.isNotEmpty ? senderId == myId : sender == myName;

                          if (status == 'pending') {
                            if (isSender) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  title: Text('Esperando a $partnerName...'),
                                  subtitle: Text('Invitación para $gameLabel'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.red),
                                    onPressed: () => firebase.deleteGameSession(id),
                                  ),
                                ),
                              );
                            } else {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                color: cs.primaryContainer.withValues(alpha: 0.3),
                                child: ListTile(
                                  leading: Icon(Icons.sports_esports_rounded, color: cs.primary),
                                  title: Text('¡$sender te invitó!'),
                                  subtitle: Text('Juego: $gameLabel'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                                        onPressed: () {
                                          firebase.updateGameSession(id, {'status': 'active'});
                                          _playGameOnline(type, id);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                                        onPressed: () => firebase.deleteGameSession(id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          } else if (status == 'active') {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: Icon(Icons.play_circle_fill_rounded, color: cs.primary),
                                title: Text('Partida de $gameLabel activa'),
                                subtitle: Text('Jugando con $partnerName'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _playGameOnline(type, id),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Jugar'),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                                      onPressed: () => firebase.deleteGameSession(id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _GameCard(
                  icon: Icons.quiz_rounded,
                  name: 'Quiz',
                  desc: 'Pon a prueba tu conocimiento',
                  gradient: const LinearGradient(colors: [Color(0xFFFF5C8A), Color(0xFFFF8AAB)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('quiz'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.favorite_rounded,
                  name: 'Verdad o Reto',
                  desc: 'Respuestas y desafíos',
                  gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFFC4B5FD)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('truth_dare'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.extension_rounded,
                  name: 'Memorama',
                  desc: 'Encuentra las parejas',
                  gradient: const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFFD54F)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('memorama'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.grid_3x3_rounded,
                  name: 'Tres en Raya',
                  desc: 'Juego clásico por turnos',
                  gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('tictactoe'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.front_hand_rounded,
                  name: 'Piedra Papel Tijera',
                  desc: 'Prueba tu suerte',
                  gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('rps'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.help_outline_rounded,
                  name: 'Ahorcado',
                  desc: 'Adivina palabras de amor',
                  gradient: const LinearGradient(colors: [Color(0xFFEF5350), Color(0xFFEF9A9A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('hangman'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.casino_rounded,
                  name: 'Dados del Amor',
                  desc: 'Acción y parte del cuerpo 🎲',
                  gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('dice'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.style_rounded,
                  name: 'Carta Mayor',
                  desc: 'La carta más alta manda 🃏',
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('cards'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.question_answer_rounded,
                  name: '¿Qué Prefieres?',
                  desc: 'Elige tu dilema amoroso 🤔',
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('prefer'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.radar_rounded,
                  name: 'Ruleta del Amor',
                  desc: 'Gira por un reto o premio 🎡',
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('roulette'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.wine_bar_rounded,
                  name: 'Yo Nunca Nunca',
                  desc: 'Revela tus secretos 🍷',
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => _onGameCardTapped('never'),
                  cs: cs,
                ),
                _GameCard(
                  icon: Icons.local_fire_department_rounded,
                  name: 'Picante',
                  desc: 'Verdad, reto y más 🔥',
                  gradient: const LinearGradient(colors: [Color(0xFFFF5C8A), Color(0xFFFF8AAB)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpicyGamesScreen())),
                  cs: cs,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _onGameCardTapped(String type) {
    final gameLabel = _getGameLabel(type);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jugar a $gameLabel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.wifi_rounded, color: cs.primary),
                title: const Text('Jugar Online con mi pareja'),
                subtitle: Text('Envía una invitación en tiempo real a $partnerName'),
                onTap: () {
                  Navigator.pop(context);
                  FirebaseService().createGameSession(type, {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invitación enviada a $partnerName 🎮')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.phone_android_rounded, color: Colors.grey.shade600),
                title: const Text('Jugar en este mismo celular'),
                subtitle: const Text('Pásense el teléfono por turnos'),
                onTap: () {
                  Navigator.pop(context);
                  _startLocalGame(type);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startLocalGame(String type) {
    if (type == 'quiz') _startTrivia();
    if (type == 'truth_dare') _startTruthOrDare();
    if (type == 'memorama') _startMemorama();
    if (type == 'tictactoe') _startTicTacToe();
    if (type == 'rps') _startRPS();
    if (type == 'hangman') _startHangman();
    if (type == 'dice') Navigator.push(context, MaterialPageRoute(builder: (_) => const NewGameScreen(gameType: 'dice')));
    if (type == 'cards') Navigator.push(context, MaterialPageRoute(builder: (_) => const NewGameScreen(gameType: 'cards')));
    if (type == 'prefer') Navigator.push(context, MaterialPageRoute(builder: (_) => const NewGameScreen(gameType: 'prefer')));
    if (type == 'roulette') Navigator.push(context, MaterialPageRoute(builder: (_) => const NewGameScreen(gameType: 'roulette')));
    if (type == 'never') Navigator.push(context, MaterialPageRoute(builder: (_) => const NewGameScreen(gameType: 'never')));
  }

  String _getGameLabel(String type) {
    switch (type) {
      case 'quiz': return 'Quiz';
      case 'truth_dare': return 'Verdad o Reto';
      case 'memorama': return 'Memorama';
      case 'tictactoe': return 'Tres en Raya';
      case 'rps': return 'Piedra Papel Tijera';
      case 'hangman': return 'Ahorcado';
      case 'dice': return 'Dados del Amor';
      case 'cards': return 'Carta Mayor';
      case 'prefer': return 'Que Prefieres?';
      case 'roulette': return 'Ruleta del Amor';
      case 'never': return 'Yo Nunca Nunca';
      default: return type;
    }
  }

  void _playGameOnline(String type, String gameId) {
    if (type == 'quiz') {
      _startTriviaOnline(gameId);
    } else if (type == 'truth_dare') {
      _startTruthOrDareOnline(gameId);
    } else if (type == 'tictactoe') {
      _startTicTacToeOnline(gameId);
    } else if (type == 'rps') {
      _startRPSOnline(gameId);
    } else if (type == 'hangman') {
      _startHangmanOnline(gameId);
    } else if (type == 'memorama') {
      _startMemoramaOnline(gameId);
    } else if (type == 'dice') {
      _showNewGameOnline('dice', gameId);
    } else if (type == 'cards') {
      _showNewGameOnline('cards', gameId);
    } else if (type == 'prefer') {
      _showNewGameOnline('prefer', gameId);
    } else if (type == 'roulette') {
      _showNewGameOnline('roulette', gameId);
    } else if (type == 'never') {
      _showNewGameOnline('never', gameId);
    }
  }

  void _showNewGameOnline(String type, String gameId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${_getGameLabel(type)} - Online', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_rounded, size: 48, color: Colors.green),
          const SizedBox(height: 12),
          const Text('Invitacion enviada! Ambos abran este juego en su telefono.'),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 300, child: NewGameScreen(gameType: type)),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); FirebaseService().deleteGameSession(gameId); }, child: const Text('Terminar')),
        ],
      ),
    );
  }

  // ──────── ONLINE GAME SYNC LOGIC ────────

  void _startTriviaOnline(String gameId) {
    int q = 0, score = 0;
    final questions = [
      {'q': '¿Dónde fue nuestra primera cita oficial?', 'o': ['Restaurante italiano', 'El cine', 'Un café acogedor', 'Un parque'], 'a': 2},
      {'q': '¿Quién dijo "te amo" primero?', 'o': ['Yo', 'Mi pareja', 'Ambos', 'Nadie'], 'a': 0},
      {'q': '¿Cuál es nuestra comida favorita?', 'o': ['Pizza', 'Sushi', 'Hamburguesas', 'Tacos'], 'a': 0},
      {'q': '¿Qué hacemos en un día lluvioso?', 'o': ['Ver películas', 'Dormir', 'Cocinar', 'Juegos'], 'a': 0},
    ];

    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

    _showOnlineGameDialog(
      title: 'Quiz de la Relación (Online)',
      gameId: gameId,
      builder: (ctx, doc, setState) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final sender = data['sender'] as String? ?? '';
        final isSender = myName == sender;
        final myScoreField = isSender ? 'senderScore' : 'receiverScore';
        final partnerScoreField = isSender ? 'receiverScore' : 'senderScore';

        final hasFinished = data[myScoreField] != null;
        final partnerFinished = data[partnerScoreField] != null;

        if (hasFinished) {
          final myFinalScore = data[myScoreField] as int;
          final partnerFinalScore = partnerFinished ? data[partnerScoreField] as int : null;

          return Column(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 56),
              const SizedBox(height: 12),
              Text('Tu puntuación: $myFinalScore / ${questions.length}', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                partnerFinished 
                    ? 'Puntuación de $partnerName: $partnerFinalScore / ${questions.length}'
                    : 'Esperando a que $partnerName termine de jugar...',
                style: TextStyle(color: ctx.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              if (partnerFinished)
                Text(
                  myFinalScore == partnerFinalScore 
                      ? '¡Empate! Se conocen igual de bien ❤️' 
                      : (myFinalScore > partnerFinalScore! ? '¡Ganaste! Conoces mejor la relación 🌟' : '¡$partnerName ganó! 🌟'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
            ],
          );
        }

        final qu = questions[q];
        return Column(
          children: [
            LinearProgressIndicator(value: (q + 1) / questions.length),
            const SizedBox(height: 20),
            Text('Pregunta ${q + 1} de ${questions.length}',
              style: TextStyle(fontSize: 12, color: ctx.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            Text(qu['q'] as String, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ctx.onSurface)),
            const SizedBox(height: 20),
            ...(qu['o'] as List<String>).asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AnswerButton(
                label: e.value,
                onTap: () {
                  if (e.key == qu['a']) score++;
                  if (q < questions.length - 1) {
                    setState(() => q++);
                  } else {
                    FirebaseService().updateGameSession(gameId, {myScoreField: score});
                  }
                },
                ctx: ctx,
              ),
            )),
          ],
        );
      },
    );
  }

  void _startTruthOrDareOnline(String gameId) {
    bool isGenerating = false;

    _showOnlineGameDialog(
      title: 'Verdad o Reto (Online)',
      gameId: gameId,
      builder: (ctx, doc, setDialogState) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final prompt = data['selectedPrompt'] as String? ?? 'Toca un botón para empezar';
        final category = data['selectedCategory'] as String? ?? 'Divertido';
        final photoUrl = data['photoProofUrl'] as String? ?? '';
        final photoStatus = data['photoStatus'] as String? ?? '';
        final challenger = data['challenger'] as String? ?? '';
        final selectedType = data['selectedType'] as String? ?? '';

        final myName = LocalStorage().getUserName() ?? 'Yo';
        final isChallenger = myName == challenger;

        Future<void> fetchPrompt(String type) async {
          setDialogState(() => isGenerating = true);
          try {
            final newPrompt = await AIService().generateTruthOrDare(type: type, category: category);
            await FirebaseService().updateGameSession(gameId, {
              'selectedPrompt': newPrompt,
              'selectedType': type,
              'challenger': myName,
              'photoProofUrl': '',
              'photoStatus': '',
            });
          } catch (_) {}
          setDialogState(() => isGenerating = false);
        }

        return Column(
          children: [
            // Vibe Category selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Divertido', 'Romántico', 'Atrevido'].map((cat) {
                final isSel = category == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : ctx.onSurface)),
                    selected: isSel,
                    selectedColor: ctx.primary,
                    onSelected: (selected) {
                      if (selected) {
                        FirebaseService().updateGameSession(gameId, {'selectedCategory': cat});
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Prompt card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ctx.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isGenerating
                  ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()))
                  : Text(prompt, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: ctx.onSurface, height: 1.4)),
            ),
            const SizedBox(height: 16),

            // Verdad / Reto actions
            Row(
              children: [
                Expanded(child: _GameButton(
                  label: 'Verdad', icon: Icons.face_rounded,
                  color: const Color(0xFF7C83FF), onTap: () => fetchPrompt('Verdad'), ctx: ctx,
                )),
                const SizedBox(width: 12),
                Expanded(child: _GameButton(
                  label: 'Reto', icon: Icons.whatshot_rounded,
                  color: const Color(0xFFFF5C8A), onTap: () => fetchPrompt('Reto'), ctx: ctx,
                )),
              ],
            ),

            // Photo verification section
            if (selectedType == 'Reto' && prompt != 'Toca un botón para empezar') ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                'Prueba del Reto',
                style: TextStyle(fontWeight: FontWeight.bold, color: ctx.primary, fontSize: 14),
              ),
              const SizedBox(height: 10),
              if (photoUrl.isEmpty) ...[
                if (isChallenger)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                      if (image == null) return;
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subiendo foto de prueba... 📸')),
                      );
                      final url = await StorageService().uploadPhoto(image.path);
                      if (!mounted) return;
                      if (url != null) {
                        await FirebaseService().updateGameSession(gameId, {
                          'photoProofUrl': url,
                          'photoStatus': 'pending',
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Error al subir la foto. Revisa tus reglas de Firebase Storage.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: const Text('Subir Foto de Prueba'),
                  )
                else
                  Text(
                    'Esperando que tu pareja suba la foto del reto...',
                    style: TextStyle(fontStyle: FontStyle.italic, color: ctx.onSurface.withValues(alpha: 0.5), fontSize: 12),
                  ),
              ] else ...[
                // Photo is uploaded
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      FirestoreImage(path: photoUrl, height: 180, width: 180, borderRadius: 8, fit: BoxFit.cover),
                      const SizedBox(height: 6),
                      Text('Prueba de $challenger 📸', 
                          style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (photoStatus == 'pending') ...[
                  if (!isChallenger) ...[
                    Text('¿Aprobar el reto de tu pareja?', style: TextStyle(fontWeight: FontWeight.bold, color: ctx.onSurface, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            FirebaseService().updateGameSession(gameId, {'photoStatus': 'approved'});
                          },
                          icon: const Icon(Icons.check_rounded, color: Colors.white),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            FirebaseService().updateGameSession(gameId, {'photoStatus': 'rejected'});
                          },
                          icon: const Icon(Icons.close_rounded, color: Colors.red),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Esperando aprobación de tu pareja...',
                      style: TextStyle(fontStyle: FontStyle.italic, color: ctx.primary, fontSize: 12),
                    ),
                  ],
                ] else if (photoStatus == 'approved') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text('¡Reto Completado con Éxito! 🎉', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ] else if (photoStatus == 'rejected') ...[
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          const Text('Reto Rechazado 👎', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      if (isChallenger) ...[
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                            if (image == null) return;
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Subiendo nueva foto... 📸')),
                            );
                            final url = await StorageService().uploadPhoto(image.path);
                            if (!mounted) return;
                            if (url != null) {
                              await FirebaseService().updateGameSession(gameId, {
                                'photoProofUrl': url,
                                'photoStatus': 'pending',
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Error al subir la foto. Revisa tus reglas de Firebase Storage.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Volver a Intentar / Subir Foto'),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ],
          ],
        );
      },
    );
  }

  void _startMemoramaOnline(String gameId) {
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

    _showOnlineGameDialog(
      title: 'Memorama (Online)',
      gameId: gameId,
      builder: (ctx, doc, setState) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final sender = data['sender'] as String? ?? '';
        final isSender = myName == sender;
        final myMovesField = isSender ? 'senderMoves' : 'receiverMoves';
        final partnerMovesField = isSender ? 'receiverMoves' : 'senderMoves';

        final hasFinished = data[myMovesField] != null;
        final partnerFinished = data[partnerMovesField] != null;

        if (hasFinished) {
          final myFinalMoves = data[myMovesField] as int;
          final partnerFinalMoves = partnerFinished ? data[partnerMovesField] as int : null;

          return Column(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 56),
              const SizedBox(height: 12),
              Text('Tus movimientos: $myFinalMoves', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                partnerFinished 
                    ? 'Movimientos de $partnerName: $partnerFinalMoves'
                    : 'Esperando a que $partnerName termine de jugar...',
                style: TextStyle(color: ctx.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              if (partnerFinished)
                Text(
                  myFinalMoves == partnerFinalMoves 
                      ? '¡Empate de velocidad! 🧠' 
                      : (myFinalMoves < partnerFinalMoves! ? '¡Ganaste! Resolviste en menos movimientos 🌟' : '¡$partnerName ganó! 🌟'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
            ],
          );
        }

        List<String> items = ['\u2764\uFE0F', '\u{1F48D}', '\u{1F338}', '\u{1F36B}', '\u{1F9F8}', '\u{1F377}',
                               '\u2764\uFE0F', '\u{1F48D}', '\u{1F338}', '\u{1F36B}', '\u{1F9F8}', '\u{1F377}'];
        final seed = gameId.hashCode;
        items.shuffle(Random(seed));

        return _MemoramaLocalGame(
          items: items,
          onComplete: (moves) {
            FirebaseService().updateGameSession(gameId, {myMovesField: moves});
          },
          ctx: ctx,
        );
      },
    );
  }

  void _startTicTacToeOnline(String gameId) {
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

    _showOnlineGameDialog(
      title: 'Tres en Raya (Online)',
      gameId: gameId,
      builder: (ctx, doc, setState) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final sender = data['sender'] as String? ?? '';
        final receiver = data['receiver'] as String? ?? '';
        final isSender = myName == sender;
        final mySymbol = isSender ? 'X' : 'O';
        final partnerSymbol = isSender ? 'O' : 'X';

        final rawBoard = data['board'] as List<dynamic>?;
        final List<String> board = rawBoard != null ? List<String>.from(rawBoard) : List.filled(9, '');
        final turn = data['turn'] as String? ?? sender;
        final winner = data['winner'] as String? ?? '';

        final isMyTurn = turn == myName;

        return Column(
          children: [
            Text(
              winner.isEmpty
                  ? (isMyTurn ? '🌟 ¡Tu Turno! ($mySymbol)' : 'Esperando a $partnerName ($partnerSymbol)...')
                  : (winner == 'Empate' ? '¡Empate!' : '¡Ganador: $winner! 🎉'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 240, height: 240,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: 9,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    if (!isMyTurn || board[i].isNotEmpty || winner.isNotEmpty) return;
                    HapticFeedback.lightImpact();
                    board[i] = mySymbol;
                    
                    String nextWinner = '';
                    if (_tttWinner(board, mySymbol)) {
                      nextWinner = myName;
                      ConfettiOverlay.of(context)?.burst();
                    } else if (!board.contains('')) {
                      nextWinner = 'Empate';
                    }

                    FirebaseService().updateGameSession(gameId, {
                      'board': board,
                      'turn': isSender ? receiver : sender,
                      'winner': nextWinner,
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: ctx.primary.withValues(alpha: 0.2))),
                    child: Center(
                      child: Text(
                        board[i],
                        style: TextStyle(
                          fontSize: 36, 
                          fontWeight: FontWeight.bold,
                          color: board[i] == 'X' ? const Color(0xFFFF5C8A) : const Color(0xFFA78BFA),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (winner.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  FirebaseService().updateGameSession(gameId, {
                    'board': List.filled(9, ''),
                    'turn': sender,
                    'winner': '',
                  });
                },
                child: const Text('Reiniciar Partida'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _startRPSOnline(String gameId) {
    final myName = LocalStorage().getUserName() ?? 'Yo';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';
    final choices = ['Piedra', 'Papel', 'Tijera'];
    final icons = {'Piedra': Icons.circle_outlined, 'Papel': Icons.description_outlined, 'Tijera': Icons.content_cut_outlined};

    _showOnlineGameDialog(
      title: 'Piedra Papel o Tijera (Online)',
      gameId: gameId,
      builder: (ctx, doc, setState) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final sender = data['sender'] as String? ?? '';
        final isSender = myName == sender;

        final myChoiceField = isSender ? 'senderChoice' : 'receiverChoice';
        final partnerChoiceField = isSender ? 'receiverChoice' : 'senderChoice';

        final myChoice = data[myChoiceField] as String? ?? '';
        final partnerChoice = data[partnerChoiceField] as String? ?? '';

        final bothChosen = myChoice.isNotEmpty && partnerChoice.isNotEmpty;

        String result = 'Elige tu jugada';
        if (myChoice.isNotEmpty && partnerChoice.isEmpty) {
          result = 'Esperando a $partnerName...';
        } else if (bothChosen) {
          if (myChoice == partnerChoice) {
            result = '¡Empate!';
          } else if ((myChoice == 'Piedra' && partnerChoice == 'Tijera') ||
                     (myChoice == 'Papel' && partnerChoice == 'Piedra') ||
                     (myChoice == 'Tijera' && partnerChoice == 'Papel')) {
            result = '¡Ganaste! 🎉';
            ConfettiOverlay.of(context)?.burst();
          } else {
            result = 'Perdiste 😢';
          }
        }

        return Column(
          children: [
            Text(result, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ctx.primary)),
            if (bothChosen) ...[
              const SizedBox(height: 8),
              Text('Tú: $myChoice  vs  $partnerName: $partnerChoice',
                style: TextStyle(fontSize: 15, color: ctx.onSurface)),
            ],
            const SizedBox(height: 24),
            if (myChoice.isEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: choices.map((c) => GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    FirebaseService().updateGameSession(gameId, {myChoiceField: c});
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ctx.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icons[c]!, size: 36, color: ctx.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(c, style: TextStyle(fontSize: 12, color: ctx.onSurface)),
                    ],
                  ),
                )).toList(),
              )
            else if (!bothChosen)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (bothChosen) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  FirebaseService().updateGameSession(gameId, {
                    'senderChoice': '',
                    'receiverChoice': '',
                  });
                },
                child: const Text('Jugar de nuevo'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _startHangmanOnline(String gameId) {
    final words = ['TEAMO', 'ANIVERSARIO', 'COMPROMISO', 'ABRAZO', 'DULCE', 'SIEMPRE'];

    _showOnlineGameDialog(
      title: 'Ahorcado (Online)',
      gameId: gameId,
      builder: (ctx, doc, setState) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        String secret = data['secretWord'] as String? ?? '';
        final rawGuessed = data['guessedLetters'] as List<dynamic>?;
        final guessed = rawGuessed != null ? List<String>.from(rawGuessed) : <String>[];
        int wrong = data['wrongCount'] as int? ?? 0;

        if (secret.isEmpty) {
          secret = words[Random().nextInt(words.length)];
          FirebaseService().updateGameSession(gameId, {
            'secretWord': secret,
            'guessedLetters': <String>[],
            'wrongCount': 0,
          });
          return const Center(child: CircularProgressIndicator());
        }

        final display = secret.split('').map((c) => guessed.contains(c) ? '$c ' : '_ ').join('');
        final won = !display.contains('_');
        final lost = wrong >= 6;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(i < (6 - wrong) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: const Color(0xFFFF5C8A), size: 22),
              )),
            ),
            const SizedBox(height: 20),
            Text(display, style: TextStyle(fontSize: 26, letterSpacing: 6, fontWeight: FontWeight.bold, color: ctx.onSurface)),
            const SizedBox(height: 20),
            if (won) ...[
              const Text('¡Salvaron la palabra! 🎉', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final newSecret = words[Random().nextInt(words.length)];
                  FirebaseService().updateGameSession(gameId, {
                    'secretWord': newSecret,
                    'guessedLetters': <String>[],
                    'wrongCount': 0,
                  });
                },
                child: const Text('Jugar otra palabra'),
              ),
            ] else if (lost) ...[
              Text('Era: $secret 😢', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final newSecret = words[Random().nextInt(words.length)];
                  FirebaseService().updateGameSession(gameId, {
                    'secretWord': newSecret,
                    'guessedLetters': <String>[],
                    'wrongCount': 0,
                  });
                },
                child: const Text('Intentar de nuevo'),
              ),
            ] else
              Wrap(
                spacing: 6, runSpacing: 6,
                children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                  final used = guessed.contains(letter);
                  return SizedBox(
                    width: 36, height: 36,
                    child: ElevatedButton(
                      onPressed: used ? null : () {
                        HapticFeedback.lightImpact();
                        guessed.add(letter);
                        final isCorrect = secret.contains(letter);
                        final nextWrong = isCorrect ? wrong : wrong + 1;
                        
                        FirebaseService().updateGameSession(gameId, {
                          'guessedLetters': guessed,
                          'wrongCount': nextWrong,
                        });
                        
                        if (secret.split('').every((c) => guessed.contains(letter) || guessed.contains(c))) {
                          ConfettiOverlay.of(context)?.burst();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: const Size(36, 36),
                        backgroundColor: used ? ctx.onSurface.withValues(alpha: 0.1) : ctx.primary,
                        foregroundColor: used ? ctx.onSurface.withValues(alpha: 0.3) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(letter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  void _showOnlineGameDialog({
    required String title,
    required String gameId,
    required Widget Function(ColorScheme cs, DocumentSnapshot doc, void Function(VoidCallback fn) setState) builder,
  }) {
    bool isDialogActive = true;
    showDialog(
      context: context,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        final myCoupleId = FirebaseService().coupleId;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('couples')
                  .doc(myCoupleId)
                  .collection('games')
                  .doc(gameId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AlertDialog(
                    title: const Text('Error de Conexión'),
                    content: const Text('No se pudo establecer la conexión con la partida en tiempo real. Inténtalo de nuevo.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return AlertDialog(
                    content: const SizedBox(
                      height: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Conectando a la partida...', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  );
                }
                
                final doc = snapshot.data!;
                if (!doc.exists) {
                  if (isDialogActive) {
                    isDialogActive = false;
                    Future.microtask(() {
                      if (ctx.mounted) Navigator.pop(ctx);
                    });
                  }
                  return const SizedBox();
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: builder(cs, doc, setState),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx), 
                      child: Text('Cerrar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).then((_) {
      isDialogActive = false;
    });
  }

  // ──────── LOCAL GAME LOGIC ────────

  void _startTrivia() {
    int q = 0, score = 0;
    final questions = [
      {'q': '¿Dónde fue nuestra primera cita oficial?', 'o': ['Restaurante italiano', 'El cine', 'Un café acogedor', 'Un parque'], 'a': 2},
      {'q': '¿Quién dijo "te amo" primero?', 'o': ['Yo', 'Mi pareja', 'Ambos', 'Nadie'], 'a': 0},
      {'q': '¿Cuál es nuestra comida favorita?', 'o': ['Pizza', 'Sushi', 'Hamburguesas', 'Tacos'], 'a': 0},
      {'q': '¿Qué hacemos en un día lluvioso?', 'o': ['Ver películas', 'Dormir', 'Cocinar', 'Juegos'], 'a': 0},
    ];

    _showGameDialog(
      title: 'Quiz de la Relación',
      builder: (ctx, setState) {
        final qu = questions[q];
        return Column(
          children: [
            LinearProgressIndicator(value: (q + 1) / questions.length),
            const SizedBox(height: 20),
            Text('Pregunta ${q + 1} de ${questions.length}',
              style: TextStyle(fontSize: 12, color: ctx.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            Text(qu['q'] as String, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ctx.onSurface)),
            const SizedBox(height: 20),
            ...(qu['o'] as List<String>).asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AnswerButton(
                label: e.value,
                onTap: () {
                  if (e.key == qu['a']) score++;
                  if (q < questions.length - 1) {
                    setState(() => q++);
                  } else {
                    Navigator.pop(context);
                    _showResult(score, questions.length, 'Quiz');
                  }
                },
                ctx: ctx,
              ),
            )),
          ],
        );
      },
      cs: Theme.of(context).colorScheme,
    );
  }

  void _startTruthOrDare() {
    final truths = [
      "¿Qué fue lo primero que te atrajo de mí?",
      "¿Cuál ha sido el momento más conectado que has sentido?",
      "Si pudieras cambiar un hábito mío, ¿cuál sería?",
      "¿Qué canción te recuerda a nosotros?",
      "¿Cuál ha sido la mentira más piadosa que me has dicho?",
    ];
    final dares = [
      "Dame un beso de 10 segundos.",
      "Cántame una canción de amor mirándome a los ojos.",
      "Hazme un masaje de hombros por 2 minutos.",
      "Susúrrame al oído 3 cosas que te gustan de mí.",
      "Imita cómo hablo o actúo.",
    ];

    String result = 'Toca un botón para empezar';

    _showGameDialog(
      title: 'Verdad o Reto',
      builder: (ctx, setState) => Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ctx.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(result, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: ctx.onSurface, height: 1.4)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _GameButton(
                label: 'Verdad', icon: Icons.face_rounded,
                color: const Color(0xFF7C83FF), onTap: () {
                  setState(() { result = truths[Random().nextInt(truths.length)]; });
                }, ctx: ctx,
              )),
              const SizedBox(width: 12),
              Expanded(child: _GameButton(
                label: 'Reto', icon: Icons.whatshot_rounded,
                color: const Color(0xFFFF5C8A), onTap: () {
                  setState(() { result = dares[Random().nextInt(dares.length)]; });
                }, ctx: ctx,
              )),
            ],
          ),
        ],
      ),
      cs: Theme.of(context).colorScheme,
    );
  }

  void _startMemorama() {
    List<String> items = ['\u2764\uFE0F', '\u{1F48D}', '\u{1F338}', '\u{1F36B}', '\u{1F9F8}', '\u{1F377}',
                           '\u2764\uFE0F', '\u{1F48D}', '\u{1F338}', '\u{1F36B}', '\u{1F9F8}', '\u{1F377}'];
    items.shuffle();
    List<bool> flips = List.filled(12, false);
    List<int> sel = [];
    int matches = 0;

    _showGameDialog(
      title: 'Memorama',
      builder: (ctx, setState) => SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (_, i) {
            final flipped = flips[i];
            return GestureDetector(
              onTap: () {
                if (flipped || sel.length >= 2) return;
                setState(() { flips[i] = true; sel.add(i); });
                if (sel.length == 2) {
                  final a = sel[0], b = sel[1];
                  if (items[a] == items[b]) {
                    matches++;
                    sel.clear();
                    if (matches == 6) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ConfettiOverlay.of(context)?.burst();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Memorama completado!')),
                        );
                      });
                    }
                  } else {
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() { flips[a] = false; flips[b] = false; sel.clear(); });
                      }
                    });
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: flipped ? ctx.primary.withValues(alpha: 0.1) : ctx.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(flipped ? items[i] : '?',
                    style: TextStyle(fontSize: 28, color: flipped ? ctx.onSurface : Colors.white)),
                ),
              ),
            );
          },
        ),
      ),
      cs: Theme.of(context).colorScheme,
    );
  }

  void _startTicTacToe() {
    List<String> board = List.filled(9, '');
    String turn = 'X';
    String winner = '';

    _showGameDialog(
      title: 'Tres en Raya',
      builder: (ctx, setState) => Column(
        children: [
          Text(winner.isEmpty ? 'Turno de $turn' : 'Ganador: $winner',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ctx.onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            width: 240, height: 240,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
              itemCount: 9,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  if (board[i].isNotEmpty || winner.isNotEmpty) return;
                  setState(() {
                    board[i] = turn;
                    if (_tttWinner(board, turn)) {
                      winner = turn;
                      ConfettiOverlay.of(context)?.burst();
                    } else if (!board.contains('')) {
                      winner = 'Empate';
                    } else {
                      turn = turn == 'X' ? 'O' : 'X';
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: ctx.primary.withValues(alpha: 0.2))),
                  child: Center(
                    child: Text(board[i],
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                        color: board[i] == 'X' ? const Color(0xFFFF5C8A) : const Color(0xFFA78BFA))),
                  ),
                ),
              ),
            ),
          ),
          if (winner.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => setState(() { board = List.filled(9, ''); turn = 'X'; winner = ''; }),
              child: const Text('Reiniciar')),
          ],
        ],
      ),
      cs: Theme.of(context).colorScheme,
    );
  }

  bool _tttWinner(List<String> b, String p) {
    return (b[0] == p && b[1] == p && b[2] == p) || (b[3] == p && b[4] == p && b[5] == p) ||
           (b[6] == p && b[7] == p && b[8] == p) || (b[0] == p && b[3] == p && b[6] == p) ||
           (b[1] == p && b[4] == p && b[7] == p) || (b[2] == p && b[5] == p && b[8] == p) ||
           (b[0] == p && b[4] == p && b[8] == p) || (b[2] == p && b[4] == p && b[6] == p);
  }

  void _startRPS() {
    String player = '', ai = '', result = 'Elige';
    final choices = ['Piedra', 'Papel', 'Tijera'];
    final icons = {'Piedra': Icons.circle_outlined, 'Papel': Icons.description_outlined, 'Tijera': Icons.content_cut_outlined};

    _showGameDialog(
      title: 'Piedra Papel o Tijera',
      builder: (ctx, setState) => Column(
        children: [
          Text(result, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ctx.primary)),
          if (player.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Tú: $player  vs  Pareja: $ai',
              style: TextStyle(fontSize: 15, color: ctx.onSurface)),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: choices.map((c) => GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                final a = choices[Random().nextInt(3)];
                setState(() {
                  player = c; ai = a;
                  if (c == a) {
                    result = '¡Empate!';
                  } else if ((c == 'Piedra' && a == 'Tijera') || (c == 'Papel' && a == 'Piedra') || (c == 'Tijera' && a == 'Papel')) {
                    result = '¡Ganaste!';
                    ConfettiOverlay.of(context)?.burst();
                  } else {
                    result = 'Perdiste';
                  }
                });
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ctx.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icons[c]!, size: 36, color: ctx.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(c, style: TextStyle(fontSize: 12, color: ctx.onSurface)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
      cs: Theme.of(context).colorScheme,
    );
  }

  void _startHangman() {
    final words = ['TEAMO', 'ANIVERSARIO', 'COMPROMISO', 'ABRAZO', 'DULCE', 'SIEMPRE'];
    final secret = words[Random().nextInt(words.length)];
    List<String> guessed = [];
    int wrong = 0;

    _showGameDialog(
      title: 'Ahorcado',
      builder: (ctx, setState) {
        final display = secret.split('').map((c) => guessed.contains(c) ? '$c ' : '_ ').join('');
        final won = !display.contains('_');
        final lost = wrong >= 6;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(i < (6 - wrong) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: const Color(0xFFFF5C8A), size: 22),
              )),
            ),
            const SizedBox(height: 20),
            Text(display, style: TextStyle(fontSize: 26, letterSpacing: 6, fontWeight: FontWeight.bold, color: ctx.onSurface)),
            const SizedBox(height: 20),
            if (won)
              const Text('¡Salvaste la palabra!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))
            else if (lost)
              Text('Era: $secret', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))
            else
              Wrap(
                spacing: 6, runSpacing: 6,
                children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                  final used = guessed.contains(letter);
                  return SizedBox(
                    width: 36, height: 36,
                    child: ElevatedButton(
                      onPressed: used ? null : () {
                        HapticFeedback.lightImpact();
                        setState(() { guessed.add(letter); if (!secret.contains(letter)) wrong++; });
                        if (secret.split('').every((c) => guessed.contains(c))) ConfettiOverlay.of(context)?.burst();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: const Size(36, 36),
                        backgroundColor: used ? ctx.onSurface.withValues(alpha: 0.1) : ctx.primary,
                        foregroundColor: used ? ctx.onSurface.withValues(alpha: 0.3) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(letter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
      cs: Theme.of(context).colorScheme,
    );
  }

  void _showResult(int score, int total, String game) {
    if (score == total) ConfettiOverlay.of(context)?.burst();
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(score == total ? Icons.emoji_events_rounded : Icons.favorite_rounded,
              color: score == total ? Colors.amber : cs.primary, size: 56),
            const SizedBox(height: 12),
            Text('$score / $total', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(score == total ? 'Perfecto! Conoces a tu pareja!' : 'Sigue intentando!',
              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      ),
    );
  }

  void _showGameDialog({
    required String title,
    required Widget Function(ColorScheme ctx, void Function(VoidCallback fn) setState) builder,
    required ColorScheme cs,
  }) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.favorite_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          content: SingleChildScrollView(child: builder(cs, setState)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cerrar', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)))),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final IconData icon;
  final String name, desc;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _GameCard({required this.icon, required this.name, required this.desc, required this.gradient, required this.onTap, required this.cs});

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: 1 - (0.04 * _ctrl.value), child: child),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: widget.gradient,
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors[0].withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(widget.desc,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                      maxLines: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme ctx;

  const _AnswerButton({required this.label, required this.onTap, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          side: BorderSide(color: ctx.primary.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, color: ctx.onSurface)),
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ColorScheme ctx;

  const _GameButton({required this.label, required this.icon, required this.color, required this.onTap, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _MemoramaLocalGame extends StatefulWidget {
  final List<String> items;
  final Function(int moves) onComplete;
  final ColorScheme ctx;

  const _MemoramaLocalGame({required this.items, required this.onComplete, required this.ctx});

  @override
  State<_MemoramaLocalGame> createState() => _MemoramaLocalGameState();
}

class _MemoramaLocalGameState extends State<_MemoramaLocalGame> {
  late List<bool> flips;
  List<int> sel = [];
  int matches = 0;
  int moves = 0;

  @override
  void initState() {
    super.initState();
    flips = List.filled(12, false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Movimientos: $moves', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final flipped = flips[i];
              return GestureDetector(
                onTap: () {
                  if (flipped || sel.length >= 2) return;
                  setState(() { flips[i] = true; sel.add(i); });
                  if (sel.length == 2) {
                    moves++;
                    final a = sel[0], b = sel[1];
                    if (widget.items[a] == widget.items[b]) {
                      matches++;
                      sel.clear();
                      if (matches == 6) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          widget.onComplete(moves);
                        });
                      }
                    } else {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() { flips[a] = false; flips[b] = false; sel.clear(); });
                        }
                      });
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: flipped ? widget.ctx.primary.withValues(alpha: 0.1) : widget.ctx.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(flipped ? widget.items[i] : '?',
                      style: TextStyle(fontSize: 28, color: flipped ? widget.ctx.onSurface : Colors.white)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
