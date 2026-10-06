import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/progress/domain/player_progress_state.dart';

abstract class ProgressRepository {
  Future<PlayerProgressState> loadProgress();
  Future<void> saveProgress(PlayerProgressState progress);
  Future<void> resetProgress();
  Future<void> saveSession(Map<String, dynamic> sessionJson);
  Future<Map<String, dynamic>?> loadSession();
  Future<void> clearSession();
}

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _progressKey = 'flow_dots_progress_v1';
  static const _sessionKey = 'flow_dots_session_v1';

  @override
  Future<PlayerProgressState> loadProgress() async {
    final raw = _prefs.getString(_progressKey);
    if (raw == null || raw.isEmpty) {
      return const PlayerProgressState();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProgressState.fromJson(json);
    } catch (_) {
      return const PlayerProgressState();
    }
  }

  @override
  Future<void> saveProgress(PlayerProgressState progress) async {
    await _prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  @override
  Future<void> resetProgress() async {
    await _prefs.remove(_progressKey);
    await clearSession();
  }

  @override
  Future<void> saveSession(Map<String, dynamic> sessionJson) async {
    await _prefs.setString(_sessionKey, jsonEncode(sessionJson));
  }

  @override
  Future<Map<String, dynamic>?> loadSession() async {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }
}

abstract class SettingsRepository {
  Future<Map<String, dynamic>> loadSettingsJson();
  Future<void> saveSettingsJson(Map<String, dynamic> json);
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'flow_dots_settings_v1';

  @override
  Future<Map<String, dynamic>> loadSettingsJson() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveSettingsJson(Map<String, dynamic> json) async {
    await _prefs.setString(_key, jsonEncode(json));
  }
}

