import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/local_storage.dart';
import '../../services/firebase_service.dart';
import '../../services/user_service.dart';
import '../../widgets/glass_card.dart';

class AnniversaryScreen extends StatefulWidget {
  const AnniversaryScreen({super.key});

  @override
  State<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<AnniversaryScreen> with SingleTickerProviderStateMixin {
  Timer? _tickTimer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Re-render every second to tick counts live
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pulseCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Calculate elapsed breakdown (Years, Months, Days, Hours, Minutes, Seconds)
  Map<String, int> _calculateElapsed(DateTime start, DateTime now) {
    int years = now.year - start.year;
    int months = now.month - start.month;
    int days = now.day - start.day;

    if (days < 0) {
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months--;
    }
    if (months < 0) {
      months += 12;
      years--;
    }

    final diff = now.difference(start);
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return {
      'years': years,
      'months': months,
      'days': days,
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
      'totalDays': diff.inDays,
    };
  }

  // Find next monthiversary
  DateTime _nextMonthiversary(DateTime start, DateTime now) {
    int targetYear = now.year;
    int targetMonth = now.month;

    // If day of this month has already passed, check next month
    if (now.day >= start.day) {
      targetMonth++;
      if (targetMonth > 12) {
        targetMonth = 1;
        targetYear++;
      }
    }

    int targetDay = start.day;
    int lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    if (targetDay > lastDay) {
      targetDay = lastDay;
    }

    return DateTime(targetYear, targetMonth, targetDay, start.hour, start.minute);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userName = LocalStorage().getUserName() ?? 'Tú';
    final partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';

    return Scaffold(
      body: ListenableBuilder(
        listenable: UserService(),
        builder: (context, _) {
          final coupleId = FirebaseService().coupleId;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

              // Sync remote dates to LocalStorage in real-time
              final remoteMet = data['metDate'] as String?;
              if (remoteMet != null && remoteMet != LocalStorage().getMetDate()) {
                LocalStorage().setString('met_date', remoteMet);
              }
              final remoteDating = data['datingDate'] as String?;
              if (remoteDating != null && remoteDating != LocalStorage().getDatingDate()) {
                LocalStorage().setString('dating_date', remoteDating);
              }
              final remoteAnn = data['anniversaryDate'] as String?;
              if (remoteAnn != null && remoteAnn != LocalStorage().getAnniversaryDate()) {
                LocalStorage().setString('anniversary_date', remoteAnn);
              }
              final remoteWedding = data['weddingDate'] as String?;
              if (remoteWedding != null && remoteWedding != LocalStorage().getWeddingDate()) {
                LocalStorage().setString('wedding_date', remoteWedding);
              }

              final metStr = remoteMet ?? LocalStorage().getMetDate();
              final met = metStr != null ? DateTime.tryParse(metStr) : null;

              final datingStr = remoteDating ?? LocalStorage().getDatingDate();
              final dating = datingStr != null ? DateTime.tryParse(datingStr) : null;

              final annStr = remoteAnn ?? LocalStorage().getAnniversaryDate();
              final ann = annStr != null ? DateTime.tryParse(annStr) : null;

              final weddingStr = remoteWedding ?? LocalStorage().getWeddingDate();
              final wedding = weddingStr != null ? DateTime.tryParse(weddingStr) : null;

          final milestones = <_MilestoneData>[];
          if (met != null) {
            milestones.add(_MilestoneData(
              icon: Icons.people_rounded,
              label: 'Nos conocimos',
              date: met,
              color: const Color(0xFF7C83FF),
              gradient: const [Color(0xFF5C62F5), Color(0xFF7C83FF)],
            ));
          }
          if (dating != null) {
            milestones.add(_MilestoneData(
              icon: Icons.coffee_rounded,
              label: 'Primera cita',
              date: dating,
              color: const Color(0xFFFFB74D),
              gradient: const [Color(0xFFF59E0B), Color(0xFFFFB74D)],
            ));
          }
          if (ann != null) {
            milestones.add(_MilestoneData(
              icon: Icons.favorite_rounded,
              label: 'Novios',
              date: ann,
              color: const Color(0xFFFF6B95),
              gradient: const [Color(0xFFE91E63), Color(0xFFFF6B95)],
            ));
          }
          if (wedding != null) {
            milestones.add(_MilestoneData(
              icon: Icons.wc_rounded,
              label: 'Boda / Esposos',
              date: wedding,
              color: const Color(0xFF66BB6A),
              gradient: const [Color(0xFF43A047), Color(0xFF66BB6A)],
            ));
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          return CustomScrollView(
            slivers: [
              // ── Sliding Hero Cards (Live Counters Carousel) ──
              SliverAppBar(
                expandedHeight: 330,
                pinned: false,
                floating: false,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.15),
                          cs.primary.withValues(alpha: 0.02),
                          cs.surface,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Spacer(),
                        if (milestones.isNotEmpty) ...[
                          SizedBox(
                            height: 230,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (idx) => setState(() => _currentPage = idx),
                              itemCount: milestones.length,
                              itemBuilder: (context, idx) {
                                final m = milestones[idx];
                                final elapsed = _calculateElapsed(m.date, now);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: AnimatedBuilder(
                                    animation: _pulseAnim,
                                    builder: (_, child) => Transform.scale(
                                      scale: _currentPage == idx ? _pulseAnim.value : 0.95,
                                      child: child,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        gradient: LinearGradient(
                                          colors: m.gradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: m.color.withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(m.icon, color: Colors.white, size: 24),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Llevamos como ${m.label.toLowerCase()}...',
                                                style: GoogleFonts.caveat(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            '${elapsed['years']} años • ${elapsed['months']} meses • ${elapsed['days']} días',
                                            style: GoogleFonts.outfit(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              '${elapsed['hours'].toString().padLeft(2, '0')}h : ${elapsed['minutes'].toString().padLeft(2, '0')}m : ${elapsed['seconds'].toString().padLeft(2, '0')}s',
                                              style: GoogleFonts.shareTechMono(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Desde el ${m.date.day}/${m.date.month}/${m.date.year}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Dots Indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              milestones.length,
                              (idx) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == idx
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$userName  💕  $partnerName',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 64, color: cs.primary.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                Text('Configura tus fechas importantes',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                const SizedBox(height: 8),
                                Text(
                                  'Agrega cuándo se conocieron, su primera cita, aniversario o boda',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Timeline Section Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.timeline_rounded, size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Nuestra Línea del Tiempo',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showConfigDialog(context, cs, met, dating, ann, wedding),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Configurar'),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Milestones Timeline list ──
              SliverToBoxAdapter(
                child: _buildMilestonesList(cs, milestones, now),
              ),

              // ── Countdown Title ──
              if (milestones.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_bottom_rounded, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Cuenta Regresiva (En Vivo)',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Countdowns List ──
              _buildCountdownsList(cs, ann, met, dating, wedding, today, now),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      );
    },
  ),
);
}

  Widget _buildMilestonesList(ColorScheme cs, List<_MilestoneData> milestones, DateTime now) {
    if (milestones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Presiona "Configurar" para añadir fechas especiales.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(milestones.length, (i) {
          final m = milestones[i];
          final elapsed = _calculateElapsed(m.date, now);

          final nextAnn = DateTime(now.year, m.date.month, m.date.day);
          final annDate = nextAnn.isBefore(DateTime(now.year, now.month, now.day))
              ? DateTime(now.year + 1, m.date.month, m.date.day)
              : nextAnn;
          final daysUntil = now.difference(annDate).inDays.abs();
          final progress = daysUntil >= 365 ? 1.0 : (365 - daysUntil) / 365.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: m.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(m.icon, color: m.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '${m.date.day} de ${_monthName(m.date.month)} ${m.date.year}',
                            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${elapsed['years']}a ${elapsed['months']}m ${elapsed['days']}d',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: m.color),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: m.color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(m.color),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  SliverToBoxAdapter _buildCountdownsList(
    ColorScheme cs,
    DateTime? ann,
    DateTime? met,
    DateTime? dating,
    DateTime? wedding,
    DateTime today,
    DateTime now,
  ) {
    final countdowns = <_CountdownItem>[];

    void addYearlyIf(String label, DateTime? date, IconData icon, Color color) {
      if (date == null) return;
      final nextYearly = DateTime(now.year, date.month, date.day);
      final target = nextYearly.isBefore(today)
          ? DateTime(now.year + 1, date.month, date.day)
          : nextYearly;

      final diff = target.difference(now);
      final countNo = target.year - date.year;

      countdowns.add(_CountdownItem(
        title: '$label #$countNo',
        targetDate: target,
        diff: diff,
        icon: icon,
        color: color,
      ));
    }

    void addMonthlyIf(String label, DateTime? date, IconData icon, Color color) {
      if (date == null) return;
      final target = _nextMonthiversary(date, now);
      final diff = target.difference(now);
      
      final monthsNo = (target.year - date.year) * 12 + (target.month - date.month);

      countdowns.add(_CountdownItem(
        title: '$label #$monthsNo',
        targetDate: target,
        diff: diff,
        icon: icon,
        color: color,
      ));
    }

    // Add anniversary countdowns
    addYearlyIf('Aniversario de novios', ann, Icons.favorite_rounded, cs.primary);
    addMonthlyIf('Mesiversario', ann, Icons.favorite_outline_rounded, cs.secondary);
    addYearlyIf('Aniversario de bodas', wedding, Icons.wc_rounded, const Color(0xFF66BB6A));
    addYearlyIf('Aniversario de conocernos', met, Icons.people_rounded, const Color(0xFF7C83FF));

    if (countdowns.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: List.generate(countdowns.length, (i) {
            final c = countdowns[i];
            final days = c.diff.inDays;
            final hours = c.diff.inHours % 24;
            final minutes = c.diff.inMinutes % 60;
            final seconds = c.diff.inSeconds % 60;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: c.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(c.icon, color: c.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              '${c.targetDate.day}/${c.targetDate.month}/${c.targetDate.year}',
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Faltan:',
                            style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 2),
                          if (days > 0)
                            Text(
                              '${days}d ${hours}h ${minutes}m ${seconds}s',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: c.color,
                              ),
                            )
                          else if (hours > 0 || minutes > 0 || seconds > 0)
                            Text(
                              '${hours}h ${minutes}m ${seconds}s',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )
                          else
                            const Text(
                              '¡Hoy! 🎉❤️',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showConfigDialog(
    BuildContext context,
    ColorScheme cs,
    DateTime? met,
    DateTime? dating,
    DateTime? ann,
    DateTime? wedding,
  ) {
    DateTime? tempMet = met;
    DateTime? tempDating = dating;
    DateTime? tempAnn = ann;
    DateTime? tempWedding = wedding;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.edit_calendar_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Fechas importantes'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DateTile(
                  icon: Icons.people_rounded,
                  label: 'Nos conocimos',
                  date: tempMet,
                  color: const Color(0xFF7C83FF),
                  onPick: (d) => setDState(() => tempMet = d),
                  onClear: () => setDState(() => tempMet = null),
                ),
                const Divider(height: 24),
                _DateTile(
                  icon: Icons.coffee_rounded,
                  label: 'Primera cita',
                  date: tempDating,
                  color: const Color(0xFFFFB74D),
                  onPick: (d) => setDState(() => tempDating = d),
                  onClear: () => setDState(() => tempDating = null),
                ),
                const Divider(height: 24),
                _DateTile(
                  icon: Icons.favorite_rounded,
                  label: 'Aniversario (Novios)',
                  date: tempAnn,
                  color: cs.primary,
                  onPick: (d) => setDState(() => tempAnn = d),
                  onClear: () => setDState(() => tempAnn = null),
                ),
                const Divider(height: 24),
                _DateTile(
                  icon: Icons.wc_rounded,
                  label: 'Boda (Esposos)',
                  date: tempWedding,
                  color: const Color(0xFF66BB6A),
                  onPick: (d) => setDState(() => tempWedding = d),
                  onClear: () => setDState(() => tempWedding = null),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final db = FirebaseFirestore.instance;
                final coupleId = FirebaseService().coupleId;

                // Sync locally
                final ls = LocalStorage();
                if (tempMet != null) {
                  await ls.setString('met_date', tempMet!.toIso8601String());
                } else {
                  await ls.remove('met_date');
                }
                if (tempDating != null) {
                  await ls.setString('dating_date', tempDating!.toIso8601String());
                } else {
                  await ls.remove('dating_date');
                }
                if (tempAnn != null) {
                  await ls.setString('anniversary_date', tempAnn!.toIso8601String());
                } else {
                  await ls.remove('anniversary_date');
                }
                if (tempWedding != null) {
                  await ls.setString('wedding_date', tempWedding!.toIso8601String());
                } else {
                  await ls.remove('wedding_date');
                }

                // Sync in Firestore for the couple
                await db.collection('couples').doc(coupleId).set({
                  'metDate': tempMet?.toIso8601String(),
                  'datingDate': tempDating?.toIso8601String(),
                  'anniversaryDate': tempAnn?.toIso8601String(),
                  'weddingDate': tempWedding?.toIso8601String(),
                }, SetOptions(merge: true));

                // Also sync to user document for cross-device persistence
                final uid = LocalStorage().getUserId();
                if (uid != null) {
                  final userData = <String, dynamic>{};
                  if (tempMet != null) userData['metDate'] = tempMet!.toIso8601String();
                  if (tempDating != null) userData['datingDate'] = tempDating!.toIso8601String();
                  if (tempAnn != null) userData['anniversaryDate'] = tempAnn!.toIso8601String();
                  if (tempWedding != null) userData['weddingDate'] = tempWedding!.toIso8601String();
                  if (tempMet == null) userData['metDate'] = null;
                  if (tempDating == null) userData['datingDate'] = null;
                  if (tempAnn == null) userData['anniversaryDate'] = null;
                  if (tempWedding == null) userData['weddingDate'] = null;
                  await db.collection('users').doc(uid).set(userData, SetOptions(merge: true));
                }

                // Send activity feed notification
                FirebaseService().sendActivityNotification(
                  'actualizó las fechas importantes de la relación 🗓️', 
                  'anniversary', 
                  icon: 'anniversary',
                );

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return names[m - 1];
  }
}

class _MilestoneData {
  final IconData icon;
  final String label;
  final DateTime date;
  final Color color;
  final List<Color> gradient;

  const _MilestoneData({
    required this.icon,
    required this.label,
    required this.date,
    required this.color,
    required this.gradient,
  });
}

class _CountdownItem {
  final String title;
  final DateTime targetDate;
  final Duration diff;
  final IconData icon;
  final Color color;

  const _CountdownItem({
    required this.title,
    required this.targetDate,
    required this.diff,
    required this.icon,
    required this.color,
  });
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? date;
  final Color color;
  final void Function(DateTime) onPick;
  final VoidCallback onClear;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.date,
    required this.color,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              if (date != null)
                Text(
                  '${date!.day}/${date!.month}/${date!.year}',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
            ],
          ),
        ),
        if (date != null)
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18,
                color: cs.onSurface.withValues(alpha: 0.4)),
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
          ),
        FilledButton.tonalIcon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(1980),
              lastDate: DateTime.now(),
              locale: const Locale('es', 'ES'),
            );
            if (picked != null) onPick(picked);
          },
          icon: Icon(Icons.calendar_today_rounded,
              size: 16, color: color),
          label: Text(date != null ? 'Cambiar' : 'Agregar',
              style: TextStyle(fontSize: 12, color: color)),
          style: FilledButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.1),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
