import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/user_profile/models/user_profile.dart';
import 'package:textin/features/user_profile/notifier/user_profile_notifier.dart';

import '../../helpers/recording_toaster.dart';
import 'fake_user_profile_repository.dart';

const _ada = UserProfile(id: 'u2', username: 'ada', displayName: 'Ada Obi');

void main() {
  late FakeUserProfileRepository repository;
  late RecordingToaster toaster;
  late UserProfileNotifier notifier;

  setUp(() {
    repository = FakeUserProfileRepository(profileResult: const Right(_ada));
    toaster = RecordingToaster();
    notifier = UserProfileNotifier(repository, 'u2', toaster: toaster);
  });

  tearDown(() => notifier.dispose());

  test('profiles read block and mute state from the id lists', () {
    final profile = UserProfile.fromResponse(
      {
        'success': true,
        'data': {
          'id': 'u2',
          'username': 'ada',
          'displayName': 'Ada Obi',
          'bio': '  ',
        },
      },
      isBlocked: true,
      isMuted: false,
    );

    expect(
      profile,
      const UserProfile(
        id: 'u2',
        username: 'ada',
        displayName: 'Ada Obi',
        isBlocked: true,
      ),
    );
  });

  test('a failed load keeps the error message', () async {
    repository.profileResult = const Left(ServerFailure('User not found'));

    await notifier.load();

    expect(notifier.state.status, UserProfileStatus.error);
    expect(notifier.state.errorMessage, 'User not found');
  });

  test('a failed mute rolls back and shows an error', () async {
    await notifier.load();
    repository.actionFailure = const ServerFailure('Offline');

    await notifier.toggleMute();

    expect(notifier.state.profile, _ada);
    expect(toaster.errors.single, (
      title: "Couldn't mute @ada",
      message: 'Offline',
    ));
  });

  test('muting and blocking use the user id', () async {
    await notifier.load();

    await notifier.toggleMute();
    await notifier.toggleBlock();

    expect(repository.calls, ['mute:u2:true', 'block:u2:true']);
    expect(notifier.state.profile!.isMuted, isTrue);
    expect(notifier.state.profile!.isBlocked, isTrue);
  });

  test('a failed unblock leaves the user blocked', () async {
    repository.profileResult = Right(_ada.copyWith(isBlocked: true));
    await notifier.load();
    repository.actionFailure = const ServerFailure('Offline');

    await notifier.toggleBlock();

    expect(notifier.state.profile!.isBlocked, isTrue);
    expect(toaster.errors.single.title, "Couldn't unblock @ada");
  });
}
