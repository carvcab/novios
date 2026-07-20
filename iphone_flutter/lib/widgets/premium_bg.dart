import 'dart:math';
import 'package:flutter/material.dart';

class PremiumBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final bool showStars;
  final bool showGradient;

  const PremiumBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showStars = true,
    this.showGradient = true,
  });

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _particles = List.generate(8, (i) => _Particle(
    x: Random(i * 7 + 3).nextDouble(),
    y: Random(i * 11 + 5).nextDouble(),
    size: Random(i * 3 + 1).nextDouble() * 2.5 + 1,
    speed: Random(i * 13 + 2).nextDouble() * 0.008 + 0.002,
    opacity: Random(i * 5 + 9).nextDouble() * 0.15 + 0.03,
  ));

  final _stars = List.generate(6, (i) => _Star(
    x: Random(i * 17 + 3).nextDouble(),
    y: Random(i * 13 + 7).nextDouble(),
    size: Random(i * 5 + 1).nextDouble() * 2 + 1,
    twinkle: Random(i * 3 + 2).nextDouble() * 0.5 + 0.5,
    phase: Random().nextDouble() * 2 * pi,
  ));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 40));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        if (widget.showGradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          cs.primary.withValues(alpha: 0.05),
                          cs.secondary.withValues(alpha: 0.03),
                          bg,
                        ]
                      : [
                          cs.primary.withValues(alpha: 0.04),
                          cs.secondary.withValues(alpha: 0.02),
                          bg,
                        ],
                ),
              ),
            ),
          ),
        if (widget.showStars)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _StarsPainter(
                  stars: _stars,
                  value: _ctrl.value,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        if (widget.showParticles)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  value: _ctrl.value,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        if (isDark)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      cs.primary.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _Particle {
  final double x, y, size, speed, opacity;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _Star {
  final double x, y, size, twinkle, phase;
  _Star({required this.x, required this.y, required this.size, required this.twinkle, required this.phase});
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double value;
  final Color color;

  _ParticlesPainter({required this.particles, required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final floatY = (p.y + value * p.speed) % 1.0;
      final opacity = p.opacity * (1 - (floatY > 0.5 ? (floatY - 0.5) * 2 : floatY * 2));
      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      
      final center = Offset(p.x * size.width, floatY * size.height);
      _drawHeart(canvas, center, p.size, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    final width = size * 2.2;
    final height = size * 2.2;

    path.moveTo(x, y + height / 4);
    path.cubicTo(x, y - height / 8, x - width / 2, y - height / 8, x - width / 2, y + height / 3);
    path.cubicTo(x - width / 2, y + height * 2 / 3, x, y + height, x, y + height);
    path.cubicTo(x, y + height, x + width / 2, y + height * 2 / 3, x + width / 2, y + height / 3);
    path.cubicTo(x + width / 2, y - height / 8, x, y - height / 8, x, y + height / 4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.value != value;
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double value;
  final bool isDark;

  _StarsPainter({required this.stars, required this.value, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final twinkle = sin(value * 2 * pi * s.twinkle + s.phase) * 0.3 + 0.7;
      final opacity = twinkle * (isDark ? 0.5 : 0.15);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.value != value;
}
