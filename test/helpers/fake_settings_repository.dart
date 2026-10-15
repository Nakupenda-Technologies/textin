import 'package:dartz/dartz.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/settings/data_source/settings_remote_data_source.dart';
import 'package:textin/features/settings/models/listed_user.dart';
import 'package:textin/features/settings/models/user_settings.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository({
    this.stored = const UserSettings(),
    this.failUpdates = false,
  }) : super(_NoRemote());

  UserSettings stored;
  bool failUpdates;

  final emailChangeRequests = <String>[];
  final passwordChanges = <(String, String)>[];
  final deletePasswords = <String?>[];
  List<ListedUser> listedUsers = const [];
  final removedUsers = <(UserListKind, String)>[];

  @override
  Future<Either<Failure, List<ListedUser>>> fetchUsers(
    UserListKind kind,
  ) async => Right(listedUsers);

  @override
  Future<Either<Failure, Unit>> removeUser(
    UserListKind kind,
    String userId,
  ) async {
    removedUsers.add((kind, userId));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount(String? password) async {
    deletePasswords.add(password);
    return const Left(ServerFailure('Invalid password'));
  }

  @override
  Future<Either<Failure, Unit>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    passwordChanges.add((currentPassword, newPassword));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, UserSettings>> fetchSettings() async => Right(stored);

  @override
  Future<Either<Failure, Unit>> requestEmailChange(String newEmail) async {
    emailChangeRequests.add(newEmail);
    return const Right(unit);
  }

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
