import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/local_storage.dart';
import '../../services/auth_service.dart';
import '../../permissions/permissions_screen.dart';
import 'profile_setup_screen.dart';
import 'add_partner_screen.dart';
import '../home_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
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

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || (_isSignUp && name.isEmpty)) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final auth = AuthService();
      if (_isSignUp) {
        await auth.signUpWithEmail(email, pass, name);
      } else {
        await auth.signInWithEmail(email, pass);
      }

      if (!mounted) return;
      if (auth.isLoggedIn) {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final email = FirebaseAuth.instance.currentUser?.email ?? '';
        await LocalStorage().setString('user_id', uid);
        await LocalStorage().setString('user_email', email);
        await LocalStorage().setBool('setup_complete_$email', true);
        final hasDob = LocalStorage().getString('dob') != null &&
            LocalStorage().getString('dob')!.isNotEmpty;
        final hasUsername = LocalStorage().getString('username') != null &&
            LocalStorage().getString('username')!.isNotEmpty;
        final hasPartner = LocalStorage().getString('partner_uid') != null &&
            LocalStorage().getString('partner_uid')!.isNotEmpty;
        final partnerSkipped = LocalStorage().getBool('partner_skipped') == true;
        if (mounted) {
          if (!hasDob || !hasUsername) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
            );
          } else if (!hasPartner && !partnerSkipped) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
            );
          } else {
            final permissionsDone = LocalStorage().getBool('permissions_granted') == true;
            if (permissionsDone) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeNavigation()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PermissionsScreen()),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().split(']').last.trim());
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 72, color: Color(0xFFFF5C8A)),
                    const SizedBox(height: 20),
                    Text('EverUs',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 6),
                    ),
                    const SizedBox(height: 8),
                    Text('Solo para nosotros dos',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 2),
                    ),
                    const SizedBox(height: 40),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (_isSignUp)
                      _buildField(_nameCtrl, 'Tu Nombre', Icons.person_outline, false),
                    const SizedBox(height: 12),
                    _buildField(_emailCtrl, 'Correo Electrónico', Icons.email_outlined, false),
                    const SizedBox(height: 12),
                    _buildField(_passCtrl, 'Contraseña', Icons.lock_outline, true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5C8A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Text(_isSignUp ? 'Registrarse' : 'Ingresar',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                      }),
                      child: Text(
                        _isSignUp ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
                        style: const TextStyle(color: Color(0xFFFF5C8A), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1),
        ),
      ),
    );
  }
}
