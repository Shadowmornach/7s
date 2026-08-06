import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../connectivity/connectivity_service.dart';
import '../auth/token_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/coordinators/session_coordinator.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/onboarding/data/storage/onboarding_storage.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/passenger/domain/repositories/passenger_repository.dart';
import '../../features/passenger/data/repositories/passenger_repository_impl.dart';
import '../../features/passenger/presentation/providers/passenger_provider.dart';
import '../../features/passenger/presentation/providers/fare_templates_provider.dart';
import '../../features/passenger/presentation/providers/ride_state_notifier.dart';
import '../../features/rider/domain/repositories/rider_repository.dart';
import '../../features/rider/data/repositories/rider_repository_impl.dart';
import '../../features/rider/presentation/providers/rider_provider.dart';
import '../../features/dispatch/data/websocket/dispatch_websocket_client.dart';
import '../../features/dispatch/data/telemetry/driver_telemetry_service.dart';
import '../../features/dispatch/presentation/coordinators/dispatch_queue_coordinator.dart';
import '../../features/payments/domain/repositories/payment_repository.dart';
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/presentation/providers/payment_provider.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/safety/domain/repositories/safety_repository.dart';
import '../../features/safety/data/repositories/safety_repository_impl.dart';
import '../../features/safety/presentation/providers/safety_provider.dart';

class AppProviders {
  static List<SingleChildWidget> buildProviders({
    required AppConfig config,
    required AppLogger logger,
    required ConnectivityService connectivityService,
    required TokenStorage tokenStorage,
    OnboardingStorage? onboardingStorage,
    ApiClient? apiClient,
    AuthRepository? authRepository,
    PassengerRepository? passengerRepository,
    RiderRepository? riderRepository,
    PaymentRepository? paymentRepository,
    SettingsRepository? settingsRepository,
    SafetyRepository? safetyRepository,
    DispatchWebSocketClient? dispatchWsClient,
  }) {
    final storage = onboardingStorage ?? OnboardingStorage();
    final wsClient = dispatchWsClient ?? DispatchWebSocketClient(logger: logger);

    return [
      Provider<AppConfig>.value(value: config),
      Provider<AppLogger>.value(value: logger),
      Provider<ConnectivityService>.value(value: connectivityService),
      Provider<TokenStorage>.value(value: tokenStorage),
      Provider<OnboardingStorage>.value(value: storage),
      Provider<DispatchWebSocketClient>.value(value: wsClient),
      Provider<DriverTelemetryService>(
        create: (context) => DriverTelemetryService(wsClient: wsClient, logger: logger),
        dispose: (context, service) => service.dispose(),
      ),
      ChangeNotifierProvider<DispatchQueueCoordinator>(
        create: (context) => DispatchQueueCoordinator(logger: logger),
      ),
      ChangeNotifierProvider<OnboardingProvider>(
        create: (context) => OnboardingProvider(storage: storage),
      ),
      ChangeNotifierProvider<FareTemplatesNotifier>(
        create: (context) => FareTemplatesNotifier(),
      ),
      ProxyProvider2<AppConfig, TokenStorage, ApiClient>(
        update: (context, cfg, tokStorage, previous) =>
            apiClient ?? ApiClient(config: cfg, tokenStorage: tokStorage, logger: logger),
      ),
      ProxyProvider2<ApiClient, TokenStorage, AuthRepository>(
        update: (context, client, tokStorage, previous) =>
            authRepository ?? AuthRepositoryImpl(apiClient: client, tokenStorage: tokStorage, logger: logger),
      ),
      ProxyProvider<ApiClient, PassengerRepository>(
        update: (context, client, previous) =>
            passengerRepository ?? PassengerRepositoryImpl(apiClient: client, logger: logger),
      ),
      ChangeNotifierProxyProvider<PassengerRepository, PassengerNotifier>(
        create: (context) => PassengerNotifier(
          repository: context.read<PassengerRepository>(),
        ),
        update: (context, repo, previous) =>
            previous ?? PassengerNotifier(repository: repo),
      ),
      ProxyProvider<ApiClient, RiderRepository>(
        update: (context, client, previous) =>
            riderRepository ?? RiderRepositoryImpl(apiClient: client, logger: logger),
      ),
      ChangeNotifierProxyProvider<RiderRepository, RiderNotifier>(
        create: (context) => RiderNotifier(
          repository: context.read<RiderRepository>(),
        ),
        update: (context, repo, previous) =>
            previous ?? RiderNotifier(repository: repo),
      ),
      ProxyProvider<ApiClient, PaymentRepository>(
        update: (context, client, previous) =>
            paymentRepository ?? PaymentRepositoryImpl(apiClient: client, logger: logger),
      ),
      ChangeNotifierProxyProvider3<PaymentRepository, DispatchWebSocketClient, ConnectivityService, PaymentNotifier>(
        create: (context) => PaymentNotifier(
          repository: context.read<PaymentRepository>(),
          wsClient: context.read<DispatchWebSocketClient>(),
          connectivityService: context.read<ConnectivityService>(),
        ),
        update: (context, repo, ws, conn, previous) =>
            previous ?? PaymentNotifier(repository: repo, wsClient: ws, connectivityService: conn),
      ),
      ProxyProvider<ApiClient, SettingsRepository>(
        update: (context, client, previous) =>
            settingsRepository ?? SettingsRepositoryImpl(apiClient: client, logger: logger),
      ),
      ChangeNotifierProxyProvider<SettingsRepository, SettingsNotifier>(
        create: (context) => SettingsNotifier(
          repository: context.read<SettingsRepository>(),
        ),
        update: (context, repo, previous) =>
            previous ?? SettingsNotifier(repository: repo),
      ),
      ProxyProvider<ApiClient, SafetyRepository>(
        update: (context, client, previous) =>
            safetyRepository ?? SafetyRepositoryImpl(apiClient: client, logger: logger),
      ),
      ChangeNotifierProxyProvider2<SafetyRepository, ConnectivityService, SafetyNotifier>(
        create: (context) => SafetyNotifier(
          repository: context.read<SafetyRepository>(),
          connectivityService: context.read<ConnectivityService>(),
        ),
        update: (context, repo, connectivity, previous) =>
            previous ?? SafetyNotifier(repository: repo, connectivityService: connectivity),
      ),
      ProxyProvider2<AuthRepository, ConnectivityService, SessionCoordinator>(
        update: (context, authRepo, conn, previous) =>
            previous ?? SessionCoordinator(authRepository: authRepo, connectivityService: conn, logger: logger),
      ),
      ChangeNotifierProvider<RideStateNotifier>(
        create: (context) => RideStateNotifier(),
      ),
      ChangeNotifierProxyProvider<SessionCoordinator, AuthNotifier>(
        create: (context) => AuthNotifier(
          sessionCoordinator: context.read<SessionCoordinator>(),
        ),
        update: (context, coordinator, previous) =>
            previous ?? AuthNotifier(sessionCoordinator: coordinator),
      ),
    ];
  }
}
