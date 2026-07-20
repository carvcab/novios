import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/local_storage.dart';
import '../../services/theme_provider.dart';
import '../home_navigation.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final List<String> _pin = [];
  String _message = "Ingresa tu código PIN para entrar";
  bool _isWrong = false;
  bool _isUnlocked = false;

  late AnimationController _unlockIconCtrl;
  late AnimationController _burstCtrl;
  final List<BurstParticle> _burstParticles = [];

  @override
  void initState() {
    super.initState();
    _unlockIconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        if (_burstCtrl.isAnimating) {
          setState(() {
            for (var p in _burstParticles) {
              p.x += p.vx;
              p.y += p.vy;
              p.vy += 0.15; // Gravity pull down
              p.opacity = (1.0 - _burstCtrl.value).clamp(0.0, 1.0);
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _unlockIconCtrl.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_pin.length < 4 && !_isUnlocked) {
      HapticFeedback.selectionClick();
      setState(() {
        _isWrong = false;
        _pin.add(digit);
      });
      if (_pin.length == 4) _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isUnlocked) {
      HapticFeedback.selectionClick();
      setState(() {
        _isWrong = false;
        _pin.removeLast();
      });
    }
  }

  void _verifyPin() {
    final correctPin = LocalStorage().getPin() ?? '1234';
    if (_pin.join() == correctPin) {
      HapticFeedback.heavyImpact();
      _triggerUnlock();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _pin.clear();
        _isWrong = true;
        _message = "PIN incorrecto. Intenta de nuevo";
      });
    }
  }

  void _triggerUnlock() {
    setState(() {
      _isUnlocked = true;
      _message = "¡Desbloqueado!";
    });

    _unlockIconCtrl.forward();
    _triggerBurst();

    Future.delayed(const Duration(milliseconds: 700), () {
      _navigateToHome();
    });
  }

  void _triggerBurst() {
    final rand = Random();
    final colors = [
      Colors.pink,
      Colors.redAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      const Color(0xFFFF5C8A),
    ];

    _burstParticles.clear();
    for (int i = 0; i < 40; i++) {
      final angle = rand.nextDouble() * 2 * pi;
      final speed = 3.0 + rand.nextDouble() * 6.0;
      _burstParticles.add(BurstParticle(
        x: 0.0,
        y: 0.0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 6.0 + rand.nextDouble() * 12.0,
        opacity: 1.0,
        color: colors[rand.nextInt(colors.length)].withValues(alpha: 0.8),
      ));
    }
    _burstCtrl.forward(from: 0.0);
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => const HomeNavigation(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _recoverPin() {
    final question = LocalStorage().getSecurityQuestion();
    final answer = LocalStorage().getSecurityAnswer();
    if (question == null || answer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No has configurado una pregunta de seguridad.")),
      );
      return;
    }
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Recuperar PIN"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pregunta: $question", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: controller, decoration: const InputDecoration(labelText: "Tu respuesta")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().toLowerCase() == answer.toLowerCase()) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Tu PIN es: ${LocalStorage().getPin() ?? '1234'}")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Respuesta incorrecta.")));
              }
            },
            child: const Text("Verificar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (!LocalStorage().isSecurityEnabled()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToHome());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ShiftingGradientBackground(
        child: Stack(
          children: [
            // Floating background hearts
            const Positioned.fill(
              child: FloatingHeartsBackground(),
            ),

            // Unlock burst particles overlay
            if (_burstCtrl.isAnimating)
              Positioned.fill(
                child: CustomPaint(
                  painter: BurstPainter(particles: _burstParticles),
                ),
              ),

            // Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Elastic Lock/Unlock Icon
                  ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.25).animate(
                      CurvedAnimation(parent: _unlockIconCtrl, curve: Curves.elasticOut),
                    ),
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0.0, end: -0.04).animate(
                        CurvedAnimation(parent: _unlockIconCtrl, curve: Curves.elasticOut),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _isUnlocked 
                              ? Colors.green.withValues(alpha: 0.15) 
                              : primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          size: 52,
                          color: _isUnlocked ? Colors.green : primaryColor,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    "Novios App",
                    style: themeProvider.getTextStyle(TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      color: primaryColor,
                      letterSpacing: 0.5,
                    )),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _message,
                    style: themeProvider.getTextStyle(TextStyle(
                      fontSize: 15,
                      color: _isWrong ? Colors.red : Colors.grey.shade600,
                      fontWeight: _isWrong || _isUnlocked ? FontWeight.w600 : FontWeight.normal,
                    )),
                  ),
                  const SizedBox(height: 32),
                  
                  // Dot PIN indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: filled ? 18 : 14,
                        height: filled ? 18 : 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? primaryColor : Colors.grey.shade300.withValues(alpha: 0.6),
                          border: Border.all(color: primaryColor, width: 2.5),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  
                  // Keypad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: row.map((digit) => _KeyButton(
                              digit: digit, 
                              color: primaryColor, 
                              onTap: () => _onKeyPress(digit),
                            )).toList(),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              onPressed: _recoverPin,
                              icon: const Icon(Icons.help_outline_rounded, size: 28, color: Colors.grey),
                            ),
                            _KeyButton(
                              digit: '0', 
                              color: primaryColor, 
                              onTap: () => _onKeyPress('0'),
                            ),
                            IconButton(
                              onPressed: _onBackspace,
                              icon: const Icon(Icons.backspace_outlined, size: 28, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SHIFTING GRADIENT BACKGROUND ---
class ShiftingGradientBackground extends StatefulWidget {
  final Widget child;
  const ShiftingGradientBackground({required this.child, super.key});

  @override
  State<ShiftingGradientBackground> createState() => _ShiftingGradientBackgroundState();
}

class _ShiftingGradientBackgroundState extends State<ShiftingGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientCtrl;

  @override
  void initState() {
    super.initState();
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _gradientCtrl,
      builder: (context, child) {
        final t = _gradientCtrl.value;
        final begin = Alignment.lerp(Alignment.topLeft, Alignment.topRight, t)!;
        final end = Alignment.lerp(Alignment.bottomRight, Alignment.bottomLeft, t)!;
        
        final color1 = isDark 
            ? Color.lerp(const Color(0xFF1C0A11), const Color(0xFF0C091C), t)!
            : Color.lerp(const Color(0xFFFFF0F5), const Color(0xFFE8EAF6), t)!;
        final color2 = isDark
            ? Color.lerp(const Color(0xFF090A1A), const Color(0xFF1A0A0A), t)!
            : Color.lerp(const Color(0xFFF3E5F5), const Color(0xFFFFEBEE), t)!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [color1, color2],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// --- FLOATING HEARTS BACKGROUND ---
class FloatingHeartsBackground extends StatefulWidget {
  const FloatingHeartsBackground({super.key});

  @override
  State<FloatingHeartsBackground> createState() => _FloatingHeartsBackgroundState();
}

class _FloatingHeartsBackgroundState extends State<FloatingHeartsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartsCtrl;
  final List<HeartParticle> _hearts = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _heartsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Spawn 16 drifting hearts
    for (int i = 0; i < 16; i++) {
      _hearts.add(_createHeart(initialY: _rand.nextDouble() * 800));
    }
  }

  HeartParticle _createHeart({double? initialY}) {
    return HeartParticle(
      x: _rand.nextDouble() * 400,
      y: initialY ?? 850,
      speed: 0.4 + _rand.nextDouble() * 0.9,
      size: 10 + _rand.nextDouble() * 22,
      opacity: 0.05 + _rand.nextDouble() * 0.12,
      wobbleSpeed: 1 + _rand.nextDouble() * 3,
      wobbleRange: 10 + _rand.nextDouble() * 25,
      seed: _rand.nextDouble() * 100,
    );
  }

  @override
  void dispose() {
    _heartsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heartsCtrl,
      builder: (context, _) {
        // Update locations on tick
        for (var heart in _hearts) {
          heart.y -= heart.speed;
          if (heart.y < -50) {
            // Reset to bottom
            _hearts[_hearts.indexOf(heart)] = _createHeart();
          }
        }
        return CustomPaint(
          painter: HeartsPainter(hearts: _hearts, animValue: _heartsCtrl.value),
        );
      },
    );
  }
}

class HeartParticle {
  double x;
  double y;
  final double speed;
  final double size;
  final double opacity;
  final double wobbleSpeed;
  final double wobbleRange;
  final double seed;

  HeartParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.wobbleSpeed,
    required this.wobbleRange,
    required this.seed,
  });
}

