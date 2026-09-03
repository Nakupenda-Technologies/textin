import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../repository/texting_repository.dart';
import 'secret_box_state.dart';

class SecretBoxCubit extends Cubit<SecretBoxState> {
  SecretBoxCubit({
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
    emit(state.copyWith(hasPin: hasPin));
  }

  Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    if (storedPin == enteredPin) {
      emit(state.copyWith(status: SecretBoxStatus.unlocked, errorMessage: null));
      await loadSecretChats();
      return true;
    } else {
      emit(state.copyWith(errorMessage: 'Incorrect PIN. Try again.'));
      return false;
    }
  }

  Future<void> setPin(String newPin) async {
    await _secureStorage.write(key: _pinKey, value: newPin);
    emit(state.copyWith(hasPin: true, status: SecretBoxStatus.unlocked));
    await loadSecretChats();
  }

  Future<void> loadSecretChats() async {
    final result = await repository.fetchSecretChats(myUserId: myUserId);
    result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      (chats) {
        emit(state.copyWith(secretConversations: chats));
      },
    );
  }

  void lock() {
    emit(state.copyWith(status: SecretBoxStatus.locked));
  }
}
