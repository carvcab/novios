import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDateTime(dynamic timestamp) {
    DateTime? dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp);
    }
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _getGameLabel(String type) {
    switch (type) {
      case 'quiz': return 'Quiz';
      case 'truth_dare': return 'Verdad o Reto';
      case 'memorama': return 'Memorama';
      case 'tictactoe': return 'Tres en Raya';
      case 'rps': return 'Piedra Papel o Tijera';
      case 'hangman': return 'Ahorcado';
      case 'Verdad': return 'Verdad Picante';
      case 'Reto': return 'Reto Picante';
      case 'foto': return 'Foto Reto';
      default: return 'Juego';
    }
  }

  IconData _getGameIcon(String type) {
    switch (type) {
      case 'quiz': return Icons.quiz_rounded;
      case 'truth_dare': return Icons.favorite_rounded;
      case 'memorama': return Icons.extension_rounded;
      case 'tictactoe': return Icons.grid_3x3_rounded;
      case 'rps': return Icons.front_hand_rounded;
      case 'hangman': return Icons.help_outline_rounded;
      case 'Verdad': return Icons.face_rounded;
      case 'Reto': return Icons.whatshot_rounded;
      case 'foto': return Icons.camera_alt_rounded;
      default: return Icons.sports_esports_rounded;
    }
  }

  LinearGradient _getGameGradient(String type) {
    switch (type) {
      case 'quiz':
        return const LinearGradient(colors: [Color(0xFFFF5C8A), Color(0xFFFF8AAB)]);
      case 'truth_dare':
        return const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFFC4B5FD)]);
      case 'memorama':
        return const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFFD54F)]);
      case 'tictactoe':
        return const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFFA5D6A7)]);
      case 'rps':
        return const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)]);
      case 'hangman':
        return const LinearGradient(colors: [Color(0xFFEF5350), Color(0xFFEF9A9A)]);
      case 'Verdad':
        return const LinearGradient(colors: [Color(0xFF7C83FF), Color(0xFF9CA3FF)]);
      case 'Reto':
      case 'foto':
        return const LinearGradient(colors: [Color(0xFFFF5C8A), Color(0xFFFF8AAB)]);
      default:
        return const LinearGradient(colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final myUid = LocalStorage().getUserId() ?? 'anon';
    final myName = LocalStorage().getUserName() ?? 'Tú';
    final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial y Estadísticas', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Estadísticas', icon: Icon(Icons.analytics_rounded)),
            Tab(text: 'Partidas', icon: Icon(Icons.history_rounded)),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService().streamAllGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final games = snapshot.data ?? [];
          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_esports_rounded, size: 64, color: cs.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay partidas registradas aún',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Empiecen a jugar para ver el historial!',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            );
          }

          // Calcular estadísticas
          int totalGamesCount = 0;
          int myTotalWins = 0;
          int partnerTotalWins = 0;
          int totalTies = 0;

          final ticTacToeStats = {'total': 0, 'myWins': 0, 'partnerWins': 0, 'ties': 0, 'active': 0};
          final quizStats = {'total': 0, 'myWins': 0, 'partnerWins': 0, 'ties': 0, 'active': 0};
          final memoramaStats = {'total': 0, 'myWins': 0, 'partnerWins': 0, 'ties': 0, 'active': 0};
          final rpsStats = {'total': 0, 'myWins': 0, 'partnerWins': 0, 'ties': 0, 'active': 0};
          final hangmanStats = {'total': 0, 'coopWins': 0, 'coopLosses': 0, 'active': 0};
          final truthOrDareStats = {'myTruths': 0, 'partnerTruths': 0, 'myDares': 0, 'partnerDares': 0};

          for (final game in games) {
            final gameType = game['gameType'] as String?;
            final spicyType = game['type'] as String?;
            final status = game['status'] as String? ?? 'pending';
            final sender = game['sender'] as String? ?? '';
            final senderId = game['senderId'] as String? ?? '';
            final winner = game['winner'] as String? ?? '';

            final isSender = myUid == senderId || myName == sender;

            if (gameType != null && gameType.isNotEmpty) {
              totalGamesCount++;
              // 1. TRES EN RAYA
              if (gameType == 'tictactoe') {
                if (winner.isEmpty) {
                  ticTacToeStats['active'] = (ticTacToeStats['active'] ?? 0) + 1;
                } else if (winner == 'Empate') {
                  ticTacToeStats['ties'] = (ticTacToeStats['ties'] ?? 0) + 1;
                  ticTacToeStats['total'] = (ticTacToeStats['total'] ?? 0) + 1;
                  totalTies++;
                } else {
                  ticTacToeStats['total'] = (ticTacToeStats['total'] ?? 0) + 1;
                  if (winner == myName || winner == 'Yo') {
                    ticTacToeStats['myWins'] = (ticTacToeStats['myWins'] ?? 0) + 1;
                    myTotalWins++;
                  } else {
                    ticTacToeStats['partnerWins'] = (ticTacToeStats['partnerWins'] ?? 0) + 1;
                    partnerTotalWins++;
                  }
                }
              }
              // 2. QUIZ
              else if (gameType == 'quiz') {
                final senderScore = game['senderScore'] as int?;
                final receiverScore = game['receiverScore'] as int?;
                if (senderScore != null && receiverScore != null) {
                  quizStats['total'] = (quizStats['total'] ?? 0) + 1;
                  final myScore = isSender ? senderScore : receiverScore;
                  final partnerScore = isSender ? receiverScore : senderScore;
                  if (myScore > partnerScore) {
                    quizStats['myWins'] = (quizStats['myWins'] ?? 0) + 1;
                    myTotalWins++;
                  } else if (partnerScore > myScore) {
                    quizStats['partnerWins'] = (quizStats['partnerWins'] ?? 0) + 1;
                    partnerTotalWins++;
                  } else {
                    quizStats['ties'] = (quizStats['ties'] ?? 0) + 1;
                    totalTies++;
                  }
                } else {
                  quizStats['active'] = (quizStats['active'] ?? 0) + 1;
                }
              }
              // 3. MEMORAMA
              else if (gameType == 'memorama') {
                final senderMoves = game['senderMoves'] as int?;
                final receiverMoves = game['receiverMoves'] as int?;
                if (senderMoves != null && receiverMoves != null) {
                  memoramaStats['total'] = (memoramaStats['total'] ?? 0) + 1;
                  final myMoves = isSender ? senderMoves : receiverMoves;
                  final partnerMoves = isSender ? receiverMoves : senderMoves;
                  if (myMoves < partnerMoves) {
                    memoramaStats['myWins'] = (memoramaStats['myWins'] ?? 0) + 1;
                    myTotalWins++;
                  } else if (partnerMoves < myMoves) {
                    memoramaStats['partnerWins'] = (memoramaStats['partnerWins'] ?? 0) + 1;
                    partnerTotalWins++;
                  } else {
                    memoramaStats['ties'] = (memoramaStats['ties'] ?? 0) + 1;
                    totalTies++;
                  }
                } else {
                  memoramaStats['active'] = (memoramaStats['active'] ?? 0) + 1;
                }
              }
              // 4. RPS
              else if (gameType == 'rps') {
                final senderChoice = game['senderChoice'] as String? ?? '';
                final receiverChoice = game['receiverChoice'] as String? ?? '';
                if (senderChoice.isNotEmpty && receiverChoice.isNotEmpty) {
                  rpsStats['total'] = (rpsStats['total'] ?? 0) + 1;
                  final myChoice = isSender ? senderChoice : receiverChoice;
                  final partnerChoice = isSender ? receiverChoice : senderChoice;
                  if (myChoice == partnerChoice) {
                    rpsStats['ties'] = (rpsStats['ties'] ?? 0) + 1;
                    totalTies++;
                  } else if ((myChoice == 'Piedra' && partnerChoice == 'Tijera') ||
                             (myChoice == 'Papel' && partnerChoice == 'Piedra') ||
                             (myChoice == 'Tijera' && partnerChoice == 'Papel')) {
                    rpsStats['myWins'] = (rpsStats['myWins'] ?? 0) + 1;
                    myTotalWins++;
                  } else {
                    rpsStats['partnerWins'] = (rpsStats['partnerWins'] ?? 0) + 1;
                    partnerTotalWins++;
                  }
                } else {
                  rpsStats['active'] = (rpsStats['active'] ?? 0) + 1;
                }
              }
              // 5. HANGMAN
              else if (gameType == 'hangman') {
                final secretWord = game['secretWord'] as String? ?? '';
                final wrongCount = game['wrongCount'] as int? ?? 0;
                final guessedLetters = List<String>.from(game['guessedLetters'] as List<dynamic>? ?? []);
                final display = secretWord.split('').map((c) => guessedLetters.contains(c) ? c : '_').join('');
                final won = secretWord.isNotEmpty && !display.contains('_');
                final lost = wrongCount >= 6;
                if (won) {
                  hangmanStats['coopWins'] = (hangmanStats['coopWins'] ?? 0) + 1;
                  hangmanStats['total'] = (hangmanStats['total'] ?? 0) + 1;
                } else if (lost) {
                  hangmanStats['coopLosses'] = (hangmanStats['coopLosses'] ?? 0) + 1;
                  hangmanStats['total'] = (hangmanStats['total'] ?? 0) + 1;
                } else {
                  hangmanStats['active'] = (hangmanStats['active'] ?? 0) + 1;
                }
              }
              // 6. ONLINE TRUTH OR DARE
              else if (gameType == 'truth_dare') {
                final photoStatus = game['photoStatus'] as String? ?? '';
                final challenger = game['challenger'] as String? ?? '';
                final selectedType = game['selectedType'] as String? ?? '';
                if (selectedType == 'Reto' && photoStatus == 'approved') {
                  if (challenger == myName) {
                    truthOrDareStats['partnerDares'] = (truthOrDareStats['partnerDares'] ?? 0) + 1;
                  } else {
                    truthOrDareStats['myDares'] = (truthOrDareStats['myDares'] ?? 0) + 1;
                  }
                }
              }
            } else if (spicyType != null && spicyType.isNotEmpty) {
              totalGamesCount++;
              // SPICY GAMES (Verdad / Reto / foto)
              final photoStatus = game['photoStatus'] as String? ?? '';
              final isResponded = status == 'responded' || photoStatus == 'approved';
              if (isResponded) {
                if (spicyType == 'Verdad') {
                  if (isSender) {
                    truthOrDareStats['partnerTruths'] = (truthOrDareStats['partnerTruths'] ?? 0) + 1;
                  } else {
                    truthOrDareStats['myTruths'] = (truthOrDareStats['myTruths'] ?? 0) + 1;
                  }
                } else if (spicyType == 'Reto' || spicyType == 'foto') {
                  if (isSender) {
                    truthOrDareStats['partnerDares'] = (truthOrDareStats['partnerDares'] ?? 0) + 1;
                  } else {
                    truthOrDareStats['myDares'] = (truthOrDareStats['myDares'] ?? 0) + 1;
                  }
                }
              }
            }
          }

          final myDaresCompleted = truthOrDareStats['myDares'] ?? 0;
          final partnerDaresCompleted = truthOrDareStats['partnerDares'] ?? 0;
          final myTruthsCompleted = truthOrDareStats['myTruths'] ?? 0;
          final partnerTruthsCompleted = truthOrDareStats['partnerTruths'] ?? 0;

          return TabBarView(
            controller: _tabController,
            children: [
              // ─────── TAB 1: ESTADÍSTICAS ───────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen general VS Card
                    _buildVSHeaderCard(
                      context: context,
                      cs: cs,
                      myName: myName,
                      partnerName: partnerName,
                      myWins: myTotalWins,
                      partnerWins: partnerTotalWins,
                      ties: totalTies,
                      total: totalGamesCount,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Rendimiento por Juego',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                    const SizedBox(height: 12),
                    // Grid de estadísticas por juego
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: [
                        _buildGameStatCard(
                          title: 'Tres en Raya',
                          type: 'tictactoe',
                          myWins: ticTacToeStats['myWins'] ?? 0,
                          partnerWins: ticTacToeStats['partnerWins'] ?? 0,
                          ties: ticTacToeStats['ties'] ?? 0,
                          active: ticTacToeStats['active'] ?? 0,
                          partnerName: partnerName,
                          cs: cs,
                        ),
                        _buildGameStatCard(
                          title: 'Quiz de Relación',
                          type: 'quiz',
                          myWins: quizStats['myWins'] ?? 0,
                          partnerWins: quizStats['partnerWins'] ?? 0,
                          ties: quizStats['ties'] ?? 0,
                          active: quizStats['active'] ?? 0,
                          partnerName: partnerName,
                          cs: cs,
                        ),
                        _buildGameStatCard(
                          title: 'Memorama',
                          type: 'memorama',
                          myWins: memoramaStats['myWins'] ?? 0,
                          partnerWins: memoramaStats['partnerWins'] ?? 0,
                          ties: memoramaStats['ties'] ?? 0,
                          active: memoramaStats['active'] ?? 0,
                          partnerName: partnerName,
                          cs: cs,
                        ),
                        _buildGameStatCard(
                          title: 'Piedra Papel Tijera',
                          type: 'rps',
                          myWins: rpsStats['myWins'] ?? 0,
                          partnerWins: rpsStats['partnerWins'] ?? 0,
                          ties: rpsStats['ties'] ?? 0,
                          active: rpsStats['active'] ?? 0,
                          partnerName: partnerName,
                          cs: cs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Coop & Challenges Cards
                    _buildCoopStatCard(
                      title: 'Ahorcado (Cooperativo)',
                      wins: hangmanStats['coopWins'] ?? 0,
                      losses: hangmanStats['coopLosses'] ?? 0,
                      active: hangmanStats['active'] ?? 0,
                      cs: cs,
                    ),
                    const SizedBox(height: 12),
                    _buildTruthDareStatCard(
                      title: 'Retos y Verdades',
                      myName: myName,
                      partnerName: partnerName,
                      myTruths: myTruthsCompleted,
                      partnerTruths: partnerTruthsCompleted,
                      myDares: myDaresCompleted,
                      partnerDares: partnerDaresCompleted,
                      cs: cs,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ─────── TAB 2: PARTIDAS (LISTADO) ───────
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  final gameType = game['gameType'] as String? ?? '';
                  final spicyType = game['type'] as String? ?? '';
                  final status = game['status'] as String? ?? 'pending';
                  final sender = game['sender'] as String? ?? game['senderName'] as String? ?? '';
                  final timestamp = game['timestamp'] ?? game['responseTimestamp'] ?? game['createdAt'];

                  final type = gameType.isNotEmpty ? gameType : spicyType;
                  final gameLabel = _getGameLabel(type);
                  final isSpicy = spicyType.isNotEmpty;

                  String outcomeText = '';
                  Color statusColor = Colors.grey;

                  if (gameType.isNotEmpty) {
                    // Multiplayer games
                    if (gameType == 'tictactoe') {
                      final winner = game['winner'] as String? ?? '';
                      if (winner.isEmpty) {
                        outcomeText = 'Partida en curso 🎮';
                        statusColor = cs.primary;
                      } else if (winner == 'Empate') {
                        outcomeText = 'Empate 🤝';
                        statusColor = Colors.orange;
                      } else {
                        outcomeText = 'Ganador: $winner 🏆';
                        statusColor = Colors.green;
                      }
                    } else if (gameType == 'quiz') {
                      final senderScore = game['senderScore'] as int?;
                      final receiverScore = game['receiverScore'] as int?;
                      if (senderScore != null && receiverScore != null) {
                        final isSenderMe = myName == sender;
                        final myScore = isSenderMe ? senderScore : receiverScore;
                        final partnerScore = isSenderMe ? receiverScore : senderScore;
                        if (myScore > partnerScore) {
                          outcomeText = 'Ganaste ($myScore - $partnerScore) 🌟';
                          statusColor = Colors.green;
                        } else if (partnerScore > myScore) {
                          outcomeText = 'Ganó $partnerName ($partnerScore - $myScore) 🏆';
                          statusColor = Colors.redAccent;
                        } else {
                          outcomeText = 'Empate ($myScore - $myScore) 🤝';
                          statusColor = Colors.orange;
                        }
                      } else {
                        outcomeText = 'Esperando puntuaciones ⌛';
                        statusColor = Colors.blue;
                      }
                    } else if (gameType == 'memorama') {
                      final senderMoves = game['senderMoves'] as int?;
                      final receiverMoves = game['receiverMoves'] as int?;
                      if (senderMoves != null && receiverMoves != null) {
                        final isSenderMe = myName == sender;
                        final myMoves = isSenderMe ? senderMoves : receiverMoves;
                        final partnerMoves = isSenderMe ? receiverMoves : senderMoves;
                        if (myMoves < partnerMoves) {
                          outcomeText = 'Ganaste ($myMoves vs $partnerMoves mov.) 🌟';
                          statusColor = Colors.green;
                        } else if (partnerMoves < myMoves) {
                          outcomeText = 'Ganó $partnerName ($partnerMoves vs $myMoves mov.) 🏆';
                          statusColor = Colors.redAccent;
                        } else {
                          outcomeText = 'Empate ($myMoves mov.) 🤝';
                          statusColor = Colors.orange;
                        }
                      } else {
                        outcomeText = 'Esperando resolución ⌛';
                        statusColor = Colors.blue;
                      }
                    } else if (gameType == 'rps') {
                      final senderChoice = game['senderChoice'] as String? ?? '';
                      final receiverChoice = game['receiverChoice'] as String? ?? '';
                      if (senderChoice.isNotEmpty && receiverChoice.isNotEmpty) {
                        final isSenderMe = myName == sender;
                        final myChoice = isSenderMe ? senderChoice : receiverChoice;
                        final partnerChoice = isSenderMe ? receiverChoice : senderChoice;
                        if (myChoice == partnerChoice) {
                          outcomeText = 'Empate ($myChoice) 🤝';
                          statusColor = Colors.orange;
                        } else if ((myChoice == 'Piedra' && partnerChoice == 'Tijera') ||
                                   (myChoice == 'Papel' && partnerChoice == 'Piedra') ||
                                   (myChoice == 'Tijera' && partnerChoice == 'Papel')) {
                          outcomeText = 'Ganaste con $myChoice 🌟';
                          statusColor = Colors.green;
                        } else {
                          outcomeText = 'Ganó $partnerName con $partnerChoice 🏆';
                          statusColor = Colors.redAccent;
                        }
                      } else {
                        outcomeText = 'Esperando jugadas ⌛';
                        statusColor = Colors.blue;
                      }
                    } else if (gameType == 'hangman') {
                      final secretWord = game['secretWord'] as String? ?? '';
                      final wrongCount = game['wrongCount'] as int? ?? 0;
                      final guessedLetters = List<String>.from(game['guessedLetters'] as List<dynamic>? ?? []);
                      final display = secretWord.split('').map((c) => guessedLetters.contains(c) ? c : '_').join('');
                      final won = secretWord.isNotEmpty && !display.contains('_');
                      final lost = wrongCount >= 6;

                      if (won) {
                        outcomeText = '¡Palabra salvada: $secretWord! 🎉';
                        statusColor = Colors.green;
                      } else if (lost) {
                        outcomeText = 'Ahorcados (Palabra: $secretWord) 😢';
                        statusColor = Colors.red;
                      } else {
                        outcomeText = 'Jugando... (Fallos: $wrongCount/6) 🎮';
                        statusColor = cs.primary;
                      }
                    } else if (gameType == 'truth_dare') {
                      final photoStatus = game['photoStatus'] as String? ?? '';
                      final challenger = game['challenger'] as String? ?? '';
                      final selectedType = game['selectedType'] as String? ?? '';
                      if (selectedType.isEmpty) {
                        outcomeText = 'Esperando elección ⌛';
                        statusColor = Colors.blue;
                      } else if (selectedType == 'Verdad') {
                        outcomeText = '$challenger eligió Verdad 💬';
                        statusColor = Colors.green;
                      } else {
                        if (photoStatus == 'approved') {
                          outcomeText = 'Reto Completado y Aprobado 🎉';
                          statusColor = Colors.green;
                        } else if (photoStatus == 'rejected') {
                          outcomeText = 'Reto Rechazado 👎';
                          statusColor = Colors.red;
                        } else if (photoStatus == 'pending') {
                          outcomeText = 'Reto subido, esperando aprobación 👀';
                          statusColor = Colors.orange;
                        } else {
                          outcomeText = 'Esperando prueba del reto 📸';
                          statusColor = Colors.blue;
                        }
                      }
                    }
                  } else if (isSpicy) {
                    // Spicy game
                    final photoStatus = game['photoStatus'] as String? ?? '';
                    final content = game['content'] as String? ?? '';
                    if (status == 'responded' || photoStatus == 'approved') {
                      final responderName = (sender == myName) ? partnerName : myName;
                      outcomeText = '$responderName completó: "$content"';
                      statusColor = Colors.green;
                    } else {
                      outcomeText = 'Reto enviado por $sender (Pendiente)';
                      statusColor = Colors.blue;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _getGameGradient(type),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getGameIcon(type), color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      gameLabel,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      _formatDateTime(timestamp),
                                      style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  outcomeText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.8)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusColor == Colors.green ? 'Completado' : (statusColor == cs.primary || statusColor == Colors.blue ? 'En Curso' : (statusColor == Colors.orange ? 'Empate' : 'Finalizado')),
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget para el cabezal comparativo (VS)
  Widget _buildVSHeaderCard({
    required BuildContext context,
    required ColorScheme cs,
    required String myName,
    required String partnerName,
    required int myWins,
    required int partnerWins,
    required int ties,
    required int total,
  }) {
    final totalWins = myWins + partnerWins;
    final double myPercentage = totalWins > 0 ? myWins / totalWins : 0.5;
    final double partnerPercentage = totalWins > 0 ? partnerWins / totalWins : 0.5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.85), cs.secondary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'BALANCE GENERAL DE VICTORIAS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myName,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$myWins Victorias',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.amberAccent),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      partnerName,
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$partnerWins Victorias',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (myPercentage * 100).round(),
                    child: Container(color: Colors.white),
                  ),
                  if (totalWins == 0)
                    Expanded(
                      flex: 1,
                      child: Container(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  Expanded(
                    flex: (partnerPercentage * 100).round(),
                    child: Container(color: Colors.amberAccent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Partidas: $total',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
              ),
              Text(
                'Empates: $ties',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card para estadísticas individuales por juego
  Widget _buildGameStatCard({
    required String title,
    required String type,
    required int myWins,
    required int partnerWins,
    required int ties,
    required int active,
    required String partnerName,
    required ColorScheme cs,
  }) {
    final total = myWins + partnerWins + ties;
    final grad = _getGameGradient(type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: grad,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getGameIcon(type), color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tú: $myWins victorias',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
              ),
              const SizedBox(height: 2),
              Text(
                '$partnerName: $partnerWins victorias',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepPurpleAccent),
              ),
              const SizedBox(height: 2),
              Text(
                'Empates: $ties',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: $total',
                style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold),
              ),
              if (active > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$active activos',
                    style: TextStyle(fontSize: 9, color: cs.primary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Card para estadísticas de juego cooperativo (Ahorcado)
  Widget _buildCoopStatCard({
    required String title,
    required int wins,
    required int losses,
    required int active,
    required ColorScheme cs,
  }) {
    final total = wins + losses;
    final rate = total > 0 ? (wins / total * 100).toStringAsFixed(0) : '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _getGameGradient('hangman'),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getGameIcon('hangman'), color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Resueltos: $wins',
                      style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Perdidos: $losses',
                      style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                    if (active > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Activos: $active',
                        style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$rate%',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                'Éxito',
                style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card para retos y verdades completados
  Widget _buildTruthDareStatCard({
    required String title,
    required String myName,
    required String partnerName,
    required int myTruths,
    required int partnerTruths,
    required int myDares,
    required int partnerDares,
    required ColorScheme cs,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C83FF), Color(0xFFFF5C8A)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💬 Verdades: $myTruths',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🌶️ Retos: $myDares',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurpleAccent),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💬 Verdades: $partnerTruths',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🌶️ Retos: $partnerDares',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
