import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ThemeModePreference { system, light, dark }

enum AnimationPreference { full, reduced }

class SettingsState extends Equatable {
  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.colorAssist = false,
    this.themeMode = ThemeModePreference.system,
    this.animations = AnimationPreference.full,
    this.howToPlaySeen = false,
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final bool colorAssist;
  final ThemeModePreference themeMode;
  final AnimationPreference animations;
  final bool howToPlaySeen;

  bool get reducedMotion => animations == AnimationPreference.reduced;

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case ThemeModePreference.system:
        return ThemeMode.system;
      case ThemeModePreference.light:
        return ThemeMode.light;
      case ThemeModePreference.dark:
        return ThemeMode.dark;
    }
  }

  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? colorAssist,
    ThemeModePreference? themeMode,
    AnimationPreference? animations,
    bool? howToPlaySeen,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      colorAssist: colorAssist ?? this.colorAssist,
      themeMode: themeMode ?? this.themeMode,
      animations: animations ?? this.animations,
      howToPlaySeen: howToPlaySeen ?? this.howToPlaySeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'hapticsEnabled': hapticsEnabled,
        'colorAssist': colorAssist,
        'themeMode': themeMode.name,
        'animations': animations.name,
        'howToPlaySeen': howToPlaySeen,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        musicEnabled: json['musicEnabled'] as bool? ?? true,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        colorAssist: json['colorAssist'] as bool? ?? false,
        themeMode: ThemeModePreference.values.byName(
          json['themeMode'] as String? ?? 'system',
        ),
        animations: AnimationPreference.values.byName(
          json['animations'] as String? ?? 'full',
        ),
        howToPlaySeen: json['howToPlaySeen'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        soundEnabled,
        musicEnabled,
        hapticsEnabled,
        colorAssist,
        themeMode,
        animations,
        howToPlaySeen,
      ];
}
