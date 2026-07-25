import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/game_service.dart';
import '../../services/local_storage.dart';

IconData _materialIcon(String name) {
  switch (name) {
    case 'favorite': return Icons.favorite;
    case 'celebration': return Icons.celebration;
    case 'travel_explore': return Icons.travel_explore;
    case 'emoji_events': return Icons.emoji_events;
    case 'whatshot': return Icons.whatshot;
    case 'psychology': return Icons.psychology;
    case 'self_improvement': return Icons.self_improvement;
    default: return Icons.quiz;
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  final full = h.length == 6 ? 'FF$h' : h;
  return Color(int.parse(full, radix: 16));
}

const _presetColors = [
  '#FF6B6B', '#4ECDC4', '#FFD93D', '#6C5CE7',
  '#A8E6CF', '#FF8A5C', '#3D84A8', '#E84A5F',
];

const _iconNames = [
  'quiz', 'favorite', 'celebration', 'travel_explore',
  'emoji_events', 'whatshot', 'psychology', 'self_improvement',
];

const _categories = ['Romantico', 'Divertido', 'Viajes', 'Picante', 'Personalizado'];
const _difficulties = ['Facil', 'Medio', 'Dificil'];

class CustomQuizScreen extends StatefulWidget {
  const CustomQuizScreen({super.key});

  @override
  State<CustomQuizScreen> createState() => _CustomQuizScreenState();
}

class _CustomQuizScreenState extends State<CustomQuizScreen> {
  String? _playingQuizId;
  String? _playingTitle;
  List<Map<String, dynamic>>? _playingQuestions;
  int _playingIndex = 0;
  int _playingScore = 0;
  bool _answered = false;

  String? _detailQuizId;
  Map<String, dynamic>? _detailQuizData;

  String get _userId => LocalStorage().getUserId() ?? '';

  void _play(String title, List<Map<String, dynamic>> questions, {String? id}) {
    setState(() {
      _playingQuizId = id;
      _playingTitle = title;
      _playingQuestions = questions;
      _playingIndex = 0;
      _playingScore = 0;
      _answered = false;
    });
  }

  void _answer(int picked) {
    if (_answered || _playingQuestions == null) return;
    final correct = picked == _playingQuestions![_playingIndex]['correctIndex'];
    setState(() => _answered = true);
    if (correct) _playingScore++;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_playingIndex >= _playingQuestions!.length - 1) {
        _endQuiz();
      } else {
        setState(() {
          _playingIndex++;
          _answered = false;
        });
      }
    });
  }

  void _endQuiz() {
    final total = _playingQuestions?.length ?? 0;
    GameService().saveGameStats('quizzes', {
      'quizId': _playingQuizId ?? '',
      'quizTitle': _playingTitle ?? '',
      'score': _playingScore,
      'total': total,
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Resultado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(c).colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text('$_playingScore / $total', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_playingScore == total ? 'Perfecto!' : _playingScore > total ~/ 2 ? 'Buen trabajo!' : 'Sigue intentando!',
                style: GoogleFonts.outfit(fontSize: 16, color: Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              setState(() { _playingQuizId = null; _playingQuestions = null; });
            },
            child: Text('Cerrar', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _showDetail(String id, Map<String, dynamic> data) {
    setState(() {
      _detailQuizId = id;
      _detailQuizData = data;
    });
  }

  void _create() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _QuizForm())).then((_) => setState(() {}));
  }

  void _edit(String id, Map<String, dynamic> data) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _QuizForm(quizId: id, initialData: data))).then((_) => setState(() {}));
  }

  void _delete(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Eliminar quiz', style: GoogleFonts.outfit()),
        content: Text('Seguro que quieres eliminar este quiz?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancelar', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () { Navigator.pop(c); GameService().deleteQuiz(id); },
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_playingQuizId != null && _playingQuestions != null && _playingQuestions!.isNotEmpty) {
      return _buildPlayScreen(cs);
    }
    if (_detailQuizId != null && _detailQuizData != null) {
      return _buildDetailScreen(cs);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tus Quizzes', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary.withValues(alpha: 0.15), cs.surface],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: GameService().streamQuizzes(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Error: ${snap.error}', style: GoogleFonts.outfit(), textAlign: TextAlign.center),
            ));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 80, color: cs.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('No hay quizzes', style: GoogleFonts.outfit(fontSize: 20, color: cs.onSurface.withValues(alpha: 0.5))),
                    const SizedBox(height: 8),
                    Text('Crea el primero!', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 80),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i];
                final data = d.data() as Map<String, dynamic>;
                final qs = (data['questions'] as List?)?.length ?? 0;
                final isOwner = data['authorId'] == _userId;
                return Dismissible(
                  key: Key('quiz_${d.id}'),
                  direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  onDismissed: (_) => GameService().deleteQuiz(d.id),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showDetail(d.id, data),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(_materialIcon(data['icon'] as String? ?? 'quiz'),
                                    color: _parseColor(data['color'] as String? ?? _presetColors[0]), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(data['title'] as String? ?? '',
                                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                PopupMenuButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 20,
                                  itemBuilder: (_) {
                                    final items = <PopupMenuEntry>[];
                                    if (isOwner) {
                                      items.add(PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [Icon(Icons.edit, size: 18, color: cs.primary), const SizedBox(width: 8), Text('Editar')]),
                                      ));
                                      items.add(PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))]),
                                      ));
                                    }
                                    return items;
                                  },
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(d.id, data);
                                    if (v == 'delete') _delete(d.id);
                                  },
                                ),
                              ],
                            ),
                            if (data['description'] is String && (data['description'] as String).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(data['description'] as String,
                                  style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.65)),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6, runSpacing: 4,
                              children: [
                                _Tag(data['category'] as String? ?? '', cs.primary, cs),
                                _Tag(data['difficulty'] as String? ?? '', cs.onSurface.withValues(alpha: 0.5), cs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.onSurface.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('$qs preg', style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('por ${data['author'] ?? 'Desconocido'}',
                                style: GoogleFonts.outfit(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        backgroundColor: cs.primary,
        child: Icon(Icons.add, color: cs.onSurface),
      ),
    );
  }

  Widget _buildPlayScreen(ColorScheme cs) {
    final q = _playingQuestions![_playingIndex];
    final options = List<String>.from(q['options'] as List? ?? []);
    final correctIndex = q['correctIndex'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_playingTitle ?? '', style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 16)),
        backgroundColor: cs.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('$_playingScore pts',
                style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary.withValues(alpha: 0.08), cs.surface],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Text('Pregunta ${_playingIndex + 1} de ${_playingQuestions!.length}',
                      style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_playingIndex + 1) / _playingQuestions!.length,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.1),
                      color: cs.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        child: Text(q['text'] as String? ?? '',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(options.length, (i) {
                      final isCorrect = i == correctIndex;
                      final isSelected = _answered && i == correctIndex;
                      final isWrong = _answered && i != correctIndex;
                      Color bg = cs.surface;
                      Color border = Colors.transparent;
                      if (isSelected) {
                        bg = Colors.green.withValues(alpha: 0.15);
                        border = Colors.green;
                      } else if (isWrong) {
                        bg = Colors.red.withValues(alpha: 0.1);
                        border = Colors.red.withValues(alpha: 0.3);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _answered ? null : () => _answer(i),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bg,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: border, width: border == Colors.transparent ? 0 : 2),
                              elevation: _answered ? 0 : 1,
                            ),
                            child: Text(options[i],
                                style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      );
                    }),
                    if (_answered && q['explanation'] is String && (q['explanation'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(q['explanation'] as String,
                            style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6), fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailScreen(ColorScheme cs) {
    final data = _detailQuizData!;
    final qs = (data['questions'] as List?)?.length ?? 0;
    final isOwner = data['authorId'] == _userId;
    final color = _parseColor(data['color'] as String? ?? _presetColors[0]);

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] as String? ?? '', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _edit(_detailQuizId!, data).then((_) {
                if (mounted) setState(() { _detailQuizId = null; _detailQuizData = null; });
              }),
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _delete(_detailQuizId!),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary.withValues(alpha: 0.08), cs.surface],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(_materialIcon(data['icon'] as String? ?? 'quiz'), size: 48, color: color),
                      const SizedBox(height: 12),
                      Text(data['title'] as String? ?? '',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (data['description'] is String && (data['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(data['description'] as String,
                            style: GoogleFonts.outfit(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
                            textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        children: [
                          _Tag(data['category'] as String? ?? '', color, cs),
                          _Tag(data['difficulty'] as String? ?? '', cs.onSurface.withValues(alpha: 0.5), cs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$qs preguntas',
                                style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Creado por ${data['author'] ?? 'Desconocido'}',
                          style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final questions = (data['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                            if (questions.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Este quiz no tiene preguntas', style: GoogleFonts.outfit()),
                                    behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }
                            setState(() { _detailQuizId = null; _detailQuizData = null; });
                            _play(data['title'] as String? ?? '', questions, id: _detailQuizId);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: Text('Jugar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Historial de partidas', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: GameService().streamGameStats('quizzes'),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final stats = snap.data!.docs.where((d) {
                    final s = d.data() as Map<String, dynamic>;
                    return s['quizId'] == _detailQuizId;
                  }).toList();
                  if (stats.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 8),
                            Text('Aun no hay partidas', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    itemBuilder: (_, i) {
                      final s = stats[i].data() as Map<String, dynamic>;
                      final score = s['score'] as int? ?? 0;
                      final total = s['total'] as int? ?? 0;
                      final ratio = total > 0 ? score / total : 0.0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: ratio >= 0.8 ? Colors.green.withValues(alpha: 0.15) :
                                ratio >= 0.5 ? Colors.orange.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                            child: Icon(Icons.emoji_events,
                                color: ratio >= 0.8 ? Colors.green : ratio >= 0.5 ? Colors.orange : Colors.red,
                                size: 20),
                          ),
                          title: Text('$score / $total',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          subtitle: Text(s['playerName'] ?? 'Anonimo',
                              style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                          trailing: Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.2)),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final ColorScheme cs;
  const _Tag(this.label, this.color, this.cs);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _QuizForm extends StatefulWidget {
  final String? quizId;
  final Map<String, dynamic>? initialData;
  const _QuizForm({this.quizId, this.initialData});

  @override
  State<_QuizForm> createState() => _QuizFormState();
}

class _QuizFormState extends State<_QuizForm> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _category;
  late String _difficulty;
  late String _color;
  late String _icon;
  final _questions = <Map<String, dynamic>>[];
  bool _saving = false;

  bool get _isEditing => widget.quizId != null;

  @override
  void initState() {
    super.initState();
    _category = _categories[0];
    _difficulty = _difficulties[1];
    _color = _presetColors[0];
    _icon = _iconNames[0];
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _titleCtrl.text = d['title'] as String? ?? '';
      _descCtrl.text = d['description'] as String? ?? '';
      _category = d['category'] as String? ?? _categories[0];
      _difficulty = d['difficulty'] as String? ?? _difficulties[1];
      _color = d['color'] as String? ?? _presetColors[0];
      _icon = d['icon'] as String? ?? _iconNames[0];
      final qs = d['questions'] as List? ?? [];
      _questions.addAll(qs.cast<Map<String, dynamic>>());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addQuestion({Map<String, dynamic>? existing, int? index}) {
    final textCtrl = TextEditingController(text: existing?['text'] as String? ?? '');
    final optCtrls = List.generate(4, (i) => TextEditingController(
      text: existing != null ? (existing['options'] as List? ?? ['', '', '', ''])[i] as String? ?? '' : '',
    ));
    int correctIdx = existing?['correctIndex'] as int? ?? 0;
    final explCtrl = TextEditingController(text: existing?['explanation'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existing != null ? 'Editar pregunta' : 'Agregar pregunta',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textCtrl,
                  decoration: InputDecoration(
                    labelText: 'Pregunta',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ...List.generate(4, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optCtrls[i],
                            decoration: InputDecoration(
                              labelText: 'Opcion ${i + 1}',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Radio<int>(
                          value: i,
                          groupValue: correctIdx,
                          onChanged: (v) => setDState(() => correctIdx = v!),
                        ),
                      ],
                    ),
                  );
                }),
                TextField(
                  controller: explCtrl,
                  decoration: InputDecoration(
                    labelText: 'Explicacion (opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: GoogleFonts.outfit()),
            ),
            ElevatedButton(
              onPressed: () {
                if (textCtrl.text.trim().isEmpty) return;
                if (optCtrls.any((c) => c.text.trim().isEmpty)) return;
                final question = {
                  'text': textCtrl.text.trim(),
                  'options': optCtrls.map((c) => c.text.trim()).toList(),
                  'correctIndex': correctIdx,
                  'explanation': explCtrl.text.trim(),
                };
                setState(() {
                  if (existing != null && index != null) {
                    _questions[index] = question;
                  } else {
                    _questions.add(question);
                  }
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.primary),
              child: Text(existing != null ? 'Guardar' : 'Agregar',
                  style: GoogleFonts.outfit(color: Theme.of(ctx).colorScheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa un titulo', style: GoogleFonts.outfit()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agrega al menos una pregunta', style: GoogleFonts.outfit()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    await GameService().saveQuiz({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      'difficulty': _difficulty,
      'color': _color,
      'icon': _icon,
      'questions': _questions,
    }, id: widget.quizId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Quiz' : 'Crear Quiz',
            style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          _saving
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurface)),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text('Guardar', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary.withValues(alpha: 0.08), cs.surface],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Titulo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: cs.surface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: 'Descripcion',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: cs.surface,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Categoria', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _categories.map((c) {
                  final sel = _category == c;
                  return ChoiceChip(
                    selected: sel,
                    label: Text(c, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                    selectedColor: cs.primary,
                    labelStyle: TextStyle(color: sel ? cs.onSurface : cs.onSurface.withValues(alpha: 0.7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (v) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Dificultad', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _difficulties.map((d) {
                  final sel = _difficulty == d;
                  return ChoiceChip(
                    selected: sel,
                    label: Text(d, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                    selectedColor: cs.primary,
                    labelStyle: TextStyle(color: sel ? cs.onSurface : cs.onSurface.withValues(alpha: 0.7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (v) => setState(() => _difficulty = d),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Color', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _presetColors.map((c) {
                  final sel = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _parseColor(c),
                        shape: BoxShape.circle,
                        border: sel ? Border.all(color: cs.onSurface, width: 3) : null,
                        boxShadow: sel ? [BoxShadow(color: _parseColor(c).withValues(alpha: 0.4), blurRadius: 8)] : null,
                      ),
                      child: sel ? Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Icono', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _iconNames.map((n) {
                  final sel = _icon == n;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = n),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: sel ? _parseColor(_color) : cs.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: sel ? Border.all(color: cs.onSurface, width: 2) : null,
                      ),
                      child: Icon(_materialIcon(n), color: sel ? Colors.white : cs.onSurface.withValues(alpha: 0.6), size: 22),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Preguntas (${_questions.length})',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: () => _addQuestion(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Agregar pregunta', style: GoogleFonts.outfit()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_questions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No hay preguntas aun', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
                  ),
                )
              else
                ..._questions.asMap().entries.map((e) {
                  final idx = e.key;
                  final q = e.value;
                  final opts = List<String>.from(q['options'] as List? ?? []);
                  final correct = q['correctIndex'] as int? ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(q['text'] as String? ?? '',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Correcta: ${correct < opts.length ? opts[correct] : ''}',
                          style: GoogleFonts.outfit(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 18, color: cs.primary),
                            onPressed: () => _addQuestion(existing: q, index: idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            onPressed: () => setState(() => _questions.removeAt(idx)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
