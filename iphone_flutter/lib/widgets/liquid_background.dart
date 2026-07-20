import 'dart:math';
import 'package:flutter/material.dart';

class LiquidBackground extends StatefulWidget {
  final Widget child;
  final bool reducedMotion;
  const LiquidBackground({
    super.key,
    required this.child,
    this.reducedMotion = false,
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _particles = List.generate(20, (i) => _Particle(
    x: Random(i * 7 + 3).nextDouble(),
    y: Random(i * 11 + 5).nextDouble(),
    size: Random(i * 3 + 1).nextDouble() * 3 + 2,
    speed: Random(i * 13 + 2).nextDouble() * 0.015 + 0.003,
    opacity: Random(i * 5 + 9).nextDouble() * 0.15 + 0.04,
  ));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 30));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(child: _buildGradient(primary, secondary, isDark)),
        if (!widget.reducedMotion) ...[
          Positioned.fill(child: _buildBlobs(primary, secondary)),
          Positioned.fill(
            child: LayoutBuilder(builder: (_, constraints) => CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ParticlesPainter(particles: _particles, value: _controller.value),
            )),
          ),
        ],
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Widget _buildGradient(Color primary, Color secondary, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  primary.withValues(alpha: 0.08),
                  secondary.withValues(alpha: 0.04),
                  const Color(0xFF0D0D0D),
                ]
              : [
                  primary.withValues(alpha: 0.06),
                  secondary.withValues(alpha: 0.04),
                  const Color(0xFFFEFEFE),
                ],
        ),
      ),
    );
  }

  Widget _buildBlobs(Color primary, Color secondary) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final v = _controller.value * 2 * pi;
        return Stack(
          children: [
            Positioned(
              left: -40 + sin(v) * 40,
              top: 60 + cos(v) * 60,
              width: 200,
              height: 200,
              child: _blob(primary.withValues(alpha: 0.12), 60),
            ),
            Positioned(
              right: -50 + cos(v + pi / 3) * 60,
              bottom: 80 + sin(v + pi / 3) * 40,
              width: 250,
              height: 250,
              child: _blob(secondary.withValues(alpha: 0.08), 80),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(Color c, double blur) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        boxShadow: [
          BoxShadow(color: c, blurRadius: blur, spreadRadius: 15),
        ],
      ),
    );
  }
}

class _Particle {
  final double x, y, size, speed, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double value;

  _ParticlesPainter({required this.particles, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final floatY = (p.y + value * p.speed) % 1.0;
      final opacity = p.opacity * (1 - (floatY > 0.5 ? (floatY - 0.5) * 2 : floatY * 2));
      final paint = Paint()
        ..color = const Color(0xFFE91E63).withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      final cx = p.x * size.width;
      final cy = floatY * size.height;
      canvas.drawCircle(Offset(cx, cy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.value != value;
}
