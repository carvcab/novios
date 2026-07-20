import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage.dart';
import '../home_navigation.dart';
import '../../permissions/permissions_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  // 0: has partner?, 1: enter code, 2: show code (creator), 3: profile setup, 4: complete
  int _step = 0;
  bool _isCreator = false; // true = creator, false = joiner
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _generatedCode = '';
  bool _loading = false;
  DateTime? _anniversaryDate;
  DateTime? _birthdayDate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();



    // Pre-fill name if available from registration
    final existingName = LocalStorage().getUserName();
    if (existingName != null && existingName.isNotEmpty) {
      _nameCtrl.text = existingName;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _selectHasPartner(bool hasPartner) {
    if (hasPartner) {
      _isCreator = false;
      setState(() => _step = 1); // Enter code
    } else {
      _isCreator = true;
      _generateCode();
    }
  }

  void _generateCode() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(6, (_) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]).join();
    setState(() {
      _generatedCode = code;
      _step = 2; // Show code
    });
    LocalStorage().setString('couple_id', code);
    _saveToFirebase(code);
  }

  Future<void> _saveToFirebase(String coupleId) async {
    setState(() => _loading = true);
    try {
      final uid = LocalStorage().getString('firebase_uid') ?? '';
      final name = LocalStorage().getUserName() ?? 'Usuario';
      await FirebaseService().createCouple(coupleId, uid, name);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _joinCouple() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 4) return;

    setState(() => _loading = true);
    try {
      final uid = LocalStorage().getString('firebase_uid') ?? '';
      final name = LocalStorage().getUserName() ?? 'Usuario';
      
      bool success = false;
      try {
        success = await FirebaseService().joinCouple(code, uid, name)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint("Error connecting to Firebase, fallback to offline link: $e");
        success = true; // Fallback to offline link
      }

      if (mounted) setState(() => _loading = false);
      if (success) {
        await LocalStorage().setString('couple_id', code);
        if (mounted) setState(() => _step = 3);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código inválido. Intenta de nuevo.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Onboarding link exception: $e. Proceeding offline.");
      if (mounted) setState(() => _loading = false);
      await LocalStorage().setString('couple_id', code);
      if (mounted) setState(() => _step = 3);
    }
  }

  void _goToProfileFromCode() {
    setState(() => _step = 3);
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre')),
      );
      return;
    }
    if (_birthdayDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu fecha de nacimiento')),
      );
      return;
    }
    if (_isCreator && _anniversaryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la fecha de aniversario')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ls = LocalStorage();
      await ls.setString('user_name', name);
      await ls.setString('birthday_date', _birthdayDate!.toIso8601String());

      if (_isCreator) {
        await ls.setString('anniversary_date', _anniversaryDate!.toIso8601String());
      }

      // Sync to Firebase
      final uid = ls.getString('firebase_uid') ?? '';
      if (uid.isNotEmpty) {
        await FirebaseService().saveUserProfile(uid, name, ls.getPartnerName());
        await FirebaseService().loadUserFromFirestore(uid);
        await FirebaseService().loadAllListsToLocal();
      }

      setState(() => _step = 4); // Complete
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickAnniversaryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anniversaryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha de aniversario',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE8467C),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
              secondary: Color(0xFF9B6FE8),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _anniversaryDate = picked);
  }

  Future<void> _pickBirthdayDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdayDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE8467C),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
              secondary: Color(0xFF9B6FE8),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthdayDate = picked);
  }

  void _complete() {
    final permissionsDone = LocalStorage().getBool('permissions_granted');
    if (permissionsDone != true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeNavigation()));
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _generatedCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Codigo copiado')),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary,
              cs.primary.withValues(alpha: 0.7),
              isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFF0F5),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.favorite_rounded, size: 56, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(height: 16),

                    if (_step == 0) _buildHasPartner(cs),
                    if (_step == 1) _buildEnterCode(cs),
                    if (_step == 2) _buildShowCode(cs),
                    if (_step == 3) _buildProfileSetup(cs),
                    if (_step == 4) _buildComplete(cs),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHasPartner(ColorScheme cs) {
    return Column(
      children: [
        const Text('Bienvenido', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Ya tienes una pareja?', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _selectHasPartner(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Si, tengo un codigo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _selectHasPartner(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('No, crear nueva relacion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterCode(ColorScheme cs) {
    return Column(
      children: [
        const Text('Ingresa el codigo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Pidele el codigo a tu pareja', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Ej: A7F9K2',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey, letterSpacing: 4),
            ),
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLength: 6,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _joinCouple,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Unirse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildShowCode(ColorScheme cs) {
    return Column(
      children: [
        const Text('Tu codigo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Comparte este codigo con tu pareja', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(_generatedCode, style: const TextStyle(fontSize: 36, letterSpacing: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Text('Muestra este codigo a tu pareja', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                    label: const Text('Copiar', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.4))),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(ShareParams(text: 'Unete a mi relacion en EverUs con el codigo: $_generatedCode')),
                    icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                    label: const Text('Compartir', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withValues(alpha: 0.4))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _goToProfileFromCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSetup(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isCreator ? 'Crea tu perfil' : 'Completa tu perfil',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Ingresa tus datos', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 24),

        // Name
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Tu nombre',
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 16),

        // Birthday
        InkWell(
          onTap: _pickBirthdayDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_rounded, color: cs.primary),
                const SizedBox(width: 12),
                Text(
                  _birthdayDate != null ? 'Nacimiento: ${_formatDate(_birthdayDate!)}' : 'Tu fecha de nacimiento',
                  style: TextStyle(
                    fontSize: 15,
                    color: _birthdayDate != null ? Colors.black87 : Colors.grey,
                    fontWeight: _birthdayDate != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Anniversary (only for creator)
        if (_isCreator) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickAnniversaryDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.pink),
                  const SizedBox(width: 12),
                  Text(
                    _anniversaryDate != null ? 'Aniversario: ${_formatDate(_anniversaryDate!)}' : 'Fecha de aniversario',
                    style: TextStyle(
                      fontSize: 15,
                      color: _anniversaryDate != null ? Colors.black87 : Colors.grey,
                      fontWeight: _anniversaryDate != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Info text for joiner
        if (!_isCreator)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Tu pareja ya configuró la relación. Solo completa tus datos.',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isCreator ? 'Crear relacion' : 'Completar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildComplete(ColorScheme cs) {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, size: 72, color: Colors.white),
        const SizedBox(height: 16),
        const Text('Todo listo!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text(_isCreator
            ? 'Tu relacion ha sido creada exitosamente'
            : 'Te has unido a la relacion exitosamente',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _complete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Comenzar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
