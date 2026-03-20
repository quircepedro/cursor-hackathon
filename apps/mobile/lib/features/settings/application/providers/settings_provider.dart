import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  const SettingsState({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
  });

  final bool notificationsEnabled;
  final bool darkModeEnabled;

  SettingsState copyWith({bool? notificationsEnabled, bool? darkModeEnabled}) => SettingsState(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(darkModeEnabled: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
