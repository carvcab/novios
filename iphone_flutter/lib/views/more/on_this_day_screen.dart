import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/memory_model.dart';
import '../../widgets/firestore_image.dart';

class OnThisDayScreen extends StatefulWidget {
  const OnThisDayScreen({super.key});

  @override
  State<OnThisDayScreen> createState() => _OnThisDayScreenState();
}

class _OnThisDayScreenState extends State<OnThisDayScreen> {
  final Random _random = Random();

  String _getYearsAgoLabel(int diffYears) {
    if (diffYears == 1) return 'Hace 1 Año 📅';
    return 'Hace $diffYears Años 📅';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hace un Año', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<MemoryModel>>(
        stream: FirebaseService().streamMemories(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allMemories = snap.data ?? [];

          // 1. Filtrar recuerdos exactos de este mismo día y mes en años pasados
          final exactMemories = allMemories.where((m) {
            return m.date.month == today.month &&
                m.date.day == today.day &&
                m.date.year < today.year;
          }).toList();

          // 2. Si no hay recuerdos exactos, buscar recuerdos de esta misma semana en años pasados (rango de +-3 días)
          List<MemoryModel> memoriesToShow = exactMemories;
          bool isAlternative = false;

          if (memoriesToShow.isEmpty) {
            isAlternative = true;
            memoriesToShow = allMemories.where((m) {
              final dayDiff = (m.date.day - today.day).abs();
              return m.date.month == today.month &&
                  dayDiff <= 3 &&
                  m.date.year < today.year;
            }).toList();
          }

          // Ordenar por año más antiguo primero (o más reciente)
          memoriesToShow.sort((a, b) => b.date.year.compareTo(a.date.year));

          if (memoriesToShow.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_toggle_off_rounded, size: 64, color: cs.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aún no hay recuerdos del pasado hoy',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando pase el tiempo y tengan recuerdos guardados en esta fecha, aparecerán aquí automáticamente para revivirlos juntos. ❤️',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isAlternative)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay recuerdos exactos de hoy, pero aquí tienen los recuerdos de esta misma semana en años anteriores.',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.8), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                'NUESTRO VIAJE EN EL TIEMPO',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...memoriesToShow.map((m) {
                final diffYears = today.year - m.date.year;
                // Rotación leve estilo scrapbook
                final angle = (_random.nextDouble() * 0.04) - 0.02;

                return Transform.rotate(
                  angle: angle,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header del Scrapbook Card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getYearsAgoLabel(diffYears),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            Text(
                              '${m.date.day}/${m.date.month}/${m.date.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Polaroid image frame
                        if (m.type == 'photo' && m.mediaPaths.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.only(bottom: 12, top: 4, left: 4, right: 4),
                            color: Colors.white,
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1.0,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: FirestoreImage(
                                      path: m.mediaPaths.first,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        Text(
                          m.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.description,
                          style: GoogleFonts.caveat(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.black12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.favorite_rounded, color: cs.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Para siempre',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
