import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../data_source/whispers_remote_data_source.dart';
import '../models/live_whisper.dart';

abstract class WhispersRepository {
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers();
}

class WhispersRepositoryImpl implements WhispersRepository {
  WhispersRepositoryImpl(this.remoteDataSource);

  final WhispersRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers() async {
    try {
      return Right(await remoteDataSource.fetchLiveWhispers());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
