import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage.dart';
import '../home_navigation.dart';
import 'onboarding_screen.dart';
import '../../permissions/permissions_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _loading = false;
  bool _showEmailForm = false;
  bool _isSignUp = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      final result = await AuthService().signInWithGoogle();
      if (result != null && mounted) {
        final coupleId = LocalStorage().getString('couple_id');
        final name = LocalStorage().getUserName();
        final hasProfile = coupleId != null &&
            coupleId.isNotEmpty &&
            coupleId != 'default_couple_id' &&
            name != null &&
            name.isNotEmpty;
        _navigateAfterAuth(hasProfile);
      }
    } catch (e) {
      if (mounted) {
        String msg = 'No se pudo iniciar sesión. Por favor verifica tu conexión.';
        if (e.toString().contains('TimeoutException')) {
          msg = 'La conexión tardó demasiado. Por favor intenta de nuevo.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _navigateAfterAuth(bool hasProfile) {
    if (hasProfile) {
      final permissionsDone = LocalStorage().getBool('permissions_granted');
      if (permissionsDone != true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeNavigation()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingFlow()));
    }
  }

  Future<void> _emailAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || (_isSignUp && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = AuthService();
      if (_isSignUp) {
        await auth.signUpWithEmail(email, pass, name);
      } else {
        await auth.signInWithEmail(email, pass);
      }

      if (auth.isLoggedIn && mounted) {
        final coupleId = LocalStorage().getString('couple_id');
        final name = LocalStorage().getUserName();
        final hasProfile = coupleId != null &&
            coupleId.isNotEmpty &&
            coupleId != 'default_couple_id' &&
            name != null &&
            name.isNotEmpty;
        _navigateAfterAuth(hasProfile);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().split(']').last.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMsg')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withValues(alpha: 0.9),
              cs.secondary.withValues(alpha: 0.6),
              const Color(0xFF0A0E27).withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                          ),
                          child: Center(
                            child: Icon(Icons.favorite_rounded, size: 36, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('EverUs', style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 4,
                        )),
                        const SizedBox(height: 6),
                        Text('Cada historia merece un lugar.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          )),
                        const SizedBox(height: 48),

                        if (!_showEmailForm) ...[
                          // Google login
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _googleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFFF4D8D),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.network(
                                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                          width: 20, height: 20,
                                          errorBuilder: (_, __, ___) => const SizedBox(),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('Continuar con Google',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Email alternative button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _showEmailForm = true),
                              icon: const Icon(Icons.email_outlined, color: Colors.white),
                              label: const Text('Entrar con Correo', style: TextStyle(color: Colors.white, fontSize: 15)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Glassmorphic Email/Password Form
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isSignUp ? 'Crear Cuenta' : 'Iniciar Sesión',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                if (_isSignUp) ...[
                                  TextField(
                                    controller: _nameCtrl,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration('Tu Nombre', Icons.person_outline),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                TextField(
                                  controller: _emailCtrl,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration('Correo Electrónico', Icons.email_outlined),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passCtrl,
                                  style: const TextStyle(color: Colors.white),
                                  obscureText: true,
                                  decoration: _inputDecoration('Contraseña', Icons.lock_outline),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loading ? null : _emailAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                      : Text(_isSignUp ? 'Registrarse' : 'Ingresar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _isSignUp = !_isSignUp;
                                    _emailCtrl.clear();
                                    _passCtrl.clear();
                                    _nameCtrl.clear();
                                  }),
                                  child: Text(
                                    _isSignUp ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
                                    style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Divider(color: Colors.white24, height: 24),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _showEmailForm = false;
                                    _emailCtrl.clear();
                                    _passCtrl.clear();
                                    _nameCtrl.clear();
                                  }),
                                  icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 16),
                                  label: const Text('Volver a opciones', style: TextStyle(color: Colors.white70)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _textLink('Política de Privacidad', () {}),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('\u2022', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                            ),
                            _textLink('Términos de Servicio', () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white54, width: 1),
      ),
    );
  }

  Widget _textLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w400)),
    );
  }
}
