import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../services/status_service.dart';
import '../services/geofence_service.dart';
import '../services/app_tracker.dart';
import '../services/firebase_service.dart';
import '../services/chat_notification_service.dart';
import '../services/couple_service.dart';
import '../services/widget_service.dart';
import '../widgets/confetti_overlay.dart';
import 'home/home_tab.dart';
import 'love/love_tab.dart';
import 'messages/messages_tab.dart';
import 'location/location_tab.dart';
import 'profile/profile_tab.dart';
import 'settings/settings_screen.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // Track loaded tabs to perform lazy-loading
  final List<bool> _loadedTabs = [true, false, false, false, false];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inicializar servicios pesados solo cuando el perfil está activo
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ChatNotificationService().init();
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        try { StatusService().init(); } catch (e) { debugPrint("StatusService init: $e"); }
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        GeofenceService().init().catchError((_) => false);
        try { AppTracker().init(); } catch (e) { debugPrint("AppTracker init: $e"); }
        try { WidgetService().updateAllWidgets().catchError((_) {}); } catch (e) { debugPrint("WidgetService update: $e"); }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No auto-lock on pause/inactive to avoid forcing PIN screen during permissions or photo picking.
    // The PIN lock is only intended when opening the app from cold start.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final _tabs = const [
    HomeTab(),
    MessagesTab(),
    LoveTab(),
    LocationTab(),
    ProfileTab(),
  ];

  void _goToSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const SettingsScreen(),
        transitionsBuilder: (_, a, __, c) => SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: a, child: c),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = theme.isDark;

    return ConfettiOverlay(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💞', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(CoupleService().coupleDisplayName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: cs.primary, size: 20),
                onPressed: _goToSettings,
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_tabs.length, (index) {
            return _loadedTabs[index] ? _tabs[index] : const SizedBox.shrink();
          }),
        ),
        bottomNavigationBar: _buildNav(cs, isDark),
      ),
    );
  }

  Widget _buildNav(ColorScheme cs, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06), width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: bgColor,
        elevation: 0,
        currentIndex: _currentIndex,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.3),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            _loadedTabs[i] = true;
          });
          const names = ['Inicio', 'Chat', 'Amor', 'Ubicación', 'Perfil'];
          StatusService().setScreen(names[i]);
          MessagesTab.isChatOpen = i == 1;
        },
        items: [
          _buildItem(0, Icons.home_outlined, Icons.home_rounded, 'Inicio', cs),
          _buildItem(1, Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'Chat', cs),
          _buildCenterHeart(cs),
          _buildItem(3, Icons.location_on_outlined, Icons.location_on_rounded, 'Ubicación', cs),
          _buildItem(4, Icons.person_outline, Icons.person_rounded, 'Perfil', cs),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildItem(int index, IconData inactive, IconData active, String label, ColorScheme cs) {
    final sel = _currentIndex == index;

    Widget buildIcon(IconData iconData, double size) {
      if (index == 1) {
        return StreamBuilder<int>(
          stream: FirebaseService().streamUnreadMessagesCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            if (count > 0) {
              return Badge(
                label: Text('$count'),
                child: Icon(iconData, size: size),
              );
            }
            return Icon(iconData, size: size);
          },
        );
      }
      return Icon(iconData, size: size);
    }

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: buildIcon(sel ? active : inactive, 22),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: buildIcon(active, 20),
      ),
      label: label,
    );
  }

  BottomNavigationBarItem _buildCenterHeart(ColorScheme cs) {
    final sel = _currentIndex == 2;
    return BottomNavigationBarItem(
      icon: sel
          ? Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
            )
          : Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_border_rounded, color: cs.onSurface.withValues(alpha: 0.35), size: 18),
            ),
      label: '',
    );
  }
}
