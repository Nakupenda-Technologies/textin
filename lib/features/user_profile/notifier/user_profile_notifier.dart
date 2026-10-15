import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/locator.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/user_profile.dart';
import '../repository/user_profile_repository.dart';

enum UserProfileStatus { loading, loaded, error }

class UserProfileState extends Equatable {
  const UserProfileState({
    this.status = UserProfileStatus.loading,
    this.profile,
    this.errorMessage,
  });

  final UserProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

final userProfileNotifierProvider = StateNotifierProvider.autoDispose
    .family<UserProfileNotifier, UserProfileState, String>(
      (ref, userId) =>
          UserProfileNotifier(locator<UserProfileRepository>(), userId)..load(),
    );

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier(
    this.repository,
    this.userId, {
    Toaster toaster = const Toaster(),
  }) : _toaster = toaster,
       super(const UserProfileState());

  final UserProfileRepository repository;
  final String userId;
  final Toaster _toaster;

  Future<void> load() async {
    state = UserProfileState(profile: state.profile);
    final result = await repository.fetchProfile(userId);
    if (!mounted) return;
    state = result.fold(
      (failure) => UserProfileState(
        status: UserProfileStatus.error,
        profile: state.profile,
        errorMessage: failure.message,
      ),
      (profile) =>
          UserProfileState(status: UserProfileStatus.loaded, profile: profile),
    );
  }

  Future<void> toggleMute() async {
    final profile = state.profile;
    if (profile == null) return;
    final muted = !profile.isMuted;
    await _optimistic(
      apply: (p) => p.copyWith(isMuted: muted),
      revert: (p) => p.copyWith(isMuted: !muted),
      request: () => repository.setMuted(profile.id, muted: muted),
      errorTitle: muted
          ? "Couldn't mute @${profile.username}"
          : "Couldn't unmute @${profile.username}",
    );
  }

  Future<void> toggleBlock() async {
    final profile = state.profile;
    if (profile == null) return;
    final blocked = !profile.isBlocked;
    await _optimistic(
      apply: (p) => p.copyWith(isBlocked: blocked),
      revert: (p) => p.copyWith(isBlocked: !blocked),
      request: () => repository.setBlocked(profile.id, blocked: blocked),
      errorTitle: blocked
          ? "Couldn't block @${profile.username}"
          : "Couldn't unblock @${profile.username}",
    );
  }

  Future<void> _optimistic({
    required UserProfile Function(UserProfile) apply,
    required UserProfile Function(UserProfile) revert,
    required Future<Either<Failure, Unit>> Function() request,
    required String errorTitle,
  }) async {
    _setProfile(apply);
    final result = await request();
    if (!mounted) return;
    result.fold((failure) {
      _setProfile(revert);
      _toaster.error(errorTitle, failure.message);
    }, (_) {});
  }

  void _setProfile(UserProfile Function(UserProfile) update) {
    final profile = state.profile;
    if (profile == null) return;
    state = UserProfileState(
      status: UserProfileStatus.loaded,
      profile: update(profile),
    );
  }
}
