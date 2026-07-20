import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/local_storage.dart';
import 'services/firebase_service.dart';
import 'services/theme_provider.dart';
import 'services/widget_service.dart';
import 'services/profile_service.dart';
import 'services/google_auth_service.dart';
import 'services/user_service.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/google_setup_screen.dart';
import 'views/auth/profile_setup_screen.dart';
import 'views/auth/add_partner_screen.dart';
import 'views/home_navigation.dart';
import 'permissions/permissions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: firebaseOptions);
  }
  try {
    await Firebase.initializeApp(name: 'backup', options: firebaseOptionsBackup);
  } catch (e) {
    debugPrint('Backup Firebase init skipped: $e');
  }
  await LocalStorage().init().catchError((_) => false);
  await FirebaseService().init().catchError((_) {});
  try { WidgetService().init().catchError((_) {}); } catch (e) { debugPrint("WidgetService init error: $e"); }
  try { await ProfileService().init(); } catch (e) { debugPrint("ProfileService init error: $e"); }
  GoogleAuthService().init();
  try { await UserService().syncFromFirestore(); } catch (_) {}
  try { UserService().startListening(); } catch (_) {}

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
    GoogleAuthService().addListener(_onAuthChanged);
    UserService().addListener(_onAuthChanged);
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ctrl.forward();
    _prepare();
  }

  void _onAuthChanged() {
    _checkFirestore();
  }

  Future<void> _checkFirestore() async {
    final auth = GoogleAuthService();
    if (!auth.isSignedIn) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;

        final remoteName = data['name'] as String?;
        if (remoteName != null && remoteName.isNotEmpty) {
          await LocalStorage().setString('user_name', remoteName);
        } else {
          final googleName = auth.displayName;
          if (googleName != null && googleName.isNotEmpty) {
            await LocalStorage().setString('user_name', googleName);
          }
        }

        final bday = data['birthdayDate'];
        if (bday != null) {
          String bdayStr;
          if (bday is Timestamp) {
            final dt = bday.toDate();
            bdayStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          } else {
            bdayStr = bday.toString();
          }
          await LocalStorage().setString('birthday_date', bdayStr);
          await LocalStorage().setString('dob', bdayStr);
        }

        final remoteUsername = data['username'] as String?;
        if (remoteUsername != null && remoteUsername.isNotEmpty) {
          await LocalStorage().setString('username', remoteUsername);
        } else {
          final displayName = LocalStorage().getUserName() ?? auth.displayName ?? '';
          if (displayName.isNotEmpty) {
            await LocalStorage().setString('username', displayName.toLowerCase().replaceAll(RegExp(r'\s+'), ''));
          }
        }

        final remoteCoupleId = data['coupleId'] as String?;
        if (remoteCoupleId != null && remoteCoupleId.isNotEmpty) {
          await LocalStorage().setString('couple_id', remoteCoupleId);
        }
        final remotePartnerUid = data['partnerUid'] as String?;
        if (remotePartnerUid != null && remotePartnerUid.isNotEmpty) {
          await LocalStorage().setString('partner_uid', remotePartnerUid);
        }
        final remotePartnerName = data['partnerName'] as String?;
        if (remotePartnerName != null && remotePartnerName.isNotEmpty) {
          await LocalStorage().setString('partner_name', remotePartnerName);
        }

        final email = auth.currentEmail;
        if (email != null) {
          await LocalStorage().setBool('setup_complete_$email', true);
        }
        await LocalStorage().setBool('has_firestore_profile', true);
      }

      // Rebuild: if doc existed → skip onboarding; if not → show onboarding
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _prepare() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    GoogleAuthService().removeListener(_onAuthChanged);
    UserService().removeListener(_onAuthChanged);
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

    final auth = GoogleAuthService();
    final user = UserService();

    if (!auth.isSignedIn) {
      return const LoginScreen();
    }

    if (!auth.setupComplete) {
      return const GoogleSetupScreen();
    }

    if (!user.hasProfile) {
      return const ProfileSetupScreen();
    }

    if (!user.hasPartner && !user.partnerSkipped) {
      return const AddPartnerScreen();
    }

    final permissionsDone = LocalStorage().getBool('permissions_granted');
    if (permissionsDone != true) {
      return const PermissionsScreen();
    }

    return const HomeNavigation();
  }
}
