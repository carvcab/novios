import 'package:flutter/material.dart';
import '../../services/local_storage.dart';
import '../../services/firebase_service.dart';
import '../../widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _partnerName = 'Tu pareja';

  @override
  void initState() {
    super.initState();
    _partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.notifications_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Notificaciones de mi pareja'),
          ],
        ),
      ),
      body: _PartnerAppsTab(partnerName: _partnerName, cs: cs),
    );
  }
}

// ── Partner's mirrored notifications from other apps ──

class _PartnerAppsTab extends StatefulWidget {
  final String partnerName;
  final ColorScheme cs;
  const _PartnerAppsTab({required this.partnerName, required this.cs});

  @override
  State<_PartnerAppsTab> createState() => _PartnerAppsTabState();
}

class _PartnerAppsTabState extends State<_PartnerAppsTab> {
  final _firebase = FirebaseService();

  IconData _iconForApp(String? app) {
    if (app == null) return Icons.apps_rounded;
    final a = app.toLowerCase();
    if (a.contains('whatsapp')) return Icons.chat_rounded;
    if (a.contains('instagram') || a.contains('ig')) return Icons.camera_alt_rounded;
    if (a.contains('tiktok')) return Icons.music_note_rounded;
    if (a.contains('facebook') || a.contains('messenger')) return Icons.facebook_rounded;
    if (a.contains('twitter') || a.contains('x')) return Icons.alternate_email_rounded;
    if (a.contains('youtube') || a.contains('yt')) return Icons.play_circle_filled_rounded;
    if (a.contains('telegram')) return Icons.send_rounded;
    if (a.contains('snapchat')) return Icons.auto_awesome_rounded;
    if (a.contains('gmail') || a.contains('mail')) return Icons.email_rounded;
    if (a.contains('chrome') || a.contains('browser')) return Icons.language_rounded;
    if (a.contains('maps') || a.contains('gps')) return Icons.map_rounded;
    if (a.contains('phone') || a.contains('llamada') || a.contains('dialer')) return Icons.phone_rounded;
    if (a.contains('spotify') || a.contains('music')) return Icons.headphones_rounded;
    return Icons.apps_rounded;
  }

  Color _colorForApp(String? app) {
    if (app == null) return Colors.grey;
    final a = app.toLowerCase();
    if (a.contains('whatsapp')) return const Color(0xFF25D366);
    if (a.contains('instagram')) return const Color(0xFFE4405F);
    if (a.contains('tiktok')) return const Color(0xFF010101);
    if (a.contains('facebook')) return const Color(0xFF1877F2);
    if (a.contains('twitter') || a.contains('x')) return const Color(0xFF1DA1F2);
    if (a.contains('youtube')) return const Color(0xFFFF0000);
    if (a.contains('telegram')) return const Color(0xFF0088CC);
    if (a.contains('snapchat')) return const Color(0xFFFFFC00);
    if (a.contains('gmail')) return const Color(0xFFEA4335);
    return widget.cs.primary;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return '${dt.day}/${dt.month}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebase.streamPartnerNotificationLogs(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off_rounded, size: 64,
                    color: widget.cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                Text('Notificaciones de ${widget.partnerName}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                        color: widget.cs.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 6),
                Text('Aca veras WhatsApp, TikTok, Instagram y mas',
                    style: TextStyle(fontSize: 13,
                        color: widget.cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 4),
                Text('Tu pareja debe tener el permiso de notificaciones activado',
                    style: TextStyle(fontSize: 12,
                        color: widget.cs.onSurface.withValues(alpha: 0.35))),
              ],
            ),
          );
        }

        final sorted = List<Map<String, dynamic>>.from(notifications);
        sorted.sort((a, b) {
          final ta = (a['createdAt'] as String?) ?? '';
          final tb = (b['createdAt'] as String?) ?? '';
          return tb.compareTo(ta);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final n = sorted[i];
            final app = n['app'] as String? ?? 'App';
            final title = n['title'] as String? ?? '';
            final text = n['text'] as String? ?? '';
            final rawTime = n['createdAt'] as String?;
            final time = rawTime != null ? DateTime.tryParse(rawTime) : null;
            final timeStr = time != null
                ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                : '';
            final dateStr = time != null ? _formatDate(time) : '';
            final appIcon = _iconForApp(app);
            final appColor = _colorForApp(app);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: appColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(appIcon, color: appColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(app, style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 11,
                                  color: appColor)),
                              if (title.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(title, style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13,
                                      color: widget.cs.onSurface),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ],
                          ),
                          if (text.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(text, style: TextStyle(
                                fontSize: 12, color: widget.cs.onSurface.withValues(alpha: 0.6)),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(dateStr, style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: widget.cs.onSurface.withValues(alpha: 0.5))),
                          Text(timeStr, style: TextStyle(
                              fontSize: 11, color: widget.cs.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


