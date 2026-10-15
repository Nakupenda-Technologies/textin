import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/locator.dart';
import '../models/live_whisper.dart';
import '../repository/whispers_repository.dart';

enum WhispersStatus { loading, loaded, error }

class WhispersState extends Equatable {
  const WhispersState({
    this.status = WhispersStatus.loading,
    this.whispers = const [],
    this.errorMessage,
  });

  final WhispersStatus status;
  final List<LiveWhisper> whispers;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, whispers, errorMessage];
}

final whispersNotifierProvider =
    StateNotifierProvider<WhispersNotifier, WhispersState>(
      (ref) => WhispersNotifier(locator<WhispersRepository>()),
    );

class WhispersNotifier extends StateNotifier<WhispersState> {
  WhispersNotifier(this.repository) : super(const WhispersState());

  final WhispersRepository repository;

  Future<void> loadLiveWhispers() async {
    state = WhispersState(whispers: state.whispers);
    final result = await repository.fetchLiveWhispers();
    state = result.fold(
      (failure) => WhispersState(
        status: WhispersStatus.error,
        whispers: state.whispers,
        errorMessage: failure.message,
      ),
      (whispers) =>
          WhispersState(status: WhispersStatus.loaded, whispers: whispers),
    );
  }
}
