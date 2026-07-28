import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/connectivity/connectivity_service.dart';
import 'core/auth/token_storage.dart';
import 'core/navigation/app_router.dart';
import 'core/state/app_provider.dart';
import 'core/theming/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final logger = AppLogger();
  final connectivityService = DefaultConnectivityService();
  final tokenStorage = SecureTokenStorage();

  logger.info('Initializing 7s Mobile Foundation in [${config.environment.name}] mode...');

  runApp(
    MultiProvider(
      providers: AppProviders.buildProviders(
        config: config,
        logger: logger,
        connectivityService: connectivityService,
        tokenStorage: tokenStorage,
      ),
      child: const AppRoot(),
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final router = AppRouter.buildRouter(authNotifier);

    return MaterialApp.router(
      title: '7s Mobile',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
