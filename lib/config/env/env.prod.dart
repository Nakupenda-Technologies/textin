import 'package:envied/envied.dart';

part 'env.prod.g.dart';

@Envied(path: '.env.prod')
abstract class EnvProd {
  @EnviedField(varName: 'PROD_BASEURL')
  static const String prodBaseUrl = _EnvProd.prodBaseUrl;

  @EnviedField(varName: 'PROD_MESSAGING_BASEURL')
  static const String prodMessagingBaseUrl = _EnvProd.prodMessagingBaseUrl;

  @EnviedField(varName: 'PROD_SOCKET_URL')
  static const String prodSocketUrl = _EnvProd.prodSocketUrl;

  @EnviedField(varName: 'PROD_WEBSOCKET_BASEURL')
  static const String prodWebsocketBaseUrl = _EnvProd.prodWebsocketBaseUrl;

  @EnviedField(varName: 'PROD_APP_NAME')
  static const String prodAppName = _EnvProd.prodAppName;

  @EnviedField(varName: 'PROD_ENVIRONMENT')
  static const String prodEnvironment = _EnvProd.prodEnvironment;
}
