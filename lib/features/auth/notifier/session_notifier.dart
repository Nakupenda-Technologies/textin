import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/di/locator.dart';
import '../../../core/navigation/navigator_key.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/auth_user.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return locator<AuthRepository>();
});

final currentUserProvider = StateProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).cachedUser;
});

Future<void> signOutToLogin(WidgetRef ref, {String? message}) async {
  await ref.read(authRepositoryProvider).signOut();
  ref.read(currentUserProvider.notifier).state = null;
  if (message != null) AppToast.show(message);
  rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRouter.login,
    (_) => false,
  );
}
