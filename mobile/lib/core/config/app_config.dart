enum AppEnvironment { development, staging, production }

class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final String appVersion;
  final String buildNumber;
  final Duration apiTimeout;
  final Duration uploadTimeout;
  final Duration downloadTimeout;

  const AppConfig({
    required this.environment,
    required this.baseUrl,
    this.appVersion = '1.0.0',
    this.buildNumber = '1',
    this.apiTimeout = const Duration(seconds: 10),
    this.uploadTimeout = const Duration(seconds: 30),
    this.downloadTimeout = const Duration(seconds: 30),
  });

  factory AppConfig.fromEnvironment({
    String? appVersion,
    String? buildNumber,
  }) {
    const envString = String.fromEnvironment('ENV', defaultValue: 'development');
    const defaultUrl = envString == 'production'
        ? 'https://api.7s.co.ke'
        : envString == 'staging'
            ? 'https://staging-api.7s.co.ke'
            : 'http://10.0.2.2:8000'; // Changed from 127.0.0.1 for Android Emulator compatibility

    const baseUrlStr = String.fromEnvironment('BASE_URL', defaultValue: defaultUrl);
    const versionStr = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
    const buildStr = String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');

    AppEnvironment env;
    switch (envString.toLowerCase()) {
      case 'production':
        env = AppEnvironment.production;
        break;
      case 'staging':
        env = AppEnvironment.staging;
        break;
      default:
        env = AppEnvironment.development;
    }

    return AppConfig(
      environment: env,
      baseUrl: baseUrlStr,
      appVersion: appVersion ?? versionStr,
      buildNumber: buildNumber ?? buildStr,
    );
  }
}
