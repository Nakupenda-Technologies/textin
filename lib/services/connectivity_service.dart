import 'dart:async';
import 'dart:io';

class ConnectivityService {
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  static final ConnectivityService _instance = ConnectivityService._internal();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    await checkConnection();
  }

  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isConnected = false;
    }
    return _isConnected;
  }
}
