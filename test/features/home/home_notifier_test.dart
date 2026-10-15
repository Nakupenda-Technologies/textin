import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/home/models/user_profile.dart';
import 'package:textin/features/home/notifier/home_notifier.dart';
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
  group('HomeNotifier tests', () {
    test('initial state is HomeInitial', () {
      final notifier = HomeNotifier(repository: MockSuccessHomeRepository());
      expect(notifier.state, isA<HomeInitial>());
      notifier.dispose();
    });

    test('emits [HomeLoading, HomeLoaded] on successful fetch', () async {
      final notifier = HomeNotifier(repository: MockSuccessHomeRepository());
      final expected = [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.profile.name,
          'profile.name',
          'Test User',
        ),
      ];

      expectLater(notifier.stream, emitsInOrder(expected));
      await notifier.loadProfile();
      notifier.dispose();
    });

    test('emits [HomeLoading, HomeError] on failed fetch', () async {
      final notifier = HomeNotifier(repository: MockFailureHomeRepository());
      final expected = [
        isA<HomeLoading>(),
        isA<HomeError>().having(
          (s) => s.message,
          'message',
          'Failed to fetch profile',
        ),
      ];

      expectLater(notifier.stream, emitsInOrder(expected));
      await notifier.loadProfile();
      notifier.dispose();
    });
  });
}
