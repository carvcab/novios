import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'local_storage.dart';
import 'firebase_service.dart';

class AppTracker {
  static final AppTracker _instance = AppTracker._internal();
  factory AppTracker() => _instance;
  AppTracker._internal();

  static const _trackerChannel = MethodChannel('com.novios/app_tracker');
  static const _permissionChannel = MethodChannel('com.novios/permissions');
  static const _notificationChannel = MethodChannel('com.novios/notifications');

  String _currentApp = '';
  final _appCtrl = StreamController<String>.broadcast();
  final _notifCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<String> get appStream => _appCtrl.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notifCtrl.stream;
  String get currentApp => _currentApp;

  bool _initialized = false;
  Timer? _pollTimer;

  void init() {
    if (_initialized) return;
    _initialized = true;

    try {
      _trackerChannel.setMethodCallHandler((call) async {
        try {
          if (call.method == 'onAppChange') {
            final json = call.arguments as String? ?? '';
            final data = _parseJson(json);
            if (data != null && data['app'] != null) {
              _currentApp = data['app'] as String;
              if (!_appCtrl.isClosed) _appCtrl.add(_currentApp);
              _uploadToFirestore(_currentApp);
            }
          }
        } catch (e) {
          debugPrint("trackerChannel handler error: $e");
        }
        return null;
      });
    } catch (e) {
      debugPrint("trackerChannel setup error: $e");
    }

    try {
      _notificationChannel.setMethodCallHandler((call) async {
        try {
          if (call.method == 'onNotification') {
            final json = call.arguments as String? ?? '';
            final data = _parseJson(json);
            if (data != null) {
              if (!_notifCtrl.isClosed) _notifCtrl.add(data);
              _uploadNotification(data);
            }
          }
        } catch (e) {
          debugPrint("notificationChannel handler error: $e");
        }
        return null;
      });
    } catch (e) {
      debugPrint("notificationChannel setup error: $e");
    }

    // Start tracking if we have permission
    _startIfGranted();

    // Fallback poll: ask native for current app every 30s
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollCurrentApp();
    });
  }

  Future<void> _pollCurrentApp() async {
    try {
      final app = await getCurrentApp();
      if (app.isNotEmpty && app != _currentApp) {
        _currentApp = app;
        if (!_appCtrl.isClosed) _appCtrl.add(_currentApp);
        _uploadToFirestore(_currentApp);
      }
    } catch (_) {}
  }

  Future<void> _startIfGranted() async {
    try {
      final hasAll = await hasAllPermissions();
      if (hasAll) {
        await startTracking();
      }
    } catch (e) {
      debugPrint("_startIfGranted error: $e");
    }
  }

  Future<bool> hasUsageStatsPermission() async {
    try {
      return await _permissionChannel.invokeMethod('hasUsageStatsPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasNotificationAccess() async {
    try {
      return await _permissionChannel.invokeMethod('hasNotificationAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasOverlayPermission() async {
    try {
      return await _permissionChannel.invokeMethod('hasOverlayPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasAllPermissions() async {
    try {
      return await _permissionChannel.invokeMethod('hasAllPermissions') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openUsageStatsSettings() async {
    try {
      await _permissionChannel.invokeMethod('openUsageStatsSettings');
    } catch (e) {
      debugPrint("openUsageStatsSettings error: $e");
    }
  }

  Future<void> openNotificationAccessSettings() async {
    try {
      await _permissionChannel.invokeMethod('openNotificationAccessSettings');
    } catch (e) {
      debugPrint("openNotificationAccessSettings error: $e");
    }
  }

  Future<void> openOverlaySettings() async {
    try {
      await _permissionChannel.invokeMethod('openOverlaySettings');
    } catch (e) {
      debugPrint("openOverlaySettings error: $e");
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      return await _permissionChannel.invokeMethod('isBatteryOptimizationIgnored') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _permissionChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint("requestIgnoreBatteryOptimizations error: $e");
    }
  }

  Future<void> openBatterySettings() async {
    try {
      await _permissionChannel.invokeMethod('openBatterySettings');
    } catch (e) {
      debugPrint("openBatterySettings error: $e");
    }
  }

  Future<void> openAppSettings() async {
    try {
      await _permissionChannel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint("openAppSettings error: $e");
    }
  }

  Future<void> openXiaomiAutostart() async {
    try {
      await _permissionChannel.invokeMethod('openXiaomiAutostart');
    } catch (e) {
      debugPrint("openXiaomiAutostart error: $e");
    }
  }

  Future<void> startTracking() async {
    try {
      await _trackerChannel.invokeMethod('startTracking');
    } catch (_) {}
  }

  Future<void> stopTracking() async {
    try {
      await _trackerChannel.invokeMethod('stopTracking');
    } catch (_) {}
  }

  Future<String> getCurrentApp() async {
    try {
      return await _trackerChannel.invokeMethod('getCurrentApp') ?? '';
    } catch (_) {
      return '';
    }
  }

  void _uploadToFirestore(String appName) {
    final uid = LocalStorage().getUserId();
    if (uid == null) return;
    FirebaseService().updateCurrentApp(appName);
  }

  final Map<String, String> _lastNotifPerApp = {};
  final Map<String, DateTime> _lastNotifTimePerApp = {};

  void _uploadNotification(Map<String, dynamic> notif) {
    final app = (notif['app'] as String? ?? '').toLowerCase();
    final title = notif['title'] as String? ?? '';
    final text = notif['text'] as String? ?? '';

    if (app.isEmpty) return;
    if (app.contains('novios') || app.contains('everus') || app.contains('ever')) return;

    final appKey = app;
    final lastNotif = _lastNotifPerApp[appKey];
    final lastTime = _lastNotifTimePerApp[appKey];

    if (lastNotif == '$title|$text' && lastTime != null &&
        DateTime.now().difference(lastTime).inSeconds < 30) {
      return;
    }

    _lastNotifPerApp[appKey] = '$title|$text';
    _lastNotifTimePerApp[appKey] = DateTime.now();

    FirebaseService().addNotificationLog(notif);
  }

  Map<String, dynamic>? _parseJson(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    stopTracking();
    _appCtrl.close();
    _notifCtrl.close();
  }
}
