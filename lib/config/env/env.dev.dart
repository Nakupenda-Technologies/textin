import 'package:envied/envied.dart';

part 'env.dev.g.dart';

@Envied(path: '.env.dev')
abstract class EnvDev {
  @EnviedField(varName: 'DEV_BASEURL')
  static const String devBaseUrl = _EnvDev.devBaseUrl;

  @EnviedField(varName: 'DEV_MESSAGING_BASEURL')
  static const String devMessagingBaseUrl = _EnvDev.devMessagingBaseUrl;

  @EnviedField(varName: 'DEV_SOCKET_URL')
  static const String devSocketUrl = _EnvDev.devSocketUrl;

  @EnviedField(varName: 'DEV_WEBSOCKET_BASEURL')
  static const String devWebsocketBaseUrl = _EnvDev.devWebsocketBaseUrl;

  @EnviedField(varName: 'DEV_APP_NAME')
  static const String devAppName = _EnvDev.devAppName;

  @EnviedField(varName: 'DEV_ENVIRONMENT')
  static const String devEnvironment = _EnvDev.devEnvironment;
}
