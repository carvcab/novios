import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../planner/planner_tab.dart';
import '../../widgets/glass_card.dart';
import '../music/music_screen.dart';
import '../ai/ai_assistant_screen.dart';
import 'gifts_screen.dart';
import 'on_this_day_screen.dart';
import 'relationship_book_screen.dart';
import 'constellation_screen.dart';
import 'voice_mailbox_screen.dart';
import 'encryption_screen.dart';
import 'favorite_gifs_screen.dart';
import 'compatibility_screen.dart';
import '../../widgets/romantic_route.dart';

class MoreTab extends StatefulWidget {
  const MoreTab({super.key});

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  final _features = <_FeatureItem>[];

  @override
  void initState() {
    super.initState();
    _features.addAll([
      _FeatureItem(Icons.music_note_rounded, 'Musica Favorita', 'Cancion, playlist, fondo', _openMusic),
      _FeatureItem(Icons.psychology_rounded, 'Asistente Amor IA', 'Cartas, poemas, citas offline', _openAIAssistant),
      _FeatureItem(Icons.calendar_month_rounded, 'Proxima Cita', 'Cuenta regresiva, cumpleanos', _openCalendar),
      _FeatureItem(Icons.list_alt_rounded, 'Planificador', 'Peliculas, series, restaurantes', _openPlanner),
      _FeatureItem(Icons.card_giftcard_rounded, 'Regalos Virtuales', 'Flores, chocolates, corazones', _openGifts),
      _FeatureItem(Icons.psychology_rounded, 'Compatibilidad', 'Cuestionario de pareja', _openCompatibility),
      _FeatureItem(Icons.nights_stay_rounded, 'Constelacion', 'El cielo del dia que se conocieron', _openConstellation),
      _FeatureItem(Icons.history_rounded, 'Hace un Anio', 'Que pasaba en esta fecha', _openOnThisDay),
      _FeatureItem(Icons.mic_rounded, 'Buzon de Voz', 'Audios para el futuro', _openVoiceMailbox),
      _FeatureItem(Icons.auto_stories_rounded, 'Libro Relacion', 'Nuestra historia en TXT', _openRelationshipBook),
      _FeatureItem(Icons.gif_box_rounded, 'GIFs Favoritos', 'Tus GIFs de pareja', _openGifs),
      _FeatureItem(Icons.lock_outline_rounded, 'Mensajes Cifrados', 'Cifrado seguro SHA-256+XOR', _openEncryption),
      _FeatureItem(Icons.download_rounded, 'Descargar', 'Guardar fotos y contenido', _openDownload),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Más Funciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _features.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 1.0, crossAxisSpacing: 10, mainAxisSpacing: 10,
          ),
          itemBuilder: (ctx, i) {
            final f = _features[i];
            return GlassCard(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => f.onTap(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(f.icon, color: primary, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(f.title, style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(f.subtitle, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openMusic() { Navigator.of(context).push(RomanticPageRoute(page: const MusicScreen())); }
  void _openCalendar() { showDialog(context: context, builder: (ctx) => Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(20), child: _CalendarContent()))); }
  void _openPlanner() { Navigator.of(context).push(RomanticPageRoute(page: const PlannerTab())); }
  void _openGifts() { Navigator.of(context).push(RomanticPageRoute(page: const GiftsScreen())); }
  void _openCompatibility() { Navigator.of(context).push(RomanticPageRoute(page: const CompatibilityScreen())); }
  void _openConstellation() { Navigator.of(context).push(RomanticPageRoute(page: const ConstellationScreen())); }
  void _openOnThisDay() { Navigator.of(context).push(RomanticPageRoute(page: const OnThisDayScreen())); }
  void _openVoiceMailbox() { Navigator.of(context).push(RomanticPageRoute(page: const VoiceMailboxScreen())); }
  void _openEncryption() { Navigator.of(context).push(RomanticPageRoute(page: const EncryptionScreen())); }
  void _openRelationshipBook() { Navigator.of(context).push(RomanticPageRoute(page: const RelationshipBookScreen())); }
  void _openGifs() { Navigator.of(context).push(RomanticPageRoute(page: const FavoriteGifsScreen())); }
  void _openDownload() { _showDownloadDialog(); }
  void _openAIAssistant() { Navigator.of(context).push(RomanticPageRoute(page: const AIAssistantScreen())); }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Descargar Contenido'),
          ],
        ),
        content: const Text('Puedes descargar todas tus fotos y recuerdos desde la seccion de Recuerdos. Toca "Compartir" en cualquier foto para guardarla.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ElevatedButton(
            onPressed: () async {
              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/novios_backup_${DateTime.now().millisecondsSinceEpoch}.json');
              final memories = LocalStorage().getLocalList('memories');
              await file.writeAsString(json.encode(memories));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Backup guardado en ${file.path}')));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Exportar Backup'),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  _FeatureItem(this.icon, this.title, this.subtitle, this.onTap);
}

// ── Music Sheet Unified ──
// ── CALENDAR ──
class _CalendarContent extends StatefulWidget {
  @override
  State<_CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<_CalendarContent> {
  final _eventCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final List<Map<String, dynamic>> _events = [];
  DateTime? _anniversary;

  @override
  void initState() {
    super.initState();
    _anniversary = DateTime.tryParse(LocalStorage().getAnniversaryDate() ?? '');
    _events.addAll(LocalStorage().getLocalList('calendar_events'));
  }

  @override
  void dispose() { _eventCtrl.dispose(); _dateCtrl.dispose(); super.dispose(); }

  void _addEvent() {
    final date = DateTime.tryParse(_dateCtrl.text.trim());
    if (_eventCtrl.text.trim().isEmpty || date == null) return;
    setState(() => _events.add({'title': _eventCtrl.text.trim(), 'date': date.toIso8601String()}));
    FirebaseService().saveListData('calendar_events', _events);
    _eventCtrl.clear(); _dateCtrl.clear();
  }

  Duration _countdown(DateTime target) => target.difference(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Fechas Importantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 16),
          if (_anniversary != null)
            GlassCard(
              child: ListTile(
                leading: Icon(Icons.favorite_rounded, color: primary),
                title: Text('Aniversario: ${_anniversary!.day}/${_anniversary!.month}/${_anniversary!.year}'),
                subtitle: Text(_countdown(DateTime(_anniversary!.year + 1, _anniversary!.month, _anniversary!.day)).isNegative
                    ? 'Feliz Aniversario!'
                    : 'Faltan ${_countdown(DateTime(DateTime.now().year, _anniversary!.month, _anniversary!.day)).inDays} dias'),
              ),
            ),
          ..._events.map((e) {
            DateTime? d;
            final rawDate = e['date'];
            if (rawDate is String) {
              d = DateTime.tryParse(rawDate);
            } else if (rawDate is Timestamp) {
              d = rawDate.toDate();
            }
            if (d == null) return const SizedBox.shrink();

            final cd = _countdown(d);
            return GlassCard(
              child: ListTile(
                leading: Icon(cd.isNegative ? Icons.event_available_rounded : Icons.event_rounded, color: cd.isNegative ? Colors.grey : primary),
                title: Text(e['title'] ?? ''),
                subtitle: Text('${d.day}/${d.month}/${d.year}'),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () {
                  setState(() => _events.remove(e));
                  FirebaseService().saveListData('calendar_events', _events);
                }),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(controller: _eventCtrl, decoration: const InputDecoration(labelText: 'Evento')),
          const SizedBox(height: 8),
          TextField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)', hintText: '2026-12-25')),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _addEvent, icon: const Icon(Icons.add_rounded), label: const Text('Agregar fecha')),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

// ── END OF MORE TAB ──
