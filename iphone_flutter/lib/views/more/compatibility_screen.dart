import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  int _q = 0;
  int _score = 0;
  bool _showResult = false;

  final _questions = [
    {
      'q': '¿Cuál fue el primer lugar donde se besaron?',
      'a': 'En el cine 🎬',
      'b': 'En el parque 🌳',
      'c': 'En su casa 🏠',
      'd': 'En la escuela 🏫',
      'correct': 'b'
    },
    {
      'q': '¿Quién dijo "Te amo" primero?',
      'a': 'Yo 🙋‍♂️',
      'b': 'Mi pareja 🙋‍♀️',
      'c': 'Los dos al mismo tiempo 🗣️',
      'd': 'Ninguno aún 🤐',
      'correct': 'a'
    },
    {
      'q': '¿Cuál es el color favorito de tu pareja?',
      'a': 'Rosa 🌸',
      'b': 'Azul 💙',
      'c': 'Rojo ❤️',
      'd': 'Negro 🖤',
      'correct': 'b'
    },
    {
      'q': '¿Cuál es la comida favorita de tu pareja?',
      'a': 'Pizza 🍕',
      'b': 'Sushi 🍣',
      'c': 'Tacos 🌮',
      'd': 'Pasta 🍝',
      'correct': 'c'
    },
    {
      'q': '¿Qué género de película prefieren ver juntos?',
      'a': 'Romántica 💖',
      'b': 'Terror 👻',
      'c': 'Comedia 😂',
      'd': 'Ciencia Ficción 🚀',
      'correct': 'a'
    },
  ];

  void _answer(String selected) {
    if (_questions[_q]['correct'] == selected) {
      _score++;
    }
    if (_q < _questions.length - 1) {
      setState(() => _q++);
    } else {
      setState(() => _showResult = true);
    }
  }

  String _getFeedbackMessage(double percent) {
    if (percent >= 1.0) return '¡Almas Gemelas! Su sintonía es absoluta. ❤️';
    if (percent >= 0.8) return '¡Increíble Conexión! Se conocen casi a la perfección. 😍';
    if (percent >= 0.6) return '¡Buen Camino! Tienen una hermosa sintonía juntos. 😘';
    return '¡Sigan conociéndose! Cada día es una oportunidad de aprender más del otro. 🌱';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (_q + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Test de Compatibilidad', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.surface, cs.surfaceContainerLowest],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _showResult
            ? _buildResultView(cs)
            : _buildQuizView(cs, progress),
      ),
    );
  }

  // VISTA DE RESULTADOS
  Widget _buildResultView(ColorScheme cs) {
    final percent = _score / _questions.length;
    final percentInt = (percent * 100).round();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heart pulse animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.1),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(Icons.favorite_rounded, size: 72, color: cs.primary),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                '$percentInt% Compatibilidad',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _getFeedbackMessage(percent),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Acertaste $_score de ${_questions.length} respuestas.',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _q = 0;
                    _score = 0;
                    _showResult = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Intentar de Nuevo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // VISTA DE PREGUNTAS
  Widget _buildQuizView(ColorScheme cs, double progress) {
    final currentQuestion = _questions[_q];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de progreso con forma de corazón
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.favorite_rounded, color: cs.primary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pregunta ${_q + 1} de ${_questions.length}',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // Tarjeta de la Pregunta
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              currentQuestion['q'] as String,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Opciones de respuesta
          Expanded(
            child: ListView(
              children: ['a', 'b', 'c', 'd'].map((opt) {
                final text = currentQuestion[opt] as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => _answer(opt),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.white,
                      foregroundColor: cs.primary,
                      elevation: 1,
                      alignment: Alignment.centerLeft,
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
