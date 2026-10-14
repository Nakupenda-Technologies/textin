import 'dart:convert';

import '../../../core/storage/shared_preferences_store.dart';
import '../models/chat_customization.dart';

class ChatCustomizationStore {
  ChatCustomizationStore._();

  static const String _prefix = 'chat_customization_';

  static ChatCustomization? read(String chatId) {
    final raw = SharedPreferencesStore.getString('$_prefix$chatId');
    if (raw == null) return null;
    return ChatCustomization.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> save(String chatId, ChatCustomization customization) {
    return SharedPreferencesStore.setString(
      '$_prefix$chatId',
      jsonEncode(customization.toJson()),
    );
  }
}
