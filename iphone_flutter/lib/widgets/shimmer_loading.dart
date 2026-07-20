import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = Tween<double>(begin: -2, end: 3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                cs.surface.withValues(alpha: 0.05),
                cs.primary.withValues(alpha: 0.08),
                cs.surface.withValues(alpha: 0.05),
              ],
              stops: [_anim.value - 0.5, _anim.value, _anim.value + 0.5],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final int itemCount;

  const ShimmerCard({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const ShimmerLoading(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(height: 14, width: 140, borderRadius: 6),
                    const SizedBox(height: 8),
                    ShimmerLoading(height: 12, width: double.infinity, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
