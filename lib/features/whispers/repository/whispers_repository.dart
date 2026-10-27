import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../data_source/whispers_remote_data_source.dart';
import '../models/live_whisper.dart';
import '../models/my_whisper.dart';

abstract class WhispersRepository {
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers();
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers();
  Future<Either<Failure, void>> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  });
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
