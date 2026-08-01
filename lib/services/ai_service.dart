import 'dart:math';
import 'package:flutter/foundation.dart';
import 'aimodel_manager.dart';
import 'ai_memory_service.dart';
import '../models/memory_model.dart';
import '../models/goal_model.dart';

enum AIMode { deepseek, local }

class AIService extends ChangeNotifier {
  static final AIService _instance = AIService._();
  factory AIService() => _instance;
  AIService._();

  final _manager = AimodelManager();
  final _memory = AiMemoryService();

  bool _modelLoaded = false;
  bool _isProcessing = false;

  bool get isReady => _manager.isReady;
  bool get isProcessing => _isProcessing;
  bool get modelLoaded => _modelLoaded;
  AimodelManager get manager => _manager;
  AiMemoryService get memory => _memory;

  // -- Model lifecycle --
  Future<void> init() async {
    await _manager.init();
  }

  Future<bool> downloadModel() => _manager.downloadModel();

  Future<bool> updateModel() => _manager.updateModel();

  Future<void> deleteModel() => _manager.deleteModel();

  // -- Load/unload model --
  Future<bool> loadModel() async {
    if (_modelLoaded) return true;
    if (!_manager.isReady) return false;
    // TODO: Load into inference engine (MediaPipe / llama.cpp)
    _modelLoaded = true;
    notifyListeners();
    return true;
  }

  void unloadModel() {
    // TODO: Unload from inference engine
    _modelLoaded = false;
    notifyListeners();
  }

  AIMode _mode = AIMode.deepseek;
  AIMode get currentMode => _mode;
  Future<void> setMode(AIMode mode) async {
    _mode = mode;
    notifyListeners();
  }
  Future<void> saveDeepseekKey(String key) async {
    // Impl: save key to secure storage
  }

  Future<String> answerRelationshipQuestion({
    required String question,
    required List<MemoryModel> memories,
    required List<GoalModel> goals,
    required String partnerName,
  }) async {
    return answerQuestion(question: question, memories: memories, goals: goals, partnerName: partnerName);
  }

  // -- Chat --
  Future<String> chat(String prompt, {String? context}) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final memContext = _memory.buildContextPrompt();
      final fullPrompt = '''
$memContext
${context != null ? "Contexto: $context" : ""}
Usuario: $prompt
Responde en espanol de forma carinosa y util. Maximo 3 parrafos.
''';

      // TODO: llamar al motor de inferencia local con el modelo cargado
      // Por ahora usamos fallback
      await Future.delayed(const Duration(milliseconds: 300));
      return _fallbackResponse(prompt);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // -- Generators --
  Future<String> generateLetter({required String tone, required String keywords}) async {
    final r = await chat("Escribe una carta de amor en espanol con tono $tone. Incluye: $keywords. Hazla emotiva, poetica y en parrafos.");
    return r.isNotEmpty ? r : _fbLetter(tone, keywords);
  }

  Future<String> suggestDate({required String type, required String budget}) async {
    final r = await chat("Sugiere una cita romantica en espanol. Categoria: $type. Presupuesto: $budget.");
    return r.isNotEmpty ? r : _fbDate(type);
  }

  Future<String> suggestGift({required String occasion}) async {
    final r = await chat("Sugiere 3 ideas de regalo creativas y romanticas para: $occasion.");
    return r.isNotEmpty ? r : _fbGift(occasion);
  }

  Future<String> generatePoem({required String style, required String topic}) async {
    final r = await chat("Escribe un poema de amor en espanol sobre $topic en estilo $style.");
    return r.isNotEmpty ? r : _fbPoem();
  }

  Future<String> generateSong({required String genre, required String details}) async {
    final r = await chat("Escribe letra de cancion romantica genero $genre inspirada en: $details.");
    return r.isNotEmpty ? r : _fbSong();
  }

  Future<String> generateStory({required String memoryTitle, required String details}) async {
    final r = await chat("Escribe una historia corta romantica basada en: '$memoryTitle'. Detalles: $details.");
    return r.isNotEmpty ? r : _fbStory(memoryTitle, details);
  }

  Future<String> answerQuestion({
    required String question,
    required List<MemoryModel> memories,
    required List<GoalModel> goals,
    required String partnerName,
  }) async {
    final memStr = memories.map((m) => "- ${m.title} (${m.date.day}/${m.date.month}/${m.date.year}): ${m.description}").join('\n');
    final goalStr = goals.map((g) => "- ${g.title} (${(g.progress * 100).toInt()}%)").join('\n');
    final r = await chat("Pregunta: '$question'.\nRecuerdos:\n$memStr\nMetas:\n$goalStr\nResponde de forma carinosa.");
    return r.isNotEmpty ? r : _fbQuestion(question, memories, goals, partnerName);
  }

