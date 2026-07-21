import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/local_storage.dart';
import '../../services/auth_service.dart';
import '../../services/status_service.dart';
import '../../services/geofence_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/page_transition.dart';
import '../letters/letters_tab.dart';
import '../games/games_tab.dart';
import '../notifications/notifications_screen.dart';
import '../live/live_status_screen.dart';
import '../screenview/screen_view_screen.dart';
import '../notes/notes_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../dreams/dreams_screen.dart';
import '../location/location_tab.dart';
import '../memories/memories_tab.dart';
import '../planner/planner_tab.dart';
import '../more/more_tab.dart';
import '../music/music_screen.dart';
import '../ai/ai_assistant_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Duration _together = const Duration();
  String _dailyQuote = '';
  final List<_HeartParticle> _particles = [];
  int _particleIdCounter = 0;
  final Random _random = Random();
  Map<String, dynamic> _partnerStatus = {};
  StreamSubscription? _statusSub;
  Position? _myPosition;

  final List<String> _quotes = [
    "El mejor lugar del mundo eres tu.",
    "Te amo no solo por lo que eres, sino por lo que soy cuando estoy contigo.",
    "Eres mi momento favorito del dia.",
    "En un beso, sabras todo lo que he callado.",
    "Si se lo que es el amor, es por ti.",
    "Eres la casualidad mas hermosa de mi vida.",
    "Juntos es mi lugar favorito para estar.",
    "Te elegiria a ti cien veces, en cien mundos.",
    "Amar no es mirarse el uno al otro; es mirar juntos en la misma direccion.",
    "Eres la cancion que hace latir mi corazon.",
  ];

  String? _coverPhotoPath;

  @override
  void initState() {
    super.initState();
    _coverPhotoPath = LocalStorage().getString('home_cover_photo');
    _dailyQuote = _quotes[DateTime.now().day % _quotes.length];
    _startTimer();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.repeat(reverse: true);

    _myPosition = GeofenceService().lastPosition;
    if (_myPosition == null) {
      Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low))
          .then((pos) {
        if (mounted) {
          setState(() {
            _myPosition = pos;
          });
        }
      }).catchError((_) {});
    }

    _statusSub = StatusService().partnerStatusStream.listen((s) {
      if (mounted) setState(() => _partnerStatus = s);
    });
  }

  void _pickCoverPhoto() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null || filePath.isEmpty) return;

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/cover_photos');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final ext = filePath.split('.').last;
      final localPath = '${photosDir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(filePath).copy(localPath);

      setState(() {
        _coverPhotoPath = localPath;
      });
      LocalStorage().setString('home_cover_photo', localPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _removeCoverPhoto() {
    setState(() {
      _coverPhotoPath = null;
    });
    LocalStorage().setString('home_cover_photo', '');
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseCtrl.dispose();
    _statusSub?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _calcTogether());
  }

  void _calcTogether() {
    final annStr = LocalStorage().getAnniversaryDate();
    if (annStr == null) return;
    final ann = DateTime.tryParse(annStr);
    if (ann == null) return;
    if (mounted) setState(() => _together = DateTime.now().difference(ann));
  }

  String _formatTime() {
    if (_together.inSeconds <= 0) return '0 dias';
    final days = _together.inDays;
    final years = (days / 365).floor();
    final remaining = days % 365;
    final months = (remaining / 30).floor();
    final finalDays = remaining % 30;
    final parts = <String>[];
    if (years > 0) parts.add('$years a');
    if (months > 0) parts.add('$months m');
    if (finalDays > 0) parts.add('${finalDays}d');
    return parts.isEmpty ? '0 dias' : parts.join(' ');
  }

  void _tapHeart() {
    HapticFeedback.lightImpact();
    _spawnParticles();
    final quote = _quotes[_random.nextInt(_quotes.length)];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(quote, style: const TextStyle(fontSize: 13)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _spawnParticles() {
    setState(() {
      for (int i = 0; i < 6; i++) {
        _particles.add(_HeartParticle(
          id: _particleIdCounter++,
          dx: _random.nextDouble() * 120 - 60,
          dy: -(_random.nextDouble() * 80 + 40),
          size: _random.nextDouble() * 10 + 6,
          opacity: _random.nextDouble() * 0.4 + 0.4,
        ));
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _particles.clear());
    });
  }

  // ── Navigation methods ──
  void _push(Widget screen, String screenName) {
    StatusService().setScreen(screenName);
    Navigator.push(context, SlideFadeRoute(page: screen)).then((_) {
      StatusService().setScreen('Inicio');
    });
  }

  void _openNoti() => _push(const NotificationsScreen(), 'Notificaciones');
  void _openLive() => _push(const LiveStatusScreen(), 'En Vivo');
  void _openScreenView() => _push(const ScreenViewScreen(), 'Ver Pantalla');
  void _openLetters() => _push(const LettersTab(), 'Cartas');
  void _openNotes() => _push(const NotesScreen(), 'Notas');
  void _openWishlist() => _push(const WishlistScreen(), 'Lista de Deseos');
  void _openDreams() => _push(const DreamsScreen(), 'Sueños');
  void _openMap() => _push(const LocationTab(), 'Mapa');
  void _openAIAssistant() => _push(const AIAssistantScreen(), 'Amor IA');
  void _openGames() => _push(const GamesTab(), 'Juegos');
  void _openPlanner() => _push(const PlannerTab(), 'Planificador');
  void _openMore() => _push(const MoreTab(), 'Más');

  void _openAlbum() => _push(const MemoriesTab(isStandalone: true), 'Recuerdos');

  void _openMusic() {
    _push(const MusicScreen(), 'Nuestra Música');
  }

  void _openCalendar() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _CalendarHome(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDiego = AuthService().isDiego;
    final userName = isDiego ? 'Diego' : 'Yosmari';
    final partnerName = isDiego ? 'Yosmari' : 'Diego';
    final isOnline = _partnerStatus['isOnline'] == true;
    final partnerScreen = _partnerStatus['currentScreen'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 16),

          Text('EverUs',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.primary, letterSpacing: 3)),
          const SizedBox(height: 20),

          // Interactive Heart
          GestureDetector(
            onTap: _tapHeart,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ..._particles.map((p) => _HeartParticleWidget(key: ValueKey(p.id), particle: p, cs: cs)),
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        cs.primary.withValues(alpha: 0.15),
                        cs.primary.withValues(alpha: 0.03),
                      ]),
                    ),
                    child: Icon(Icons.favorite_rounded, color: cs.primary, size: 42),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('$userName  💞  $partnerName',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurface, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(_formatTime(),
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: cs.primary, letterSpacing: 1)),
          const SizedBox(height: 20),

          // ── Status cards (Noti + En Vivo) ──
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  onTap: _openNoti,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.notifications_rounded, color: cs.primary, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text('Noti', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                      Text('Actividad', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  onTap: _openLive,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isOnline ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isOnline ? Colors.green : cs.onSurface.withValues(alpha: 0.4),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('En Vivo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                      Text(
                        isOnline ? (partnerScreen.isNotEmpty ? partnerScreen : 'En linea') : 'Offline',
                        style: TextStyle(fontSize: 10, color: isOnline ? Colors.green : cs.onSurface.withValues(alpha: 0.4)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Quote card ──
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Row(
              children: [
                Icon(Icons.format_quote_rounded, size: 22, color: cs.primary.withValues(alpha: 0.3)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('"$_dailyQuote"',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: cs.onSurface, height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Photo placeholder ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickCoverPhoto,
            onLongPress: _coverPhotoPath != null && _coverPhotoPath!.isNotEmpty ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Portada del Inicio'),
                  content: const Text('¿Qué deseas hacer con la foto de portada?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _removeCoverPhoto();
                      },
                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _pickCoverPhoto();
                      },
                      child: const Text('Cambiar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              );
            } : null,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: _coverPhotoPath != null && _coverPhotoPath!.isNotEmpty && File(_coverPhotoPath!).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(_coverPhotoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: _coverPhotoPath == null || _coverPhotoPath!.isEmpty
                    ? LinearGradient(
                        colors: [cs.primary.withValues(alpha: 0.15), cs.secondary.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: _coverPhotoPath == null || _coverPhotoPath!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 48, color: cs.primary.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Text('Toca para poner tu foto aquí',
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45), fontSize: 14)),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // ── Compact Info Strip (Distance + Countdown) ──
          _buildCompactInfoStrip(cs),
          const SizedBox(height: 20),

          // ── Feature Grid (4 rows × 3 cols) ──
          _buildFeatureGrid(cs),

          const SizedBox(height: 20),

          // ── Mood & Weather ──
          Row(
            children: [
              Expanded(child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(children: [
                  Icon(Icons.favorite_rounded, color: cs.primary, size: 22),
                  const SizedBox(height: 6),
                  Text('Feliz', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 14)),
                  Text('Hoy', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
                ]))),
              const SizedBox(width: 10),
              Expanded(child: GlassCard(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(children: [
                  Icon(Icons.wb_sunny_rounded, color: cs.primary, size: 22),
                  const SizedBox(height: 6),
                  Text('Soleado', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 14)),
                  Text('Relación', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
                ]))),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompactInfoStrip(ColorScheme cs) {
    // ── Distance calculation ──
    double? dist;
    final partnerLat = _partnerStatus['latitude'] != null ? (_partnerStatus['latitude'] as num).toDouble() : null;
    final partnerLng = _partnerStatus['longitude'] != null ? (_partnerStatus['longitude'] as num).toDouble() : null;
    final myPos = _myPosition ?? GeofenceService().lastPosition;

    if (partnerLat != null && partnerLng != null && myPos != null) {
      dist = GeofenceService().distanceTo(partnerLat, partnerLng);
    }

    // ── Countdown calculation ──
    final annStr = LocalStorage().getAnniversaryDate();
    int? daysLeft;
    String countdownLabel = 'Aniversario';

    if (annStr != null && annStr.isNotEmpty) {
      final ann = DateTime.tryParse(annStr);
      if (ann != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        DateTime nextAnn = DateTime(today.year, ann.month, ann.day);
        if (nextAnn.isBefore(today)) {
          nextAnn = DateTime(today.year + 1, ann.month, ann.day);
        }
        final daysToAnn = nextAnn.difference(today).inDays;

        DateTime nextMon = DateTime(today.year, today.month, ann.day);
        if (nextMon.isBefore(today)) {
          int nextM = today.month + 1;
          int nextY = today.year;
          if (nextM > 12) {
            nextM = 1;
            nextY++;
          }
          final lastDay = DateTime(nextY, nextM + 1, 0).day;
          final finalDay = ann.day > lastDay ? lastDay : ann.day;
          nextMon = DateTime(nextY, nextM, finalDay);
        }
        final daysToMon = nextMon.difference(today).inDays;

        if (daysToMon <= daysToAnn && daysToMon > 0) {
          daysLeft = daysToMon;
          countdownLabel = 'Mesiversario';
        } else {
          daysLeft = daysToAnn;
          countdownLabel = 'Aniversario';
        }
      }
    }

    return Row(
      children: [
        // ── Distance card ──
        Expanded(
          child: GestureDetector(
            onTap: _openMap,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C83FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF7C83FF)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dist != null ? '${dist.toStringAsFixed(1)} km' : 'Sin datos',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dist != null && dist < 0.2 ? '¡Juntos! ❤️' : 'Distancia',
                          style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ── Countdown card ──
        Expanded(
          child: GestureDetector(
            onTap: _openCalendar,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.hourglass_bottom_rounded, size: 18, color: Color(0xFFEF5350)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          daysLeft != null
                              ? (daysLeft == 0 ? '¡HOY! 🎉' : '$daysLeft días')
                              : 'Configura',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          daysLeft != null ? countdownLabel : 'Tu fecha',
                          style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(ColorScheme cs) {
    final features = [
      _FeatureInfo(Icons.screen_share_rounded, 'Pantalla', const Color(0xFF00BFA5), _openScreenView),
      _FeatureInfo(Icons.mail_outline_rounded, 'Cartas', const Color(0xFFFF7F7F), _openLetters),
      _FeatureInfo(Icons.sticky_note_2_outlined, 'Notas', const Color(0xFFE8467C), _openNotes),
      _FeatureInfo(Icons.psychology_rounded, 'Amor IA', const Color(0xFF4FC3F7), _openAIAssistant),
      _FeatureInfo(Icons.photo_library_outlined, 'Recuerdos', const Color(0xFF7C83FF), _openAlbum),
      _FeatureInfo(Icons.sports_esports_outlined, 'Juegos', const Color(0xFFFFB74D), _openGames),
      _FeatureInfo(Icons.auto_awesome_rounded, 'Deseos', const Color(0xFFAB47BC), _openWishlist),
      _FeatureInfo(Icons.nights_stay_rounded, 'Sueños', const Color(0xFF5C6BC0), _openDreams),
      _FeatureInfo(Icons.list_alt_rounded, 'Planner', const Color(0xFF66BB6A), _openPlanner),
      _FeatureInfo(Icons.music_note_outlined, 'Música', const Color(0xFF26A69A), _openMusic),
      _FeatureInfo(Icons.calendar_month_outlined, 'Fechas', const Color(0xFFEF5350), _openCalendar),
      _FeatureInfo(Icons.apps_rounded, 'Más', const Color(0xFF78909C), _openMore),
    ];

    // Build rows of 3
    final rows = <Widget>[];
    for (int i = 0; i < features.length; i += 3) {
      final rowItems = <Widget>[];
      for (int j = i; j < i + 3; j++) {
        if (j < features.length) {
          rowItems.add(Expanded(
            child: _ActionCard(
              icon: features[j].icon,
              label: features[j].label,
              color: features[j].color,
              cs: cs,
              onTap: features[j].onTap,
            ),
          ));
        } else {
          rowItems.add(const Expanded(child: SizedBox()));
        }
        if (j < i + 2) {
          rowItems.add(const SizedBox(width: 10));
        }
      }
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rowItems,
        ),
      ));
      if (i + 3 < features.length) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return Column(children: rows);
  }
}

// ── Data classes ──

class _FeatureInfo {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureInfo(this.icon, this.label, this.color, this.onTap);
}

class _HeartParticle {
  final int id;
  final double dx, dy, size, opacity;
  _HeartParticle({required this.id, required this.dx, required this.dy, required this.size, required this.opacity});
}

class _HeartParticleWidget extends StatelessWidget {
  final _HeartParticle particle;
  final ColorScheme cs;
  const _HeartParticleWidget({required this.particle, required this.cs, super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(particle.dx, particle.dy),
      child: Opacity(
        opacity: particle.opacity,
        child: Icon(Icons.favorite_rounded, size: particle.size, color: cs.primary),
      ),
    );
  }
}

// ── Action Card widget ──

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.cs, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: widget.cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

// ── Music Sheet Unified ──

// ── Calendar Dialog ──

String _elapsedTime(DateTime past) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(past.year, past.month, past.day);
  
  int years = today.year - start.year;
  int months = today.month - start.month;
  int days = today.day - start.day;

  if (days < 0) {
    final prevMonth = DateTime(today.year, today.month, 0);
    days += prevMonth.day;
    months--;
  }
  if (months < 0) {
    months += 12;
    years--;
  }

  final parts = <String>[];
  if (years > 0) parts.add(years == 1 ? '1 año' : '$years años');
  if (months > 0) parts.add(months == 1 ? '1 mes' : '$months meses');
  if (days > 0) parts.add(days == 1 ? '1 día' : '$days días');
  
  if (parts.isEmpty) return '¡Comienza hoy!';
  return parts.join(', ');
}

class _CalendarHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Build unified list of dates
    final List<Map<String, dynamic>> allDates = [];

    final annStr = LocalStorage().getAnniversaryDate();
    if (annStr != null && annStr.isNotEmpty) {
      allDates.add({
        'title': 'Aniversario de novios 💖',
        'date': annStr,
        'repeats': true,
        'icon': Icons.favorite_rounded,
        'color': cs.primary,
      });
    }

    final metStr = LocalStorage().getString('met_date');
    if (metStr != null && metStr.isNotEmpty) {
      allDates.add({
        'title': 'Día que nos conocimos 🧑‍🤝‍🧑',
        'date': metStr,
        'repeats': true,
        'icon': Icons.people_rounded,
        'color': const Color(0xFF7C83FF),
      });
    }

    final datingStr = LocalStorage().getString('dating_date');
    if (datingStr != null && datingStr.isNotEmpty) {
      allDates.add({
        'title': 'Primera cita ☕',
        'date': datingStr,
        'repeats': true,
        'icon': Icons.coffee_rounded,
        'color': const Color(0xFFFFB74D),
      });
    }

    final customList = LocalStorage().getLocalList('important_dates');
    for (final d in customList) {
      allDates.add({
        'title': d['title'] ?? 'Fecha Especial',
        'date': d['date'] ?? '',
        'repeats': d['repeats'] == true,
        'icon': d['repeats'] == true ? Icons.loop_rounded : Icons.star_rounded,
        'color': cs.secondary,
      });
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Fechas Importantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 16),
          if (allDates.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Agrega tus fechas desde Perfil o Ajustes',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center),
            )
          else
            ...allDates.map((d) {
              final date = DateTime.tryParse(d['date'] ?? '');
              if (date == null) return const SizedBox();
              
              final repeats = d['repeats'] == true;
              final title = d['title'] ?? '';
              final color = d['color'] as Color;
              final icon = d['icon'] as IconData;

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final start = DateTime(date.year, date.month, date.day);

              // 1. Next Annual Anniversary countdown
              DateTime nextAnn = DateTime(today.year, start.month, start.day);
              if (nextAnn.isBefore(today)) {
                nextAnn = DateTime(today.year + 1, start.month, start.day);
              }
              final daysToAnn = nextAnn.difference(today).inDays;

              // 2. Next Monthly Anniversary countdown (Mesiversario)
              DateTime nextMon = DateTime(today.year, today.month, start.day);
              if (nextMon.isBefore(today)) {
                int nextM = today.month + 1;
                int nextY = today.year;
                if (nextM > 12) {
                  nextM = 1;
                  nextY++;
                }
                final lastDay = DateTime(nextY, nextM + 1, 0).day;
                final finalDay = start.day > lastDay ? lastDay : start.day;
                nextMon = DateTime(nextY, nextM, finalDay);
              }
              final daysToMon = nextMon.difference(today).inDays;

              final elapsed = _elapsedTime(start);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Fecha: ${start.day}/${start.month}/${start.year}', 
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11)),
                          Text('Tiempo: $elapsed', 
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          if (repeats) ...[
                            Text(
                              daysToAnn == 0 
                                  ? '¡Hoy es el aniversario anual! 🎉' 
                                  : 'Faltan $daysToAnn días para el aniversario anual',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                            ),
                            Text(
                              daysToMon == 0 
                                  ? '¡Hoy es el mesiversario! 💕' 
                                  : 'Faltan $daysToMon días para el mesiversario',
                              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
                            ),
                          ] else
                            Text(
                              'Faltan ${start.difference(today).inDays} días para el evento',
                              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
                            ),
                          const Divider(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))),
        ],
      ),
    );
  }
}
