import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../data_source/home_data_source.dart';
import '../models/user_profile.dart';

abstract class HomeRepository {
  Future<Either<Failure, UserProfile>> getUserProfile();
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this.dataSource);

  final HomeDataSource dataSource;

  @override
  Future<Either<Failure, UserProfile>> getUserProfile() async {
    try {
      final profile = await dataSource.fetchUserProfile();
      return Right(profile);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