  // -- Fallbacks --
  String _fallbackResponse(String q) {
    final ql = q.toLowerCase();
    if (ql.contains('hola') || ql.contains('buenos')) return 'Hola amor! Como estas hoy? En que puedo ayudarte?';
    if (ql.contains('te amo') || ql.contains('quiero')) return 'Yo tambien te quiero mucho! Eres la persona mas especial del mundo.';
    if (ql.contains('cita') || ql.contains('plan')) return 'Que tal un picnic al atardecer? Preparen algo rico y busquen un lugar bonito al aire libre.';
    if (ql.contains('regalo') || ql.contains('sorprender')) return 'Un frasco con 100 razones por las que la amas nunca falla. O un mapa de rascadito.';
    if (ql.contains('recuerdo') || ql.contains('recordar')) {
      final mems = _memory.memories;
      if (mems.isNotEmpty) {
        final m = mems[Random().nextInt(mems.length)];
        return "Me acuerdo de \"${m.key}\". Fue un momento especial para ustedes.";
      }
      return 'Aun estan creando sus recuerdos. Cada dia es una oportunidad.';
    }
    final r = [
      'El amor es un viaje, no un destino. Disfruten cada paso.',
      'La comunicacion es la llave maestra de toda relacion exitosa.',
      'Los pequenos gestos de amor diario construyen un amor inquebrantable.',
      'Lo mas valioso que pueden regalarse es tiempo de calidad juntos.',
    ];
    return r[Random().nextInt(r.length)];
  }

  String _fbLetter(String tone, String keywords) {
    final f = [
      "Mi amor,\n\nDesde que llegaste a mi vida todo tiene un brillo diferente. Pensaba en nosotros y en $keywords, y no pude evitar sonreir. Eres mi refugio, mi felicidad y la persona con la que quiero compartir cada amanecer.\n\nCon todo mi amor, hoy y siempre.",
      "Hola mi vida,\n\nEscribo esto pensando en ti. Cuando pienso en $keywords, me doy cuenta de lo afortunados que somos. Eres mi presente y mi futuro sonado.\n\nTuyo/a para siempre."
    ];
    return f[Random().nextInt(f.length)];
  }

  String _fbDate(String type) {
    final d = {
      'aventura': "Picnic al atardecer en un mirador. Lleven manta, snacks y una app de constelaciones.",
      'hogarena': "Noche de cocina tematica. Elijan un pais y cocinen juntos.",
      'cultural': "Busqueda del tesoro en una libreria.",
    };
    return d[type.toLowerCase()] ?? "Cena sorpresa a ciegas.";
  }

  String _fbGift(String occasion) {
    return "3 ideas:\n1. Frasco con '100 razones por las que te amo'.\n2. Mapa de rascadito.\n3. Lampara de constelacion.";
  }

  String _fbPoem() {
    return "En el vaiven del tiempo y de la brisa,\nbusco en tus ojos mi mejor destino,\ntu voz es la musica en mi camino,\ny mi paz se dibuja en tu sonrisa.";
  }

  String _fbSong() {
    return "[Estrofa I]\nCaminando en la lluvia sin direccion,\nencontre en tus ojos mi cancion.\n\n[Coro]\nPorque tu eres mi norte, mi constelacion,\nel latido constante de mi corazon.";
  }

  String _fbStory(String title, String details) {
    return "Habia una vez, dos almas llamadas a encontrarse. Aquel dia de '$title' quedo sellado en el libro del destino.";
  }

  String _fbQuestion(String question, List<MemoryModel> memories, List<GoalModel> goals, String partnerName) {
    final q = question.toLowerCase();
    if (q.contains('viaje') || q.contains('ir') || q.contains('conocer')) {
      final tg = goals.where((g) => g.category == 'travel').map((g) => g.title).join(', ');
      return "Veo que suenan con: $tg. Suena a un plan increible.";
    }
    if (memories.isNotEmpty) {
      final m = memories[Random().nextInt(memories.length)];
      return "Eso me recuerda a '${m.title}' el ${m.date.day}/${m.date.month}/${m.date.year}. Fue especial.";
    }
    return "Aun estan construyendo su caja de recuerdos.";
  }

  Future<String> generateTruthOrDare({required String type, required String category}) async {
    final r = await chat("Genera una frase corta en espanol para un juego de $type de pareja. Categoria: $category.");
    return r.isNotEmpty ? r : _fbTruthOrDare(type, category);
  }

  String _fbTruthOrDare(String type, String category) {
    if (type == 'verdad') {
      if (category == 'Atrevido') return "Cual es tu fantasia mas audaz?";
      if (category == 'Romanico') return "Que momento a mi lado te ha hecho sentir mas amado/a?";
      return "Que habito gracioso mio te da mas ternura?";
    } else {
      if (category == 'Atrevido') return "Dale un beso largo a tu pareja en el cuello durante 10 segundos.";
      if (category == 'Romanico') return "Escribele 3 cosas que admiras de ella.";
      return "Haz una imitacion de como tu pareja actua cuando tiene sueno.";
    }
  }
}
