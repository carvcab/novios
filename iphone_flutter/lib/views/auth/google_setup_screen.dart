import 'package:flutter/material.dart';
import '../../services/google_auth_service.dart';
import '../../services/local_storage.dart';

class GoogleSetupScreen extends StatefulWidget {
  const GoogleSetupScreen({super.key});

  @override
  State<GoogleSetupScreen> createState() => _GoogleSetupScreenState();
}

class _GoogleSetupScreenState extends State<GoogleSetupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();

    final auth = GoogleAuthService();
    _nameCtrl.text = auth.displayName ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final auth = GoogleAuthService();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    await LocalStorage().setString('user_name', name);
    String pName = auth.partnerName ?? 'Mi pareja';
    if (pName == 'Mi pareja') {
      if (name.toLowerCase().contains('diego')) {
        pName = 'Yosmari';
      } else {
        pName = 'Diego';
      }
    }
    await LocalStorage().setString('partner_name', pName);
    await auth.markSetupComplete();

    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = GoogleAuthService();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, size: 56, color: Color(0xFFFF5C8A)),
                  const SizedBox(height: 16),
                  const Text('Bienvenido',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text('Confirma tu nombre para continuar',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 32),

                  if (auth.photoUrl != null && auth.photoUrl!.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        auth.photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                          child: const Icon(Icons.person, color: Colors.white54, size: 40),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                      child: Icon(Icons.person, color: Colors.white54, size: 40),
                    ),
                  const SizedBox(height: 16),

                  Text(auth.currentEmail ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4)),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Tu nombre',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                        hintText: 'Cómo quieres aparecer',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: _saving
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5C8A)))
                      : ElevatedButton(
                          onPressed: _nameCtrl.text.trim().isEmpty ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5C8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