class HeartsPainter extends CustomPainter {
  final List<HeartParticle> hearts;
  final double animValue;

  HeartsPainter({required this.hearts, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var h in hearts) {
      // Calculate horizontal sway using sine wave
      final offset = sin(animValue * 2 * pi * h.wobbleSpeed + h.seed) * h.wobbleRange;
      final paintColor = Colors.pinkAccent.withValues(alpha: h.opacity);
      paint.color = paintColor;

      canvas.save();
      // Position and draw the heart shape
      canvas.translate(h.x + offset, h.y);
      final heartSize = Size(h.size, h.size);
      final path = _getHeartPath(heartSize);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  Path _getHeartPath(Size size) {
    final double width = size.width;
    final double height = size.height;
    Path path = Path();
    path.moveTo(width / 2, height / 5);
    path.cubicTo(5 * width / 14, 0, 0, height / 15, width / 28, 2 * height / 5);
    path.cubicTo(width / 14, 2 * height / 3, 3 * width / 7, 5 * height / 6, width / 2, height);
    path.cubicTo(4 * width / 7, 5 * height / 6, 13 * width / 14, 2 * height / 3, 27 * width / 28, 2 * height / 5);
    path.cubicTo(width, height / 15, 9 * width / 14, 0, width / 2, height / 5);
    return path;
  }

  @override
  bool shouldRepaint(covariant HeartsPainter oldDelegate) => true;
}

// --- BURST PARTICLES ---
class BurstParticle {
  double x;
  double y;
  final double vx;
  double vy;
  final double size;
  double opacity;
  final Color color;

  BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.color,
  });
}

