// ============================================================
// core/network/network_checker.dart
// ============================================================

import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks internet connectivity before making API calls.
class NetworkChecker {
  NetworkChecker(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> get hasConnection async {
    final result = await _connectivity.checkConnectivity();
    return result.any(
      (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi,
    );
  }

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any(
          (r) =>
              r == ConnectivityResult.mobile || r == ConnectivityResult.wifi,
        ),
      );
}
