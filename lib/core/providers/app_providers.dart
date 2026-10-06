import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_service.dart';
import '../audio/audio_manager.dart';
import '../services/haptics_manager.dart';
import '../storage/local_repositories.dart';
import '../../features/gameplay/data/level_repository.dart';
import '../../features/settings/domain/settings_state.dart';
import '../../features/progress/domain/player_progress_state.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider at startup');
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return LocalProgressRepository(ref.watch(sharedPreferencesProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository(ref.watch(sharedPreferencesProvider));
});

final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  return LocalLevelRepository();
});

final audioManagerProvider = Provider<AudioManager>((ref) {
  return NoOpAudioManager();
});

final hapticsManagerProvider = Provider<HapticsManager>((ref) {
  return SystemHapticsManager();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return NoOpAnalyticsService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return NoOpAdService();
});

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future.microtask(_load);
    return const SettingsState();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    final json = await repo.loadSettingsJson();
    if (json.isEmpty) return;
    state = SettingsState.fromJson(json);
    ref.read(audioManagerProvider).setSoundEnabled(state.soundEnabled);
    ref.read(audioManagerProvider).setMusicEnabled(state.musicEnabled);
    ref.read(hapticsManagerProvider).setEnabled(state.hapticsEnabled);
  }

  Future<void> _persist() async {
    await ref.read(settingsRepositoryProvider).saveSettingsJson(state.toJson());
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await ref.read(audioManagerProvider).setSoundEnabled(value);
    await _persist();
  }

  Future<void> setMusicEnabled(bool value) async {
    state = state.copyWith(musicEnabled: value);
    await ref.read(audioManagerProvider).setMusicEnabled(value);
    await _persist();
  }

  Future<void> setHapticsEnabled(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    ref.read(hapticsManagerProvider).setEnabled(value);
    await _persist();
  }

  Future<void> setColorAssist(bool value) async {
    state = state.copyWith(colorAssist: value);
    await _persist();
  }

  Future<void> setThemeMode(ThemeModePreference value) async {
    state = state.copyWith(themeMode: value);
    await _persist();
  }

  Future<void> setAnimations(AnimationPreference value) async {
    state = state.copyWith(animations: value);
    await _persist();
  }

  Future<void> markHowToPlaySeen() async {
    state = state.copyWith(howToPlaySeen: true);
    await _persist();
  }
}

final progressControllerProvider =
    AsyncNotifierProvider<ProgressController, PlayerProgressState>(
  ProgressController.new,
);

class ProgressController extends AsyncNotifier<PlayerProgressState> {
  @override
  Future<PlayerProgressState> build() async {
    return ref.read(progressRepositoryProvider).loadProgress();
  }

  Future<void> _save(PlayerProgressState next) async {
    state = AsyncData(next);
    await ref.read(progressRepositoryProvider).saveProgress(next);
  }

  Future<void> applyLevelResult({
    required int levelId,
    required int stars,
    required int score,
    required int moves,
    required double timeSeconds,
    required int coinsEarned,
    required bool wasPerfect,
    required int bonusCollected,
    required int totalLevels,
  }) async {
    final current = state.value ?? const PlayerProgressState();
    final existing = current.levels[levelId];
    final bestStars =
        existing == null ? stars : (stars > existing.stars ? stars : existing.stars);
    final bestScore = existing == null
        ? score
        : (score > existing.bestScore ? score : existing.bestScore);
    final bestMoves = existing?.bestMoves == null
        ? moves
        : (moves < existing!.bestMoves! ? moves : existing.bestMoves);
    final bestTime = existing?.bestTime == null
        ? timeSeconds
        : (timeSeconds < existing!.bestTime! ? timeSeconds : existing.bestTime);

    final updatedLevels = Map<int, LevelProgressEntry>.from(current.levels);
    updatedLevels[levelId] = LevelProgressEntry(
      completed: true,
      stars: bestStars,
      bestScore: bestScore,
      bestMoves: bestMoves,
      bestTime: bestTime,
    );

    final nextUnlocked = (levelId + 1).clamp(1, totalLevels + 1);
    final highest = current.highestUnlockedLevel > nextUnlocked
        ? current.highestUnlockedLevel
        : nextUnlocked.clamp(1, totalLevels);

    await _save(
      current.copyWith(
        levels: updatedLevels,
        coins: current.coins + coinsEarned,
        highestUnlockedLevel: highest,
        perfectCompletions:
            current.perfectCompletions + (wasPerfect ? 1 : 0),
        totalBonusNodesCollected:
            current.totalBonusNodesCollected + bonusCollected,
      ),
    );
  }

  Future<void> spendHint() async {
    final current = state.value ?? const PlayerProgressState();
    if (current.hints <= 0) return;
    await _save(current.copyWith(hints: current.hints - 1));
  }

  Future<void> addHints(int count) async {
    final current = state.value ?? const PlayerProgressState();
    await _save(current.copyWith(hints: current.hints + count));
  }

  Future<void> addCoins(int count) async {
    final current = state.value ?? const PlayerProgressState();
    await _save(current.copyWith(coins: current.coins + count));
  }

  Future<void> unlockAllLevels(int total) async {
    final current = state.value ?? const PlayerProgressState();
    await _save(current.copyWith(highestUnlockedLevel: total));
  }

  Future<void> resetProgress() async {
    await ref.read(progressRepositoryProvider).resetProgress();
    state = const AsyncData(PlayerProgressState());
  }
}
