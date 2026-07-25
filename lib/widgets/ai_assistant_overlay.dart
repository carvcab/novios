import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_ai_service.dart';
import '../services/ai_memory_service.dart';
import 'glass_card.dart';

class AiAssistantOverlay extends StatefulWidget {
  final String screenContext;
  final VoidCallback? onOpenSettings;
  const AiAssistantOverlay({
    super.key,
    this.screenContext = 'general',
    this.onOpenSettings,
  });

  @override
  State<AiAssistantOverlay> createState() => _AiAssistantOverlayState();
}

class _AiAssistantOverlayState extends State<AiAssistantOverlay>
    with SingleTickerProviderStateMixin {
  final _ai = LocalAIService();
  final _memory = AiMemoryService();
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _open = false;
  bool _thinking = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _contextHint() {
    switch (widget.screenContext) {
      case 'location': return 'Puedo ayudarte con direcciones, lugares cercanos o estados de ubicacion';
      case 'chat': return 'Puedo ayudarte a escribir mensajes romanticos, corregir o traducir';
      case 'letters': return 'Puedo ayudarte a escribir cartas de amor, poemas o dedicatorias';
      case 'memories': return 'Puedo ayudarte a crear historias con tus recuerdos';
      case 'goals': return 'Puedo ayudarte a planificar metas y sugerir pasos';
      default: return 'Preguntame lo que quieras';
    }
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMsg(esUser: true, text: text));
      _thinking = true;
    });
    _controller.clear();
    _scrollToBottom();

    final memContext = _memory.buildContextPrompt();
    final prompt = """
$memContext
Contexto actual: ${widget.screenContext}
Pregunta: $text
Responde en espanol de forma carinosa y util. Maximo 3 parrafos.
""";
    final response = await _ai.chat(prompt);
    if (mounted) {
      setState(() {
        final reply = response.isNotEmpty ? response : _fallbackResponse(text);
        _messages.add(_ChatMsg(esUser: false, text: reply));
        _thinking = false;
      });
      _scrollToBottom();
    }
  }

  String _fallbackResponse(String q) {
    final ql = q.toLowerCase();
    if (ql.contains('hola') || ql.contains('buenos')) {
      return 'Hola amor! Como estas hoy? En que puedo ayudarte?';
    }
    if (ql.contains('te amo') || ql.contains('quiero')) {
      return 'Yo tambien te quiero mucho! Eres la persona mas especial del mundo.';
    }
    if (ql.contains('cita') || ql.contains('plan')) {
      return 'Que tal un picnic al atardecer? Preparen algo rico y busquen un lugar bonito al aire libre.';
    }
    if (ql.contains('regalo') || ql.contains('sorprender')) {
      return 'Un frasco con 100 razones por las que la amas nunca falla. O un mapa de rascadito con sus proximos viajes.';
    }
    if (ql.contains('recordar') || ql.contains('recuerdo')) {
      final mems = _memory.memories;
      if (mems.isNotEmpty) {
        final m = mems[DateTime.now().millisecond % mems.length];
        return 'Me acuerdo de "${m.key}". Fue un momento especial para ustedes.';
      }
      return 'Aun estan creando sus recuerdos. Cada dia es una oportunidad para guardar un momento especial.';
    }
    return 'Gracias por tu mensaje! Siempre estoy aqui para ayudarlos. Puedes preguntarme sobre citas, regalos, cartas o lo que necesites.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        if (_open) _buildOverlay(theme, isDark),
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildFab(theme),
        ),
      ],
    );
  }

  Widget _buildFab(ColorScheme cs) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, child) => Transform.scale(
        scale: _open ? 1.0 : _pulse.value,
        child: FloatingActionButton(
          onPressed: () => setState(() => _open = !_open),
          backgroundColor: cs.primary,
          child: Icon(_open ? Icons.close : Icons.auto_awesome_rounded,
              color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOverlay(ColorScheme cs, bool isDark) {
    final bottom = MediaQuery.of(context).size.height * 0.12;
    return Positioned(
      right: 16,
      bottom: bottom,
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Asistente IA',
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  ),
                  if (_ai.isInitialized)
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                    ),
                  const SizedBox(width: 4),
                  Text(_ai.isInitialized ? 'En linea' : 'Sin coneccion',
                      style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _contextHint(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length + (_thinking ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _messages.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final msg = _messages[i];
                        return Align(
                          alignment: msg.esUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: msg.esUser ? cs.primary : cs.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: msg.esUser ? const Radius.circular(4) : null,
                                bottomLeft: !msg.esUser ? const Radius.circular(4) : null,
                              ),
                            ),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                            child: Text(msg.text,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: msg.esUser ? Colors.white : cs.onSurface)),
                          ),
                        );
                      },
                    ),
            ),
            // Input
            if (_ai.isInitialized)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Escribe aqui...',
                          hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.onSurface.withValues(alpha: 0.06),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        style: TextStyle(fontSize: 13, color: cs.onSurface),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _send(_controller.text),
                      icon: Icon(Icons.send_rounded, color: cs.primary, size: 20),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Modelo de IA no instalado. Ve a Ajustes > IA para descargarlo.',
                    style: TextStyle(fontSize: 11, color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatMsg {
  final bool esUser;
  final String text;
  _ChatMsg({required this.esUser, required this.text});
}
