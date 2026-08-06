import 'dart:ui';
import 'package:flutter/material.dart';
import '../theming/app_colors.dart';

/// Premium Bottom Sheet container with glassmorphism backdrop blur options,
/// top drag handle, and rounded top corners (24dp).
class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showHandle;
  final bool isGlassmorphic;
  final EdgeInsetsGeometry padding;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.isGlassmorphic = true,
    this.padding = const EdgeInsets.all(20),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppBottomSheet(
        title: title,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget sheetContent = Container(
      decoration: BoxDecoration(
        color: isGlassmorphic
            ? AppColors.surface.withValues(alpha: 0.95)
            : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle) ...[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (title != null) ...[
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );

    if (isGlassmorphic) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: sheetContent,
        ),
      );
    }

    return sheetContent;
  }
}
