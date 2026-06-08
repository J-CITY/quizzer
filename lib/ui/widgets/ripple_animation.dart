import 'package:flutter/material.dart';
import 'dart:math' as math;

class RippleAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double minRadius;
  final Color color;
  final int ripplesCount;
  final Duration duration;

  const RippleAnimation({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.minRadius = 60,
    required this.color,
    this.ripplesCount = 3,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
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
        return CustomPaint(
          painter: _RipplePainter(
            _controller.value,
            widget.ripplesCount,
            widget.color,
            widget.minRadius,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double animationValue;
  final int count;
  final Color color;
  final double minRadius;

  _RipplePainter(this.animationValue, this.count, this.color, this.minRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < count; i++) {
      final circleValue = (animationValue + (i / count)) % 1.0;
      final radius = minRadius + (minRadius * circleValue * 0.5);
      final opacity = (1.0 - circleValue).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
