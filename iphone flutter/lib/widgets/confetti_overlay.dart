import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  const ConfettiOverlay({required this.child, super.key});

  static ConfettiOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<ConfettiOverlayState>();
  }

  @override
  ConfettiOverlayState createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  late AnimationController _ctrl;
  final Random _r = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..addListener(_update);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _update() {
    if (_particles.isEmpty) { if (_ctrl.isAnimating) _ctrl.stop(); return; }
    setState(() {
      for (var p in _particles) {
        p.y += p.speed;
        p.x += sin(_ctrl.value * 2 * pi * p.wobble) * 1.5;
        p.rot += p.rotSpeed;
      }
      _particles.removeWhere((p) => p.y > MediaQuery.of(context).size.height + 100);
    });
  }

  void burst() {
    final size = MediaQuery.of(context).size;
    final colors = [
      Colors.pink, Colors.red, Colors.amber, Colors.blue,
      Colors.green, Colors.orange, Colors.purple, Colors.teal,
    ];
    setState(() {
      _particles.clear();
      for (int i = 0; i < 60; i++) {
        _particles.add(_Particle(
          x: _r.nextDouble() * size.width,
          y: -20 - _r.nextDouble() * 80,
          size: _r.nextDouble() * 8 + 4,
          color: colors[_r.nextInt(colors.length)],
          rot: _r.nextDouble() * 2 * pi,
          rotSpeed: _r.nextDouble() * 0.1 - 0.05,
          speed: _r.nextDouble() * 3 + 3,
          wobble: _r.nextDouble() * 2 + 1,
        ));
      }
    });
    _ctrl.repeat();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _particles.clear());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(_particles),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  double x, y, rot;
  final double size, rotSpeed, speed, wobble;
  final Color color;

  _Particle({
    required this.x, required this.y, required this.size, required this.color,
    required this.rot, required this.rotSpeed, required this.speed, required this.wobble,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.4),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
