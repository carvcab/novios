import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crypto/crypto.dart';

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key});

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _lockController;
  late Animation<double> _lockScale;

  final _msgCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _resultCtrl = TextEditingController();
  String _mode = 'encrypt';

  @override
  void initState() {
    super.initState();
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _lockScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _lockController, curve: Curves.bounceOut),
    );
  }

  @override
  void dispose() {
    _lockController.dispose();
    _msgCtrl.dispose();
    _keyCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  String _xorCipher(String input, String secret) {
    final key = sha256.convert(utf8.encode(secret)).bytes;
    final inputBytes = utf8.encode(input);
    final output = Uint8List(inputBytes.length);
    for (int i = 0; i < inputBytes.length; i++) {
      output[i] = inputBytes[i] ^ key[i % key.length];
    }
    return base64.encode(output);
  }

  String _xorDecipher(String input, String secret) {
    try {
      final key = sha256.convert(utf8.encode(secret)).bytes;
      final inputBytes = base64.decode(input);
      final output = Uint8List(inputBytes.length);
      for (int i = 0; i < inputBytes.length; i++) {
        output[i] = inputBytes[i] ^ key[i % key.length];
      }
      return utf8.decode(output);
    } catch (_) {
      return 'Error: Clave incorrecta o formato inválido';
    }
  }

  void _process() {
    if (_msgCtrl.text.trim().isEmpty || _keyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    _lockController.forward().then((_) => _lockController.reverse());
    HapticFeedback.mediumImpact();

    setState(() {
      _resultCtrl.text = _mode == 'encrypt'
          ? _xorCipher(_msgCtrl.text.trim(), _keyCtrl.text.trim())
          : _xorDecipher(_msgCtrl.text.trim(), _keyCtrl.text.trim());
    });
  }

  void _copyResult() {
    if (_resultCtrl.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultCtrl.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado al portapapeles 📋'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cifrado Secreto', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary.withValues(alpha: 0.12), cs.secondary.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _lockScale,
                    child: Icon(
                      _mode == 'encrypt' ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                      size: 48,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mensajes Ultra Secretos 🤐',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cifra tus cartas o mensajes usando una contraseña que solo tú y tu pareja conozcan (SHA-256 + XOR). Nadie más en internet podrá leerlos.',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Selector Cifrar / Descifrar
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'encrypt',
                  label: Text('Cifrar 🔒'),
                ),
                ButtonSegment(
                  value: 'decrypt',
                  label: Text('Descifrar 🔓'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) {
                setState(() {
                  _mode = v.first;
                  _resultCtrl.clear();
                  _msgCtrl.clear();
                });
              },
            ),
            const SizedBox(height: 20),

            // Inputs
            TextField(
              controller: _msgCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _mode == 'encrypt' ? 'Mensaje original a cifrar' : 'Código cifrado a descifrar',
                hintText: _mode == 'encrypt' ? 'Escribe aquí tu carta secreta...' : 'Pega el código extraño aquí...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Clave Secreta Compartida',
                hintText: 'Ej. nuestro lugar favorito',
                prefixIcon: const Icon(Icons.key_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),

            // Process Button
            ElevatedButton.icon(
              onPressed: _process,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              icon: Icon(_mode == 'encrypt' ? Icons.lock_rounded : Icons.lock_open_rounded),
              label: Text(
                _mode == 'encrypt' ? 'Cifrar Mensaje' : 'Descifrar Mensaje',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 24),

            // Result
            if (_resultCtrl.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.output_rounded, color: cs.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Resultado:',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          onPressed: _copyResult,
                          tooltip: 'Copiar al portapapeles',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _resultCtrl.text,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 14,
                        color: _resultCtrl.text.startsWith('Error') ? Colors.redAccent : cs.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
