import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool glow;
  final VoidCallback? onTap;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.color,
    this.glow = false,
    this.onTap,
    this.glowColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _startShineLoop();
  }

  void _startShineLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) {
        await _shineCtrl.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    // Premium frosted glass semi-transparent colors
    final cardColor = widget.color ?? (isDark
        ? const Color(0xFF1E1E22).withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.75));

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isDark ? 16 : 20,
            offset: const Offset(0, 4),
          ),
          if (widget.glow)
            BoxShadow(
              color: (widget.glowColor ?? primary).withValues(alpha: isDark ? 0.15 : 0.10),
              blurRadius: 30,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 1),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(widget.borderRadius - 1),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                  // Shine sweep shader layer
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shineCtrl,
                      builder: (context, _) {
                        final val = _shineCtrl.value;
                        if (val == 0.0 || val == 1.0) return const SizedBox();
                        return FractionallySizedBox(
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(widget.borderRadius - 1),
                                gradient: LinearGradient(
                                  begin: Alignment(-2.0 + val * 4.0, -1.0),
                                  end: Alignment(-1.0 + val * 4.0, 1.0),
                                  colors: const [
                                    Colors.transparent,
                                    Colors.white10,
                                    Colors.white24,
                                    Colors.white10,
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

class TiltCard extends StatefulWidget {
  final Widget child;
  final double tilt;
  final double borderRadius;

  const TiltCard({
    super.key,
    required this.child,
    this.tilt = 0.02,
    this.borderRadius = 24,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-widget.tilt * _ctrl.value)
            ..rotateY(widget.tilt * _ctrl.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
