import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/chat_customization.dart';
import '../../models/conversation.dart';

class MoodPalette {
  const MoodPalette({
    required this.sentBg,
    required this.sentFg,
    required this.receivedBg,
    required this.receivedBorder,
    required this.receivedFg,
    required this.accent,
    this.sentBorder,
  });

  factory MoodPalette.of(ConversationTag mood) {
    switch (mood) {
      case ConversationTag.excited:
        return const MoodPalette(
          sentBg: AppTheme.textingTagExcitedBg,
          sentFg: AppTheme.textingTagExcitedFg,
          receivedBg: AppTheme.textingTagExcitedReceivedBg,
          receivedBorder: Colors.transparent,
          receivedFg: AppTheme.textingTagExcitedFg,
          accent: AppTheme.textingActiveRedBorder,
        );
      case ConversationTag.chill:
        return const MoodPalette(
          sentBg: AppTheme.textingTagChillBg,
          sentBorder: AppTheme.textingTagChillSentBorder,
          sentFg: AppTheme.textingTagChillFg,
          receivedBg: AppTheme.textingTagChillReceivedBg,
          receivedBorder: AppTheme.textingTagChillReceivedBorder,
          receivedFg: AppTheme.textingTagChillFg,
          accent: AppTheme.textingTagChillSentBorder,
        );
      case ConversationTag.professional:
        return const MoodPalette(
          sentBg: AppTheme.textingTagProfessionalBg,
          sentFg: AppTheme.textingTagProfessionalFg,
          receivedBg: AppTheme.surface,
          receivedBorder: AppTheme.textingTagProfessionalReceivedBorder,
          receivedFg: AppTheme.subtitle,
          accent: AppTheme.textingSendBtn,
        );
      case ConversationTag.romantic:
      case ConversationTag.none:
        return const MoodPalette(
          sentBg: AppTheme.textingSentBubble,
          sentFg: Colors.white,
          receivedBg: AppTheme.textingReceivedBubble,
          receivedBorder: AppTheme.pinkborder,
          receivedFg: AppTheme.textingReceivedText,
          accent: AppTheme.textingSentBubble,
        );
    }
  }

  final Color sentBg;
  final Color? sentBorder;
  final Color sentFg;
  final Color receivedBg;
  final Color receivedBorder;
  final Color receivedFg;
  final Color accent;
}

BorderRadius bubbleRadius(BubbleStyle style, {required bool isMe}) {
  final (corner, tail) = switch (style) {
    BubbleStyle.soft => (24.0, 4.0),
    BubbleStyle.minimal => (6.0, 6.0),
    BubbleStyle.smooth => (16.0, 4.0),
    BubbleStyle.classy => (14.0, 2.0),
  };
  return BorderRadius.only(
    topLeft: Radius.circular(corner),
    topRight: Radius.circular(corner),
    bottomLeft: Radius.circular(isMe ? corner : tail),
    bottomRight: Radius.circular(isMe ? tail : corner),
  );
}
