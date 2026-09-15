import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../library/repositories/metadata_store.dart';

class AppearanceSettings extends Equatable {
  const AppearanceSettings({
    this.themeMode = ThemeMode.light,
    this.reduceMotion = false,
  });
  final ThemeMode themeMode;
  final bool reduceMotion;
  AppearanceSettings copyWith({ThemeMode? themeMode, bool? reduceMotion}) =>
      AppearanceSettings(
        themeMode: themeMode ?? this.themeMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );
  @override
  List<Object?> get props => [themeMode, reduceMotion];
}

class SettingsRepository {
  const SettingsRepository(this.store);
  final MetadataStore store;
  static const key = 'yank.demo.appearance.v1';
  Future<AppearanceSettings> load() async {
    final value = await store.read(key);
    if (value == null) {
      return const AppearanceSettings();
    }
    final json = jsonDecode(value) as Map<String, dynamic>;
    return AppearanceSettings(
      themeMode: ThemeMode.values.byName(json['theme'] as String),
      reduceMotion: json['reduceMotion'] as bool,
    );
  }

  Future<void> save(AppearanceSettings value) => store.write(
    key,
    jsonEncode({
      'theme': value.themeMode.name,
      'reduceMotion': value.reduceMotion,
    }),
  );
}
