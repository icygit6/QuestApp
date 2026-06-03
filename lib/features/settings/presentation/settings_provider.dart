import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.watch(sharedPreferencesProvider))..load(),
);

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.notificationsEnabled,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;

  SettingsState copyWith({ThemeMode? themeMode, bool? notificationsEnabled}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._preferences)
    : super(
        const SettingsState(
          themeMode: ThemeMode.dark,
          notificationsEnabled: true,
        ),
      );

  static const _themeModeKey = 'theme_mode';
  static const _notificationsKey = 'notifications_enabled';

  final SharedPreferences _preferences;

  /// Loads local settings from SharedPreferences.
  void load() {
    final theme = _preferences.getString(_themeModeKey) ?? 'dark';
    state = state.copyWith(
      themeMode: theme == 'light' ? ThemeMode.light : ThemeMode.dark,
      notificationsEnabled: _preferences.getBool(_notificationsKey) ?? true,
    );
  }

  /// Toggles dark and light theme mode.
  Future<void> setDarkMode(bool enabled) async {
    final theme = enabled ? ThemeMode.dark : ThemeMode.light;
    await _preferences.setString(_themeModeKey, enabled ? 'dark' : 'light');
    state = state.copyWith(themeMode: theme);
  }

  /// Toggles local notification preference.
  Future<void> setNotifications(bool enabled) async {
    await _preferences.setBool(_notificationsKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}
