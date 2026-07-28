import 'package:flutter/material.dart';

class OnboardingPageItem {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const OnboardingPageItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}
