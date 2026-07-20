import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/user_service.dart';

class AddPartnerScreen extends StatefulWidget {
  const AddPartnerScreen({super.key});

  @override
  State<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends State<AddPartnerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  bool _adding = false;
  Map<String, dynamic>? _foundUser;
  String? _error;
  Timer? _debounce;
  String _myPairCode = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    _loadMyCode();
  }

  Future<void> _loadMyCode() async {
    final code = await UserService().getOrGeneratePairCode();
    if (mounted) setState(() => _myPairCode = code);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _foundUser = null;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _error = null;
      _foundUser = null;
    });
    final result = await UserService().searchUser(query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (result != null) {
        _foundUser = result;
      } else if (query.length >= 3) {
        _error = 'No se encontro ningun usuario con ese codigo, usuario o correo.';
      }
    });
  }

  Future<void> _addPartner() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() {
      _adding = true;
      _error = null;
    });
    final result = await UserService().addPartner(_searchCtrl.text.trim());
    if (!mounted) return;
    if (result == AddPartnerResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vincularon sus cuentas exitosamente!')),
      );
      return;
    }
    setState(() {
      _adding = false;
      switch (result) {
        case AddPartnerResult.alreadyHasPartner:
          _error = 'Ya tienes una pareja vinculada.';
        case AddPartnerResult.targetHasPartner:
          _error = 'Esta persona ya esta vinculada con otra pareja.';
        case AddPartnerResult.notFound:
          _error = 'No se pudo encontrar al usuario. Verifica el codigo o usuario.';
        default:
          _error = 'Ocurrio un error al vincular. Intenta de nuevo.';
      }
    });
  }

  void _skip() async {
    await UserService().didSkipPartner();
  }

  void _copyCode() {
    if (_myPairCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _myPairCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Codigo  copiado al portapapeles!')),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, size: 64, color: Color(0xFFFF5C8A)),
                  const SizedBox(height: 12),
                  const Text(
                    'Vincular Pareja',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Conectate con tu pareja usando su Codigo, Usuario o Correo',
                    style: TextStyle(fontSize: 13, color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (_myPairCode.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF5C8A).withValues(alpha: 0.15),
                            const Color(0xFFFF5C8A).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF5C8A).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TU CODIGO DE VINCULACION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF5C8A), letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _myPairCode,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Color(0xFFFF5C8A), size: 20),
                                onPressed: _copyCode,
                                tooltip: 'Copiar Codigo',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pasale este codigo a tu pareja para que te agregue',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),

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
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _foundUser != null
                            ? const Color(0xFFFF5C8A).withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textCapitalization: TextCapitalization.none,
                      autofocus: false,
                      decoration: InputDecoration(
                        labelText: 'Codigo, Usuario o Correo de tu pareja',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4), size: 22),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5C8A))),
                              )
                            : _foundUser != null
                                ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22)
                                : null,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  if (_foundUser != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFF5C8A).withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5C8A).withValues(alpha: 0.08),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFFFF5C8A).withValues(alpha: 0.15),
                            child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFFFF5C8A)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _foundUser!['displayName'] as String? ?? _foundUser!['name'] as String? ?? 'Usuario Encontrado',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          if (_foundUser!['username'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5C8A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '@',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFFF5C8A), fontWeight: FontWeight.w500),
                              ),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _adding
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5C8A)))
                                : ElevatedButton.icon(
                                    onPressed: _addPartner,
                                    icon: const Icon(Icons.favorite_rounded, size: 18),
                                    label: const Text('Vincular Pareja Ahora', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5C8A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  TextButton(
                    onPressed: _skip,
                    child: Text('Vincular mas tarde', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
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