import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../widgets/glass_card.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Estadisticas')),
      body: FutureBuilder<Map<String, int>>(
        future: _loadStats(),
        builder: (ctx, snap) {
          final stats = snap.data ?? {};
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatRow(icon: Icons.chat_rounded, label: 'Mensajes', value: '${stats['messages'] ?? 0}', color: cs.primary, cs: cs),
                const SizedBox(height: 10),
                _StatRow(icon: Icons.photo_library_rounded, label: 'Fotos', value: '${stats['memories'] ?? 0}', color: const Color(0xFF7C83FF), cs: cs),
                const SizedBox(height: 10),
                _StatRow(icon: Icons.mail_outline_rounded, label: 'Cartas', value: '${stats['letters'] ?? 0}', color: const Color(0xFFFF7F7F), cs: cs),
                const SizedBox(height: 10),
                _StatRow(icon: Icons.flight_takeoff_rounded, label: 'Viajes', value: '${stats['trips'] ?? 0}', color: const Color(0xFF66BB6A), cs: cs),
                const SizedBox(height: 10),
                _StatRow(icon: Icons.favorite_rounded, label: 'Puntos de amor', value: '${stats['points'] ?? 0}', color: const Color(0xFFFFB74D), cs: cs),
                const SizedBox(height: 24),

                // Streak
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28),
                        const SizedBox(width: 10),
                        Text('Racha: ${LocalStorage().getInt('streak_count', defaultValue: 1)} dias',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Days together
                _buildDaysCounter(cs),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaysCounter(ColorScheme cs) {
    final ann = DateTime.tryParse(LocalStorage().getAnniversaryDate() ?? '');
    if (ann == null) return const SizedBox();
    final days = DateTime.now().difference(ann).inDays;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 10),
            Text('$days dias juntos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _loadStats() async {
    final firebase = FirebaseService();
    try {
      final msgs = await firebase.getMessageCount();
      final mems = await firebase.getMemoryCount();
      final letters = LocalStorage().getLocalList('letters').length;
      final points = LocalStorage().getInt('love_points', defaultValue: 0);
      return {
        'messages': msgs,
        'memories': mems,
        'letters': letters,
        'trips': 0,
        'points': points,
      };
    } catch (_) {
      return {'messages': 0, 'memories': 0, 'letters': 0, 'trips': 0, 'points': 0};
    }
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final ColorScheme cs;

  const _StatRow({required this.icon, required this.label, required this.value, required this.color, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 15, color: cs.onSurface)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
