import 'dart:async';

enum ConnectivityStatus {
  online,           // Interface connected AND backend API reachable
  localNetworkOnly, // Interface connected, but internet/backend unreachable
  offline,          // No network interface active
}

abstract class ConnectivityService {
  Future<ConnectivityStatus> checkConnectivity();
  Stream<ConnectivityStatus> get onConnectivityChanged;
  bool get isBackendReachable;
}

class DefaultConnectivityService implements ConnectivityService {
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;

  DefaultConnectivityService() {
    _controller.add(_currentStatus);
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return _currentStatus;
  }

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => _controller.stream;

  @override
  bool get isBackendReachable => _currentStatus == ConnectivityStatus.online;

  void updateStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _controller.add(status);
    }
  }

  void dispose() {
    _controller.close();
  }
}
