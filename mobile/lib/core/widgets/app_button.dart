import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theming/app_colors.dart';
import '../theming/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { small, medium, large }

/// Modern responsive design system button with haptic feedback,
/// micro-animations, loading states, and large touch targets.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.suffixIcon,
    this.fullWidth = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    // Height based on size
    final double height = switch (widget.size) {
      AppButtonSize.small => 40.0,
      AppButtonSize.medium => 48.0,
      AppButtonSize.large => 54.0,
    };

    final double fontSize = switch (widget.size) {
      AppButtonSize.small => 13.0,
      AppButtonSize.medium => 14.0,
      AppButtonSize.large => 16.0,
    };

    // Styling based on variant
    final Color backgroundColor;
    final Color textColor;
    final BorderSide borderSide;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.border;
        textColor = isEnabled ? AppColors.secondary : AppColors.textMuted;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isEnabled ? AppColors.surface : AppColors.background;
        textColor = isEnabled ? AppColors.primary : AppColors.textMuted;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.primary : AppColors.border,
          width: 1.5,
        );
        break;
      case AppButtonVariant.ghost:
        backgroundColor = _isPressed
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent;
        textColor = isEnabled ? AppColors.primary : AppColors.textMuted;
        borderSide = BorderSide.none;
        break;
      case AppButtonVariant.danger:
        backgroundColor = isEnabled ? AppColors.alert : AppColors.border;
        textColor = AppColors.secondary;
        borderSide = BorderSide.none;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: fontSize + 4,
            height: fontSize + 4,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: fontSize + 4, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: AppTypography.labelLarge.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        if (!widget.isLoading && widget.suffixIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.suffixIcon, size: fontSize + 4, color: textColor),
        ],
      ],
    );

    Widget buttonWidget = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: borderSide != BorderSide.none
                ? Border.fromBorderSide(borderSide)
                : null,
            boxShadow: widget.variant == AppButtonVariant.primary && isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(child: content),
        ),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }
    return buttonWidget;
  }
}
