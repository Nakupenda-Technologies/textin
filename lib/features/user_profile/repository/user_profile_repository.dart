import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../data_source/user_profile_remote_data_source.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this.remote);

  final UserProfileRemoteDataSource remote;

  Future<Either<Failure, UserProfile>> fetchProfile(String userId) =>
      _guard(() => remote.fetchProfile(userId));

  Future<Either<Failure, Unit>> setFollowing(
    String username, {
    required bool following,
  }) => _guard(() async {
    await remote.setFollowing(username, following: following);
    return unit;
  });

  Future<Either<Failure, Unit>> setBlocked(
    String userId, {
    required bool blocked,
  }) => _guard(() async {
    await remote.setBlocked(userId, blocked: blocked);
    return unit;
  });

  Future<Either<Failure, Unit>> setMuted(
    String userId, {
    required bool muted,
  }) => _guard(() async {
    await remote.setMuted(userId, muted: muted);
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
