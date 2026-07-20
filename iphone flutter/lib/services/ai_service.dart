import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/memory_model.dart';
import '../models/goal_model.dart';
import 'local_storage.dart';
import 'local_ai_service.dart';

enum AIMode { deepseek, local }

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String? get _deepseekKey => LocalStorage().getString('deepseek_api_key');

  bool get hasApiKey => _deepseekKey != null && _deepseekKey!.isNotEmpty;

  AIMode get currentMode {
    final mode = LocalStorage().getString('ai_mode') ?? 'local';
    return mode == 'local' ? AIMode.local : AIMode.deepseek;
  }

  Future<void> setMode(AIMode mode) async {
    await LocalStorage().setString('ai_mode', mode.toString().split('.').last);
  }

  Future<void> saveDeepseekKey(String key) async {
    await LocalStorage().setString('deepseek_api_key', key);
  }

  Future<String> _callDeepSeek(String prompt) async {
    final key = _deepseekKey;
    if (key == null || key.isEmpty) return '';

    try {
      final url = Uri.parse('https://api.deepseek.com/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un asistente romantico y carinoso para una app de parejas. Responde en espanol, de forma calida y poetica. Se conciso.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 800,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['choices'][0]['message']['content'] as String).trim();
      } else {
        debugPrint('DeepSeek API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('DeepSeek connection error: $e');
    }
    return '';
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
      'aventura': 'Picnic en el mirador al atardecer. Lleven manta, snacks y una app de constelaciones.',
      'hogarena': 'Noche de cocina tematica. Elijan un pais y cocinen juntos. Decoren con velas y pongan musica.',
      'cultural': 'Busqueda del tesoro en una libreria. Elijan un libro para el otro con retos.',
    };
    return d[type.toLowerCase()] ?? 'Cena sorpresa a ciegas. Cocinen un plato secreto y usen una venda para adivinar.';
  }

  String _fbGift(String occasion) {
    return '3 ideas para $occasion:\n\n'
        '1. Hecho a mano: Frasco con "100 razones por las que te amo".\n'
        '2. Experiencia: Mapa de rascadito con lugares para visitar.\n'
        '3. Fisico: Lampara con la constelacion del dia que se conocieron.';
  }

  String _fbPoem() {
    return "En el vaiven del tiempo y de la brisa,\n"
        "busco en tus ojos mi mejor destino,\n"
        "tu voz es la musica en mi camino,\n"
        "y mi paz se dibuja en tu sonrisa.\n\n"
        "Eres el sol que alumbra mi manana,\n"
        "el dulce abismo donde quiero estar,\n"
        "amarte es mi verdad mas soberana,\n"
        "un cielo eterno frente a nuestro mar.";
  }

  String _fbSong() {
    return "[Estrofa I]\nCaminando en la lluvia sin direccion,\n"
        "encontre en tus ojos mi cancion.\n\n"
        "[Coro]\nPorque tu eres mi norte, mi constelacion,\n"
        "el latido constante de mi corazon.\n\n"
        "[Estrofa II]\nEn tus brazos la noche se vuelve azul,\n"
        "llenas cada espacio con tu dulce luz...";
  }

  String _fbStory(String title, String details) {
    return "Habia una vez, dos almas llamadas a encontrarse. Aquel dia de '$title' quedo sellado en el libro del destino.\n\n"
        "Cuando compartieron ese momento ($details), el universo brillo un poco mas.";
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

  // --- PUBLIC AI METHODS ---

  Future<String> generateLetter({required String tone, required String keywords}) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().generateLetter(tone: tone, keywords: keywords);
    }
    final prompt = "Escribe una carta de amor en espanol con tono $tone. Incluye: $keywords. Hazla emotiva, poetica y en parrafos.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbLetter(tone, keywords);
  }

  Future<String> suggestDate({required String type, required String budget}) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().suggestDate(type: type, budget: budget);
    }
    final prompt = "Sugiere una cita romantica en espanol. Categoria: $type. Presupuesto: $budget. Explica el plan paso a paso.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbDate(type);
  }

  Future<String> suggestGift({required String occasion}) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().suggestGift(occasion: occasion);
    }
    final prompt = "Sugiere 3 ideas de regalo creativas y romanticas para: $occasion. Incluye DIY, experiencia y fisico.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbGift(occasion);
  }

  Future<String> generatePoem({required String style, required String topic}) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().generatePoem(style: style, topic: topic);
    }
    final prompt = "Escribe un poema de amor en espanol sobre $topic en estilo $style. Lirico, emotivo, con rima o verso libre.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbPoem();
  }

  Future<String> generateSong({required String genre, required String details}) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().generateSong(genre: genre, details: details);
    }
    final prompt = "Escribe letra de cancion romantica genero $genre inspirada en: $details. Incluye Estrofa I, Coro, Estrofa II, Puente y Coro Final.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbSong();
  }

  Future<String> generateStory({required String memoryTitle, required String details}) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().generateStory(memoryTitle: memoryTitle, details: details);
    }
    final prompt = "Escribe una historia corta romantica y magica basada en: '$memoryTitle'. Detalles: $details. Conmovedora.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbStory(memoryTitle, details);
  }

  Future<String> answerRelationshipQuestion({
    required String question,
    required List<MemoryModel> memories,
    required List<GoalModel> goals,
    required String partnerName,
  }) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().answerQuestion(
        question: question,
        memories: memories,
        goals: goals,
        partnerName: partnerName,
      );
    }
    final memStr = memories.map((m) => "- ${m.title} (${m.date.day}/${m.date.month}/${m.date.year}): ${m.description}").join('\n');
    final goalStr = goals.map((g) => "- ${g.title} (${(g.progress * 100).toInt()}%)").join('\n');
    final prompt = "Eres la IA de esta relacion. Pregunta: '$question'.\nRecuerdos:\n$memStr\nMetas:\n$goalStr\nResponde de forma carinosa y creativa. Invita a crear nuevos recuerdos con $partnerName.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbQuestion(question, memories, goals, partnerName);
  }

  Future<String> generateTruthOrDare({required String type, required String category}) async {
    if (currentMode == AIMode.local) {
      return LocalAIService().generateTruthOrDare(type: type, category: category);
    }
    final prompt = "Genera una sola frase corta en espanol para un juego de $type de pareja. Categoria: $category. Debe ser divertida, interactiva, emocionante y respetuosa pero picante si es atrevida. Responde con solo el texto del reto/verdad, sin introducciones.";
    final r = await _callDeepSeek(prompt);
    return r.isNotEmpty ? r : _fbTruthOrDare(type, category);
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

  Future<String> ask(String prompt, String systemPrompt) async {
    if (currentMode == AIMode.local) {
      try {
        final result = await LocalAIService().chat(prompt);
        return result;
      } catch (_) {
        return '';
      }
    }
    final r = await _callDeepSeek(prompt);
    return r;
  }
}
