import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/local_storage.dart';
import '../../services/status_service.dart';
import '../../widgets/glass_card.dart';
import 'screen_share_view.dart';

class LiveStatusScreen extends StatefulWidget {
  const LiveStatusScreen({super.key});

  @override
  State<LiveStatusScreen> createState() => _LiveStatusScreenState();
}

class _LiveStatusScreenState extends State<LiveStatusScreen> {
  Map<String, dynamic> _status = {};
  StreamSubscription? _sub;
  String _partnerName = 'Tu pareja';
  List<Map<String, dynamic>> _screenHistory = [];

  @override
  void initState() {
    super.initState();
    _partnerName = LocalStorage().getPartnerName() ?? 'Tu pareja';
    _sub = StatusService().partnerStatusStream.listen((data) {
      if (!mounted) return;
      final screen = data['currentScreen'] as String? ?? '';
      final isOnline = data['isOnline'] == true;

      if (screen.isNotEmpty && isOnline) {
        final last = _screenHistory.isNotEmpty ? _screenHistory.first['screen'] : '';
        if (screen != last) {
          _screenHistory.insert(0, {
            'screen': screen,
            'time': DateTime.now(),
          });
          if (_screenHistory.length > 30) {
            _screenHistory = _screenHistory.sublist(0, 30);
          }
        }
      }
      setState(() => _status = data);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOnline = _status['isOnline'] == true;
    final lastSeen = _status['lastSeenDate'] as DateTime?;
    final battery = _status['batteryLevel'] as int? ?? -1;
    final isCharging = _status['isCharging'] as bool? ?? false;
    final currentApp = _status['currentApp'] as String? ?? '';
    final lastAppUpdate = _status['lastAppUpdate'] as DateTime?;
    final phoneStateFromDb = _status['phoneState'] as String? ?? 'activo';
    final lastNotification = _status['lastNotification'] as Map<String, dynamic>?;
    final lastNotificationTime = _status['lastNotificationTime'] as DateTime?;

    final isPhoneActive = lastSeen != null && DateTime.now().difference(lastSeen).inSeconds < 25;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.favorite_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(_partnerName),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isOnline
                      ? [Colors.green, Colors.greenAccent]
                      : [cs.onSurface.withValues(alpha: 0.2), cs.onSurface.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: isOnline
                    ? [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 4)]
                    : [],
              ),
              child: Center(
                child: Icon(
                  isOnline ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: Colors.white, size: 46,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(_partnerName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'En linea ahora' : 'Desconectado',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isOnline ? Colors.green : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _AppCard(
              app: currentApp,
              appLabel: _status['currentAppLabel'] as String? ?? '',
              lastUpdate: lastAppUpdate,
              isOnline: isOnline,
              isPhoneActive: isPhoneActive,
              phoneState: phoneStateFromDb,
              cs: cs,
            ),
            const SizedBox(height: 10),

            _DetailCard(
              icon: isCharging ? Icons.battery_charging_full_rounded : Icons.battery_std_rounded,
              label: 'Bateria',
              value: battery >= 0 ? '$battery%${isCharging ? '  Cargando' : ''}' : 'Desconocido',
              color: isCharging ? Colors.green : (battery > 20 ? Colors.green : (battery >= 0 ? Colors.red : Colors.grey)),
              cs: cs,
              isActive: battery >= 0,
            ),
            const SizedBox(height: 10),

            _DetailCard(
              icon: Icons.access_time_rounded,
              label: 'Ultima vez activo',
              value: lastSeen != null
                  ? _formatDateTime(lastSeen)
                  : 'Desconocido',
              color: Colors.orange,
              cs: cs,
              isActive: lastSeen != null,
              trailing: lastSeen != null
                  ? Text(
                      _timeAgo(lastSeen),
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                    )
                  : null,
            ),
            const SizedBox(height: 10),

            _PhoneStateCard(
              phoneStateFromDb: phoneStateFromDb,
              isOnline: isOnline,
              lastSeen: lastSeen,
              cs: cs,
            ),
            const SizedBox(height: 10),

            if (lastNotification != null)
              _LastNotificationCard(
                notification: lastNotification,
                time: lastNotificationTime,
                partnerName: _partnerName,
                cs: cs,
              ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GlassCard(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenShareView())),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.tv_rounded, color: cs.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Compartir pantalla',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                const SizedBox(height: 2),
                                Text('Ver la pantalla de tu pareja en tiempo real',
                                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_screenHistory.isNotEmpty) ...[
              const SizedBox(height: 30),
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Historial de pantallas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(
                _screenHistory.length > 15 ? 15 : _screenHistory.length,
                (i) {
                  final entry = _screenHistory[i];
                  final s = entry['screen'] as String;
                  final t = entry['time'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0 ? Colors.green : cs.onSurface.withValues(alpha: 0.2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
                          ),
                          Text(
                            '${t.hour}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Hoy ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day && dt.month == yesterday.month && dt.year == yesterday.year) {
      return 'Ayer ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _AppCard extends StatelessWidget {
  final String app;
  final String appLabel;
  final DateTime? lastUpdate;
  final bool isOnline;
  final bool isPhoneActive;
  final String phoneState;
  final ColorScheme cs;

  const _AppCard({
    required this.app,
    required this.appLabel,
    required this.lastUpdate,
    required this.isOnline,
    required this.isPhoneActive,
    required this.phoneState,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final appIsRecent = lastUpdate != null && DateTime.now().difference(lastUpdate!).inSeconds < 90;
    final hasApp = app.isNotEmpty && (isPhoneActive || isOnline || appIsRecent);

    IconData icon;
    Color color;
    String label;

    if (!hasApp) {
      icon = Icons.phone_android_rounded;
      color = cs.onSurface.withValues(alpha: 0.4);
      if (!isOnline) {
        label = 'Desconectado';
      } else {
        label = 'Sin datos de apps (conceder permiso Uso de Apps)';
      }
    } else {
      final a = app.toLowerCase();
      final labelFromNative = appLabel;
      if (labelFromNative.isNotEmpty && !labelFromNative.startsWith('com.')) {
        icon = Icons.apps_rounded;
        color = Colors.blue;
        label = labelFromNative;
      } else if (a.contains('tiktok') || a.contains('musically') || a.contains('trill')) {
        icon = Icons.music_note_rounded;
        color = const Color(0xFF010101);
        label = 'TikTok';
      } else if (a.contains('file') || a.contains('archivo') || a.contains('documentsui') || a.contains('download') || a.contains('myfiles')) {
        icon = Icons.folder_open_rounded;
        color = const Color(0xFFFF9800);
        label = 'Archivos / Documentos';
      } else if (a.contains('whatsapp')) {
        icon = Icons.chat_rounded;
        color = const Color(0xFF25D366);
        label = 'WhatsApp';
      } else if (a.contains('instagram')) {
        icon = Icons.camera_alt_rounded;
        color = const Color(0xFFE4405F);
        label = 'Instagram';
      } else if (a.contains('facebook') || a.contains('messenger')) {
        icon = Icons.facebook_rounded;
        color = const Color(0xFF1877F2);
        label = a.contains('messenger') ? 'Messenger' : 'Facebook';
      } else if (a.contains('twitter') || a == 'com.x.android' || a.endsWith('.twitter') || a.endsWith('.x')) {
        icon = Icons.alternate_email_rounded;
        color = const Color(0xFF1DA1F2);
        label = 'Twitter / X';
      } else if (a.contains('youtube')) {
        icon = Icons.play_circle_filled_rounded;
        color = const Color(0xFFFF0000);
        label = 'YouTube';
      } else if (a.contains('telegram')) {
        icon = Icons.send_rounded;
        color = const Color(0xFF0088CC);
        label = 'Telegram';
      } else if (a.contains('snapchat')) {
        icon = Icons.auto_awesome_rounded;
        color = const Color(0xFFFFFC00);
        label = 'Snapchat';
      } else if (a.contains('gmail') || a.contains('email')) {
        icon = Icons.email_rounded;
        color = const Color(0xFFEA4335);
        label = 'Correo';
      } else if (a.contains('chrome') || a.contains('browser')) {
        icon = Icons.language_rounded;
        color = const Color(0xFF4285F4);
        label = 'Navegador';
      } else if (a.contains('maps') || a.contains('gps')) {
        icon = Icons.map_rounded;
        color = const Color(0xFF34A853);
        label = 'Google Maps';
      } else if (a.contains('spotify') || a.contains('music') || a.contains('deezer')) {
        icon = Icons.headphones_rounded;
        color = const Color(0xFF1DB954);
        label = 'Música';
      } else if (a.contains('phone') || a.contains('dialer') || a.contains('incallui')) {
        icon = Icons.phone_rounded;
        color = const Color(0xFF4CAF50);
        label = 'Teléfono';
      } else if (a.contains('camera')) {
        icon = Icons.camera_alt_rounded;
        color = const Color(0xFF9C27B0);
        label = 'Cámara';
      } else {
        icon = Icons.apps_rounded;
        color = Colors.blue;
        label = (appLabel.isNotEmpty && !appLabel.startsWith('com.')) ? appLabel : app;
      }
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(phoneState == 'suspendido' ? 'Ultima app (pantalla apagada)' : 'Usando app',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 2),
                  Text(label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                ],
              ),
            ),
            if (hasApp && lastUpdate != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(phoneState == 'suspendido' ? 'Suspendido' : 'Activo',
                      style: TextStyle(fontSize: 10, color: phoneState == 'suspendido' ? Colors.orange : Colors.green)),
                  Text(_timeAgo2(lastUpdate!),
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasApp ? (phoneState == 'suspendido' ? Colors.orange : Colors.green) : cs.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo2(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
}

class _PhoneStateCard extends StatelessWidget {
  final String phoneStateFromDb;
  final bool isOnline;
  final DateTime? lastSeen;
  final ColorScheme cs;

  const _PhoneStateCard({
    required this.phoneStateFromDb,
    required this.isOnline,
    required this.lastSeen,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    String phoneState = 'apagado o sin conexion';
    Color stateColor = cs.onSurface.withValues(alpha: 0.4);
    IconData stateIcon = Icons.signal_wifi_off_rounded;

    final ls = lastSeen;
    final recentlySeen = ls != null && DateTime.now().difference(ls).inSeconds < 130;

    if (isOnline || recentlySeen) {
      final effectiveState = isOnline ? phoneStateFromDb : 'apagado';
      if (effectiveState == 'suspendido') {
        phoneState = 'suspendido (pantalla apagada)';
        stateColor = Colors.orange;
        stateIcon = Icons.screen_lock_landscape_rounded;
      } else if (effectiveState == 'bloqueado') {
        phoneState = 'bloqueado (pantalla bloqueada)';
        stateColor = Colors.orangeAccent;
        stateIcon = Icons.lock_outline_rounded;
      } else if (effectiveState == 'apagado') {
        phoneState = 'apagado (sin conexion)';
        stateColor = Colors.red;
        stateIcon = Icons.power_off_rounded;
      } else {
        phoneState = 'encendido (activo)';
        stateColor = Colors.green;
        stateIcon = Icons.phone_android_rounded;
      }
    }

    return _DetailCard(
      icon: stateIcon,
      label: 'Estado del telefono',
      value: phoneState,
      color: stateColor,
      cs: cs,
      isActive: phoneState != 'apagado o sin conexion',
    );
  }
}

class _LastNotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final DateTime? time;
  final String partnerName;
  final ColorScheme cs;

  const _LastNotificationCard({
    required this.notification,
    required this.time,
    required this.partnerName,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final app = notification['app'] as String? ?? '';
    final title = notification['title'] as String? ?? '';
    final text = notification['text'] as String? ?? '';

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_active_rounded, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ultima notificacion',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                  if (app.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(app,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                  ],
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(title,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(text,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (time != null) ...[
              const SizedBox(width: 8),
              Text('${time!.hour}:${time!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final ColorScheme cs;
  final bool isActive;
  final Widget? trailing;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
    this.isActive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            const SizedBox(width: 8),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : cs.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
