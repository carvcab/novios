import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../letters/letters_tab.dart';
import '../games/games_tab.dart';
import '../location/location_tab.dart';
import '../../widgets/page_transition.dart';
import '../screenview/screen_view_screen.dart';
import '../notes/notes_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../dreams/dreams_screen.dart';
import '../planner/planner_tab.dart';
import '../music/music_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _streak = 0;
  List<Map<String, dynamic>> _dates = [];

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _loadDates();
  }

  void _loadStreak() {
    final partnerUid = LocalStorage().getString('partner_uid');
    final isPaired = partnerUid != null && partnerUid.isNotEmpty;
    if (!isPaired) {
      _streak = 0;
      return;
    }

    final lastDate = LocalStorage().getString('last_streak_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastDate != todayStr) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

      if (lastDate != yesterdayStr) {
        _streak = 1;
      } else {
        _streak = LocalStorage().getInt('streak_count', defaultValue: 1) + 1;
        if (_streak > 999) _streak = 999;
      }
      LocalStorage().setInt('streak_count', _streak);
      LocalStorage().setString('last_streak_date', todayStr);
      FirebaseService().saveAllSettings(
        streakCount: _streak,
        lastStreakDate: todayStr,
      );
    } else {
      _streak = LocalStorage().getInt('streak_count', defaultValue: 1);
    }
  }

  void _loadDates() {
    _dates = LocalStorage().getLocalList('important_dates');
  }

  void _saveDates() {
    FirebaseService().saveListData('important_dates', _dates);
  }

  DateTime _nextDate(DateTime date, bool repeats) {
    if (!repeats) return date;
    final now = DateTime.now();
    final thisYear = DateTime(now.year, date.month, date.day);
    if (thisYear.isBefore(now) || thisYear.isAtSameMomentAs(now)) {
      return DateTime(now.year + 1, date.month, date.day);
    }
    return thisYear;
  }

  String _formatCounter(DateTime date, bool repeats) {
    final target = _nextDate(date, repeats);
    final diff = target.difference(DateTime.now()).inDays;
    if (diff > 0) return 'Faltan $diff dias';
    if (diff == 0) return 'Hoy!';
    final past = DateTime.now().difference(date).inDays;
    return '$past dias desde entonces';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ProfileHeader(cs: cs),
          const SizedBox(height: 20),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 10),
                  Text('Racha: $_streak días seguidos 🔥',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildImportantDates(cs),
          const SizedBox(height: 24),
          _buildActionGrid(cs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildImportantDates(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text('Fechas Importantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.add_rounded, color: cs.primary, size: 20),
                onPressed: _addDate,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_dates.isEmpty)
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.date_range_rounded, size: 36, color: cs.onSurface.withValues(alpha: 0.15)),
                    const SizedBox(height: 8),
                    Text('No hay fechas importantes aun',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _addDate,
                      icon: Icon(Icons.add_rounded, size: 16, color: cs.primary),
                      label: Text('Agregar fecha', style: TextStyle(color: cs.primary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._dates.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final title = d['title'] ?? '';
            final dateStr = d['date'] ?? '';
            final date = DateTime.tryParse(dateStr);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  onTap: () => _editDate(i),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.favorite_rounded, color: cs.primary, size: 20),
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year} - ${_formatCounter(date, d['repeats'] == true)}'
                        : 'Fecha no válida',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: cs.onSurface.withValues(alpha: 0.3), size: 20),
                    onPressed: () {
                      setState(() {
                        _dates.removeAt(i);
                        _saveDates();
                      });
                    },
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _editDate(int index) {
    final d = _dates[index];
    final nameCtrl = TextEditingController(text: d['title']);
    DateTime selected = DateTime.tryParse(d['date'] ?? '') ?? DateTime.now();
    bool repeats = d['repeats'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Editar fecha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la fecha',
                  hintText: 'Ej: Aniversario, Primera cita...',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selected,
                    firstDate: DateTime(1980),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => selected = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('${selected.day}/${selected.month}/${selected.year}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Se repite cada año', style: TextStyle(fontSize: 14)),
                value: repeats,
                onChanged: (v) => setDialogState(() => repeats = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _dates.removeAt(index);
                  _saveDates();
                });
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _dates[index] = {
                    'title': nameCtrl.text.trim(),
                    'date': selected.toIso8601String().split('T')[0],
                    'repeats': repeats,
                  };
                  _saveDates();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addDate() {
    final nameCtrl = TextEditingController();
    DateTime selected = DateTime.now();
    bool repeats = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.favorite_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Nueva fecha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la fecha',
                  hintText: 'Ej: Aniversario, Primera cita...',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selected,
                    firstDate: DateTime(1980),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => selected = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('${selected.day}/${selected.month}/${selected.year}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Se repite cada año', style: TextStyle(fontSize: 14)),
                value: repeats,
                onChanged: (v) => setDialogState(() => repeats = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _dates.add({
                    'title': nameCtrl.text.trim(),
                    'date': selected.toIso8601String().split('T')[0],
                    'repeats': repeats,
                  });
                  _saveDates();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(ColorScheme cs) {
    final actions = [
      _ActionItem(Icons.screen_share_rounded, 'Pantalla Compartida', _openScreenView),
      _ActionItem(Icons.sticky_note_2_rounded, 'Notas', _openNotes),
      _ActionItem(Icons.auto_awesome_rounded, 'Lista de Deseos', _openWishlist),
      _ActionItem(Icons.nights_stay_rounded, 'Sueños', _openDreams),
      _ActionItem(Icons.list_alt_rounded, 'Planificador', _openPlanner),
      _ActionItem(Icons.music_note_rounded, 'Música', _openMusic),
      _ActionItem(Icons.calendar_month_rounded, 'Fechas Importantes', _openCalendar),
      _ActionItem(Icons.mail_outline_rounded, 'Cartas', _openLetters),
      _ActionItem(Icons.sports_esports_rounded, 'Juegos', _openGames),
      _ActionItem(Icons.location_on_rounded, 'Mapa', _openMap),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text('Accesos rápidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          ],
        ),
        const SizedBox(height: 12),
        Column(children: actions.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, color: cs.primary, size: 22),
              ),
              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.4)),
              onTap: a.onTap,
            ),
          ),
        )).toList()),
      ],
    );
  }

  void _openMusic() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MusicScreen()),
    );
  }

  void _openCalendar() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _CalendarContent(),
        ),
      ),
    );
  }

  void _openLetters() => Navigator.push(context, MaterialPageRoute(builder: (_) => const LettersTab()));
  void _openGames() => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesTab()));
  void _openMap() => Navigator.push(context, SlideFadeRoute(page: const LocationTab()));
  void _openScreenView() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenViewScreen()));
  void _openNotes() => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
  void _openWishlist() => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
  void _openDreams() => Navigator.push(context, MaterialPageRoute(builder: (_) => const DreamsScreen()));
  void _openPlanner() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerTab()));
}

