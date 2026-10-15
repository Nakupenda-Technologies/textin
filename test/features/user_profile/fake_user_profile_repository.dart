import 'package:dartz/dartz.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/user_profile/data_source/user_profile_remote_data_source.dart';
import 'package:textin/features/user_profile/models/user_profile.dart';
import 'package:textin/features/user_profile/repository/user_profile_repository.dart';

class _UnusedRemote implements UserProfileRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeUserProfileRepository extends UserProfileRepository {
  FakeUserProfileRepository({required this.profileResult})
    : super(_UnusedRemote());

  Either<Failure, UserProfile> profileResult;
  Failure? actionFailure;
  final List<String> calls = [];

  Either<Failure, Unit> get _actionResult =>
      actionFailure == null ? const Right(unit) : Left(actionFailure!);

  @override
  Future<Either<Failure, UserProfile>> fetchProfile(String userId) async =>
      profileResult;

  @override
  Future<Either<Failure, Unit>> setBlocked(
    String userId, {
    required bool blocked,
  }) async {
    calls.add('block:$userId:$blocked');
    return _actionResult;
  }

  @override
  Future<Either<Failure, Unit>> setMuted(
    String userId, {
    required bool muted,
  }) async {
    calls.add('mute:$userId:$muted');
    return _actionResult;
  }
}
