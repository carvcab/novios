import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomQuizScreen extends StatefulWidget {
  const CustomQuizScreen({super.key});

  @override
  State<CustomQuizScreen> createState() => _CustomQuizScreenState();
}

class _CustomQuizScreenState extends State<CustomQuizScreen> {
  final _coupleId = ['joeBcVn2o1hfXfU68rWNOyAZIqt2', 'Dd1X94n3gxg7leWtMtnLlxDVHcm2'].join('_');
  String? _playingQuizId;
  String? _playingName;
  List<_QuizQuestion>? _playingQuestions;
  int _playingIndex = 0;
  int _playingScore = 0;
  bool _answered = false;

  CollectionReference get _quizzesRef =>
      FirebaseFirestore.instance.collection('couples').doc(_coupleId).collection('customQuizzes');

  void _play(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final questions = (data['questions'] as List).map((q) => _QuizQuestion.fromMap(q)).toList();
    setState(() {
      _playingQuizId = doc.id;
      _playingName = data['name'] as String;
      _playingQuestions = questions;
      _playingIndex = 0;
      _playingScore = 0;
      _answered = false;
    });
  }

  void _answer(int picked) {
    if (_answered || _playingQuestions == null) return;
    setState(() => _answered = true);
    if (picked == _playingQuestions![_playingIndex].correctIndex) {
      setState(() => _playingScore++);
    }
    Future.delayed(const Duration(milliseconds: 600), () {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Resultado', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        content: Text('Puntaje: $_playingScore de ${_playingQuestions?.length ?? 0}', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(c); setState(() { _playingQuizId = null; _playingQuestions = null; }); },
            child: Text('Cerrar', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }

  void _create() {
    final nameCtrl = TextEditingController();
    final questions = <_QuizQuestion>[];
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _QuizEditor(nameCtrl, questions, () async {
        if (nameCtrl.text.trim().isEmpty || questions.isEmpty) return;
        await _quizzesRef.add({
          'name': nameCtrl.text.trim(),
          'questions': questions.map((q) => q.toMap()).toList(),
        });
        Navigator.pop(context);
      }),
    ));
  }

  void _delete(String id) {
    _quizzesRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_playingQuizId != null && _playingQuestions != null) {
      return _buildPlayScreen(cs);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Personalizado', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
      ),
      body: StreamBuilder(
        stream: _quizzesRef.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.outfit()));
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
                  Text('Crea tu primer quiz!', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final qs = (data['questions'] as List?)?.length ?? 0;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(data['name'] as String? ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text('$qs preguntas', style: GoogleFonts.outfit()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.play_arrow, color: Colors.green), onPressed: () => _play(d)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(d.id)),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_playingName ?? '', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('$_playingScore pts', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Pregunta ${_playingIndex + 1} de ${_playingQuestions!.length}', style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Text(q.text, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(q.options.length, (i) {
              final selected = _answered && i == q.correctIndex;
              final wrong = _answered && i != q.correctIndex;
              Color bg = cs.surface;
              if (selected) bg = Colors.green;
              else if (wrong && _answered) bg = Colors.red.shade100;
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
                      side: _answered && i == q.correctIndex ? const BorderSide(color: Colors.green, width: 2) : null,
                    ),
                    child: Text(q.options[i], style: GoogleFonts.outfit(color: cs.onSurface, fontSize: 16)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _QuizQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;
  const _QuizQuestion({required this.text, required this.options, required this.correctIndex});

  factory _QuizQuestion.fromMap(Map<String, dynamic> m) => _QuizQuestion(
    text: m['text'] as String,
    options: List<String>.from(m['options'] as List),
    correctIndex: m['correctIndex'] as int,
  );

  Map<String, dynamic> toMap() => {'text': text, 'options': options, 'correctIndex': correctIndex};
}

class _QuizEditor extends StatefulWidget {
  final TextEditingController nameCtrl;
  final List<_QuizQuestion> questions;
  final VoidCallback onSave;
  const _QuizEditor(this.nameCtrl, this.questions, this.onSave);

  @override
  State<_QuizEditor> createState() => _QuizEditorState();
}

class _QuizEditorState extends State<_QuizEditor> {
  final _optionControllers = List.generate(4, (_) => TextEditingController());
  final _questionCtrl = TextEditingController();
  int _correctIndex = 0;

  void _addQuestion() {
    if (_questionCtrl.text.trim().isEmpty || _optionControllers.any((c) => c.text.trim().isEmpty)) return;
    setState(() {
      widget.questions.add(_QuizQuestion(
        text: _questionCtrl.text.trim(),
        options: _optionControllers.map((c) => c.text.trim()).toList(),
        correctIndex: _correctIndex,
      ));
      _questionCtrl.clear();
      for (final c in _optionControllers) c.clear();
      _correctIndex = 0;
    });
  }

  void _removeQuestion(int i) {
    setState(() => widget.questions.removeAt(i));
  }

  @override
  void dispose() {
    for (final c in _optionControllers) c.dispose();
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Quiz', style: GoogleFonts.outfit(color: cs.onSurface)),
        backgroundColor: cs.primary,
        actions: [
          TextButton(
            onPressed: widget.onSave,
            child: Text('Guardar', style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del quiz', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Text('Agregar pregunta', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _questionCtrl,
              decoration: const InputDecoration(labelText: 'Pregunta', border: OutlineInputBorder()),
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
                        controller: _optionControllers[i],
                        decoration: InputDecoration(labelText: 'Opcion ${i + 1}', border: const OutlineInputBorder()),
                      ),
                    ),
                    Radio<int>(
                      value: i,
                      groupValue: _correctIndex,
                      onChanged: (v) => setState(() => _correctIndex = v!),
                    ),
                  ],
                ),
              );
            }),
            ElevatedButton(
              onPressed: _addQuestion,
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
              child: Text('Agregar pregunta', style: GoogleFonts.outfit(color: cs.onSurface)),
            ),
            const SizedBox(height: 24),
            if (widget.questions.isNotEmpty) ...[
              Text('Preguntas (${widget.questions.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ...widget.questions.asMap().entries.map((e) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(e.value.text, style: GoogleFonts.outfit()),
                  subtitle: Text('Correcta: ${e.value.options[e.value.correctIndex]}', style: GoogleFonts.outfit()),
                  trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _removeQuestion(e.key)),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
