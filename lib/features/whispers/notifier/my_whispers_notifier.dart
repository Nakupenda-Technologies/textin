import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/di/locator.dart';
import '../../../core/errors/failure.dart';
import '../models/my_whisper.dart';
import '../repository/whispers_repository.dart';
import 'whispers_notifier.dart';

class MyWhispersState extends Equatable {
  const MyWhispersState({
    this.status = WhispersStatus.loading,
    this.whispers = const [],
    this.errorMessage,
  });

  final WhispersStatus status;
  final List<MyWhisper> whispers;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, whispers, errorMessage];
}

final myWhispersNotifierProvider =
    StateNotifierProvider<MyWhispersNotifier, MyWhispersState>(
      (ref) => MyWhispersNotifier(locator<WhispersRepository>()),
    );

class MyWhispersNotifier extends StateNotifier<MyWhispersState> {
  MyWhispersNotifier(this.repository) : super(const MyWhispersState());

  final WhispersRepository repository;

  Future<void> load() async {
    state = MyWhispersState(whispers: state.whispers);
    final result = await repository.fetchMyWhispers();
    if (!mounted) return;
    state = result.fold(
      (failure) => MyWhispersState(
        status: WhispersStatus.error,
        whispers: state.whispers,
        errorMessage: failure.message,
      ),
      (whispers) =>
          MyWhispersState(status: WhispersStatus.loaded, whispers: whispers),
    );
  }

  Future<Either<Failure, String>> create({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  }) async {
    final result = await repository.createWhisper(
      title: title,
      isPrivate: isPrivate,
      scheduledAt: scheduledAt,
    );
    if (result.isRight()) load();
    return result;
  }

  Future<Failure?> start(String id) async => (await repository.startWhisper(
    id,
  )).fold((failure) => failure, (_) => null);
}
