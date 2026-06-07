import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

const _kThemeKey = 'app_theme_mode';

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeKey);
    if (stored != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  Future<void> set(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) => ThemeNotifier());

/// Converts AppThemeMode → Flutter ThemeMode for MaterialApp.
extension AppThemeModeX on AppThemeMode {
  ThemeMode get flutterMode => switch (this) {
        AppThemeMode.light  => ThemeMode.light,
        AppThemeMode.dark   => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  String get label => switch (this) {
        AppThemeMode.light  => 'Light',
        AppThemeMode.dark   => 'Dark',
        AppThemeMode.system => 'System Default',
      };

  IconData get icon => switch (this) {
        AppThemeMode.light  => Icons.light_mode_outlined,
        AppThemeMode.dark   => Icons.dark_mode_outlined,
        AppThemeMode.system => Icons.brightness_auto_outlined,
      };
}