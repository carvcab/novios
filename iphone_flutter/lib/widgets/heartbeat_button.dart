import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';

class HeartbeatButton extends StatefulWidget {
  const HeartbeatButton({super.key});

  @override
  State<HeartbeatButton> createState() => _HeartbeatButtonState();
}

class _HeartbeatButtonState extends State<HeartbeatButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<_FloatingParticle> _particles = [];
  int _particleIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.heavyImpact();
    AudioService().playHeartbeat();

    final random = Random();
    setState(() {
      for (int i = 0; i < 8; i++) {
        _particles.add(_FloatingParticle(
          id: _particleIdCounter++,
          dx: random.nextDouble() * 160 - 80,
          size: random.nextDouble() * 16 + 8,
          color: Colors.pink.withValues(alpha: random.nextDouble() * 0.3 + 0.5),
          speed: random.nextDouble() * 80 + 120,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ..._particles.map((p) => _ParticleAnimation(
            key: ValueKey(p.id),
            particle: p,
            onComplete: () {
              setState(() => _particles.removeWhere((x) => x.id == p.id));
            },
          )),
          GestureDetector(
            onTap: _onTap,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: 0.15),
                      primary.withValues(alpha: 0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.2),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: primary,
                  size: 60,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingParticle {
  final int id;
  final double dx, size, speed;
  final Color color;

  _FloatingParticle({
    required this.id,
    required this.dx,
    required this.size,
    required this.color,
    required this.speed,
  });
}

class _ParticleAnimation extends StatefulWidget {
  final _FloatingParticle particle;
  final VoidCallback onComplete;

  const _ParticleAnimation({
    required this.particle,
    required this.onComplete,
    super.key,
  });

  @override
  State<_ParticleAnimation> createState() => _ParticleAnimationState();
}

class _ParticleAnimationState extends State<_ParticleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnim;
  late Animation<double> _xAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.particle.speed.toInt()),
    );

    _yAnim = Tween<double>(begin: 0, end: -200).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _xAnim = Tween<double>(begin: 0, end: widget.particle.dx).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_xAnim.value, _yAnim.value),
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Container(
              width: widget.particle.size,
              height: widget.particle.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.particle.color,
              ),
            ),
          ),
        );
      },
    );
  }
}
