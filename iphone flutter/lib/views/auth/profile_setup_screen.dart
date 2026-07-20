import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'add_partner_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  final _usernameCtrl = TextEditingController();
  String _dob = '';
  bool _loading = false;
  String? _error;
  bool _usernameAvailable = false;
  bool _checkingUsername = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final text = _usernameCtrl.text.trim().toLowerCase();
    if (text.length < 3) {
      setState(() => _usernameAvailable = false);
      return;
    }
    setState(() => _checkingUsername = true);
    final result = await UserService().searchUser(text);
    if (!mounted) return;
    setState(() {
      _checkingUsername = false;
      _usernameAvailable = result == null && text.length >= 3;
    });
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}');
    }
  }

  Future<void> _handleContinue() async {
    if (_usernameCtrl.text.trim().length < 3) {
      setState(() => _error = 'El usuario debe tener al menos 3 caracteres');
      return;
    }
    if (_dob.isEmpty) {
      setState(() => _error = 'Selecciona tu fecha de nacimiento');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await UserService().createProfile(_usernameCtrl.text.trim(), _dob);
    if (!mounted) return;
    switch (result) {
      case CreateProfileResult.success:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
        );
      case CreateProfileResult.usernameTaken:
        setState(() {
          _error = 'Ese usuario ya está ocupado. Prueba otro.';
          _loading = false;
        });
      case CreateProfileResult.error:
        setState(() {
          _error = 'Error de conexión. Revisa tu internet y permisos.';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(Icons.person_outline_rounded, size: 56, color: Color(0xFFFF5C8A)),
                  const SizedBox(height: 16),
                  const Text('Tu Perfil',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text('Elige un nombre de usuario y tu fecha de nacimiento',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                    ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _usernameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                        hintText: 'ej: pareja2024',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                        suffixIcon: _checkingUsername
                          ? const SizedBox(width: 20, height: 20, child: Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5C8A)),
                            ))
                          : _usernameAvailable
                            ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                            : null,
                      ),
                      onChanged: (_) => _checkUsername(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: _pickDob,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cake_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _dob.isEmpty ? 'Fecha de nacimiento' : _dob,
                            style: TextStyle(
                              fontSize: 16,
                              color: _dob.isEmpty ? Colors.white.withValues(alpha: 0.4) : Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.edit_calendar_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5C8A)))
                      : ElevatedButton(
                          onPressed: _handleContinue,
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
