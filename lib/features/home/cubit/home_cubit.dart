import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this.repository}) : super(HomeInitial());

  final HomeRepository repository;

  Future<void> loadProfile() async {
    emit(HomeLoading());
    final result = await repository.getUserProfile();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (profile) => emit(HomeLoaded(profile)),
    );
  }
}
