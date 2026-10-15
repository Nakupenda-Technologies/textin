import 'package:equatable/equatable.dart';
import 'conversation.dart';

enum BubbleStyle { soft, minimal, smooth, classy }

class ChatCustomization extends Equatable {
  const ChatCustomization({
    this.mood = ConversationTag.romantic,
    this.bubbleStyle = BubbleStyle.soft,
    this.auraGlow = 0.4,
  });

  factory ChatCustomization.fromJson(Map<String, dynamic> json) {
    final glow = (json['auraGlow'] as num?)?.toDouble();
    return ChatCustomization(
      mood: ConversationTag.values.asNameMap()[json['mood']] ??
          ConversationTag.romantic,
      bubbleStyle: BubbleStyle.values.asNameMap()[json['bubbleStyle']] ??
          BubbleStyle.soft,
      auraGlow: glow == null ? 0.4 : (glow / 100).clamp(0.0, 1.0),
    );
  }

  final ConversationTag mood;
  final BubbleStyle bubbleStyle;
  final double auraGlow;

  Map<String, dynamic> toJson() => {
    'mood': mood.name,
    'bubbleStyle': bubbleStyle.name,
    'auraGlow': (auraGlow * 100).round(),
  };

  ChatCustomization copyWith({
    ConversationTag? mood,
    BubbleStyle? bubbleStyle,
    double? auraGlow,
  }) {
    return ChatCustomization(
      mood: mood ?? this.mood,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      auraGlow: auraGlow ?? this.auraGlow,
    );
  }

  @override
  List<Object?> get props => [mood, bubbleStyle, auraGlow];
}
