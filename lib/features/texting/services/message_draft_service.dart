import '../../../core/storage/shared_preferences_store.dart';

class MessageDraftService {
  MessageDraftService._();

  static const String _prefix = 'draft_msg_';

  static String? getDraft(String chatId) {
    return SharedPreferencesStore.getString('$_prefix$chatId');
  }

  static Future<void> saveDraft(String chatId, String text) async {
    if (text.trim().isEmpty) {
      await clearDraft(chatId);
    } else {
      await SharedPreferencesStore.setString('$_prefix$chatId', text);
    }
  }

  static Future<void> clearDraft(String chatId) async {
    await SharedPreferencesStore.remove('$_prefix$chatId');
  }
}
