import 'package:get_it/get_it.dart';
import '../../config/env/env.dart';
import '../../features/auth/data_source/auth_remote_data_source.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/home/data_source/home_data_source.dart';
import '../../features/home/repository/home_repository.dart';
import '../../features/texting/data_source/texting_remote_data_source.dart';
import '../../features/texting/repository/texting_repository.dart';
import '../../features/texting/repository/texting_repository_impl.dart';
import '../../features/texting/services/texting_socket_service.dart';
import '../../services/websocket_service.dart';
import '../network/client.dart';
import '../network/session_manager.dart';
import '../storage/session_store.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton<SessionStore>(SessionStore.new);
  locator.registerLazySingleton<SessionManager>(
    () => SessionManager(
      store: locator<SessionStore>(),
      authBaseUrl: Env.baseUrl,
    ),
  );

  locator.registerLazySingleton<BaseApiClients>(
    () => BaseApiClients(
      baseUrl: Env.baseUrl,
      session: locator<SessionManager>(),
    ),
  );

  locator.registerLazySingleton<BaseApiClients>(
    () => BaseApiClients(
      baseUrl: Env.messagingBaseUrl,
      session: locator<SessionManager>(),
    ),
    instanceName: 'messaging',
  );

  locator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(locator<BaseApiClients>()),
  );
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      remote: locator<AuthRemoteDataSource>(),
      session: locator<SessionStore>(),
    ),
  );

  locator.registerLazySingleton<WebSocketService>(() => WebSocketService());
  locator.registerLazySingleton<TextingSocketService>(
    () => TextingSocketService(
      locator<WebSocketService>(),
      accessToken: () => locator<SessionStore>().accessToken,
    ),
  );

  locator.registerLazySingleton<TextingRemoteDataSource>(
    () => TextingRemoteDataSourceImpl(
      locator<BaseApiClients>(instanceName: 'messaging'),
    ),
  );
  locator.registerLazySingleton<TextingRepository>(
    () => TextingRepositoryImpl(locator<TextingRemoteDataSource>()),
  );

  locator.registerLazySingleton<HomeDataSource>(
    () => HomeRemoteDataSource(locator<BaseApiClients>()),
  );
  locator.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(locator<HomeDataSource>()),
  );
}
