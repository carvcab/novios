import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../services/geofence_service.dart';
import '../../services/local_storage.dart';
import '../../models/user_model.dart';
import '../../models/place_model.dart';
import '../../models/zone_model.dart';
import '../../models/memory_model.dart';
import '../../widgets/glass_card.dart';

class LocationTab extends StatefulWidget {
  const LocationTab({super.key});

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  double? _myLat, _myLng;
  double? _partnerLat, _partnerLng;
  double _distanceKm = 0;
  double _partnerSpeed = 0;
  int _partnerBattery = -1;
  int _myBattery = -1;
  bool _partnerOnline = false;
  String _partnerName = '';
  String _partnerScreen = '';
  DateTime? _lastPartnerUpdate;
  bool _areTogether = false;
  bool _satelliteMode = false;
  String? _expandedSection;

  // Place CRUD controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _placeType = 'visited';

  // Zone management controllers
  final _zoneNameCtrl = TextEditingController();
  double _zoneRadius = 200;

  StreamSubscription? _partnerSub;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _togetherCtrl;
  late Animation<double> _togetherScale;
  Timer? _batteryTimer;
  Timer? _updateTimer;

  // Privacy settings
  bool _shareLocation = true;
  bool _shareHistory = false;
  bool _shareBattery = true;
  bool _shareSpeed = false;
  bool _shareGeofences = true;
  bool _shareArrival = true;

