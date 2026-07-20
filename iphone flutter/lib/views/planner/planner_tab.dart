import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/planner_model.dart';
import '../../widgets/glass_card.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'movie';
  bool _doneTogether = false;

  final List<Map<String, String>> _dateIdeas = [
    {
      'title': 'Cine bajo las Estrellas 🌌',
      'desc': 'Preparen mantas en la terraza o jardín, usen un proyector o laptop, y vean su película romántica favorita acompañados de palomitas dulces y luces tenues.'
    },
    {
      'title': 'Pícnic en la Sala 🧺',
      'desc': 'Pongan un mantel de cuadros en el suelo de la sala, preparen aperitivos rápidos (quesos, uvas, sándwiches) y disfruten de música suave en segundo plano.'
    },
    {
      'title': 'Cena Temática de Viaje ✈️',
      'desc': 'Elijan un país al que les gustaría viajar juntos (Italia, Japón, México) y preparen o pidan comida típica de ese país mientras ven un documental del lugar.'
    },
    {
      'title': 'Noche de Juegos de Mesa 🎲',
      'desc': 'Reúnan sus juegos de mesa favoritos (o cartas) y jueguen rondas donde el perdedor tiene que hacerle un masaje al ganador o prepararle su postre favorito.'
    },
    {
      'title': 'Maratón de Recuerdos 📸',
      'desc': 'Junten todas las fotos y videos que se han tomado desde que se conocieron, preparen una bebida rica y dediquen la noche a recordar los momentos divertidos.'
    },
    {
      'title': 'Sesión de Cocina Juntos 🧑‍🍳',
      'desc': 'Elijan una receta dulce o plato complejo que nunca hayan preparado, pónganse música y diviértanse cocinándola desde cero en equipo.'
    },
    {
      'title': 'Cápsula del Tiempo Romántica ⏳',
      'desc': 'Escriban cartas contándose cómo se ven en 5 años, junten pequeños recuerdos de hoy y guárdenlos en una cajita especial para abrirla en una fecha futura pactada.'
    },
    {
      'title': 'Paseo de Fotos por la Ciudad 🗺️',
      'desc': 'Salgan a caminar por un barrio bonito de su ciudad con el único objetivo de tomarse fotos creativas u artísticas entre sí.'
    },
    {
      'title': 'Noche de Preguntas Profundas 💬',
      'desc': 'Busquen preguntas interesantes o usen tarjetas de conversación para conocerse aún más a fondo, hablando de sus mayores sueños, miedos y recuerdos tiernos.'
    },
    {
      'title': 'Spa en Casa 🕯️',
      'desc': 'Enciendan velas aromáticas, pongan música ambiental zen y preparen masajes relajantes mutuos con aceites perfumados y mascarillas faciales.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Agregar Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción / Notas'),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'movie', child: Row(children: [Icon(Icons.movie_rounded, size: 18), SizedBox(width: 8), Text('Película')])),
                    DropdownMenuItem(value: 'series', child: Row(children: [Icon(Icons.tv_rounded, size: 18), SizedBox(width: 8), Text('Serie')])),
                    DropdownMenuItem(value: 'restaurant', child: Row(children: [Icon(Icons.restaurant_rounded, size: 18), SizedBox(width: 8), Text('Restaurante')])),
                    DropdownMenuItem(value: 'trip', child: Row(children: [Icon(Icons.flight_takeoff_rounded, size: 18), SizedBox(width: 8), Text('Viaje')])),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => _type = v);
                  },
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Hecho juntos'),
                  value: _doneTogether,
                  onChanged: (v) => setDialogState(() => _doneTogether = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (_titleCtrl.text.trim().isEmpty) return;
                final item = PlannerModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _titleCtrl.text.trim(),
                  description: _descCtrl.text.trim(),
                  type: _type,
                  doneTogether: _doneTogether,
                  dateAdded: DateTime.now(),
                );
                await FirebaseService().savePlanner(item);
                _titleCtrl.clear();
                _descCtrl.clear();
                setDialogState(() => _doneTogether = false);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDone(PlannerModel item) async {
    final updated = PlannerModel(
      id: item.id,
      title: item.title,
      description: item.description,
      type: item.type,
      doneTogether: !item.doneTogether,
      dateAdded: item.dateAdded,
    );
    await FirebaseService().savePlanner(updated);
    if (updated.doneTogether) {
      FirebaseService().sendActivityNotification('Completó un plan: "${item.title}" 🏆', 'planner', icon: 'done');
    }
  }

  void _deleteItem(PlannerModel item) async {
    await FirebaseService().deletePlanner(item.id);
  }

  void _showSurpriseDateGenerator() {
    final rand = Random();
    Map<String, String> currentIdea = _dateIdeas[rand.nextInt(_dateIdeas.length)];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161524),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: const Color(0xFFFFD54F), size: 24),
                const SizedBox(width: 8),
                Text('Idea Sorpresa de Cita 💡', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentIdea['title']!,
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFFF5C8A)),
                ),
                const SizedBox(height: 12),
                Text(
                  currentIdea['desc']!,
                  style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: TextButton.styleFrom(foregroundColor: Colors.white38),
                child: const Text('Cerrar'),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
                onPressed: () {
                  setDialogState(() {
                    currentIdea = _dateIdeas[rand.nextInt(_dateIdeas.length)];
                  });
                },
                tooltip: 'Sugerir otra idea',
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final now = DateTime.now();
                  final item = PlannerModel(
                    id: now.millisecondsSinceEpoch.toString(),
                    title: currentIdea['title']!,
                    description: currentIdea['desc']!,
                    type: 'place',
                    doneTogether: false,
                    dateAdded: now,
                  );
                  await FirebaseService().savePlanner(item);
                  FirebaseService().sendActivityNotification('Añadió plan sorpresa: "${item.title}" 💡', 'planner', icon: 'lightbulb');
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Plan "${currentIdea['title']}" añadido al organizador.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5C8A), foregroundColor: Colors.white),
                child: const Text('¡Hagámoslo! 💖'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'movie': return Icons.movie_rounded;
      case 'series': return Icons.tv_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'trip': return Icons.flight_takeoff_rounded;
      default: return Icons.calendar_today_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'movie': return const Color(0xFF4FC3F7);
      case 'series': return const Color(0xFFFFB74D);
      case 'restaurant': return const Color(0xFFFF7F7F);
      case 'trip': return const Color(0xFF7C83FF);
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = cs.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0912) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        title: Text('Organizador de Planes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: cs.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFD54F)),
            onPressed: _showSurpriseDateGenerator,
            tooltip: 'Idea Sorpresa de Cita',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tab bar styling
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? const Color(0xFFFF5C8A) : cs.primary,
                ),
                labelColor: isDark ? Colors.white : cs.onSurface,
                unselectedLabelColor: cs.onSurface.withValues(alpha: 0.38),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.movie_rounded, size: 18)),
                  Tab(icon: Icon(Icons.tv_rounded, size: 18)),
                  Tab(icon: Icon(Icons.restaurant_rounded, size: 18)),
                  Tab(icon: Icon(Icons.flight_takeoff_rounded, size: 18)),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: ['movie', 'series', 'restaurant', 'trip'].map((type) {
                return _buildList(primary, type);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: isDark ? const Color(0xFFFF5C8A) : cs.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildList(Color primary, String filterType) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<PlannerModel>>(
      stream: FirebaseService().streamPlanner(),
      builder: (ctx, snap) {
        final all = snap.data ?? [];
        final items = all.where((i) => i.type == filterType).toList();
        final typeColor = _colorForType(filterType);

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconForType(filterType), size: 64, color: cs.onSurface.withValues(alpha: 0.1)),
                const SizedBox(height: 12),
                Text(
                  'No hay planes listados aún',
                  style: GoogleFonts.outfit(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteItem(item),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                ),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconForType(item.type), color: typeColor, size: 24),
                    ),
                    title: Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: item.doneTogether ? cs.onSurface.withValues(alpha: 0.38) : cs.onSurface,
                        decoration: item.doneTogether ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: (item.description != null && item.description!.isNotEmpty)
                        ? Text(
                            item.description!,
                            style: TextStyle(color: item.doneTogether ? cs.onSurface.withValues(alpha: 0.24) : cs.onSurface.withValues(alpha: 0.7), fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: GestureDetector(
                      onTap: () => _toggleDone(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.doneTogether ? Colors.green.withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.05),
                          border: Border.all(
                            color: item.doneTogether ? Colors.green : cs.onSurface.withValues(alpha: 0.24),
                            width: 2,
                          ),
                        ),
                        child: item.doneTogether
                            ? const Icon(Icons.check_rounded, color: Colors.green, size: 16)
                            : const SizedBox(width: 16, height: 16),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
