import '../core/storage/shared_preferences_store.dart';

class LocalStorageService {
  LocalStorageService._();

  static Future<void> init() async {
    await SharedPreferencesStore.init();
  }
}
