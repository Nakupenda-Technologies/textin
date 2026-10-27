import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../data_source/whispers_remote_data_source.dart';
import '../models/live_whisper.dart';
import '../models/my_whisper.dart';
import '../models/whisper_media_session.dart';

abstract class WhispersRepository {
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers();
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers();
  Future<Either<Failure, void>> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  });
  Future<Either<Failure, void>> startWhisper(String id);
  Future<Either<Failure, void>> endWhisper(String id);
  Future<Either<Failure, void>> joinWhisper(String id);
  Future<Either<Failure, void>> leaveWhisper(String id);
  Future<Either<Failure, WhisperMediaSession>> createMediaSession(String id);
}

class WhispersRepositoryImpl implements WhispersRepository {
  WhispersRepositoryImpl(this.remoteDataSource);

  final WhispersRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers() =>
      _guard(remoteDataSource.fetchLiveWhispers);

  @override
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers() =>
      _guard(remoteDataSource.fetchMyWhispers);

  @override
  Future<Either<Failure, void>> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  }) => _guard(
    () => remoteDataSource.createWhisper(
      title: title,
      isPrivate: isPrivate,
      scheduledAt: scheduledAt,
    ),
  );

  @override
  Future<Either<Failure, void>> startWhisper(String id) =>
      _guard(() => remoteDataSource.startWhisper(id));

  @override
  Future<Either<Failure, void>> endWhisper(String id) =>
      _guard(() => remoteDataSource.endWhisper(id));

  @override
  Future<Either<Failure, void>> joinWhisper(String id) =>
      _guard(() => remoteDataSource.joinWhisper(id));

  @override
  Future<Either<Failure, void>> leaveWhisper(String id) =>
      _guard(() => remoteDataSource.leaveWhisper(id));

  @override
  Future<Either<Failure, WhisperMediaSession>> createMediaSession(String id) =>
      _guard(() => remoteDataSource.createMediaSession(id));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
