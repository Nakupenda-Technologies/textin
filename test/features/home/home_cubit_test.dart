import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/home/cubit/home_cubit.dart';
import 'package:textin/features/home/cubit/home_state.dart';
import 'package:textin/features/home/models/user_profile.dart';
import 'package:textin/features/home/repository/home_repository.dart';

class MockSuccessHomeRepository implements HomeRepository {
  @override
  Future<Either<Failure, UserProfile>> getUserProfile() async {
    return const Right(
      UserProfile(
        id: '1',
        name: 'Test User',
        status: 'Online',
      ),
    );
  }
}

class MockFailureHomeRepository implements HomeRepository {
  @override
  Future<Either<Failure, UserProfile>> getUserProfile() async {
    return const Left(ServerFailure('Failed to fetch profile'));
  }
}

void main() {
  group('HomeCubit tests', () {
    test('initial state is HomeInitial', () {
      final cubit = HomeCubit(repository: MockSuccessHomeRepository());
      expect(cubit.state, isA<HomeInitial>());
      cubit.close();
    });

    test('emits [HomeLoading, HomeLoaded] on successful fetch', () async {
      final cubit = HomeCubit(repository: MockSuccessHomeRepository());
      final expected = [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.profile.name,
          'profile.name',
          'Test User',
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.loadProfile();
      cubit.close();
    });

    test('emits [HomeLoading, HomeError] on failed fetch', () async {
      final cubit = HomeCubit(repository: MockFailureHomeRepository());
      final expected = [
        isA<HomeLoading>(),
        isA<HomeError>().having(
          (s) => s.message,
          'message',
          'Failed to fetch profile',
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.loadProfile();
      cubit.close();
    });
  });
}
