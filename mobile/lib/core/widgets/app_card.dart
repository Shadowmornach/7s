import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theming/app_colors.dart';

/// Modern surface container card with soft elevation shadows,
/// 16dp rounded corners, optional borders, and interactive touch response.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? border;
  final double borderRadius;
  final double elevation;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = 16.0,
    this.elevation = 1.0,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.backgroundColor ?? AppColors.surface;
    final effectiveBorder = widget.border ??
        const BorderSide(color: AppColors.border, width: 1);

    Widget cardContent = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.fromBorderSide(effectiveBorder),
          boxShadow: widget.elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04 * widget.elevation),
                    blurRadius: 10 * widget.elevation,
                    offset: Offset(0, 2 * widget.elevation),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: cardContent,
    );
  }
}
