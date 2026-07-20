import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_service.dart';
import '../../services/local_ai_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../models/message_model.dart';
import '../../models/memory_model.dart';
import '../../models/goal_model.dart';
import '../settings/settings_screen.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  String _activeTab = 'letter'; // 'letter', 'poem', 'date', 'gift', 'song', 'story', 'qa'
  bool _generating = false;
  String _resultText = '';

  // Controllers
  final _keywordsCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _storyTitleCtrl = TextEditingController();

  // Dropdowns
  String _letterTone = 'Romántico';
  String _dateType = 'Aventura';
  String _dateBudget = 'Medio';
  String _giftOccasion = 'Aniversario';
  String _poemStyle = 'Romántico';
  String _songGenre = 'Balada';

  @override
  void dispose() {
    _keywordsCtrl.dispose();
    _topicCtrl.dispose();
    _detailsCtrl.dispose();
    _questionCtrl.dispose();
    _storyTitleCtrl.dispose();
    super.dispose();
  }

  void _generate() async {
    setState(() {
      _generating = true;
      _resultText = '';
    });

    final partnerName = LocalStorage().getPartnerName() ?? 'tu pareja';
    String output = '';

    try {
      if (_activeTab == 'letter') {
        output = await AIService().generateLetter(
          tone: _letterTone,
          keywords: _keywordsCtrl.text.trim().isNotEmpty ? _keywordsCtrl.text.trim() : 'nuestro amor, el futuro',
        );
      } else if (_activeTab == 'poem') {
        output = await AIService().generatePoem(
          style: _poemStyle,
          topic: _topicCtrl.text.trim().isNotEmpty ? _topicCtrl.text.trim() : 'tus hermosos ojos',
        );
      } else if (_activeTab == 'date') {
        output = await AIService().suggestDate(
          type: _dateType,
          budget: _dateBudget,
        );
      } else if (_activeTab == 'gift') {
        output = await AIService().suggestGift(
          occasion: _giftOccasion,
        );
      } else if (_activeTab == 'song') {
        output = await AIService().generateSong(
          genre: _songGenre,
          details: _detailsCtrl.text.trim().isNotEmpty ? _detailsCtrl.text.trim() : 'nuestro primer beso bajo la lluvia',
        );
      } else if (_activeTab == 'story') {
        output = await AIService().generateStory(
          memoryTitle: _storyTitleCtrl.text.trim().isNotEmpty ? _storyTitleCtrl.text.trim() : 'El día que nos conocimos',
          details: _detailsCtrl.text.trim().isNotEmpty ? _detailsCtrl.text.trim() : 'caminando por el parque',
        );
      } else if (_activeTab == 'qa') {
        final q = _questionCtrl.text.trim();
        if (q.isEmpty) {
          output = 'Por favor escribe una pregunta para la IA.';
        } else {
          final coupleId = FirebaseService().coupleId;
          final db = FirebaseFirestore.instance;

          // Fetch some memories
          final memSnap = await db.collection('couples').doc(coupleId).collection('memories').limit(5).get();
          final memories = memSnap.docs.map((doc) => MemoryModel.fromMap(doc.data())).toList();

          // Fetch some goals
          final goalSnap = await db.collection('couples').doc(coupleId).collection('goals').limit(5).get();
          final goals = goalSnap.docs.map((doc) => GoalModel.fromMap(doc.data())).toList();

          output = await AIService().answerRelationshipQuestion(
            question: q,
            memories: memories,
            goals: goals,
            partnerName: partnerName,
          );
        }
      }
    } catch (e) {
      output = 'Ocurrió un error al generar con la IA: $e';
    }

    if (mounted) {
      setState(() {
        _resultText = output;
        _generating = false;
      });
    }
  }

  void _sendToChat() async {
    if (_resultText.isEmpty) return;

    final userId = LocalStorage().getUserId() ?? 'local_user_id';
    final msg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: userId,
      text: _resultText,
      timestamp: DateTime.now(),
      type: 'chat',
    );

    await FirebaseService().sendMessage(msg);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Mensaje enviado al chat de pareja! ❤️')),
      );
    }
  }

  void _copyToClipboard() {
    if (_resultText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado al portapapeles 📋')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLlmReady = LocalAIService().isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Amor IA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Local Model Warning Banner ──
            if (!isLlmReady)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Modelo Local No Inicializado',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Se utilizarán respuestas rápidas locales predefinidas. Descarga el modelo DeepSeek R1 1.5B (1.1 GB) en Ajustes para activar el razonamiento offline completo.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.settings_rounded, size: 14),
                        label: const Text('Ir a Ajustes para Descargar', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amber.shade900,
                          backgroundColor: Colors.amber.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Tabs Grid selector ──
            Row(
              children: [
                Icon(Icons.psychology_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Elige qué quieres crear:',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildTabButton('letter', Icons.edit_note_rounded, 'Carta'),
                _buildTabButton('poem', Icons.auto_awesome_rounded, 'Poema'),
                _buildTabButton('date', Icons.restaurant_rounded, 'Cita'),
                _buildTabButton('gift', Icons.card_giftcard_rounded, 'Regalo'),
                _buildTabButton('song', Icons.music_note_rounded, 'Canción'),
                _buildTabButton('story', Icons.book_rounded, 'Historia'),
                _buildTabButton('qa', Icons.question_answer_rounded, 'Chat IA'),
              ],
            ),
            const SizedBox(height: 24),

            // ── Form configuration fields ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: cs.surfaceContainerLow,
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeTab == 'letter') ...[
                    DropdownButtonFormField<String>(
                      value: _letterTone,
                      items: ['Romántico', 'Apasionado', 'Divertido', 'Poético', 'Corto'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (v) => setState(() => _letterTone = v ?? 'Romántico'),
                      decoration: const InputDecoration(labelText: 'Tono de la carta'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keywordsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Palabras clave (separadas por comas)',
                        hintText: 'ej: primer año, viaje, complicidad',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                  if (_activeTab == 'poem') ...[
                    DropdownButtonFormField<String>(
                      value: _poemStyle,
                      items: ['Romántico', 'Clásico', 'Verso Libre', 'Soneto'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (v) => setState(() => _poemStyle = v ?? 'Romántico'),
                      decoration: const InputDecoration(labelText: 'Estilo del poema'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _topicCtrl,
                      decoration: const InputDecoration(
                        labelText: '¿Sobre qué escribir?',
                        hintText: 'ej: tu sonrisa, caminar tomados de la mano',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                  if (_activeTab == 'date') ...[
                    DropdownButtonFormField<String>(
                      value: _dateType,
                      items: ['Hogareña', 'Aventura', 'Cultural', 'Económica', 'Sorpresa'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (v) => setState(() => _dateType = v ?? 'Aventura'),
                      decoration: const InputDecoration(labelText: 'Tipo de Cita'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _dateBudget,
                      items: ['Bajo', 'Medio', 'Alto'].map((t) {
                        return DropdownMenuItem(value: t, child: Text('Presupuesto $t'));
                      }).toList(),
                      onChanged: (v) => setState(() => _dateBudget = v ?? 'Medio'),
                      decoration: const InputDecoration(labelText: 'Presupuesto'),
                    ),
                  ],
                  if (_activeTab == 'gift') ...[
                    DropdownButtonFormField<String>(
                      value: _giftOccasion,
                      items: ['Aniversario', 'Cumpleaños', 'San Valentín', 'Sin motivo especial'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (v) => setState(() => _giftOccasion = v ?? 'Aniversario'),
                      decoration: const InputDecoration(labelText: 'Ocasión del regalo'),
                    ),
                  ],
                  if (_activeTab == 'song') ...[
                    DropdownButtonFormField<String>(
                      value: _songGenre,
                      items: ['Balada', 'Pop Acústico', 'Rock Romántico', 'Reggae Suave'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (v) => setState(() => _songGenre = v ?? 'Balada'),
                      decoration: const InputDecoration(labelText: 'Género musical'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _detailsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Detalles que inspiran la canción',
                        hintText: 'ej: nuestro primer café, el viaje a la playa',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                  if (_activeTab == 'story') ...[
                    TextField(
                      controller: _storyTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título del momento / recuerdo',
                        hintText: 'ej: El campamento bajo las estrellas',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _detailsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Detalles y anécdotas de lo que pasó',
                        hintText: 'ej: hacía frío, quemamos los bombones',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                  if (_activeTab == 'qa') ...[
                    TextField(
                      controller: _questionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pregúntale a la IA de su Relación',
                        hintText: 'ej: ¿Qué metas tenemos pendientes? o ¿Qué opinas de nosotros?',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Generate Button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt_rounded),
                      label: Text(_generating ? 'Pensando...' : 'Generar con IA Local'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── AI Result Output Area ──
            if (_resultText.isNotEmpty || _generating) ...[
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Resultado Generado:',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [cs.primary.withValues(alpha: 0.05), cs.secondary.withValues(alpha: 0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.all(20),
                child: _generating
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text('DeepSeek R1 está escribiendo...', style: TextStyle(fontSize: 13, color: cs.primary)),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            _resultText,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              height: 1.5,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copiar'),
                              ),
                              TextButton.icon(
                                onPressed: _sendToChat,
                                icon: const Icon(Icons.send_rounded, size: 18),
                                label: const Text('Enviar a Chat'),
                                style: TextButton.styleFrom(foregroundColor: Colors.pinkAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabId, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    final active = _activeTab == tabId;

    return InkWell(
      onTap: () => setState(() => _activeTab = tabId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : cs.onSurface.withValues(alpha: 0.6), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.white : cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
