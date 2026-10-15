import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum MessagePermission {
  everyone('everyone', 'Everyone'),
  following('following', 'Following');

  const MessagePermission(this.value, this.label);

  final String value;
  final String label;

  static MessagePermission fromValue(Object? value) => values.firstWhere(
    (p) => p.value == value,
    orElse: () => MessagePermission.everyone,
  );
}

enum AppThemePreference {
  system('system', 'System', ThemeMode.system),
  light('light', 'Light', ThemeMode.light),
  dark('dark', 'Dark', ThemeMode.dark);

  const AppThemePreference(this.value, this.label, this.mode);

  final String value;
  final String label;
  final ThemeMode mode;

  static AppThemePreference fromValue(Object? value) => values.firstWhere(
    (t) => t.value == value,
    orElse: () => AppThemePreference.system,
  );
}

const supportedLanguages = {
  'en-US': 'English (US)',
  'fr-FR': 'Français',
  'sw-KE': 'Kiswahili',
};

class UserSettings extends Equatable {
  const UserSettings({
    this.whoCanMessageMe = MessagePermission.everyone,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.whisperNotifications = true,
    this.allowWhisperInvites = true,
    this.allowSpeakerRequests = true,
    this.theme = AppThemePreference.system,
    this.language = 'en-US',
  });

  factory UserSettings.fromResponse(Object? response) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    final settings = data is Map<String, dynamic> ? data['settings'] : null;
    if (settings is! Map<String, dynamic>) return const UserSettings();

    Map<String, dynamic> section(String key) =>
        settings[key] is Map<String, dynamic>
        ? settings[key] as Map<String, dynamic>
        : const {};
    final privacy = section('privacy');
    final notification = section('notification');
    final preferences = section('preferences');
    final more = section('more');

    return UserSettings(
      whoCanMessageMe: MessagePermission.fromValue(privacy['whoCanMessageMe']),
      pushNotifications: notification['pushNotifications'] as bool? ?? true,
      emailNotifications: notification['emailNotifications'] as bool? ?? true,
      whisperNotifications:
          notification['whisperNotifications'] as bool? ?? true,
      allowWhisperInvites: more['allowWhisperInvites'] as bool? ?? true,
      allowSpeakerRequests: more['allowSpeakerRequests'] as bool? ?? true,
      theme: AppThemePreference.fromValue(preferences['theme']),
      language: preferences['language'] as String? ?? 'en-US',
    );
  }

  final MessagePermission whoCanMessageMe;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool whisperNotifications;
  final bool allowWhisperInvites;
  final bool allowSpeakerRequests;
  final AppThemePreference theme;
  final String language;

  UserSettings copyWith({
    MessagePermission? whoCanMessageMe,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? whisperNotifications,
    bool? allowWhisperInvites,
    bool? allowSpeakerRequests,
    AppThemePreference? theme,
    String? language,
  }) => UserSettings(
    whoCanMessageMe: whoCanMessageMe ?? this.whoCanMessageMe,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    emailNotifications: emailNotifications ?? this.emailNotifications,
    whisperNotifications: whisperNotifications ?? this.whisperNotifications,
    allowWhisperInvites: allowWhisperInvites ?? this.allowWhisperInvites,
    allowSpeakerRequests: allowSpeakerRequests ?? this.allowSpeakerRequests,
    theme: theme ?? this.theme,
    language: language ?? this.language,
  );

  Map<String, dynamic> toJson() => {
    'privacy': {'whoCanMessageMe': whoCanMessageMe.value},
    'notification': {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'whisperNotifications': whisperNotifications,
    },
    'preferences': {'theme': theme.value, 'language': language},
    'more': {
      'allowWhisperInvites': allowWhisperInvites,
      'allowSpeakerRequests': allowSpeakerRequests,
    },
  };

  @override
  List<Object?> get props => [
    whoCanMessageMe,
    pushNotifications,
    emailNotifications,
    whisperNotifications,
    allowWhisperInvites,
    allowSpeakerRequests,
    theme,
    language,
  ];
}
