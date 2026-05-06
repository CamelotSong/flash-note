import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/app_database.dart';

part 'theme_provider.g.dart';

// ignore: non_constant_identifier_names
@riverpod
class ThemeMode_ extends _$ThemeMode_ {
  @override
  ThemeMode build() => ThemeMode.dark;

  Future<void> load(AppDatabase db) async {
    final val = await db.getSetting('theme_mode') ?? 'dark';
    state = _fromString(val);
  }

  Future<void> setMode(AppDatabase db, String mode) async {
    await db.setSetting('theme_mode', mode);
    state = _fromString(mode);
  }

  ThemeMode _fromString(String s) {
    if (s == 'light') return ThemeMode.light;
    if (s == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }
}
