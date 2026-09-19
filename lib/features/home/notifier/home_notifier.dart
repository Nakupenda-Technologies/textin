import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/locator.dart';
import '../repository/home_repository.dart';
import 'home_state.dart';

export 'home_state.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return locator<HomeRepository>();
});

final homeNotifierProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository: repository);
});

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier({required this.repository}) : super(HomeInitial());

  final HomeRepository repository;

  Future<void> loadProfile() async {
    state = HomeLoading();
    final result = await repository.getUserProfile();
    result.fold(
      (failure) => state = HomeError(failure.message),
      (profile) => state = HomeLoaded(profile),
    );
  }
}
