import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/transfers/domain/transfer.dart';

/// Link Vault (PRD §6.11). Private by default — saving an item never publishes
/// it, and nothing here has a public-facing surface.
class VaultController extends Notifier<List<VaultItem>> {
  @override
  List<VaultItem> build() => const [];

  void add(VaultItem item) => state = [item, ...state];

  void update(VaultItem item) =>
      state = [for (final e in state) if (e.id == item.id) item else e];

  void remove(String id) => state = state.where((e) => e.id != id).toList();

  void clear() => state = const [];
}

final vaultProvider =
    NotifierProvider<VaultController, List<VaultItem>>(VaultController.new);

/// Theme preference (PRD §6.13). `null` means follow the system.
class ThemeController extends Notifier<ThemeMode> {
  static const _key = 'linksy.theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_key)) {
        case 'light':
          state = ThemeMode.light;
        case 'dark':
          state = ThemeMode.dark;
      }
    } catch (_) {
      // Storage unavailable (e.g. first run on web) — keep the system default.
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Non-fatal: the in-memory choice still applies for this session.
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

/// Which notification categories the user has opted into (PRD §6.12).
class NotificationPrefs {
  const NotificationPrefs({
    this.uploadComplete = true,
    this.uploadFailed = true,
    this.shareExpiring = true,
    this.shareCreated = true,
    this.showSensitivePreviews = false,
  });

  final bool uploadComplete;
  final bool uploadFailed;
  final bool shareExpiring;
  final bool shareCreated;

  /// PRD §6.12 — filenames must not reach a lock screen unless explicitly
  /// enabled. Defaults to off.
  final bool showSensitivePreviews;

  NotificationPrefs copyWith({
    bool? uploadComplete,
    bool? uploadFailed,
    bool? shareExpiring,
    bool? shareCreated,
    bool? showSensitivePreviews,
  }) =>
      NotificationPrefs(
        uploadComplete: uploadComplete ?? this.uploadComplete,
        uploadFailed: uploadFailed ?? this.uploadFailed,
        shareExpiring: shareExpiring ?? this.shareExpiring,
        shareCreated: shareCreated ?? this.shareCreated,
        showSensitivePreviews: showSensitivePreviews ?? this.showSensitivePreviews,
      );
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefs>(
  NotificationPrefsController.new,
);

class NotificationPrefsController extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() => const NotificationPrefs();

  void toggle(String key, bool value) {
    switch (key) {
      case 'uploadComplete':
        state = state.copyWith(uploadComplete: value);
      case 'uploadFailed':
        state = state.copyWith(uploadFailed: value);
      case 'shareExpiring':
        state = state.copyWith(shareExpiring: value);
      case 'shareCreated':
        state = state.copyWith(shareCreated: value);
      case 'previews':
        state = state.copyWith(showSensitivePreviews: value);
    }
  }
}