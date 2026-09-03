import 'package:envied/envied.dart';

part 'env.staging.g.dart';

@Envied(path: '.env.staging')
abstract class EnvStaging {
  @EnviedField(varName: 'STAGE_BASEURL')
  static const String stageBaseUrl = _EnvStaging.stageBaseUrl;

  @EnviedField(varName: 'STAGE_MESSAGING_BASEURL')
  static const String stageMessagingBaseUrl = _EnvStaging.stageMessagingBaseUrl;

  @EnviedField(varName: 'STAGE_SOCKET_URL')
  static const String stageSocketUrl = _EnvStaging.stageSocketUrl;

  @EnviedField(varName: 'STAGE_WEBSOCKET_BASEURL')
  static const String stageWebsocketBaseUrl = _EnvStaging.stageWebsocketBaseUrl;

  @EnviedField(varName: 'STAGE_APP_NAME')
  static const String stageAppName = _EnvStaging.stageAppName;

  @EnviedField(varName: 'STAGE_ENVIRONMENT')
  static const String stageEnvironment = _EnvStaging.stageEnvironment;
}
