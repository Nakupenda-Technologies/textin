import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../models/live_whisper.dart';
import '../../notifier/whispers_notifier.dart';

class WhispersScreen extends ConsumerStatefulWidget {
  const WhispersScreen({super.key});

  @override
  ConsumerState<WhispersScreen> createState() => _WhispersScreenState();
}

class _WhispersScreenState extends ConsumerState<WhispersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(whispersNotifierProvider.notifier).loadLiveWhispers(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(whispersNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Whispers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTitle : AppTheme.header,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Live rooms', style: AppTextStyle.bodySecondary),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(WhispersState state) {
    if (state.status == WhispersStatus.loading && state.whispers.isEmpty) {
      return const ShimmerList();
    }

    if (state.status == WhispersStatus.error && state.whispers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? 'Live whispers could not be loaded.',
                textAlign: TextAlign.center,
                style: AppTextStyle.bodySecondary,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref
                    .read(whispersNotifierProvider.notifier)
                    .loadLiveWhispers(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.whispers.isEmpty) {
      return Center(
        child: Text(
          'No live whispers right now 🎙️',
          style: AppTextStyle.bodySecondary,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: state.whispers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _WhisperCard(whisper: state.whispers[index]),
    );
  }
}

class _WhisperCard extends StatelessWidget {
  const _WhisperCard({required this.whisper});

  final LiveWhisper whisper;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final picture = whisper.hostProfilePicture;
    final initial = whisper.hostDisplayName.isNotEmpty
        ? whisper.hostDisplayName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.onSurface.withValues(alpha: 0.10),
            backgroundImage: picture != null
                ? CachedNetworkImageProvider(picture)
                : null,
            child: picture == null
                ? Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  whisper.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        whisper.hostDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodySecondary.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (whisper.hostIsVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppTheme.textingSendBtn,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.headphones_rounded,
                      size: 14,
                      color: AppTheme.textingTimestamp,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${whisper.listenerCount} listening',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textingTimestamp,
                      ),
                    ),
                    if (whisper.chargeListeners) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '• Paid entry',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textingTimestamp,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
