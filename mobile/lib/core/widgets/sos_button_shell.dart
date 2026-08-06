import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theming/app_colors.dart';
import '../theming/app_typography.dart';

/// Redesigned Emergency SOS button with red emergency glow,
/// bold visual urgency, animated scale, and haptic feedback.
class SosButtonShell extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isActive;

  const SosButtonShell({
    super.key,
    this.onPressed,
    this.label = 'SOS',
    this.isActive = false,
  });

  @override
  State<SosButtonShell> createState() => _SosButtonShellState();
}

class _SosButtonShellState extends State<SosButtonShell> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isActive
        ? AppColors.alert
        : const Color(0xFFFEF2F2);
    final contentColor = widget.isActive
        ? Colors.white
        : const Color(0xFFEF4444);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.heavyImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed ?? () {},
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.alert
                  : const Color(0xFFFCA5A5),
              width: 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: AppColors.alert.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: contentColor, size: 17),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.labelLarge.copyWith(
                  color: contentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