class BurstPainter extends CustomPainter {
  final List<BurstParticle> particles;
  BurstPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2 - 130); // Center around lock icon

    for (var p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);
      canvas.save();
      canvas.translate(center.dx + p.x, center.dy + p.y);
      final heartSize = Size(p.size, p.size);
      final path = _getHeartPath(heartSize);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  Path _getHeartPath(Size size) {
    final double width = size.width;
    final double height = size.height;
    Path path = Path();
    path.moveTo(width / 2, height / 5);
    path.cubicTo(5 * width / 14, 0, 0, height / 15, width / 28, 2 * height / 5);
    path.cubicTo(width / 14, 2 * height / 3, 3 * width / 7, 5 * height / 6, width / 2, height);
    path.cubicTo(4 * width / 7, 5 * height / 6, 13 * width / 14, 2 * height / 3, 27 * width / 28, 2 * height / 5);
    path.cubicTo(width, height / 15, 9 * width / 14, 0, width / 2, height / 5);
    return path;
  }

  @override
  bool shouldRepaint(covariant BurstPainter oldDelegate) => true;
}

// --- REACTIVELY SCALING KEY BUTTON ---
class _KeyButton extends StatefulWidget {
  final String digit;
  final Color color;
  final VoidCallback onTap;

  const _KeyButton({required this.digit, required this.color, required this.onTap});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: Container(
          margin: const EdgeInsets.all(8),
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed ? widget.color.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: OutlinedButton(
            onPressed: null, // Disabled so GestureDetector handles tap gestures
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isPressed ? widget.color : widget.color.withValues(alpha: 0.3),
                width: _isPressed ? 2.5 : 1.5,
              ),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              disabledForegroundColor: widget.color,
            ),
            child: Text(
              widget.digit, 
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
