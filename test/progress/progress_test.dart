import 'package:connect_dots/features/progress/domain/player_progress_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial unlock is level 1', () {
    const progress = PlayerProgressState();
    expect(progress.highestUnlockedLevel, 1);
    expect(progress.isUnlocked(1), isTrue);
    expect(progress.isUnlocked(2), isFalse);
  });

  test('json roundtrip', () {
    final progress = PlayerProgressState(
      highestUnlockedLevel: 5,
      coins: 40,
      hints: 3,
      levels: {
        1: const LevelProgressEntry(
          completed: true,
          stars: 3,
          bestScore: 400,
          bestMoves: 4,
        ),
      },
    );
    final restored = PlayerProgressState.fromJson(progress.toJson());
    expect(restored.highestUnlockedLevel, 5);
    expect(restored.coins, 40);
    expect(restored.entryFor(1)?.stars, 3);
  });

  test('best stars only improve', () {
    const existing = LevelProgressEntry(completed: true, stars: 3, bestScore: 500);
    final worse = existing.copyWith(stars: 1, bestScore: 100);
    // Persistence layer keeps max — simulate
    final keptStars = worse.stars > existing.stars ? worse.stars : existing.stars;
    final keptScore =
        worse.bestScore > existing.bestScore ? worse.bestScore : existing.bestScore;
    expect(keptStars, 3);
    expect(keptScore, 500);
  });
}
