import 'package:flutter/material.dart';
import '../theming/app_colors.dart';

class SosButtonShell extends StatelessWidget {
  final VoidCallback? onPressed;

  const SosButtonShell({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.alert,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      onPressed: onPressed ?? () {},
      icon: const Icon(Icons.warning_amber_rounded),
      label: const Text(
        'EMERGENCY SOS',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }
}
