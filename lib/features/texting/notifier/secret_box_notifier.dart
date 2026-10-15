import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repository/texting_repository.dart';
import 'inbox_notifier.dart';
import 'secret_box_state.dart';

export 'secret_box_state.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secretBoxNotifierProvider =
    StateNotifierProvider.autoDispose<SecretBoxNotifier, SecretBoxState>((ref) {
  final repository = ref.watch(textingRepositoryProvider);
  final myUserId = ref.watch(myUserIdProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return SecretBoxNotifier(
    repository: repository,
    myUserId: myUserId,
    secureStorage: secureStorage,
  );
});

class SecretBoxNotifier extends StateNotifier<SecretBoxState> {
  SecretBoxNotifier({
    required this.repository,
    required this.myUserId,
    FlutterSecureStorage? secureStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(const SecretBoxState()) {
    checkPinStatus();
  }

  final TextingRepository repository;
  final String myUserId;
  final FlutterSecureStorage _secureStorage;
  static const String _pinKey = 'secret_box_pin';

  Future<void> checkPinStatus() async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    final hasPin = storedPin != null && storedPin.isNotEmpty;
    state = state.copyWith(hasPin: hasPin);
  }

  Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    if (storedPin == enteredPin) {
      state = state.copyWith(status: SecretBoxStatus.unlocked, errorMessage: null);
      await loadSecretChats();
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Incorrect PIN. Try again.');
      return false;
    }
  }

  Future<void> setPin(String newPin) async {
    await _secureStorage.write(key: _pinKey, value: newPin);
    state = state.copyWith(hasPin: true, status: SecretBoxStatus.unlocked);
    await loadSecretChats();
  }

  Future<void> loadSecretChats() async {
    final result = await repository.fetchSecretChats(myUserId: myUserId);
    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
      (chats) {
        state = state.copyWith(secretConversations: chats);
      },
    );
  }

  void lock() {
    state = state.copyWith(status: SecretBoxStatus.locked);
  }
}
