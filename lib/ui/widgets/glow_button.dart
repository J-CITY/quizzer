import 'package:flutter/material.dart';

class GlowButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isPrimary;
  final double glowOpacity;
  final double? width;

  const GlowButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    this.borderRadius = 16.0,
    this.isPrimary = true,
    this.glowOpacity = 0.25,
    this.width,
  }) : super(key: key);

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final isDisabled = widget.onPressed == null;
    final btnColor = isDisabled ? Colors.grey[800]! : themeColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = widget.isPrimary
        ? LinearGradient(
            colors: [
              Color.lerp(btnColor, Colors.white, 0.05) ?? btnColor,
              Color.lerp(btnColor, Colors.black, 0.15) ?? btnColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Color.lerp(Theme.of(context).colorScheme.surface, btnColor, 0.15) ?? btnColor,
              Color.lerp(Theme.of(context).colorScheme.surface, btnColor, 0.05) ?? btnColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          width: widget.width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: (!widget.isPrimary && widget.color != null)
                  ? btnColor.withValues(alpha: 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : btnColor.withValues(alpha: 0.08)),
              width: 1,
            ),
            boxShadow: (widget.isPrimary && !isDisabled)
                ? [
                    BoxShadow(
                      color: btnColor.withValues(alpha: widget.glowOpacity),
                      blurRadius: 24,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.isPrimary ? Colors.white : themeColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: widget.isPrimary ? Colors.white : btnColor,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
