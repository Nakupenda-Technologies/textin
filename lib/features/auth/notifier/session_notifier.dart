import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/locator.dart';
import '../models/auth_user.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return locator<AuthRepository>();
});

final currentUserProvider = StateProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).cachedUser;
});
