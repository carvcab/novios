import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/local_storage.dart';
import '../../services/firebase_service.dart';
import '../home_navigation.dart';
import '../../permissions/permissions_screen.dart';

class WhoScreen extends StatefulWidget {
  const WhoScreen({super.key});

  @override
  State<WhoScreen> createState() => _WhoScreenState();
}

class _WhoScreenState extends State<WhoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _selected = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _pick(String me) async {
    if (_selected) return;
    _selected = true;
    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously();
      final uid = auth.currentUser!.uid;
      final partner = me == 'Yosmar' ? 'Diego' : 'Yosmar';
      final storage = LocalStorage();
      storage.saveUserProfile(id: uid, name: me, partnerName: partner);
      storage.setString('firebase_uid', uid);
      await FirebaseService().saveUserProfile(uid, me, partner);
    } catch (e) {
      debugPrint("Auth error: $e");
    }

    if (!mounted) return;
    final permissionsDone = LocalStorage().getBool('permissions_granted');
    final nextScreen = (permissionsDone != true) ? const PermissionsScreen() : const HomeNavigation();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => nextScreen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
              theme.brightness == Brightness.dark ? const Color(0xFF0D0D0D) : const Color(0xFFFFF0F5),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(Icons.favorite_rounded, size: 48, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(height: 12),
                Text(
                  'Nuestra App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quien eres?',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Spacer(flex: 1),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else
                  SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screen.width * 0.1),
                      child: Row(
                        children: [
                          Expanded(child: _Card(
                            name: 'Yosmar',
                            color: Colors.pink,
                            icon: Icons.favorite_rounded,
                            onTap: () => _pick('Yosmar'),
                          )),
                          const SizedBox(width: 20),
                          Expanded(child: _Card(
                            name: 'Diego',
                            color: Colors.blue,
                            icon: Icons.favorite_rounded,
                            onTap: () => _pick('Diego'),
                          )),
                        ],
                      ),
                    ),
                  ),
                const Spacer(flex: 2),
                Text(
                  _loading ? 'Creando tu identidad...' : 'Solo puedes elegir una vez',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatefulWidget {
  final String name;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _Card({
    required this.name,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 36),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  widget.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: widget.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
