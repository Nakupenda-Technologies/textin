import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../data_source/settings_remote_data_source.dart';
import '../models/listed_user.dart';
import '../models/user_settings.dart';

class SettingsRepository {
  SettingsRepository(this.remote);

  final SettingsRemoteDataSource remote;

  static const _imageTypes = {
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  Future<Either<Failure, UserSettings>> fetchSettings() =>
      _guard(remote.fetchSettings);

  Future<Either<Failure, UserSettings>> updateSettings(UserSettings settings) =>
      _guard(() => remote.updateSettings(settings));

  Future<Either<Failure, Map<String, dynamic>>> updateProfile({
    required String firstName,
    required String lastName,
    required String bio,
    String? newPicturePath,
  }) => _guard(() async {
    final picture = newPicturePath == null
        ? null
        : await remote.uploadProfilePicture(
            newPicturePath,
            _imageTypes[newPicturePath.split('.').last.toLowerCase()] ??
                'image/jpeg',
          );
    return remote.updateProfile({
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio,
      'profilePicture': ?picture,
    });
  });

  Future<Either<Failure, Unit>> requestEmailChange(String newEmail) =>
      _guardUnit(() => remote.requestEmailChange(newEmail));

  Future<Either<Failure, Unit>> confirmEmailChange(
    String newEmail,
    String code,
  ) => _guardUnit(() => remote.confirmEmailChange(newEmail, code));

  Future<Either<Failure, Unit>> changePassword(
    String currentPassword,
    String newPassword,
  ) => _guardUnit(() => remote.changePassword(currentPassword, newPassword));

  Future<Either<Failure, Unit>> deactivateAccount() =>
      _guardUnit(remote.deactivateAccount);

  Future<Either<Failure, Unit>> deleteAccount(String? password) =>
      _guardUnit(() => remote.deleteAccount(password));

  Future<Either<Failure, List<ListedUser>>> fetchUsers(UserListKind kind) =>
      _guard(() => remote.fetchUsers(kind));

  Future<Either<Failure, Unit>> removeUser(UserListKind kind, String userId) =>
      _guardUnit(() => remote.removeUser(kind, userId));

  Future<Either<Failure, Unit>> _guardUnit(Future<void> Function() action) =>
      _guard(() async {
        await action();
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
