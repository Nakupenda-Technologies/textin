import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../notifier/registration_notifier.dart';

class UsernameStatusIcon extends StatelessWidget {
  const UsernameStatusIcon({super.key, required this.status});

  final UsernameStatus status;

  @override
  Widget build(BuildContext context) {
    final Widget icon = switch (status) {
      UsernameStatus.idle => const SizedBox.shrink(),
      UsernameStatus.checking => const AppShimmer(
        child: ShimmerBlock.circle(size: 16),
      ),
      UsernameStatus.available => const Icon(
        Icons.check_circle_rounded,
        size: 20,
        color: AppTheme.textingSendBtn,
        semanticLabel: 'Username available',
      ),
      UsernameStatus.taken => Icon(
        Icons.cancel_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.error,
        semanticLabel: 'Username taken',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Center(widthFactor: 1, child: icon),
    );
  }
}
