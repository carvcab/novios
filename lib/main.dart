import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/local_storage.dart';
import 'services/firebase_service.dart';
import 'services/theme_provider.dart';
import 'services/widget_service.dart';
import 'services/geofence_service.dart';
import 'services/couple_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  await LocalStorage().init().catchError((_) => false);
  try { await FirebaseService().init().catchError((_) {}); } catch (e) {}
  try { WidgetService().init().catchError((_) {}); } catch (e) {}
  try { await GeofenceService().init(); } catch (e) { debugPrint("Geofence init error: $e"); }

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    try {
      LocalStorage().setString('last_dart_error', '${details.exception}\n${details.stack}');
    } catch (_) {}
  };

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => CoupleService()),
        ],
        child: const EverUsApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    try {
      LocalStorage().setString('last_dart_error', '$error\n$stack');
    } catch (_) {}
  });
}

class EverUsApp extends StatelessWidget {
  const EverUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'EverUs',
      debugShowCheckedModeBanner: false,
      theme: tp.getThemeData(),
      darkTheme: tp.getThemeData(),
      themeMode: tp.isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: const AppGate(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ctrl.forward();
    _prepare();
  }

  Future<void> _prepare() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await CoupleService().ensureParejaDocExists();
      await CoupleService().migrateOldData();
      await CoupleService().init();
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Opacity(
                opacity: _ctrl.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 64, color: Color(0xFFFF5C8A)),
                    const SizedBox(height: 16),
                    Text('EverUs',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 4)),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.isAnonymous) {
      return const LoginScreen();
    }

    return const HomeNavigation();
  }
}
