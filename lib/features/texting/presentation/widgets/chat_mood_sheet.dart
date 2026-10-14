import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/chat_customization.dart';
import '../../models/conversation.dart';
import 'mood_palette.dart';

class ChatMoodSheet extends StatefulWidget {
  const ChatMoodSheet({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final ChatCustomization initial;
  final ValueChanged<ChatCustomization> onChanged;

  static Future<void> show(
    BuildContext context, {
    required ChatCustomization initial,
    required ValueChanged<ChatCustomization> onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChatMoodSheet(initial: initial, onChanged: onChanged),
    );
  }

  @override
  State<ChatMoodSheet> createState() => _ChatMoodSheetState();
}

class _ChatMoodSheetState extends State<ChatMoodSheet> {
  late ChatCustomization _value = widget.initial;

  void _update(ChatCustomization value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grayBg,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Mood?',
            children: [
              for (final mood in _moods)
                _MoodOption(
                  mood: mood,
                  selected: _value.mood == mood.tag,
                  onTap: () => _update(_value.copyWith(mood: mood.tag)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Bubble Style',
            children: [
              for (final style in BubbleStyle.values)
                _BubbleStyleOption(
                  style: style,
                  selected: _value.bubbleStyle == style,
                  onTap: () => _update(_value.copyWith(bubbleStyle: style)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Aura Glow',
            children: [
              _AuraGlowSlider(
                value: _value.auraGlow,
                onChanged: (glow) => setState(
                  () => _value = _value.copyWith(auraGlow: glow),
                ),
                onChangeEnd: (glow) => _update(_value.copyWith(auraGlow: glow)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodData {
  const _MoodData(this.tag, this.label, this.icon, this.tile);

  final ConversationTag tag;
  final String label;
  final Widget icon;
  final Color tile;
}

final _moods = [
  _MoodData(
    ConversationTag.romantic,
    'Romantic',
    SvgPicture.asset('assets/svgs/love_icon.svg', width: 14, height: 14),
    AppTheme.textingSentBubble,
  ),
  const _MoodData(
    ConversationTag.excited,
    'Excited',
    Text('😁', style: TextStyle(fontSize: 13)),
    AppTheme.textingTagExcitedBg,
  ),
  const _MoodData(
    ConversationTag.chill,
    'Chill',
    Icon(Icons.blur_circular, size: 16, color: AppTheme.textingTagChillSentBorder),
    AppTheme.textingTagChillBg,
  ),
  _MoodData(
    ConversationTag.professional,
    'Professional',
    SvgPicture.asset('assets/svgs/tie_icon.svg', width: 14, height: 14),
    AppTheme.textingTagProfessionalBg,
  ),
];

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.selected,
    required this.onTap,
    required this.child,
    this.tint,
  });

  final bool selected;
  final VoidCallback onTap;
  final Color? tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppTheme.darkSurface2 : AppTheme.surface2;
    final tint = this.tint;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppTheme.textingSentBubble
                : (isDark ? AppTheme.darkBorder : AppTheme.grayBg),
          ),
          color: tint == null ? base : null,
          gradient: tint == null
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    base,
                    tint.withValues(alpha: selected ? 0.25 : 0.12),
                  ],
                ),
        ),
        child: child,
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final _MoodData mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OptionCard(
      selected: selected,
      onTap: onTap,
      tint: mood.tile,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: mood.tile,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: mood.icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mood.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? AppTheme.textingSentBubble
                  : AppTheme.divider2,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BubbleStyleOption extends StatelessWidget {
  const _BubbleStyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final BubbleStyle style;
  final bool selected;
  final VoidCallback onTap;

  static const _moodFor = {
    BubbleStyle.soft: ConversationTag.romantic,
    BubbleStyle.minimal: ConversationTag.professional,
    BubbleStyle.smooth: ConversationTag.chill,
    BubbleStyle.classy: ConversationTag.excited,
  };

  @override
  Widget build(BuildContext context) {
    final palette = MoodPalette.of(_moodFor[style]!);
    final label = style.name[0].toUpperCase() + style.name.substring(1);

    return _OptionCard(
      selected: selected,
      onTap: onTap,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: style == BubbleStyle.soft
                ? palette.receivedBg
                : palette.sentBg,
            borderRadius: bubbleRadius(style, isMe: true),
            border: Border.all(
              width: 0.5,
              color: style == BubbleStyle.soft
                  ? palette.receivedBorder
                  : palette.sentBorder ?? palette.sentBg,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: style == BubbleStyle.soft
                  ? palette.receivedFg
                  : palette.sentFg,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuraGlowSlider extends StatelessWidget {
  const _AuraGlowSlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 12, color: AppTheme.iconColor);

    return Column(
      children: [
        Row(
          children: [
            const Text('0%', style: labelStyle),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: AppTheme.red,
                  inactiveTrackColor: AppTheme.grayBg,
                  thumbColor: Colors.white,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.title,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SUBTLE', style: labelStyle),
            Text('INTENSE', style: labelStyle),
          ],
        ),
      ],
    );
  }
}
