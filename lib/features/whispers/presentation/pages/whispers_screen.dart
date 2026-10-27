import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../models/live_whisper.dart';
import '../../models/my_whisper.dart';
import '../../notifier/my_whispers_notifier.dart';
import '../../notifier/whisper_room_notifier.dart';
import '../../notifier/whispers_notifier.dart';
import '../widgets/create_whisper_sheet.dart';
import '../widgets/whisper_live_room_sheet.dart';

final _whenFormat = DateFormat('MMM d, h:mm a');

class WhispersScreen extends ConsumerStatefulWidget {
  const WhispersScreen({super.key});

  @override
  ConsumerState<WhispersScreen> createState() => _WhispersScreenState();
}

class _WhispersScreenState extends ConsumerState<WhispersScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() => Future.wait([
    ref.read(whispersNotifierProvider.notifier).loadLiveWhispers(),
    ref.read(myWhispersNotifierProvider.notifier).load(),
  ]);

  Future<void> _openCreate() async {
    await showCreateWhisperSheet(context);
    if (mounted) _refresh();
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
    if (mounted) _refresh();
  }

  Future<void> _startMine(MyWhisper whisper) async {
    final failure = await ref
        .read(myWhispersNotifierProvider.notifier)
        .start(whisper.id);
    if (!mounted) return;
    if (failure != null) {
      AppToast.failure("Couldn't start the whisper", failure);
      return;
    }
    final user = ref.read(currentUserProvider);
    _refresh();
    openWhisperRoom(
      context,
      WhisperRoomArgs(
        whisperId: whisper.id,
        title: whisper.title,
        hostName: user?.displayName ?? '',
        hostAvatarUrl: user?.profilePicture,
        isHost: true,
      ),
    ).then((_) {
      if (mounted) _refresh();
    });
  }

  bool _matches(LiveWhisper whisper) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        whisper.title.toLowerCase().contains(q) ||
        whisper.hostDisplayName.toLowerCase().contains(q) ||
        whisper.hostUsername.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final live = ref.watch(whispersNotifierProvider);
    final mine = ref.watch(myWhispersNotifierProvider).whispers;
    final myId = ref.watch(currentUserProvider)?.id;
    final rooms = live.whispers.where(_matches).toList();
    final upcoming =
        mine
            .where(
              (w) =>
                  w.status == WhisperStatus.scheduled ||
                  w.status == WhisperStatus.draft,
            )
            .toList()
          ..sort(
            (a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(
              b.scheduledAt ?? DateTime(9999),
            ),
          );
    final past = mine.where((w) => w.status == WhisperStatus.ended).toList()
      ..sort(
        (a, b) =>
            (b.endedAt ?? DateTime(0)).compareTo(a.endedAt ?? DateTime(0)),
      );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Whispers',
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
      ),
      body: live.status == WhispersStatus.loading && live.whispers.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textred,
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              color: AppTheme.textred,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 160),
                children: [
                  _SearchBar(onChanged: (q) => setState(() => _query = q)),
                  const SizedBox(height: 14),
                  if (upcoming.isNotEmpty)
                    _UpcomingSection(whispers: upcoming, onStart: _startMine),
                  if (rooms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: live.status == WhispersStatus.error
                          ? _LoadError(
                              message: live.errorMessage,
                              onRetry: _refresh,
                            )
                          : _EmptyWhispers(
                              searching: _query.trim().isNotEmpty,
                              onStart: _openCreate,
                            ),
                    )
                  else
                    for (final room in rooms)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WhisperCard(
                          room: room,
                          isOwner: room.hostId == myId,
                          onJoin: () => _openLive(room),
                        ),
                      ),
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _PastSection(whispers: past),
                  ],
                ],
              ),
            ),
      floatingActionButton: _MicFab(onTap: _openCreate),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.35);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
          hintText: 'Search for Whispers',
          hintStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.55),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _WhisperCard extends StatelessWidget {
  const _WhisperCard({
    required this.room,
    required this.isOwner,
    required this.onJoin,
  });

  final LiveWhisper room;
  final bool isOwner;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LivePill(),
          const SizedBox(height: 8),
          Text(
            room.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Avatar(imageUrl: room.hostProfilePicture, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            room.hostDisplayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (room.hostIsVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppTheme.textred,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (room.hostUsername.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              '@${room.hostUsername}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.circle, size: 8, color: muted),
                          const SizedBox(width: 5),
                        ],
                        const Text(
                          'Host',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.setinggray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatListeners(room.listenerCount),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: muted,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textred,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isOwner ? 'Resume Whisper' : 'Join whisper',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isOwner)
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  else
                    const _WaveIcon(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkPinkBg2 : AppTheme.pinkbg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.textred, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.textred,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Live',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.textred,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveIcon extends StatelessWidget {
  const _WaveIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _WaveBar(4),
          _WaveBar(9),
          _WaveBar(6),
          _WaveBar(11),
          _WaveBar(7),
        ],
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar(this.height);

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: 2.2,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

class _UpcomingSection extends StatefulWidget {
  const _UpcomingSection({required this.whispers, required this.onStart});

  final List<MyWhisper> whispers;
  final Future<void> Function(MyWhisper) onStart;

  @override
  State<_UpcomingSection> createState() => _UpcomingSectionState();
}

class _UpcomingSectionState extends State<_UpcomingSection> {
  String? _startingId;

  Future<void> _start(MyWhisper whisper) async {
    setState(() => _startingId = whisper.id);
    await widget.onStart(whisper);
    if (mounted) setState(() => _startingId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Your upcoming whispers'),
          const SizedBox(height: 8),
          for (final whisper in widget.whispers)
            _SectionCard(
              title: whisper.title,
              subtitle: switch (whisper.scheduledAt) {
                final at? => _whenFormat.format(at),
                null => 'Draft',
              },
              trailing: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _startingId == null ? () => _start(whisper) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textred,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.textred.withValues(
                      alpha: .6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _startingId == whisper.id
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Start',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PastSection extends StatelessWidget {
  const _PastSection({required this.whispers});

  final List<MyWhisper> whispers;

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return 'under a minute';
    if (d.inHours < 1) return '${d.inMinutes} min';
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} hr' : '${d.inHours} hr $m min';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your past whispers'),
        const SizedBox(height: 8),
        for (final whisper in whispers)
          _SectionCard(
            title: whisper.title,
            subtitle: [
              switch (whisper.endedAt) {
                final at? => _whenFormat.format(at),
                null => 'Ended',
              },
              if (whisper.duration case final d?) _formatDuration(d),
            ].join(' · '),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          if (trailing case final trailing?) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }
}

class _EmptyWhispers extends StatelessWidget {
  const _EmptyWhispers({required this.searching, required this.onStart});

  final bool searching;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          Icons.mic_none_rounded,
          size: 56,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 12),
        Text(
          searching
              ? 'No whispers match your search'
              : 'No live whispers right now',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Start one and let people hop in to listen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.mic, size: 18, color: Colors.white),
            label: const Text(
              'Start a whisper',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.textred,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          message ?? 'Live whispers could not be loaded.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

class _MicFab extends StatelessWidget {
  const _MicFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New whisper',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.textred,
            boxShadow: [
              BoxShadow(
                color: AppTheme.textred.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