class _ProfileHeader extends StatelessWidget {
  final ColorScheme cs;

  const _ProfileHeader({required this.cs});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final myName = auth.myName;
    final partnerName = auth.partnerName;
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    final myInitial = myName.isNotEmpty ? myName[0].toUpperCase() : '?';
    final partnerInitial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';

    return Column(
      children: [
        SizedBox(
          height: 110,
          width: 150,
          child: Stack(
            children: [
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.secondary.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Center(
                      child: Text(partnerInitial, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.secondary)),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 5,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.25),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(photoUrl, fit: BoxFit.cover, width: 86, height: 86, errorBuilder: (_, __, ___) => Center(
                            child: Text(myInitial, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: cs.primary)),
                          ))
                        : Center(
                            child: Text(myInitial, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: cs.primary)),
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 70,
                top: 40,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text('💞', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
              children: [
                TextSpan(text: myName),
                WidgetSpan(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.favorite_rounded, size: 18, color: cs.primary),
                )),
                TextSpan(text: partnerName),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.title, this.onTap);
}

// ── Music Sheet Unified ──

// ── CALENDAR ──
class _CalendarContent extends StatefulWidget {
  @override
  State<_CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<_CalendarContent> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dates = LocalStorage().getLocalList('important_dates');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Fechas Importantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 16),
        if (dates.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Agrega fechas desde la seccion de arriba',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.center),
          )
        else
          ...dates.map((d) {
            final date = DateTime.tryParse(d['date'] ?? '');
            final repeats = d['repeats'] == true;
            final title = d['title'] ?? '';
            final target = !repeats ? date : _nextOccurrence(date!);
            final diff = target != null ? target.difference(DateTime.now()).inDays : 0;
            final counter = date != null
                ? (diff > 0 ? 'Faltan $diff dias' : diff == 0 ? 'Hoy!' : '${-diff} dias desde entonces')
                : '';
            return ListTile(
              leading: Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(repeats ? Icons.loop_rounded : Icons.favorite_rounded, color: cs.primary, size: 20)),
              title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
              subtitle: Text(
                date != null ? '${date.day}/${date.month}/${date.year} - $counter' : 'Fecha no valida',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12)),
            );
          }),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }

  DateTime? _nextOccurrence(DateTime date) {
    final now = DateTime.now();
    final thisYear = DateTime(now.year, date.month, date.day);
    if (thisYear.isBefore(now) || thisYear.isAtSameMomentAs(now)) {
      return DateTime(now.year + 1, date.month, date.day);
    }
    return thisYear;
  }
}