  @override
  void initState() {
    super.initState();

    _partnerName = LocalStorage().getPartnerName() ?? 'Pareja';
    _loadPrivacySettings();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseAnim = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseCtrl.repeat();

    _togetherCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _togetherScale = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _togetherCtrl, curve: Curves.easeInOut),
    );

    _initLocation();
    _listenPartner();
    _startBatteryMonitor();

    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _checkTogetherStatus();
    });
  }

  void _loadPrivacySettings() {
    final ls = LocalStorage();
    _shareLocation = ls.getBool('privacy_share_location', defaultValue: true);
    _shareHistory = ls.getBool('privacy_share_history');
    _shareBattery = ls.getBool('privacy_share_battery', defaultValue: true);
    _shareSpeed = ls.getBool('privacy_share_speed');
    _shareGeofences = ls.getBool('privacy_share_geofences', defaultValue: true);
    _shareArrival = ls.getBool('privacy_share_arrival', defaultValue: true);
  }

  void _savePrivacySetting(String key, bool val) {
    LocalStorage().setBool(key, val);
    FirebaseService().savePrivacySettings({
      'shareLocation': LocalStorage().getBool('privacy_share_location', defaultValue: true),
      'shareHistory': LocalStorage().getBool('privacy_share_history'),
      'shareBattery': LocalStorage().getBool('privacy_share_battery', defaultValue: true),
      'shareSpeed': LocalStorage().getBool('privacy_share_speed'),
      'shareGeofences': LocalStorage().getBool('privacy_share_geofences', defaultValue: true),
      'shareArrival': LocalStorage().getBool('privacy_share_arrival', defaultValue: true),
    });
  }

  void _initLocation() async {
    final pos = GeofenceService().lastPosition;
    if (pos != null) {
      setState(() {
        _myLat = pos.latitude;
        _myLng = pos.longitude;
      });
    }

    GeofenceService().onPositionUpdate = (p) {
      if (mounted) {
        setState(() {
          _myLat = p.latitude;
          _myLng = p.longitude;
        });
      }
    };

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _myLat = p.latitude;
          _myLng = p.longitude;
        });
        _mapController.move(LatLng(p.latitude, p.longitude), 15.0);
      }
    } catch (_) {}

    if (!GeofenceService().isMonitoring) {
      await GeofenceService().startMonitoring(userInitiated: true);
    }
  }

  void _listenPartner() async {
    final partnerId = await FirebaseService().getPartnerId();
    if (partnerId == null) return;

    _partnerSub = FirebaseService().streamUser(partnerId).listen((UserModel user) {
      if (!mounted) return;
      setState(() {
        _partnerLat = user.latitude;
        _partnerLng = user.longitude;
        _partnerOnline = user.isOnline;
        _partnerName = user.name.isNotEmpty ? user.name : (_partnerName);
        _partnerScreen = user.currentScreen;
        _partnerBattery = user.batteryLevel;
        _partnerSpeed = user.speed;
        _lastPartnerUpdate = user.lastLocationUpdate;
        if (_partnerLat != null && _partnerLng != null && _myLat != null && _myLng != null) {
          _distanceKm = GeofenceService().distanceTo(_partnerLat!, _partnerLng!);
        }
      });
      _checkTogetherStatus();
    });
  }

  void _startBatteryMonitor() {
    _updateBattery();
    _batteryTimer = Timer.periodic(const Duration(seconds: 60), (_) => _updateBattery());
  }

  void _updateBattery() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      if (mounted) setState(() => _myBattery = level);

      final userId = LocalStorage().getUserId();
      if (userId != null && _shareBattery) {
        FirebaseService().updateBatteryLevel(userId, level);
      }
    } catch (_) {}
  }

  void _checkTogetherStatus() {
    final wasTogether = _areTogether;
    final together = _distanceKm > 0 && _distanceKm < 0.02;
    if (together != wasTogether && mounted) {
      setState(() => _areTogether = together);
      if (together && !wasTogether) {
        _togetherCtrl.repeat(reverse: true);
        HapticFeedback.mediumImpact();
      } else if (!together) {
        _togetherCtrl.stop();
        _togetherCtrl.reset();
      }
    }
  }

  void _centerOnMe() {
    if (_myLat != null && _myLng != null) {
      _mapController.move(LatLng(_myLat!, _myLng!), 16.0);
    }
  }

  void _centerOnPartner() {
    if (_partnerLat != null && _partnerLng != null) {
      _mapController.move(LatLng(_partnerLat!, _partnerLng!), 16.0);
    }
  }

  void _centerBoth() {
    if (_myLat == null || _partnerLat == null) return;
    final centerLat = (_myLat! + _partnerLat!) / 2;
    final centerLng = (_myLng! + _partnerLng!) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 13.0);
  }

  void _openDirections() async {
    if (_partnerLat == null || _partnerLng == null) return;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$_partnerLat,$_partnerLng&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _sendArrivedSafe() async {
    HapticFeedback.heavyImpact();
    await GeofenceService().sendArrivalAlert();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('💞 ¡Check-in enviado!'),
            ],
          ),
          backgroundColor: Colors.pinkAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _sendSOS() async {
    HapticFeedback.heavyImpact();
    final msg = '🚨 SOS — Necesito ayuda! Batería: $_myBattery%';
    await GeofenceService().sendCheckIn(msg);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('🚨 Alerta SOS enviada'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _sendHeartToPartner() {
    HapticFeedback.lightImpact();
    FirebaseService().sendActivityNotification(
      '💗 Te envió un corazón desde el mapa',
      'location',
      icon: 'heart',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('💗 Corazón enviado'),
        backgroundColor: Colors.pinkAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _lastUpdateText() {
    if (_lastPartnerUpdate == null) return 'Sin datos';
    final diff = DateTime.now().difference(_lastPartnerUpdate!);
    if (diff.inSeconds < 30) return 'Ahora mismo';
    if (diff.inMinutes < 1) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    return 'Hace ${diff.inHours}h';
  }

  @override
  void dispose() {
    _partnerSub?.cancel();
    _pulseCtrl.dispose();
    _togetherCtrl.dispose();
    _batteryTimer?.cancel();
    _updateTimer?.cancel();
    _sheetCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _zoneNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        _buildMap(cs, isDark),

        // Top bar
        Positioned(
          top: 8,
          left: 16,
          right: 16,
          child: _buildTopBar(cs, isDark),
        ),

        // Map controls (right)
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).size.height * 0.35 + 16,
          child: _buildMapControls(cs, isDark),
        ),

        // Together badge
        if (_areTogether)
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(child: _buildTogetherBadge(cs)),
          ),

        // Zone list overlay
        Positioned(
          top: 70,
          left: 60,
          right: 60,
          child: _buildZoneOverlay(cs),
        ),

        // Bottom sheet
        _buildBottomSheet(cs, isDark),

        // SOS + Arrived Safe buttons
        Positioned(
          left: 16,
          bottom: MediaQuery.of(context).size.height * 0.35 + 16,
          child: Column(
            children: [
              _buildSOSButton(cs),
              const SizedBox(height: 10),
              _buildArrivedButton(cs),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  MAP
  // ─────────────────────────────────────────────
  Widget _buildMap(ColorScheme cs, bool isDark) {
    final myLatLng = (_myLat != null && _myLng != null) ? LatLng(_myLat!, _myLng!) : null;
    final partnerLatLng = (_partnerLat != null && _partnerLng != null) ? LatLng(_partnerLat!, _partnerLng!) : null;
    final center = myLatLng ?? const LatLng(4.6097, -74.0817);

    final mapUrl = isDark
        ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onLongPress: (tapPos, latlng) => _showMapActionSheet(latlng.latitude, latlng.longitude),
      ),
      children: [
        // Tile layer
        TileLayer(
          urlTemplate: _satelliteMode
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : mapUrl,
          userAgentPackageName: 'com.everus.app',
          maxZoom: 19,
        ),

        // Geofence zones (filled circles)
        StreamBuilder<List<ZoneModel>>(
          stream: FirebaseService().streamZones(),
          builder: (context, snapshot) {
            final zones = snapshot.data ?? [];
            return CircleLayer(
              circles: zones.map((z) => CircleMarker(
                point: LatLng(z.latitude, z.longitude),
                radius: z.radiusMeters,
                useRadiusInMeter: true,
                color: cs.primary.withValues(alpha: 0.08),
                borderColor: cs.primary.withValues(alpha: 0.3),
                borderStrokeWidth: 2,
              )).toList(),
            );
          },
        ),

        // Geofence zones (outline circles)
        StreamBuilder<List<ZoneModel>>(
          stream: FirebaseService().streamZones(),
          builder: (context, snapshot) {
            final zones = snapshot.data ?? [];
            return PolylineLayer(
              polylines: zones.map((z) => Polyline(
                points: _circlePoints(z.latitude, z.longitude, z.radiusMeters),
                color: cs.primary.withValues(alpha: 0.25),
                strokeWidth: 1.5,
              )).toList(),
            );
          },
        ),

        // Distance line between partners
        if (myLatLng != null && partnerLatLng != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [myLatLng, partnerLatLng],
                color: cs.primary.withValues(alpha: 0.4),
                strokeWidth: 2,
              ),
            ],
          ),

        // Main markers (me + partner)
        MarkerLayer(
          markers: [
            // My marker with pulse
            if (myLatLng != null)
              Marker(
                point: myLatLng,
                width: 60,
                height: 60,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.15 * (1 - _pulseCtrl.value)),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3 * (1 - _pulseCtrl.value)),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Partner marker
            if (partnerLatLng != null)
              Marker(
                point: partnerLatLng,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () => _showPartnerSheet(cs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 8)],
                        ),
                        child: Text(
                          _partnerName.split(' ').first,
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 10)],
                        ),
                        child: Icon(Icons.favorite_rounded, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Memory markers
        StreamBuilder<List<MemoryModel>>(
          stream: FirebaseService().streamMemories(),
          builder: (context, snapshot) {
            final memories = (snapshot.data ?? []).where((m) => m.latitude != null && m.longitude != null).toList();
            if (memories.isEmpty) return const SizedBox.shrink();
            return MarkerLayer(
              markers: memories.map((m) => Marker(
                point: LatLng(m.latitude!, m.longitude!),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showMemoryCard(m, cs),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.9),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              )).toList(),
            );
          },
        ),

        // Place markers (MapTab style)
        StreamBuilder<List<PlaceModel>>(
          stream: FirebaseService().streamPlaces(),
          builder: (context, snapshot) {
            final places = snapshot.data ?? [];
            if (places.isEmpty) return const SizedBox.shrink();
            return MarkerLayer(
              markers: places.map((p) => Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 36,
                height: 36,
                child: GestureDetector(
                  onTap: () => _showPlacePopup(p),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _placeColor(p.type).withValues(alpha: 0.85),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(_placeIcon(p.type), size: 14, color: Colors.white),
                  ),
                ),
              )).toList(),
            );
          },
        ),

        // Zone markers
        StreamBuilder<List<ZoneModel>>(
          stream: FirebaseService().streamZones(),
          builder: (context, snapshot) {
            final zones = snapshot.data ?? [];
            if (zones.isEmpty) return const SizedBox.shrink();
            return MarkerLayer(
              markers: zones.map((z) => Marker(
                point: LatLng(z.latitude, z.longitude),
                width: 100,
                height: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      z.autoDetected ? Icons.hub_rounded : Icons.notifications_active_rounded,
                      color: cs.primary,
                      size: 26,
                    ),
                    Text(
                      z.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  ZONE OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildZoneOverlay(ColorScheme cs) {
    return StreamBuilder<List<ZoneModel>>(
      stream: FirebaseService().streamZones(),
      builder: (ctx, snap) {
        final zones = snap.data ?? [];
        if (zones.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔔 Zonas activas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 4),
              ...zones.take(3).map((z) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(z.autoDetected ? Icons.hub_rounded : Icons.notifications_active_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${z.name} (${z.radiusMeters.toInt()}m)',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseService().deleteZone(z.id);
                        FirebaseService().sendActivityNotification('Eliminó la geocerca: "${z.name}" 🗑️', 'map', icon: 'zone');
                      },
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 14),
                    ),
                  ],
                ),
              )),
              if (zones.length > 3)
                Text(
                  '+${zones.length - 3} más...',
                  style: const TextStyle(fontSize: 9, color: Colors.white38),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar(ColorScheme cs, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _distanceKm > 0 ? '${_distanceKm.toStringAsFixed(1)} km' : 'Ubicación',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                    Text(
                      _partnerOnline ? '🟢 $_partnerName en línea' : '⚫ $_partnerName sin conexión',
                      style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              if (_shareBattery && _myBattery > 0)
                _BatteryChip(label: 'Yo', level: _myBattery, color: Colors.blue),
              if (_shareBattery && _partnerBattery > 0) ...[
                const SizedBox(width: 6),
                _BatteryChip(label: _partnerName.split(' ').first, level: _partnerBattery, color: cs.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MAP CONTROLS
  // ─────────────────────────────────────────────
  Widget _buildMapControls(ColorScheme cs, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapButton(
          icon: Icons.satellite_alt_rounded,
          active: _satelliteMode,
          cs: cs,
          isDark: isDark,
          onTap: () => setState(() => _satelliteMode = !_satelliteMode),
        ),
        const SizedBox(height: 8),
        _MapButton(
          icon: Icons.my_location_rounded,
          cs: cs,
          isDark: isDark,
          onTap: _centerOnMe,
        ),
        const SizedBox(height: 8),
        _MapButton(
          icon: Icons.favorite_rounded,
          cs: cs,
          isDark: isDark,
          onTap: _centerOnPartner,
          iconColor: cs.primary,
        ),
        const SizedBox(height: 8),
        _MapButton(
          icon: Icons.people_rounded,
          cs: cs,
          isDark: isDark,
          onTap: _centerBoth,
        ),
        const SizedBox(height: 8),
        _MapButton(
          icon: Icons.add_location_rounded,
          cs: cs,
          isDark: isDark,
          onTap: () => _addPlace(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  TOGETHER BADGE
  // ─────────────────────────────────────────────
  Widget _buildTogetherBadge(ColorScheme cs) {
    return AnimatedBuilder(
      animation: _togetherCtrl,
      builder: (ctx, child) => Transform.scale(
        scale: _togetherScale.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Están juntos ❤️',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BOTTOM SHEET
  // ─────────────────────────────────────────────
  Widget _buildBottomSheet(ColorScheme cs, bool isDark) {
    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: 0.32,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.12, 0.32, 0.85],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1A1A2E) : Colors.white).withValues(alpha: 0.88),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 14),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Partner Info Card
                  _buildPartnerCard(cs, isDark),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(cs, isDark),
                  const SizedBox(height: 20),

                  // Info Strips
                  _buildInfoStrips(cs),
                  const SizedBox(height: 20),

                  // Expandable Sections
                  _buildExpandableSection(
                    title: '📍 Historial',
                    sectionKey: 'history',
                    child: _buildHistorySection(cs),
                    cs: cs,
                  ),
                  _buildExpandableSection(
                    title: '⭐ Lugares',
                    sectionKey: 'places',
                    child: _buildPlacesSection(cs),
                    cs: cs,
                  ),
                  _buildExpandableSection(
                    title: '🔒 Privacidad',
                    sectionKey: 'privacy',
                    child: _buildPrivacySection(cs),
                    cs: cs,
                  ),
                  _buildExpandableSection(
                    title: '📊 Estadísticas',
                    sectionKey: 'stats',
                    child: _buildStatsSection(cs),
                    cs: cs,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _buildExpandableSection({
    required String title,
    required String sectionKey,
    required Widget child,
    required ColorScheme cs,
  }) {
    final isExpanded = _expandedSection == sectionKey;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() {
              _expandedSection = isExpanded ? null : sectionKey;
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: child,
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.05)),
      ],
    );
  }

  // ── Partner Card ──
  Widget _buildPartnerCard(ColorScheme cs, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
              boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 10)],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '💞 $_partnerName',
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _partnerOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _partnerOnline
                      ? (_partnerScreen.isNotEmpty ? '📱 $_partnerScreen' : '🟢 En línea')
                      : '⚫ Sin conexión',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  '📍 ${_lastUpdateText()}',
                  style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _distanceKm > 0 ? '${_distanceKm.toStringAsFixed(1)} km' : '--',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──
  Widget _buildQuickActions(ColorScheme cs, bool isDark) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.directions_rounded,
          label: 'Cómo llegar',
          color: Colors.blue,
          onTap: _openDirections,
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.favorite_rounded,
          label: 'Corazón',
          color: cs.primary,
          onTap: _sendHeartToPartner,
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.share_rounded,
          label: 'Compartir',
          color: Colors.teal,
          onTap: () => GeofenceService().sendHeadingHome(),
        ),
        const SizedBox(width: 10),
        _QuickActionButton(
          icon: Icons.privacy_tip_rounded,
          label: 'Privacidad',
          color: Colors.grey,
          onTap: () => setState(() {
            _expandedSection = _expandedSection == 'privacy' ? null : 'privacy';
          }),
        ),
      ],
    );
  }

  // ── Info Strips ──
  Widget _buildInfoStrips(ColorScheme cs) {
    return Row(
      children: [
        Expanded(child: _InfoChip(icon: Icons.speed_rounded, label: 'Velocidad', value: '${_partnerSpeed.toStringAsFixed(0)} km/h', color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _InfoChip(
          icon: Icons.battery_std_rounded,
          label: 'Batería',
          value: _partnerBattery > 0 ? '$_partnerBattery%' : '--',
          color: _partnerBattery < 20 ? Colors.red : Colors.green,
        )),
        const SizedBox(width: 8),
        Expanded(child: _InfoChip(
          icon: Icons.timer_rounded,
          label: 'Actualizado',
          value: _lastUpdateText(),
          color: Colors.blue,
        )),
      ],
    );
  }

  // ── History Section ──
  Widget _buildHistorySection(ColorScheme cs) {
    final history = GeofenceService().getLocationHistory(hours: 24);
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text('Sin historial hoy', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)))),
      );
    }

    final entries = history.reversed.take(20).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hoy', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 8),
        ...entries.map((e) {
          final t = DateTime.tryParse(e['time'] ?? '');
          final timeStr = t != null ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}' : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 2,
                  height: 30,
                  color: cs.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${(e['lat'] as double?)?.toStringAsFixed(4) ?? ''}, ${(e['lng'] as double?)?.toStringAsFixed(4) ?? ''}',
                            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.7)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(timeStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Places Section ──
  Widget _buildPlacesSection(ColorScheme cs) {
    return StreamBuilder<List<PlaceModel>>(
      stream: FirebaseService().streamPlaces(),
      builder: (context, snapshot) {
        final places = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lugares Favoritos', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                TextButton.icon(
                  onPressed: () => _addPlace(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Agregar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (places.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('No hay lugares guardados', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)))),
              )
            else
              ...places.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () => _editOrDeletePlace(p),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _placeColor(p.type).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_placeIcon(p.type), size: 18, color: _placeColor(p.type)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
                            if (p.description != null && p.description!.isNotEmpty)
                              Text(p.description!, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              )),
          ],
        );
      },
    );
  }

  // ── Privacy Section ──
  Widget _buildPrivacySection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🔒 Privacidad', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Controla exactamente qué compartes', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 12),
        _PrivacyToggle(label: 'Ubicación en tiempo real', value: _shareLocation, icon: Icons.location_on_rounded,
          onChanged: (v) => setState(() { _shareLocation = v; _savePrivacySetting('privacy_share_location', v); })),
        _PrivacyToggle(label: 'Historial de ubicaciones', value: _shareHistory, icon: Icons.history_rounded,
          onChanged: (v) => setState(() { _shareHistory = v; _savePrivacySetting('privacy_share_history', v); })),
        _PrivacyToggle(label: 'Batería', value: _shareBattery, icon: Icons.battery_std_rounded,
          onChanged: (v) => setState(() { _shareBattery = v; _savePrivacySetting('privacy_share_battery', v); })),
        _PrivacyToggle(label: 'Velocidad', value: _shareSpeed, icon: Icons.speed_rounded,
          onChanged: (v) => setState(() { _shareSpeed = v; _savePrivacySetting('privacy_share_speed', v); })),
        _PrivacyToggle(label: 'Geocercas', value: _shareGeofences, icon: Icons.fence_rounded,
          onChanged: (v) => setState(() { _shareGeofences = v; _savePrivacySetting('privacy_share_geofences', v); })),
        _PrivacyToggle(label: 'Notificaciones de llegada', value: _shareArrival, icon: Icons.notifications_active_rounded,
          onChanged: (v) => setState(() { _shareArrival = v; _savePrivacySetting('privacy_share_arrival', v); })),
      ],
    );
  }

  // ── Stats Section ──
  Widget _buildStatsSection(ColorScheme cs) {
    final history = GeofenceService().getLocationHistory(hours: 24 * 365);
    final totalPoints = history.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📊 Estadísticas', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Puntos GPS', value: '$totalPoints', icon: Icons.location_on_rounded, color: cs.primary)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Distancia hoy', value: '${_distanceKm.toStringAsFixed(1)} km', icon: Icons.straighten_rounded, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Estado', value: _areTogether ? 'Juntos ❤️' : 'Separados', icon: Icons.people_rounded, color: Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Compartiendo', value: GeofenceService().isMonitoring ? 'Activo' : 'Inactivo', icon: Icons.share_location_rounded, color: Colors.orange)),
          ],
        ),
      ],
    );
  }

  // ── FABs ──
  Widget _buildArrivedButton(ColorScheme cs) {
    return GestureDetector(
      onTap: _sendArrivedSafe,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text('Llegué bien', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton(ColorScheme cs) {
    return GestureDetector(
      onLongPress: _sendSOS,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('SOS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PLACE CRUD (from MapTab)
  // ─────────────────────────────────────────────
  void _showMapActionSheet(double lat, double lng) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Qué deseas agregar aquí?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.add_location_rounded, color: cs.primary),
                title: const Text('Agregar Lugar Especial'),
                subtitle: const Text('Guarda este sitio en tu álbum de mapa'),
                onTap: () {
                  Navigator.pop(context);
                  _addPlace(latitude: lat, longitude: lng);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded, color: Colors.orange),
                title: const Text('Agregar Zona de Geocerca'),
                subtitle: const Text('Recibe avisos automáticos al entrar/salir'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddZoneDialog(lat, lng);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addPlace({double? latitude, double? longitude}) {
    double targetLat = _myLat ?? 19.4326;
    double targetLng = _myLng ?? -99.1332;
    if (latitude != null && longitude != null) {
      targetLat = latitude;
      targetLng = longitude;
    }
    _nameCtrl.clear();
    _descCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.add_location_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Agregar Lugar'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del lugar'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _placeType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'visited', child: Text('Visitado')),
                    DropdownMenuItem(value: 'wish', child: Text('Por visitar')),
                    DropdownMenuItem(value: 'restaurant', child: Text('Restaurante favorito')),
                    DropdownMenuItem(value: 'dream', child: Text('País soñado')),
                    DropdownMenuItem(value: 'first_date', child: Text('Primera cita')),
                    DropdownMenuItem(value: 'first_trip', child: Text('Primer viaje')),
                  ],
                  onChanged: (v) => setDialogState(() => _placeType = v ?? 'visited'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ubicación detectada automáticamente.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty) return;
                final placeName = _nameCtrl.text.trim();
                final place = PlaceModel(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: placeName,
                  description: _descCtrl.text.trim(),
                  latitude: targetLat,
                  longitude: targetLng,
                  type: _placeType,
                );
                await FirebaseService().savePlace(place);
                FirebaseService().sendActivityNotification('Añadió el lugar especial: "$placeName" 📍', 'map', icon: 'place');
                _nameCtrl.clear();
                _descCtrl.clear();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _editOrDeletePlace(PlaceModel place) {
    final nameCtrl = TextEditingController(text: place.name);
    final descCtrl = TextEditingController(text: place.description);
    String typeVal = place.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.edit_location_alt_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Editar Lugar'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del lugar')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: typeVal,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'visited', child: Text('Visitado')),
                    DropdownMenuItem(value: 'wish', child: Text('Por visitar')),
                    DropdownMenuItem(value: 'restaurant', child: Text('Restaurante favorito')),
                    DropdownMenuItem(value: 'dream', child: Text('País soñado')),
                    DropdownMenuItem(value: 'first_date', child: Text('Primera cita')),
                    DropdownMenuItem(value: 'first_trip', child: Text('Primer viaje')),
                  ],
                  onChanged: (v) => setDialogState(() => typeVal = v ?? 'visited'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('¿Eliminar lugar?'),
                    content: const Text('Esta acción borrará el lugar permanentemente.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(confirmCtx), child: const Text('Cancelar')),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseService().deletePlace(place.id);
                          FirebaseService().sendActivityNotification('Eliminó un lugar especial 🗑️', 'map', icon: 'place');
                          if (confirmCtx.mounted) Navigator.pop(confirmCtx);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final updated = place.copyWith(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  type: typeVal,
                );
                await FirebaseService().savePlace(updated);
                FirebaseService().sendActivityNotification('Actualizó el lugar especial: "${updated.name}" 📝', 'map', icon: 'place');
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlacePopup(PlaceModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(_placeIcon(p.type), color: _placeColor(p.type)),
            const SizedBox(width: 8),
            Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Text(p.description != null && p.description!.isNotEmpty ? p.description! : 'Sin descripción adicional.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _editOrDeletePlace(p);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  void _showAddZoneDialog(double lat, double lng) {
    _zoneNameCtrl.clear();
    _zoneRadius = 200;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Nueva Zona'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _zoneNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de la zona', hintText: 'Ej: Casa, Trabajo, Café...'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lat: ${lat.toStringAsFixed(5)}, Lon: ${lng.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Radio:', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: _zoneRadius,
                        min: 30,
                        max: 1000,
                        divisions: 20,
                        label: '${_zoneRadius.toInt()}m',
                        onChanged: (v) => setDialogState(() => _zoneRadius = v),
                      ),
                    ),
                    Text('${_zoneRadius.toInt()}m', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (_zoneNameCtrl.text.trim().isEmpty) return;
                final zoneName = _zoneNameCtrl.text.trim();
                final zone = ZoneModel(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: zoneName,
                  latitude: lat,
                  longitude: lng,
                  radiusMeters: _zoneRadius,
                );
                FirebaseService().saveZone(zone);
                FirebaseService().sendActivityNotification('Creó una nueva geocerca: "$zoneName" 🔔', 'map', icon: 'zone');
                Navigator.pop(ctx);
              },
              child: const Text('Guardar Zona'),
            ),
          ],
        ),
      ),
    );
  }

  List<LatLng> _circlePoints(double lat, double lon, double radiusMeters) {
    final points = <LatLng>[];
    final steps = 36;
    for (int i = 0; i <= steps; i++) {
      final angle = (i * 360 / steps) * pi / 180;
      final dx = radiusMeters * cos(angle);
      final dy = radiusMeters * sin(angle);
      final dLat = dy / 111320;
      final dLon = dx / (111320 * cos(lat * pi / 180));
      points.add(LatLng(lat + dLat, lon + dLon));
    }
    return points;
  }

  // ── Helpers ──
  void _showPartnerSheet(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
                  ),
                  child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text('💞 $_partnerName', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _partnerOnline ? Colors.green : Colors.grey)),
                    const SizedBox(width: 6),
                    Text(_partnerOnline ? 'En línea' : 'Sin conexión', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DetailItem(icon: Icons.straighten_rounded, label: 'Distancia', value: '${_distanceKm.toStringAsFixed(1)} km'),
                    _DetailItem(icon: Icons.battery_std_rounded, label: 'Batería', value: _partnerBattery > 0 ? '$_partnerBattery%' : '--'),
                    _DetailItem(icon: Icons.speed_rounded, label: 'Velocidad', value: '${_partnerSpeed.toStringAsFixed(0)} km/h'),
                    _DetailItem(icon: Icons.access_time_rounded, label: 'Actualizado', value: _lastUpdateText()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Cómo llegar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendHeartToPartner();
                      },
                      icon: const Icon(Icons.favorite_rounded, size: 18),
                      label: const Text('Corazón'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemoryCard(MemoryModel memory, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_rounded, size: 32, color: Colors.amber),
            const SizedBox(height: 8),
            Text(memory.title, style: GoogleFonts.caveat(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('📅 ${memory.date.day}/${memory.date.month}/${memory.date.year}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            if (memory.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(memory.description, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          ],
        ),
      ),
    );
  }

  IconData _placeIcon(String type) {
    switch (type) {
      case 'visited': return Icons.check_circle_rounded;
      case 'wish': return Icons.star_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'dream': return Icons.public_rounded;
      case 'first_date': return Icons.favorite_rounded;
      case 'first_trip': return Icons.flight_takeoff_rounded;
      default: return Icons.place_rounded;
    }
  }

  Color _placeColor(String type) {
    switch (type) {
      case 'visited': return Colors.green;
      case 'wish': return Colors.amber;
      case 'restaurant': return Colors.orange;
      case 'dream': return Colors.purple;
      case 'first_date': return const Color(0xFFFF5C8A);
      case 'first_trip': return Colors.blue;
      default: return const Color(0xFFFF5C8A);
    }
  }
}

// ═══════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════

class _BatteryChip extends StatelessWidget {
  final String label;
  final int level;
  final Color color;
  const _BatteryChip({required this.label, required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level > 50 ? Icons.battery_full_rounded : (level > 20 ? Icons.battery_3_bar_rounded : Icons.battery_alert_rounded),
            size: 12,
            color: level < 20 ? Colors.red : color,
          ),
          const SizedBox(width: 3),
          Text('$level%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isDark;
  final bool active;
  final Color? iconColor;
  const _MapButton({required this.icon, required this.onTap, required this.cs, required this.isDark, this.active = false, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? cs.primary.withValues(alpha: 0.2)
                  : (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: Icon(icon, size: 20, color: iconColor ?? (active ? cs.primary : cs.onSurface.withValues(alpha: 0.7))),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface), textAlign: TextAlign.center),
          Text(label, style: TextStyle(fontSize: 8, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;
  const _PrivacyToggle({required this.label, required this.value, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? cs.primary : cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface))),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface)),
        Text(label, style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
