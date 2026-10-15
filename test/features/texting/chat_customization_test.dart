import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/storage/shared_preferences_store.dart';
import 'package:textin/features/texting/models/chat_customization.dart';
import 'package:textin/features/texting/models/conversation.dart';
import 'package:textin/features/texting/services/chat_customization_store.dart';

void main() {
  const chill = ChatCustomization(
    mood: ConversationTag.chill,
    bubbleStyle: BubbleStyle.smooth,
    auraGlow: 0.75,
  );

  test('round trips through json with aura glow as a percentage', () {
    expect(chill.toJson(), {
      'mood': 'chill',
      'bubbleStyle': 'smooth',
      'auraGlow': 75,
    });
    expect(ChatCustomization.fromJson(chill.toJson()), chill);
  });

  test('unknown or missing values fall back to the romantic defaults', () {
    expect(
      ChatCustomization.fromJson({'mood': 'grumpy'}),
      const ChatCustomization(),
    );
  });

  test('the store keeps a customization per chat', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesStore.init();

    expect(ChatCustomizationStore.read('chat_1'), isNull);

    await ChatCustomizationStore.save('chat_1', chill);

    expect(ChatCustomizationStore.read('chat_1'), chill);
    expect(ChatCustomizationStore.read('chat_2'), isNull);
  });
}
