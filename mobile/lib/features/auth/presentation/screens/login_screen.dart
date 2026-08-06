import 'package:flutter/material.dart';
import 'sign_in_screen.dart';

/// Legacy entry point redirected to modern Email SignInScreen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignInScreen();
  }
}
