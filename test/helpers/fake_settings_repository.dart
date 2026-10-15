import 'package:dartz/dartz.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/settings/data_source/settings_remote_data_source.dart';
import 'package:textin/features/settings/models/user_settings.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository({
    this.stored = const UserSettings(),
    this.failUpdates = false,
  }) : super(_NoRemote());

  UserSettings stored;
  bool failUpdates;

  @override
  Future<Either<Failure, UserSettings>> fetchSettings() async => Right(stored);

  @override
  Future<Either<Failure, UserSettings>> updateSettings(
    UserSettings settings,
  ) async {
    if (failUpdates) return const Left(ServerFailure('Offline'));
    return Right(stored = settings);
  }
}

class _NoRemote implements SettingsRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
