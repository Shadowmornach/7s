import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/logging/app_logger.dart';

class DispatchQueueCoordinator extends ChangeNotifier {
  final AppLogger _logger;
  Timer? _offerCountdownTimer;
  int _remainingSeconds = 0;

  DispatchQueueCoordinator({required AppLogger logger}) : _logger = logger;

  int get remainingSeconds => _remainingSeconds;

  void startOfferCountdown(int seconds, VoidCallback onExpired) {
    _offerCountdownTimer?.cancel();
    _remainingSeconds = seconds;
    notifyListeners();

    _logger.info('Telemetry: [dispatch_countdown_started] Window: ${seconds}s');

    _offerCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _remainingSeconds = 0;
        timer.cancel();
        _logger.info('Telemetry: [dispatch_offer_expired]');
        notifyListeners();
        onExpired();
      }
    });
  }

  void cancelCountdown() {
    _offerCountdownTimer?.cancel();
    _remainingSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _offerCountdownTimer?.cancel();
    super.dispose();
  }
}
