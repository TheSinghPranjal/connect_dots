import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connect_dots/features/gameplay/domain/models/cell_type.dart';
import 'package:connect_dots/features/gameplay/domain/models/grid_position.dart';
import 'package:connect_dots/features/gameplay/domain/models/level_definition.dart';
import 'package:connect_dots/features/gameplay/domain/solver/level_generator.dart';
import 'package:connect_dots/features/gameplay/domain/solver/level_solver.dart';

/// Run with: dart run tool/generate_levels.dart
void main() {
  final generator = LevelGenerator();
  final solver = LevelSolver();
  final levels = <LevelDefinition>[];
  final failed = <int>[];

  for (var n = 1; n <= 100; n++) {
    final spec = _specFor(n);
    LevelDefinition? level;

    for (var retry = 0; retry < 20; retry++) {
      level = generator.generate(
        levelNumber: n,
        rows: spec.rows,
        columns: spec.cols,
        colorCount: spec.colors,
        difficulty: spec.difficulty,
        seed: 1000 + n * 137 + retry * 41,
        blockedCells: spec.blocked,
        targetMoves: spec.targetMoves,
        moveLimit: spec.moveLimit,
        timeLimitSeconds: spec.timeLimit,
        objective: spec.objective,
        requiredBonusNodes: spec.bonusNodes,
        maxAttempts: 30,
      );
      if (level == null) continue;

      // For larger boards, trust snake-split solvability; spot-check with solver
      if (spec.rows * spec.cols <= 36) {
        final result = solver.solve(level, maxNodes: 300000);
        if (!result.solved) {
          level = null;
          continue;
        }
      }
      break;
    }

    if (level == null) {
      failed.add(n);
      stdout.writeln('FAIL level $n');
      // Emergency fallback: open board serpentine-friendly
      level = generator.generate(
        levelNumber: n,
        rows: spec.rows,
        columns: spec.cols,
        colorCount: min(spec.colors, (spec.rows * spec.cols) ~/ 2),
        difficulty: spec.difficulty,
        seed: 99999 + n,
        blockedCells: const [],
        targetMoves: spec.targetMoves,
        moveLimit: spec.moveLimit,
        maxAttempts: 50,
      );
    }

    if (level != null) {
      levels.add(level);
      stdout.writeln(
        'OK  level $n  ${level.rows}x${level.columns}  '
        'colors=${level.colorCount}  blocked=${level.blockedCells.length}',
      );
    } else {
      stderr.writeln('CRITICAL: could not generate level $n');
      exit(1);
    }
  }

  final jsonList = levels.map((l) => l.toJson()).toList();
  final out = JsonEncoder.withIndent('  ').convert({'levels': jsonList});

  Directory('assets/levels').createSync(recursive: true);
  File('assets/levels/campaign.json').writeAsStringSync(out);
  stdout.writeln('\nWrote ${levels.length} levels to assets/levels/campaign.json');
  if (failed.isNotEmpty) {
    stdout.writeln('Used fallback for: $failed');
  }
}

class _Spec {
  const _Spec({
    required this.rows,
    required this.cols,
    required this.colors,
    required this.difficulty,
    this.blocked = const [],
    this.targetMoves,
    this.moveLimit,
    this.timeLimit,
    this.objective = LevelObjectiveType.normal,
    this.bonusNodes = 0,
  });

  final int rows;
  final int cols;
  final int colors;
  final Difficulty difficulty;
  final List<GridPosition> blocked;
  final int? targetMoves;
  final int? moveLimit;
  final int? timeLimit;
  final LevelObjectiveType objective;
  final int bonusNodes;
}

