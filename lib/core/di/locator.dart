import 'package:get_it/get_it.dart';
import '../../config/env/env.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/home/data_source/home_data_source.dart';
import '../../features/home/repository/home_repository.dart';
import '../../features/texting/cubit/inbox/inbox_cubit.dart';
import '../../features/texting/data_source/texting_remote_data_source.dart';
import '../../features/texting/repository/texting_repository.dart';
import '../../features/texting/repository/texting_repository_impl.dart';
import '../../features/texting/services/texting_socket_service.dart';
import '../../services/websocket_service.dart';
import '../network/client.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton<BaseApiClients>(
    () => BaseApiClients(baseUrl: Env.baseUrl),
  );

  locator.registerLazySingleton<BaseApiClients>(
    () => BaseApiClients(baseUrl: Env.messagingBaseUrl),
    instanceName: 'messaging',
  );

  locator.registerLazySingleton<WebSocketService>(() => WebSocketService());
  locator.registerLazySingleton<TextingSocketService>(
    () => TextingSocketService(locator<WebSocketService>()),
  );

  locator.registerLazySingleton<TextingRemoteDataSource>(
    () => TextingRemoteDataSourceImpl(
      locator<BaseApiClients>(instanceName: 'messaging'),
    ),
  );
  locator.registerLazySingleton<TextingRepository>(
    () => TextingRepositoryImpl(locator<TextingRemoteDataSource>()),
  );

  locator.registerFactory<InboxCubit>(
    () => InboxCubit(
      repository: locator<TextingRepository>(),
      socketService: locator<TextingSocketService>(),
      myUserId: 'me',
    ),
  );

  locator.registerLazySingleton<HomeDataSource>(
    () => HomeRemoteDataSource(locator<BaseApiClients>()),
  );
  locator.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(locator<HomeDataSource>()),
  );
  locator.registerFactory<HomeCubit>(
    () => HomeCubit(repository: locator<HomeRepository>()),
  );
}
