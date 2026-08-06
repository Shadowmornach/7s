import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theming/app_colors.dart';
import '../theming/app_typography.dart';

/// Modern chip / badge widget for category filters, ride status indicators,
/// and metadata tags.
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = isSelected
        ? (color ?? AppColors.primary)
        : (color?.withValues(alpha: 0.12) ?? AppColors.background);

    final effectiveFg = isSelected
        ? (textColor ?? AppColors.secondary)
        : (textColor ?? AppColors.textPrimary);

    Widget chipContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? (color ?? AppColors.primary)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: effectiveFg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: effectiveFg,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chipContent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      child: chipContent,
    );
  }
}
