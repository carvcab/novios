import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WheelSpinner extends StatefulWidget {
  final List<String> items;
  final String title;
  final Function(String) onFinished;

  const WheelSpinner({
    required this.items,
    required this.title,
    required this.onFinished,
    super.key,
  });

  @override
  State<WheelSpinner> createState() => _WheelSpinnerState();
}

class _WheelSpinnerState extends State<WheelSpinner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _angle = 0.0;
  bool _isSpinning = false;

  static const _colors = [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFF26A69A),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFEF5350),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSpinning = true);

    final random = Random();
    final targetAngle = _angle + (2 * pi * (4 + random.nextInt(4))) + (random.nextDouble() * 2 * pi);

    _animation = Tween<double>(begin: _angle, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    )..addListener(() => setState(() => _angle = _animation.value % (2 * pi)));

    _controller.forward(from: 0.0).then((_) {
      setState(() => _isSpinning = false);
      final itemCount = widget.items.length;
      final sectorSize = 2 * pi / itemCount;
      double targetPosition = (-pi / 2 - _angle) % (2 * pi);
      if (targetPosition < 0) targetPosition += 2 * pi;
      final selectedIndex = (targetPosition / sectorSize).floor() % itemCount;
      HapticFeedback.heavyImpact();
      widget.onFinished(widget.items[selectedIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
        const SizedBox(height: 15),
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: _spin,
              child: Transform.rotate(
                angle: _angle,
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _WheelPainter(items: widget.items, colors: _colors),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _spin,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, spreadRadius: 1)],
                ),
                child: Icon(Icons.play_arrow_rounded, size: 30, color: _isSpinning ? Colors.grey : primary),
              ),
            ),
            Positioned(
              top: 0,
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: Icon(Icons.arrow_drop_down_rounded, size: 40, color: primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _spin,
          icon: const Icon(Icons.casino_rounded),
          label: Text(_isSpinning ? 'Girando...' : 'Girar Ruleta!'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> items;
  final List<Color> colors;

  _WheelPainter({required this.items, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final sweepAngle = 2 * pi / items.length;

    final fillPaint = Paint()..style = PaintingStyle.fill..isAntiAlias = true;
    final borderPaint = Paint()..style = PaintingStyle.stroke..color = Colors.white..strokeWidth = 2.5;

    for (int i = 0; i < items.length; i++) {
      fillPaint.color = colors[i % colors.length];
      final startAngle = i * sweepAngle;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, fillPaint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, borderPaint);

      canvas.save();
      final textAngle = startAngle + sweepAngle / 2;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final textSpan = TextSpan(
        text: items[i].length > 10 ? '${items[i].substring(0, 8)}...' : items[i],
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr, textAlign: TextAlign.right)
        ..layout(maxWidth: radius - 25);
      tp.paint(canvas, Offset(radius - tp.width - 20, -tp.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
