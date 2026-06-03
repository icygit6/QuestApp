import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device has a usable network route.
class NetworkInfo {
  const NetworkInfo(this._connectivity);

  final Connectivity _connectivity;

  /// Returns true when ConnectivityPlus reports any non-offline transport.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
