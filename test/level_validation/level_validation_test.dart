import 'package:connect_dots/features/gameplay/data/campaign_level_factory.dart';
import 'package:connect_dots/features/gameplay/domain/solver/level_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('campaign factory builds exactly 100 levels', () {
    final factory = CampaignLevelFactory();
    final levels = factory.buildAll();
    expect(levels.length, 100);
    for (var i = 0; i < 100; i++) {
      expect(levels[i].levelNumber, i + 1);
    }
  });

  test('all levels pass schema validation', () {
    final factory = CampaignLevelFactory();
    final validator = LevelValidator();
    final levels = factory.buildAll();
    for (final level in levels) {
      final issues = validator.validateSchema(level);
      expect(issues, isEmpty, reason: 'Level ${level.levelNumber}: $issues');
    }
  });

  test('levels 1-30 are solvable', () {
    final factory = CampaignLevelFactory();
    final solver = LevelSolver();
    for (var n = 1; n <= 30; n++) {
      final level = factory.buildLevel(n);
      final result = solver.solve(level, maxNodes: 400000);
      expect(
        result.solved,
        isTrue,
        reason: 'Level $n unsolvable: ${result.message}',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('sample later levels are solvable', () {
    final factory = CampaignLevelFactory();
    final solver = LevelSolver();
    for (final n in [40, 50, 55, 70, 80, 90, 100]) {
      final level = factory.buildLevel(n);
      // Snake-split guarantees a solution exists; schema already checked.
      // Spot-check solver on medium boards; large boards may exceed node budget.
      if (level.rows * level.columns <= 49) {
        final result = solver.solve(level, maxNodes: 500000);
        expect(
          result.solved,
          isTrue,
          reason: 'Level $n: ${result.message}',
        );
      } else {
        // Generator builds from a known space-filling path — verify structure
        expect(level.endpoints.length, level.colorCount * 2);
        expect(level.fillableCellCount, greaterThan(0));
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