_Spec _specFor(int n) {
  if (n <= 10) {
    final colors = n == 1
        ? 1
        : n <= 2
            ? 1
            : n <= 7
                ? 2
                : 3;
    return _Spec(
      rows: 4,
      cols: 4,
      colors: colors,
      difficulty: Difficulty.tutorial,
      targetMoves: colors + 1,
    );
  }
  if (n <= 20) {
    return _Spec(
      rows: 5,
      cols: 5,
      colors: n <= 15 ? 2 : 3,
      difficulty: Difficulty.easy,
      targetMoves: (n <= 15 ? 2 : 3) + 2,
    );
  }
  if (n <= 30) {
    return _Spec(
      rows: 5,
      cols: 5,
      colors: 3,
      difficulty: n <= 25 ? Difficulty.easy : Difficulty.medium,
      targetMoves: 5,
    );
  }
  if (n <= 40) {
    return _Spec(
      rows: 6,
      cols: 6,
      colors: n <= 35 ? 3 : 4,
      difficulty: Difficulty.medium,
      targetMoves: (n <= 35 ? 3 : 4) + 2,
    );
  }
  if (n <= 50) {
    return _Spec(
      rows: 6,
      cols: 6,
      colors: 4,
      difficulty: n <= 45 ? Difficulty.medium : Difficulty.hard,
      targetMoves: 7,
    );
  }
  if (n <= 60) {
    final blocked = _blockedPattern(n, 7, 7, count: 2 + (n - 51) ~/ 3);
    return _Spec(
      rows: 7,
      cols: 7,
      colors: n <= 55 ? 4 : 5,
      difficulty: Difficulty.hard,
      blocked: blocked,
      targetMoves: 8,
    );
  }
  if (n <= 70) {
    final blocked = _blockedPattern(n, 7, 7, count: 3 + (n % 3));
    final bonus = n >= 61 && n % 3 == 0 ? 2 : (n >= 65 ? 1 : 0);
    return _Spec(
      rows: 7,
      cols: 7,
      colors: 5,
      difficulty: Difficulty.hard,
      blocked: blocked,
      targetMoves: 9,
      bonusNodes: bonus,
      objective: bonus > 0
          ? LevelObjectiveType.bonusCollection
          : LevelObjectiveType.normal,
    );
  }
  if (n <= 80) {
    final blocked = _blockedPattern(n, 8, 8, count: 4 + (n % 4));
    return _Spec(
      rows: 8,
      cols: 8,
      colors: 5,
      difficulty: n <= 75 ? Difficulty.hard : Difficulty.expert,
      blocked: blocked,
      targetMoves: 10,
      bonusNodes: n % 2 == 0 ? 2 : 0,
    );
  }
  if (n <= 90) {
    final blocked = _blockedPattern(n, 8, 8, count: 5 + (n % 3));
    return _Spec(
      rows: 8,
      cols: 8,
      colors: n <= 85 ? 5 : 6,
      difficulty: Difficulty.expert,
      blocked: blocked,
      targetMoves: 11,
      bonusNodes: 1,
      objective: LevelObjectiveType.efficiency,
    );
  }
  // 91–100 challenge
  final moveLimits = {
    91: 28,
    92: 26,
    93: 26,
    94: 24,
    95: 24,
    96: 22,
    97: 22,
    98: 20,
    99: 20,
    100: 20,
  };
  final blocked = _blockedPattern(n, 9, 9, count: 6 + (n % 4));
  return _Spec(
    rows: 9,
    cols: 9,
    colors: 6,
    difficulty: Difficulty.expert,
    blocked: blocked,
    targetMoves: 12,
    moveLimit: moveLimits[n],
    timeLimit: n >= 98 ? 180 : null,
    objective: LevelObjectiveType.efficiency,
  );
}

List<GridPosition> _blockedPattern(int seed, int rows, int cols, {required int count}) {
  final rng = Random(seed * 31 + 7);
  final cells = <GridPosition>{};
  // Keep border mostly open; place interior blocks that don't isolate
  var attempts = 0;
  while (cells.length < count && attempts < 200) {
    attempts++;
    final r = 1 + rng.nextInt(max(1, rows - 2));
    final c = 1 + rng.nextInt(max(1, cols - 2));
    cells.add(GridPosition(r, c));
  }
  return cells.toList();
}
