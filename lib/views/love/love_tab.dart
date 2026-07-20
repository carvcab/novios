import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../services/user_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/page_transition.dart';
import 'anniversary_screen.dart';

class LoveTab extends StatefulWidget {
  const LoveTab({super.key});

  @override
  State<LoveTab> createState() => _LoveTabState();
}

class _LoveTabState extends State<LoveTab> {
  void _confirmDeleteEvent(List<Map<String, dynamic>> currentEvents, int indexToDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('¿Eliminar momento?'),
          ],
        ),
        content: const Text('¿Estás seguro de que quieres eliminar este momento especial de su historia para ambos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedEvents = List<Map<String, dynamic>>.from(currentEvents);
              updatedEvents.removeAt(indexToDelete);
              await FirebaseService().saveListData('timeline_events', updatedEvents);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return "${date.day} de ${months[date.month - 1]}, ${date.year}";
  }

  void _showAddEvent(String coupleId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedCategory = 'favorite';
    String selectedColorHex = 'FFFF7F7F';

    final List<Map<String, dynamic>> categoriesList = [
      {'id': 'favorite', 'name': 'Amor', 'icon': Icons.favorite_rounded, 'color': 'FFFF7F7F'},
      {'id': 'flight', 'name': 'Viaje', 'icon': Icons.flight_takeoff_rounded, 'color': 'FF66BB6A'},
      {'id': 'cake', 'name': 'Cumple', 'icon': Icons.cake_rounded, 'color': 'FF7C83FF'},
      {'id': 'star', 'name': 'Especial', 'icon': Icons.star_rounded, 'color': 'FFFFB74D'},
      {'id': 'movie', 'name': 'Cine', 'icon': Icons.movie_creation_rounded, 'color': 'FF8E24AA'},
      {'id': 'restaurant', 'name': 'Cena', 'icon': Icons.restaurant_rounded, 'color': 'FFD81B60'},
      {'id': 'gift', 'name': 'Regalo', 'icon': Icons.card_giftcard_rounded, 'color': 'FF00ACC1'},
      {'id': 'music', 'name': 'Música', 'icon': Icons.music_note_rounded, 'color': 'FF3949AB'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: selectedDate,
              firstDate: DateTime(1980),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('es', 'ES'),
            );
            if (picked != null) {
              setDialogState(() => selectedDate = picked);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Agregar momento especial 💖'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: '¿Qué pasó?',
                      hintText: 'Ej: Nuestro primer beso',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción / Nota (Opcional)',
                      hintText: 'Ej: Fue un día inolvidable...',
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today_rounded, color: cs.primary),
                    title: const Text('Fecha del momento', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      _formatDate(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 18),
                    onTap: pickDate,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Categoría:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoriesList.length,
                      itemBuilder: (ctx, i) {
                        final cat = categoriesList[i];
                        final isSel = selectedCategory == cat['id'];
                        final catColor = _parseColor(cat['color'] as String);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              cat['icon'] as IconData,
                              size: 16,
                              color: isSel ? Colors.white : catColor,
                            ),
                            label: Text(cat['name'] as String),
                            selected: isSel,
                            selectedColor: catColor,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : cs.onSurface,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() {
                                  selectedCategory = cat['id'] as String;
                                  selectedColorHex = cat['color'] as String;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  
                  List<Map<String, dynamic>> currentEvents = [];
                  try {
                    final doc = await FirebaseFirestore.instance
                        .collection('couples')
                        .doc(coupleId)
                        .collection('lists')
                        .doc('timeline_events')
                        .get();
                    if (doc.exists && doc.data() != null && doc.data()!['items'] is List) {
                      currentEvents = (doc.data()!['items'] as List)
                          .map((item) => Map<String, dynamic>.from(item as Map))
                          .toList();
                    }
                  } catch (e) {
                    debugPrint("Error loading existing events: $e");
                  }

                  final newEvent = {
                    'icon': selectedCategory,
                    'date': _formatDate(selectedDate),
                    'dateISO': selectedDate.toIso8601String(),
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'color': selectedColorHex,
                  };

                  currentEvents.add(newEvent);
                  
                  await FirebaseService().saveListData('timeline_events', currentEvents);
                  
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconData(String icon) {
    switch (icon) {
      case 'cake': return Icons.cake_rounded;
      case 'flight': return Icons.flight_takeoff_rounded;
      case 'star': return Icons.star_rounded;
      case 'movie': return Icons.movie_creation_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'gift': return Icons.card_giftcard_rounded;
      case 'music': return Icons.music_note_rounded;
      default: return Icons.favorite_rounded;
    }
  }

  Color _parseColor(String hex) {
    try {
      String cleanHex = hex.replaceAll('#', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse('0x$cleanHex'));
    } catch (_) {
      return const Color(0xFFFF7F7F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = FirebaseService().coupleId;

    return ListenableBuilder(
      listenable: UserService(),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final userName = LocalStorage().getUserName() ?? 'Tu';
        final partnerName = LocalStorage().getPartnerName() ?? 'Pareja';

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).snapshots(),
          builder: (context, coupleSnapshot) {
            final coupleData = coupleSnapshot.data?.data() as Map<String, dynamic>? ?? {};

            // Keep LocalStorage values in sync in real-time
            final remoteMet = coupleData['metDate'] as String?;
            if (remoteMet != null && remoteMet != LocalStorage().getMetDate()) {
              LocalStorage().setString('met_date', remoteMet);
            }
            final remoteDating = coupleData['datingDate'] as String?;
            if (remoteDating != null && remoteDating != LocalStorage().getDatingDate()) {
              LocalStorage().setString('dating_date', remoteDating);
            }
            final remoteAnn = coupleData['anniversaryDate'] as String?;
            if (remoteAnn != null && remoteAnn != LocalStorage().getAnniversaryDate()) {
              LocalStorage().setString('anniversary_date', remoteAnn);
            }
            final remoteWedding = coupleData['weddingDate'] as String?;
            if (remoteWedding != null && remoteWedding != LocalStorage().getWeddingDate()) {
              LocalStorage().setString('wedding_date', remoteWedding);
            }

            final annStr = remoteAnn ?? LocalStorage().getAnniversaryDate();
            final ann = annStr != null ? DateTime.tryParse(annStr) : null;
            final met = DateTime.tryParse(remoteMet ?? LocalStorage().getMetDate() ?? '');
            final dating = DateTime.tryParse(remoteDating ?? LocalStorage().getDatingDate() ?? '');
            final wedding = DateTime.tryParse(remoteWedding ?? LocalStorage().getWeddingDate() ?? '');

            final firstDate = [
              if (met != null) met,
              if (dating != null) dating,
              if (ann != null) ann,
              if (wedding != null) wedding,
            ].fold<DateTime?>(null, (prev, d) =>
                prev == null || d.isBefore(prev) ? d : prev);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildAnniversaryHero(cs, userName, partnerName, firstDate, ann),
                  const SizedBox(height: 20),
                  if (firstDate != null) _buildQuickStats(cs, firstDate, ann),
                  if (firstDate != null) const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.timeline_rounded, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('Nuestra Historia',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Real-time collaborative Timeline
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('couples')
                        .doc(coupleId)
                        .collection('lists')
                        .doc('timeline_events')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }

                      final docData = snapshot.data?.data() as Map<String, dynamic>?;
                      final rawItems = docData?['items'] as List<dynamic>? ?? [];
                      final eventsList = rawItems
                          .map((item) => Map<String, dynamic>.from(item as Map))
                          .toList();

                      eventsList.sort((a, b) {
                        final aDate = DateTime.tryParse(a['dateISO'] as String? ?? '') ?? DateTime(1970);
                        final bDate = DateTime.tryParse(b['dateISO'] as String? ?? '') ?? DateTime(1970);
                        return bDate.compareTo(aDate);
                      });

                      if (eventsList.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(Icons.timeline_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                                const SizedBox(height: 8),
                                Text(
                                  'Aún no hay momentos en su historia',
                                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          ...eventsList.asMap().entries.map((entry) {
                            final i = entry.key;
                            final e = entry.value;
                            return _TimelineItem(
                              icon: _iconData(e['icon'] as String? ?? 'favorite'),
                              date: e['date'] as String? ?? '',
                              title: e['title'] as String? ?? '',
                              description: e['description'] as String? ?? '',
                              color: _parseColor(e['color'] as String? ?? 'FFFF7F7F'),
                              isLast: i == eventsList.length - 1,
                              cs: cs,
                              onDelete: () => _confirmDeleteEvent(eventsList, i),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddEvent(coupleId),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Agregar recuerdo'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<UserModel>(
                    stream: FirebaseService().streamUser(LocalStorage().getUserId() ?? ''),
                    builder: (ctx, snap) {
                      final pts = snap.data?.lovePoints ?? 0;
                      return GlassCard(
                        glow: true,
                        glowColor: cs.primary,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_rounded, color: cs.primary, size: 24),
                              const SizedBox(width: 10),
                              Text('$pts puntos de amor',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnniversaryHero(ColorScheme cs, String userName,
      String partnerName, DateTime? firstDate, DateTime? ann) {
    final now = DateTime.now();
    final days = firstDate != null ? now.difference(firstDate).inDays : 0;
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    final remDays = days % 30;

    return GlassCard(
      glow: true,
      glowColor: cs.primary,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          SlideFadeRoute(page: const AnniversaryScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$userName  💕  $partnerName',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        const SizedBox(height: 4),
                        Text(firstDate != null
                            ? 'Juntos desde el ${firstDate.day}/${firstDate.month}/${firstDate.year}'
                            : 'Configura tus fechas',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
                ],
              ),
              if (firstDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$years años  $months meses  $remDays días',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: cs.primary),
                      ),
                      if (ann != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _nextAnniversaryText(ann),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ColorScheme cs, DateTime firstDate, DateTime? ann) {
    final now = DateTime.now();
    final totalDays = now.difference(firstDate).inDays;
    final totalHours = now.difference(firstDate).inHours;
    final totalMinutes = now.difference(firstDate).inMinutes;

    return Row(
      children: [
        Expanded(
          child: _StatMini(
            icon: Icons.calendar_today_rounded,
            value: '$totalDays',
            label: 'días',
            color: cs.primary,
            cs: cs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMini(
            icon: Icons.schedule_rounded,
            value: '$totalHours',
            label: 'horas',
            color: const Color(0xFF7C83FF),
            cs: cs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMini(
            icon: Icons.timer_rounded,
            value: '$totalMinutes',
            label: 'minutos',
            color: const Color(0xFFFFB74D),
            cs: cs,
          ),
        ),
      ],
    );
  }

  String _nextAnniversaryText(DateTime ann) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime next = DateTime(now.year, ann.month, ann.day);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, ann.month, ann.day);
    }
    final diff = next.difference(today);
    if (diff.inDays == 0) return '🎉 ¡Hoy es su aniversario!';
    if (diff.inDays == 1) return 'Mañana es su aniversario 💕';
    return 'Próximo aniversario: ${diff.inDays} días';
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String date, title, description;
  final Color color;
  final bool isLast;
  final ColorScheme cs;
  final VoidCallback onDelete;

  const _TimelineItem({
    required this.icon,
    required this.date,
    required this.title,
    required this.description,
    required this.color,
    required this.isLast,
    required this.cs,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.primary.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.65),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: cs.error.withValues(alpha: 0.7)),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  final ColorScheme cs;

  const _StatMini({required this.icon, required this.value, required this.label,
      required this.color, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
          Text(label,
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
