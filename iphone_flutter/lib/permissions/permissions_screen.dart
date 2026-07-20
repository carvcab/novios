import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:google_fonts/google_fonts.dart';
import '../services/app_tracker.dart';
import '../services/local_storage.dart';
import '../views/home_navigation.dart';
import '../widgets/glass_card.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _tracker = AppTracker();
  bool _notifPushGranted = false;
  bool _locationGranted = false;
  bool _cameraGranted = false;
  bool _microphoneGranted = false;
  bool _galleryGranted = false;
  bool _usageGranted = false;
  bool _notifGranted = false;
  bool _overlayGranted = false;
  bool _batteryGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    try {
      final notifPushGranted = await ph.Permission.notification.isGranted;
      
      final locStatus = await ph.Permission.location.status;
      final locationGranted = locStatus == ph.PermissionStatus.granted || 
                              await ph.Permission.locationAlways.isGranted;
                              
      final cameraGranted = await ph.Permission.camera.isGranted;
      final microphoneGranted = await ph.Permission.microphone.isGranted;
      
      final galleryGranted = await ph.Permission.photos.isGranted || 
                             await ph.Permission.storage.isGranted;

      final results = await Future.wait([
        _tracker.hasUsageStatsPermission(),
        _tracker.hasNotificationAccess(),
        _tracker.hasOverlayPermission(),
        _tracker.isBatteryOptimizationIgnored(),
      ]);

      if (!mounted) return;
      setState(() {
        _notifPushGranted = notifPushGranted;
        _locationGranted = locationGranted;
        _cameraGranted = cameraGranted;
        _microphoneGranted = microphoneGranted;
        _galleryGranted = galleryGranted;
        _usageGranted = results[0];
        _notifGranted = results[1];
        _overlayGranted = results[2];
        _batteryGranted = results[3];
      });
    } catch (e) {
      debugPrint("Error checking permissions: $e");
    }
  }

  Future<void> _requestPermission(ph.Permission perm) async {
    final status = await perm.request();
    if (status.isPermanentlyDenied) {
      await ph.openAppSettings();
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _checkPermissions();
  }

  Future<void> _requestLocation() async {
    final status = await ph.Permission.location.request();
    if (status.isGranted) {
      // Try to request always for background geofencing
      await ph.Permission.locationAlways.request();
    } else if (status.isPermanentlyDenied) {
      await ph.openAppSettings();
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _checkPermissions();
  }

  Future<void> _requestGallery() async {
    // Request both to cover all Android versions
    await ph.Permission.photos.request();
    await ph.Permission.storage.request();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _checkPermissions();
  }

  Future<void> _requestUsage() async {
    await _tracker.openUsageStatsSettings();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) _checkPermissions();
  }

  Future<void> _requestNotificationListener() async {
    await _tracker.openNotificationAccessSettings();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) _checkPermissions();
  }

  Future<void> _requestOverlay() async {
    await _tracker.openOverlaySettings();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) _checkPermissions();
  }

  Future<void> _requestBattery() async {
    await _tracker.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) _checkPermissions();
  }

  Future<void> _finish() async {
    await _tracker.startTracking();
    if (mounted) {
      LocalStorage().setBool('permissions_granted', true);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeNavigation()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allRequiredGranted = _notifPushGranted && 
                               _locationGranted && 
                               _cameraGranted && 
                               _microphoneGranted && 
                               _galleryGranted && 
                               _usageGranted && 
                               _notifGranted;

    return Scaffold(
      appBar: AppBar(
        title: Text('Permisos de la Aplicación', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Para que EverUs funcione correctamente necesitas activar los permisos desde los Ajustes del Sistema.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Para Xiaomi/HyperOS:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade800)),
                                const SizedBox(height: 4),
                                Text(
                                  '1. Abre Ajustes → Apps → Administrar apps → EverUs\n'
                                  '2. Activa "Autoinicio" y "Mostrar ventana emergente"\n'
                                  '3. En Recientes, bloquea la app (mantén presionado → candado)\n'
                                  '4. Ajustes → Batería → Batería de apps → EverUs → Sin restricciones',
                                  style: TextStyle(fontSize: 11, color: Colors.amber.shade800, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _SectionTitle(title: 'Permisos de Sistema', cs: cs),
                    const SizedBox(height: 10),
                    
                    _PermissionTile(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notificaciones Push',
                      subtitle: 'Recibe cartas, alertas de chat y avisos en vivo de tu pareja.',
                      granted: _notifPushGranted,
                      cs: cs,
                      onRequest: () => _requestPermission(ph.Permission.notification),
                    ),
                    const SizedBox(height: 10),
                    
                    _PermissionTile(
                      icon: Icons.location_on_rounded,
                      title: 'Ubicación en tiempo real',
                      subtitle: 'Muestra tu posición en el mapa y notifica cuando llegas a zonas seguras.',
                      granted: _locationGranted,
                      cs: cs,
                      onRequest: _requestLocation,
                    ),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.camera_alt_rounded,
                      title: 'Cámara',
                      subtitle: 'Captura fotos al instante para subirlas al álbum de recuerdos.',
                      granted: _cameraGranted,
                      cs: cs,
                      onRequest: () => _requestPermission(ph.Permission.camera),
                    ),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.mic_rounded,
                      title: 'Micrófono',
                      subtitle: 'Graba notas de voz y mensajes de audio directo en el chat.',
                      granted: _microphoneGranted,
                      cs: cs,
                      onRequest: () => _requestPermission(ph.Permission.microphone),
                    ),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.photo_library_rounded,
                      title: 'Galería y Fotos',
                      subtitle: 'Elige imágenes o videos guardados para decorar tu timeline.',
                      granted: _galleryGranted,
                      cs: cs,
                      onRequest: _requestGallery,
                    ),
                    
                    const SizedBox(height: 20),
                    _SectionTitle(title: 'Monitoreo en Vivo (Requerido para compartir pantalla)', cs: cs),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Acceso a uso de apps',
                      subtitle: 'Ajustes → Acceso de uso → EverUs → Permitir. Muestra en qué app estás en vivo.',
                      granted: _usageGranted,
                      cs: cs,
                      onRequest: _requestUsage,
                    ),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.notifications_rounded,
                      title: 'Acceso a notificaciones',
                      subtitle: 'Ajustes → Acceso a notificaciones → EverUs → Permitir. Sincroniza notificaciones en vivo.',
                      granted: _notifGranted,
                      cs: cs,
                      onRequest: _requestNotificationListener,
                    ),

                    const SizedBox(height: 20),
                    _SectionTitle(title: 'Para Xiaomi/HyperOS (Obligatorio)', cs: cs),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.power_settings_new_rounded,
                      title: 'Autoinicio',
                      subtitle: 'Permite que la app se inicie automaticamente al encender el telefono.',
                      granted: true,
                      cs: cs,
                      onRequest: () => _tracker.openXiaomiAutostart(),
                    ),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.picture_in_picture_rounded,
                      title: 'Mostrar sobre otras apps',
                      subtitle: 'Mantiene el servicio en segundo plano activo.',
                      granted: _overlayGranted,
                      cs: cs,
                      onRequest: _requestOverlay,
                    ),
                    const SizedBox(height: 10),

                    _PermissionTile(
                      icon: Icons.battery_saver_rounded,
                      title: 'Desactivar ahorro de batería',
                      subtitle: 'Evita que el sistema detenga la app al bloquear el movil.',
                      granted: _batteryGranted,
                      cs: cs,
                      onRequest: _requestBattery,
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bloquear en Recientes:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade800)),
                                const SizedBox(height: 4),
                                Text(
                                  'Abre la lista de apps recientes, mantén presionado EverUs y toca el candado 🔒',
                                  style: TextStyle(fontSize: 11, color: Colors.amber.shade800, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
              ),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: _finish,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: allRequiredGranted ? Colors.green : cs.primary,
                    ),
                    child: Text(
                      allRequiredGranted ? 'Comenzar 💖' : 'Continuar de todas formas',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!allRequiredGranted)
                    TextButton(
                      onPressed: () async { await ph.openAppSettings(); },
                      child: Text(
                        'Abrir Ajustes del Sistema',
                        style: TextStyle(color: cs.primary.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme cs;

  const _SectionTitle({required this.title, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: cs.primary,
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool granted;
  final ColorScheme cs;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.cs,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (granted ? Colors.green : cs.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: granted ? Colors.green : cs.primary, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface),
              ),
            ),
            if (granted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Activo',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pendiente',
                  style: TextStyle(color: cs.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6), height: 1.3)),
        ),
        trailing: !granted
            ? IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onPressed: onRequest,
              )
            : null,
      ),
    );
  }
}
