import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../coordinators/session_coordinator.dart';
import '../../../../core/widgets/loading_indicator.dart';

class SplashSessionScreen extends StatefulWidget {
  const SplashSessionScreen({super.key});

  @override
  State<SplashSessionScreen> createState() => _SplashSessionScreenState();
}

class _SplashSessionScreenState extends State<SplashSessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthNotifier>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthNotifier>(
        builder: (context, auth, child) {
          if (auth.state == AuthState.offlineWaiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Waiting for internet connection...'),
                ],
              ),
            );
          }
          return const LoadingIndicator();
        },
      ),
    );
  }
}
