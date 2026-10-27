import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../models/live_whisper.dart';
import '../../notifier/my_whispers_notifier.dart';
import '../../notifier/whisper_room_notifier.dart';
import '../../notifier/whispers_notifier.dart';
import '../widgets/create_whisper_sheet.dart';
import '../widgets/my_whispers_list.dart';
import '../widgets/whisper_live_room_sheet.dart';

class WhispersScreen extends ConsumerStatefulWidget {
  const WhispersScreen({super.key});

  @override
  ConsumerState<WhispersScreen> createState() => _WhispersScreenState();
}

class _WhispersScreenState extends ConsumerState<WhispersScreen> {
  bool _showMine = false;

  void _selectTab({required bool mine}) {
    setState(() => _showMine = mine);
    if (mine) ref.read(myWhispersNotifierProvider.notifier).load();
  }

  Future<void> _openCreate() async {
    await showCreateWhisperSheet(context);
    if (mounted) ref.read(myWhispersNotifierProvider.notifier).load();
  }

  Future<void> _openLive(LiveWhisper whisper) async {
    final isHost = whisper.hostId == ref.read(currentUserProvider)?.id;
    // The backend charges the wallet on join, and TEXTin has no payment
    // confirmation yet, so paid rooms stay closed rather than charge silently.
    if (whisper.chargeListeners && !isHost) {
      AppToast.show("Paid whispers can't be joined from TEXTin yet");
      return;
    }
    await openWhisperRoom(
      context,
      WhisperRoomArgs(
        whisperId: whisper.id,
        title: whisper.title,
        hostName: whisper.hostDisplayName,
        hostAvatarUrl: whisper.hostProfilePicture,
        isHost: isHost,
      ),
    );
    if (mounted) {
      ref.read(whispersNotifierProvider.notifier).loadLiveWhispers();
    }
  }

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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  _TabPill(
                    label: 'Live',
                    selected: !_showMine,
                    onTap: () => _selectTab(mine: false),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    label: 'Mine',
                    selected: _showMine,
                    onTap: () => _selectTab(mine: true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _showMine ? const MyWhispersList() : _buildBody(state),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppTheme.textred,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic_none_rounded),
        label: const Text('New whisper'),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: state.whispers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final whisper = state.whispers[index];
        return _WhisperCard(whisper: whisper, onTap: () => _openLive(whisper));
      },
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppTheme.darkRedBg : AppTheme.textingTagRomanticBg2)
              : (isDark ? AppTheme.darkSurface : AppTheme.bg),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.textingActiveRedBorder
                : (isDark ? AppTheme.darkBorder : AppTheme.grayBg),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextingFilterInactiveFg
                : AppTheme.pillRed,
          ),
        ),
      ),
    );
  }
}

class _WhisperCard extends StatelessWidget {
  const _WhisperCard({required this.whisper, required this.onTap});

  final LiveWhisper whisper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final picture = whisper.hostProfilePicture;
    final initial = whisper.hostDisplayName.isNotEmpty
        ? whisper.hostDisplayName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
