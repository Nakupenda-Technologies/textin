import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/locator.dart';
import '../../../core/storage/shared_pref_keys.dart';
import '../../../core/storage/shared_preferences_store.dart';
import '../models/user_settings.dart';
import '../repository/settings_repository.dart';

enum SettingsStatus { loading, loaded, error }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.loading,
    this.settings = const UserSettings(),
    this.errorMessage,
  });

  final SettingsStatus status;
  final UserSettings settings;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, settings, errorMessage];
}

final appThemeProvider = StateProvider<AppThemePreference>(
  (ref) => AppThemePreference.fromValue(
    SharedPreferencesStore.getString(SharedPrefKeys.themeMode),
  ),
);

final settingsNotifierProvider =
    StateNotifierProvider.autoDispose<SettingsNotifier, SettingsState>(
      (ref) => SettingsNotifier(
        locator<SettingsRepository>(),
        onThemeChanged: (theme) {
          ref.read(appThemeProvider.notifier).state = theme;
          SharedPreferencesStore.setString(
            SharedPrefKeys.themeMode,
            theme.value,
          );
        },
      ),
    );

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this.repository, {required this.onThemeChanged})
    : super(const SettingsState());

  final SettingsRepository repository;
  final void Function(AppThemePreference theme) onThemeChanged;

  Future<void> load() async {
    state = SettingsState(settings: state.settings);
    final result = await repository.fetchSettings();
    if (!mounted) return;
    result.fold(
      (failure) => state = SettingsState(
        status: SettingsStatus.error,
        settings: state.settings,
        errorMessage: failure.message,
      ),
      _apply,
    );
  }

  Future<void> update(UserSettings next) async {
    final previous = state.settings;
    _apply(next);
    final result = await repository.updateSettings(next);
    if (!mounted) return;
    result.fold((failure) {
      _apply(previous);
      state = SettingsState(
        status: SettingsStatus.loaded,
        settings: previous,
        errorMessage: failure.message,
      );
    }, _apply);
  }

  void _apply(UserSettings settings) {
    if (settings.theme != state.settings.theme ||
        state.status != SettingsStatus.loaded) {
      onThemeChanged(settings.theme);
    }
    state = SettingsState(status: SettingsStatus.loaded, settings: settings);
  }
}
