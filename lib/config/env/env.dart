import 'dart:developer' as developer;
import 'env.dev.dart';
import 'env.staging.dart';
import 'env.prod.dart';

enum Flavor { dev, staging, prod }

class Env {
  static Flavor _currentFlavor = Flavor.dev;

  static void setFlavor(Flavor flavor) {
    _currentFlavor = flavor;
    developer.log('App running in ${_currentFlavor.name} flavor', name: 'Env');
  }

  static Flavor get flavor => _currentFlavor;

  static bool get isDev => _currentFlavor == Flavor.dev;
  static bool get isStaging => _currentFlavor == Flavor.staging;
  static bool get isProd => _currentFlavor == Flavor.prod;

  static T _getValue<T>(T dev, T staging, T prod) {
    switch (_currentFlavor) {
      case Flavor.dev:
        return dev;
      case Flavor.staging:
        return staging;
      case Flavor.prod:
        return prod;
    }
  }

  static const String _baseUrlOverride = String.fromEnvironment('BASE_URL');
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    return _getValue(
      EnvDev.devBaseUrl,
      EnvStaging.stageBaseUrl,
      EnvProd.prodBaseUrl,
    );
  }

  static String get messagingBaseUrl => _getValue(
    EnvDev.devMessagingBaseUrl,
    EnvStaging.stageMessagingBaseUrl,
    EnvProd.prodMessagingBaseUrl,
  );

  static String get socketUrl => _getValue(
    EnvDev.devSocketUrl,
    EnvStaging.stageSocketUrl,
    EnvProd.prodSocketUrl,
  );

  static String get websocketBaseUrl => _getValue(
    EnvDev.devWebsocketBaseUrl,
    EnvStaging.stageWebsocketBaseUrl,
    EnvProd.prodWebsocketBaseUrl,
  );

  static String get socketPath =>
      _getValue('/dev/socket.io', '/staging/socket.io', '/socket.io');

  static String get appName => _getValue(
    EnvDev.devAppName,
    EnvStaging.stageAppName,
    EnvProd.prodAppName,
  );

  static String get environment => _getValue(
    EnvDev.devEnvironment,
    EnvStaging.stageEnvironment,
    EnvProd.prodEnvironment,
  );
}
