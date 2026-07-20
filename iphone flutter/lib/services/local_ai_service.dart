import 'dart:math';
import 'package:onenm_local_llm/onenm_local_llm.dart';
import '../models/memory_model.dart';
import '../models/goal_model.dart';

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  OneNm? _llm;
  bool _isInitialized = false;
  bool _isLoading = false;
  String _status = 'No iniciado';
  double _downloadProgress = 0.0;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String get status => _status;
  double get downloadProgress => _downloadProgress;

  static const _model = ModelInfo(
    id: 'deepseek-r1-1.5b',
    name: 'DeepSeek R1 1.5B',
    fileName: 'DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
    ggufUrl: 'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
    sizeMB: 1120,
    minRamGB: 2,
    context: 8192,
    chatTemplate: ChatTemplate(
      system: '<|im_start|>system\n{text}<|im_end|>\n',
      user: '<|im_start|>user\n{text}<|im_end|>\n',
      assistant: '<|im_start|>assistant\n{text}<|im_end|>\n',
    ),
  );

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    _isLoading = true;
    _status = 'Preparando modelo...';

    try {
      _llm = OneNm(
        model: _model,
        settings: const GenerationSettings(
          temperature: 0.7,
          topK: 40,
          topP: 0.9,
          maxTokens: 512,
          repeatPenalty: 1.1,
        ),
        onProgress: (msg) {
          _status = msg;
          final match = RegExp(r'(\d+)%').firstMatch(msg);
          if (match != null) {
            _downloadProgress = int.parse(match.group(1)!) / 100.0;
          }
        },
        onRetryRequired: (_) async => false,
      );

      await _llm!.initialize();
      _isInitialized = true;
      _status = 'Modelo listo';
      _downloadProgress = 1.0;
    } catch (e) {
      _status = 'Error: $e';
      _isInitialized = false;
      _llm = null;
    } finally {
      _isLoading = false;
    }
  }

  Future<String> chat(String prompt) async {
    if (!_isInitialized || _llm == null) return '';

    try {
      _llm!.clearHistory();
      final response = await _llm!.chat(
        prompt,
        systemPrompt: 'Eres un asistente romantico y carinoso para una app de parejas. Responde en espanol, de forma calida, poetica y emotiva. Se conciso (maximo 3 parrafos).',
      );
      return response.trim();
    } catch (e) {
      return '';
    }
  }

  Future<void> dispose() async {
    if (_llm != null) {
      try {
        await _llm!.dispose();
      } catch (_) {}
      _llm = null;
    }
    _isInitialized = false;
    _status = 'No iniciado';
    _downloadProgress = 0.0;
  }

  // --- Generators with fallback ---

  Future<String> generateLetter({required String tone, required String keywords}) async {
    final result = await chat("Escribe una carta de amor en espanol con tono $tone. Incluye: $keywords. Hazla emotiva, poetica y en parrafos.");
    return result.isNotEmpty ? result : _fbLetter(tone, keywords);
  }

  Future<String> suggestDate({required String type, required String budget}) async {
    final result = await chat("Sugiere una cita romantica en espanol. Categoria: $type. Presupuesto: $budget. Explica el plan paso a paso.");
    return result.isNotEmpty ? result : _fbDate(type);
  }

  Future<String> suggestGift({required String occasion}) async {
    final result = await chat("Sugiere 3 ideas de regalo creativas y romanticas para: $occasion. Incluye DIY, experiencia y fisico.");
    return result.isNotEmpty ? result : _fbGift(occasion);
  }

  Future<String> generatePoem({required String style, required String topic}) async {
    final result = await chat("Escribe un poema de amor en espanol sobre $topic en estilo $style. Lirico, emotivo, con rima o verso libre.");
    return result.isNotEmpty ? result : _fbPoem();
  }

  Future<String> generateSong({required String genre, required String details}) async {
    final result = await chat("Escribe letra de cancion romantica genero $genre inspirada en: $details. Incluye Estrofa I, Coro, Estrofa II, Puente y Coro Final.");
    return result.isNotEmpty ? result : _fbSong();
  }

  Future<String> generateStory({required String memoryTitle, required String details}) async {
    final result = await chat("Escribe una historia corta romantica y magica basada en: '$memoryTitle'. Detalles: $details. Conmovedora.");
    return result.isNotEmpty ? result : _fbStory(memoryTitle, details);
  }

  Future<String> answerQuestion({
    required String question,
    required List<MemoryModel> memories,
    required List<GoalModel> goals,
    required String partnerName,
  }) async {
    final memStr = memories.map((m) => "- ${m.title} (${m.date.day}/${m.date.month}/${m.date.year}): ${m.description}").join('\n');
    final goalStr = goals.map((g) => "- ${g.title} (${(g.progress * 100).toInt()}%)").join('\n');
    final result = await chat("Eres la IA de esta relacion. Pregunta: '$question'.\nRecuerdos:\n$memStr\nMetas:\n$goalStr\nResponde de forma carinosa y creativa. Invita a crear nuevos recuerdos con $partnerName.");
    return result.isNotEmpty ? result : _fbQuestion(question, memories, goals, partnerName);
  }

  // --- Fallbacks ---

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
      'hogarena': "Noche de cocina tematica. Elijan un pais y cocinen juntos. Decoren con velas y pongan musica.",
      'cultural': "Busqueda del tesoro en una libreria. Elijan un libro para el otro con retos divertidos.",
    };
    return d[type.toLowerCase()] ?? "Cena sorpresa a ciegas. Cocinen un plato secreto y usen una venda para adivinar.";
  }

  String _fbGift(String occasion) {
    return "3 ideas para $occasion:\n\n1. Hecho a mano: Frasco con '100 razones por las que te amo'.\n2. Experiencia: Mapa de rascadito con lugares para visitar.\n3. Fisico: Lampara con la constelacion del dia que se conocieron.";
  }

  String _fbPoem() {
    return "En el vaiven del tiempo y de la brisa,\nbusco en tus ojos mi mejor destino,\ntu voz es la musica en mi camino,\ny mi paz se dibuja en tu sonrisa.\n\nEres el sol que alumbra mi manana,\nel dulce abismo donde quiero estar,\namarte es mi verdad mas soberana,\nun cielo eterno frente a nuestro mar.";
  }

  String _fbSong() {
    return "[Estrofa I]\nCaminando en la lluvia sin direccion,\nencontre en tus ojos mi cancion.\n\n[Coro]\nPorque tu eres mi norte, mi constelacion,\nel latido constante de mi corazon.\n\n[Estrofa II]\nEn tus brazos la noche se vuelve azul,\nllenas cada espacio con tu dulce luz...";
  }

  String _fbStory(String title, String details) {
    return "Habia una vez, dos almas llamadas a encontrarse. Aquel dia de '$title' quedo sellado en el libro del destino.\n\nCuando compartieron ese momento ($details), el universo brillo un poco mas.";
  }

  String _fbQuestion(String question, List<MemoryModel> memories, List<GoalModel> goals, String partnerName) {
    final q = question.toLowerCase();
    if (q.contains('viaje') || q.contains('ir') || q.contains('conocer')) {
      final tg = goals.where((g) => g.category == 'travel').map((g) => g.title).join(', ');
      return "Veo que sueñan con: $tg. Suena a un plan increíble para su próxima aventura juntos.";
    }
    if (memories.isNotEmpty) {
      final m = memories[Random().nextInt(memories.length)];
      return "Eso me recuerda a '${m.title}' el ${m.date.day}/${m.date.month}/${m.date.year}. Fue especial. ¿No les gustaría repetirlo?";
    }
    return "Aún están construyendo su caja de recuerdos. Es el momento perfecto para escribir una carta o planear su próximo gran sueño juntos.";
  }

  Future<String> generateTruthOrDare({required String type, required String category}) async {
    final prompt = "Genera una sola frase corta en espanol para un juego de $type de pareja. Categoria: $category. Debe ser divertida, interactiva, emocionante y respetuosa pero picante si es atrevida. Responde con solo el texto del reto/verdad, sin introducciones.";
    final result = await chat(prompt);
    return result.isNotEmpty ? result : _fbTruthOrDare(type, category);
  }

  String _fbTruthOrDare(String type, String category) {
    if (type.toLowerCase() == 'verdad') {
      if (category == 'Atrevido') {
        return "¿Cuál es tu fantasía romántica más audaz que aún no hemos realizado?";
      } else if (category == 'Romántico') {
        return "¿Qué momento a mi lado te ha hecho sentir más amado/a?";
      } else {
        return "¿Qué hábito gracioso mío te da más ternura?";
      }
    } else {
      if (category == 'Atrevido') {
        return "Dale un beso largo y apasionado a tu pareja en el cuello durante 10 segundos.";
      } else if (category == 'Romántico') {
        return "Escríbele un mensaje rápido al celular diciéndole 3 cosas que admiras de ella.";
      } else {
        return "Haz una imitación exagerada de cómo tu pareja actúa cuando tiene sueño.";
      }
    }
  }
}
