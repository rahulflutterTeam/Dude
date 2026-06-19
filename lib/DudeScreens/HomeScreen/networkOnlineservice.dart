import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkOnlineStatusService {
  static final NetworkOnlineStatusService _instance =
      NetworkOnlineStatusService._internal();
  factory NetworkOnlineStatusService() => _instance;
  NetworkOnlineStatusService._internal();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Callbacks
  VoidCallback? onWentOffline;
  VoidCallback? onCameOnline;

  Future<void> init() async {
    // Check current status immediately
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final nowOnline = _hasConnection(results);

      if (_isOnline && !nowOnline) {
        // Internet went OFF
        _isOnline = false;
        debugPrint("📴 Network: went OFFLINE");
        onWentOffline?.call();
      } else if (!_isOnline && nowOnline) {
        // Internet came back ON
        _isOnline = true;
        debugPrint("📶 Network: came ONLINE");
        onCameOnline?.call();
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }

  void dispose() {
    _subscription?.cancel();
    onWentOffline = null;
    onCameOnline = null;
  }
}
