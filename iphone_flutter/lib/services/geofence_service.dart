import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/zone_model.dart';
import '../models/place_model.dart';
import 'firebase_service.dart';
import 'local_storage.dart';
import 'widget_service.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._();
  factory GeofenceService() => _instance;
  GeofenceService._();

  StreamSubscription<Position>? _positionSub;
  bool _isMonitoring = false;
  final Set<String> _insideZones = {};
  List<ZoneModel> _cachedZones = [];
  List<PlaceModel> _cachedPlaces = [];
  DateTime _lastZoneRefresh = DateTime(2000);
  final Set<String> _recentNotifications = {};
  DateTime _lastFirebaseUpdate = DateTime(2000);
  DateTime _lastHistorySave = DateTime(2000);
  List<Map<String, dynamic>> _locationHistory = [];
  Position? _lastPosition;
  double? _partnerLat;
  double? _partnerLng;
  bool _partnerOnline = false;
  StreamSubscription? _partnerSub2;
  String _lastMotionState = 'static';
  DateTime _locationUpdateDebounce = DateTime(2000);

  bool get areTogether {
    if (_lastPosition == null || _partnerLat == null || _partnerLng == null) return false;
    final dist = _distance(_lastPosition!.latitude, _lastPosition!.longitude, _partnerLat!, _partnerLng!);
    return dist < 20.0;
  }

  void _listenPartnerLocation() async {
    _partnerSub2?.cancel();
    if (!FirebaseService().isFirebaseAvailable) return;
    final partnerId = await FirebaseService().getPartnerId();
    if (partnerId == null) return;
    _partnerSub2 = FirebaseService().streamUser(partnerId).listen((user) {
      _partnerLat = user.latitude;
      _partnerLng = user.longitude;
      _partnerOnline = user.isOnline;

      double? dist;
      if (_lastPosition != null && _partnerLat != null && _partnerLng != null) {
        dist = distanceTo(_partnerLat!, _partnerLng!);
        if (dist < 0) dist = null;
      }
      WidgetService().updateDistance(dist, _partnerOnline);
    }, onError: (err) {
      debugPrint("[Geofence] Partner listener error: $err");
      FirebaseService.recordError(err);
    });
  }

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const int _persistentNotificationId = 9999;

  bool _initialized = false;

  void Function(Position pos)? onPositionUpdate;
  void Function(double km)? onDistanceUpdate;

  Future<bool> init() async {
    if (_initialized) return true;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
    _locationHistory = LocalStorage().getLocalList('location_history');
    _tryAutoStart();
    return true;
  }

  Future<void> _tryAutoStart() async {
    await Future.delayed(const Duration(seconds: 2));
    if (LocalStorage().getBool('location_sharing_enabled')) {
      await startMonitoring();
    }
  }

  Future<bool> requestPermissions({bool userInitiated = true}) async {
    return await _requestPermission(userInitiated: userInitiated);
  }

  Future<bool> _requestPermission({bool userInitiated = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (userInitiated) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (userInitiated) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    if (permission == LocationPermission.whileInUse) {
      if (userInitiated) {
        permission = await Geolocator.requestPermission();
      }
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  LocationSettings _getAdaptiveSettings() {
    if (_lastPosition == null || _lastPosition!.speed < 0) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      );
    }

    final speedMs = _lastPosition!.speed;
    final speedKmh = speedMs * 3.6;

    if (speedKmh > 50) {
      _lastMotionState = 'driving';
      return const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 100,
      );
    } else if (speedKmh > 10) {
      _lastMotionState = 'walking';
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      );
    } else {
      _lastMotionState = 'static';
      return const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 50,
      );
    }
  }

  Future<bool> startMonitoring({bool userInitiated = false}) async {
    if (_isMonitoring) return true;
    if (!await _requestPermission(userInitiated: userInitiated)) return false;

    _isMonitoring = true;
    LocalStorage().setBool('location_sharing_enabled', true);

    _tryUpdateFirebasePosition();
    _listenPartnerLocation();

    final settings = _getAdaptiveSettings();
    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (e) => debugPrint("Geofence error: $e"),
    );

    _showPersistentNotification();
    return true;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    LocalStorage().setBool('location_sharing_enabled', false);
    _positionSub?.cancel();
    _positionSub = null;
    _partnerSub2?.cancel();
    _partnerSub2 = null;
    _insideZones.clear();
    _cachedZones = [];
    _notifications.cancel(id: _persistentNotificationId);
  }

  bool get isMonitoring => _isMonitoring;
  Position? get lastPosition => _lastPosition;

  double distanceTo(double lat, double lon) {
    if (_lastPosition == null) return -1;
    return _distance(_lastPosition!.latitude, _lastPosition!.longitude, lat, lon) / 1000;
  }

  void _onPosition(Position pos) {
    final oldSpeed = _lastPosition?.speed ?? -1;
    _lastPosition = pos;

    final newSettings = _getAdaptiveSettings();
    final speedChanged = (pos.speed < 0 && oldSpeed >= 0) || (pos.speed >= 0 && oldSpeed < 0) ||
        (pos.speed >= 0 && oldSpeed >= 0 && (pos.speed - oldSpeed).abs() > 2);

    if (speedChanged && _positionSub != null) {
      _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(locationSettings: newSettings).listen(
        _onPosition,
        onError: (e) => debugPrint("Geofence error: $e"),
      );
    }

    final now = DateTime.now();
    if (now.difference(_locationUpdateDebounce).inSeconds < 10) return;
    _locationUpdateDebounce = now;

    final shareGeofences = LocalStorage().getBool('privacy_share_geofences', defaultValue: true);
    if (shareGeofences) {
      _checkZones(pos);
    }

    _tryUpdateFirebasePosition();

    final shareHistory = LocalStorage().getBool('privacy_share_history', defaultValue: false);
    if (shareHistory) {
      _trySaveHistory(pos);
    }

    double? dist;
    if (_partnerLat != null && _partnerLng != null) {
      dist = distanceTo(_partnerLat!, _partnerLng!);
      if (dist < 0) dist = null;
    }
    WidgetService().updateDistance(dist, _partnerOnline);

    onPositionUpdate?.call(pos);
  }

  Future<void> _tryUpdateFirebasePosition() async {
    final now = DateTime.now();
    final secondsSinceLastUpdate = now.difference(_lastFirebaseUpdate).inSeconds;

    if (_lastMotionState == 'static') {
      if (secondsSinceLastUpdate < 300) return;
    } else if (_lastMotionState == 'walking') {
      if (secondsSinceLastUpdate < 120) return;
    } else {
      if (secondsSinceLastUpdate < 60) return;
    }

    _lastFirebaseUpdate = now;

    final userId = LocalStorage().getUserId();
    if (userId == null || _lastPosition == null) return;

    final shareLocation = LocalStorage().getBool('privacy_share_location', defaultValue: true);
    if (!shareLocation) return;

    final shareSpeed = LocalStorage().getBool('privacy_share_speed', defaultValue: false);
    final speedKmh = shareSpeed ? (_lastPosition!.speed * 3.6) : 0.0;

    try {
      if (!FirebaseService().isFirebaseAvailable) return;
      final firebase = FirebaseService();
      await firebase.updateUserPosition(
        userId,
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        speed: speedKmh,
      );
    } catch (e) {
      FirebaseService.recordError(e);
    }
  }

  Future<void> _trySaveHistory(Position pos) async {
    final now = DateTime.now();
    if (now.difference(_lastHistorySave).inMinutes < 5) return;
    _lastHistorySave = now;

    _locationHistory.add({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'time': now.toIso8601String(),
      'accuracy': pos.accuracy,
    });

    if (_locationHistory.length > 500) {
      _locationHistory = _locationHistory.sublist(_locationHistory.length - 500);
    }
    LocalStorage().saveLocalList('location_history', _locationHistory);
  }

  List<Map<String, dynamic>> getLocationHistory({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _locationHistory.where((e) {
      final t = DateTime.tryParse(e['time'] ?? '');
      return t != null && t.isAfter(cutoff);
    }).toList();
  }

  Future<void> sendCheckIn(String message) async {
    final pos = _lastPosition;
    if (pos == null) return;

    final userId = LocalStorage().getUserId() ?? 'local_user_id';
    final userName = LocalStorage().getUserName() ?? 'Tu';
    final firebase = FirebaseService();

    await firebase.sendCheckIn(userId, userName, message, pos.latitude, pos.longitude);

    _showNotification(
      'Check-in enviado',
      message,
      'checkin_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> sendArrivalAlert() async {
    await sendCheckIn('Llegue bien!  Estoy en mi destino');
  }

  Future<void> sendHeadingHome() async {
    await sendCheckIn('Voy para casa');
  }

  bool isSpeeding(double thresholdKmh) {
    if (_lastPosition == null) return false;
    final speedKmh = _lastPosition!.speed * 3.6;
    return speedKmh > thresholdKmh;
  }

  void _showPersistentNotification() {
    _notifications.show(
      id: _persistentNotificationId,
      title: 'Compartiendo ubicacion',
      body: 'Tu pareja puede ver tu ubicacion en tiempo real',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'geofence_channel',
          'Ubicacion en vivo',
          channelDescription: 'Notificacion de ubicacion compartida',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _refreshZones() async {
    final now = DateTime.now();
    if (now.difference(_lastZoneRefresh).inSeconds < 30) return;
    _lastZoneRefresh = now;
    if (!FirebaseService().isFirebaseAvailable) return;
    try {
      _cachedZones = await FirebaseService().streamZones().first;
      _cachedPlaces = await FirebaseService().streamPlaces().first;
    } catch (e) {
      FirebaseService.recordError(e);
    }
  }

  void _checkZones(Position pos) async {
    try {
      if (areTogether) return;
      await _refreshZones();

      for (final zone in _cachedZones) {
        final dist = _distance(pos.latitude, pos.longitude, zone.latitude, zone.longitude);
        final inside = dist <= zone.radiusMeters;
        final wasInside = _insideZones.contains(zone.id);

        if (inside && !wasInside && zone.notifyOnEnter) {
          _insideZones.add(zone.id);
          _notifyZoneEnter(zone, dist);
        } else if (!inside && wasInside && zone.notifyOnExit) {
          _insideZones.remove(zone.id);
          _notifyZoneExit(zone);
        }
      }

      for (final place in _cachedPlaces) {
        final dist = _distance(pos.latitude, pos.longitude, place.latitude, place.longitude);
        final inside = dist <= 150.0;
        final geofenceId = 'place_${place.id}';
        final wasInside = _insideZones.contains(geofenceId);

        if (inside && !wasInside) {
          _insideZones.add(geofenceId);
          _notifyPlaceArrive(place);
        } else if (!inside && wasInside) {
          _insideZones.remove(geofenceId);
        }
      }

      await _checkAutoDetect(pos, _cachedZones);
    } catch (e) {
      debugPrint("Error checking zones: $e");
    }
  }

  void _notifyZoneEnter(ZoneModel zone, double dist) {
    final dedupKey = 'zone_enter_${zone.id}';
    if (!_dedupNotification(dedupKey)) return;

    _showNotification(
      'Bienvenida a ${zone.name}',
      '${zone.autoDetected ? "Zona detectada" : "Tu lugar"}  ${dist.toStringAsFixed(0)}m',
      dedupKey,
    );
    FirebaseService().sendActivityNotification('Entro a la zona: "${zone.name}" 📍', 'map', icon: 'zone');
  }

  void _notifyZoneExit(ZoneModel zone) {
    final dedupKey = 'zone_exit_${zone.id}';
    if (!_dedupNotification(dedupKey)) return;

    _showNotification(
      'Saliste de ${zone.name}',
      'Te esperamos de vuelta',
      dedupKey,
    );
    FirebaseService().sendActivityNotification('Salio de la zona: "${zone.name}" 🚶', 'map', icon: 'zone');
  }

  void _notifyPlaceArrive(PlaceModel place) {
    final dedupKey = 'place_${place.id}';
    if (!_dedupNotification(dedupKey)) return;

    _showNotification(
      'Llegaste a ${place.name}',
      'Un lugar especial para ustedes',
      dedupKey,
    );
    FirebaseService().sendActivityNotification('Llego al lugar especial: "${place.name}" 📍', 'map', icon: 'place');
  }

  bool _dedupNotification(String dedupId) {
    final now = DateTime.now();
    final hourKey = '${dedupId}_${now.day}_${now.hour}';
    if (_recentNotifications.contains(hourKey)) return false;
    _recentNotifications.add(hourKey);
    if (_recentNotifications.length > 200) {
      final list = _recentNotifications.toList();
      _recentNotifications.clear();
      _recentNotifications.addAll(list.sublist(list.length - 100));
    }
    return true;
  }

  Future<void> _checkAutoDetect(Position pos, List<ZoneModel> existingZones) async {
    for (final z in existingZones) {
      if (_distance(pos.latitude, pos.longitude, z.latitude, z.longitude) <= z.radiusMeters + 100) return;
    }

    final cellLat = (pos.latitude * 500).round() / 500;
    final cellLng = (pos.longitude * 500).round() / 500;
    final cellKey = 'visit_${cellLat.toStringAsFixed(3)}_${cellLng.toStringAsFixed(3)}';

    final storage = LocalStorage();
    final now = DateTime.now();

    final lastVisitKey = 'last_visit_time_$cellKey';
    final lastVisitStr = storage.getString(lastVisitKey);
    final lastVisitTime = lastVisitStr != null ? DateTime.tryParse(lastVisitStr) : null;

    if (lastVisitTime != null && now.difference(lastVisitTime).inMinutes < 30) return;
    await storage.setString(lastVisitKey, now.toIso8601String());

    final visitCount = storage.getInt(cellKey, defaultValue: 0) + 1;
    await storage.setInt(cellKey, visitCount);

    if (visitCount < 7) return;

    final lastZoneKey = 'zone_created_$cellKey';
    final lastCreated = storage.getString(lastZoneKey);
    if (lastCreated != null) {
      final parsed = DateTime.tryParse(lastCreated);
      if (parsed != null && now.difference(parsed).inDays < 30) return;
    }

    final hour = now.hour;
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    String name;
    double radius;
    if (hour >= 21 || hour < 7) {
      name = isWeekend ? 'Casa Fin de Semana' : 'Hogar';
      radius = 200;
    } else if (hour >= 8 && hour <= 18 && !isWeekend) {
      name = 'Trabajo/Estudio';
      radius = 300;
    } else if (isWeekend && hour >= 10 && hour <= 20) {
      name = 'Lugar de finde';
      radius = 250;
    } else {
      name = 'Lugar Frecuente';
      radius = 150;
    }

    final zone = ZoneModel(
      id: 'auto_${now.microsecondsSinceEpoch}',
      name: name,
      latitude: cellLat,
      longitude: cellLng,
      radiusMeters: radius,
      autoDetected: true,
      notifyOnEnter: true,
      notifyOnExit: false,
    );

    final firebase = FirebaseService();
    await firebase.saveZone(zone);
    await storage.setString(lastZoneKey, now.toIso8601String());

    _insideZones.add(zone.id);

    _showNotification(
      'Nueva zona: $name',
      'Se ha creado una geocerca automaticamente.',
      'auto_zone_$cellKey',
    );
  }

  void _showNotification(String title, String body, String dedupId) {
    final now = DateTime.now();
    final dedupKey = '${dedupId}_${now.minute}';
    if (_recentNotifications.contains(dedupKey)) return;
    _recentNotifications.add(dedupKey);
    if (_recentNotifications.length > 30) {
      _recentNotifications.remove(_recentNotifications.first);
    }

    _notifications.show(
      id: now.millisecond % 100000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'geofence_alerts',
          'Alertas de Zonas',
          channelDescription: 'Notificaciones al entrar o salir de zonas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double deg) => deg * pi / 180;
}
