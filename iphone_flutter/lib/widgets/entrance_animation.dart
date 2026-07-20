import 'package:flutter/material.dart';

class EntranceAnimation extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset offset;
  final bool fade;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 500),
    this.offset = const Offset(0, 30),
    this.fade = true,
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _slideAnim = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnim.value,
          child: widget.fade
              ? Opacity(opacity: _fadeAnim.value, child: child)
              : child,
        );
      },
      child: widget.child,
    );
  }
}

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final int baseDelay;
  final int staggerMs;

  const StaggeredList({
    super.key,
    required this.children,
    this.baseDelay = 50,
    this.staggerMs = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (i) {
        return EntranceAnimation(
          delayMs: baseDelay + i * staggerMs,
          child: children[i],
        );
      }),
    );
  }
}

class PulseIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double minScale;
  final double maxScale;

  const PulseIcon({
    super.key,
    required this.icon,
    this.size = 24,
    required this.color,
    this.minScale = 0.9,
    this.maxScale = 1.1,
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Transform.scale(scale: _anim.value, child: child);
      },
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}

class FadeInSection extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeInSection({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<FadeInSection> createState() => _FadeInSectionState();
}

class _FadeInSectionState extends State<FadeInSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _anim, child: widget.child);
  }
}
