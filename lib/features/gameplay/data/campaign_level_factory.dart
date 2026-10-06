import '../domain/models/cell_type.dart';
import '../domain/models/grid_position.dart';
import '../domain/models/level_definition.dart';
import '../domain/solver/level_generator.dart';

/// Builds all 100 campaign levels deterministically from fixed seeds.
/// Levels 1–10 are hand-authored for teaching; 11–100 use the generator.
class CampaignLevelFactory {
  CampaignLevelFactory({LevelGenerator? generator})
      : _generator = generator ?? LevelGenerator();

  final LevelGenerator _generator;
  List<LevelDefinition>? _cache;

  List<LevelDefinition> buildAll() {
    if (_cache != null) return _cache!;
    final levels = <LevelDefinition>[];
    for (var n = 1; n <= 100; n++) {
      levels.add(buildLevel(n));
    }
    _cache = List.unmodifiable(levels);
    return _cache!;
  }

  LevelDefinition buildLevel(int n) {
    final spec = _specFor(n);
    LevelDefinition? level;

    for (var retry = 0; retry < 8; retry++) {
      final blocked = retry < 5 ? spec.blocked : <GridPosition>[];
      final colors = spec.colors;

      level = _generator.generate(
        levelNumber: n,
        rows: spec.rows,
        columns: spec.cols,
        colorCount: colors,
        difficulty: spec.difficulty,
        seed: 42000 + n * 97 + retry * 13,
        blockedCells: blocked,
        targetMoves: spec.targetMoves,
        moveLimit: spec.moveLimit,
        timeLimitSeconds: spec.timeLimit,
        objective: spec.objective,
        requiredBonusNodes: blocked.isEmpty ? 0 : spec.bonusNodes,
        maxAttempts: 8,
      );
      if (level != null) break;
    }

    level ??= _generator.generate(
      levelNumber: n,
      rows: spec.rows,
      columns: spec.cols,
      colorCount: spec.colors.clamp(2, (spec.rows * spec.cols) ~/ 4),
      difficulty: spec.difficulty,
      seed: 900000 + n,
      targetMoves: spec.targetMoves,
      moveLimit: spec.moveLimit,
      timeLimitSeconds: spec.timeLimit,
      maxAttempts: 40,
    );

    if (level == null) {
      throw StateError('Failed to build deterministic level $n');
    }
    return level;
  }

  _LevelSpec _specFor(int n) {
    if (n <= 10) {
      final colors = n <= 2
          ? 1
          : n <= 7
              ? 2
              : 3;
      return _LevelSpec(
        rows: 4,
        cols: 4,
        colors: colors,
        difficulty: Difficulty.tutorial,
        targetMoves: colors + 1,
      );
    }
    if (n <= 20) {
      return _LevelSpec(
        rows: 5,
        cols: 5,
        colors: n <= 15 ? 2 : 3,
        difficulty: Difficulty.easy,
        targetMoves: n <= 15 ? 4 : 5,
      );
    }
    if (n <= 30) {
      return _LevelSpec(
        rows: 5,
        cols: 5,
        colors: 3,
        difficulty: n <= 25 ? Difficulty.easy : Difficulty.medium,
        targetMoves: 5,
      );
    }
    if (n <= 40) {
      return _LevelSpec(
        rows: 6,
        cols: 6,
        colors: n <= 35 ? 3 : 4,
        difficulty: Difficulty.medium,
        targetMoves: n <= 35 ? 5 : 6,
      );
    }
    if (n <= 50) {
      return _LevelSpec(
        rows: 6,
        cols: 6,
        colors: 4,
        difficulty: n <= 45 ? Difficulty.medium : Difficulty.hard,
        targetMoves: 7,
      );
    }
    if (n <= 60) {
      return _LevelSpec(
        rows: 7,
        cols: 7,
        colors: n <= 55 ? 4 : 5,
        difficulty: Difficulty.hard,
        targetMoves: 8,
        blocked: _blocks(n, 7, 7, 2 + (n - 51) ~/ 3),
      );
    }
    if (n <= 70) {
      final bonus = n % 3 == 0 ? 2 : 0;
      return _LevelSpec(
        rows: 7,
        cols: 7,
        colors: 5,
        difficulty: Difficulty.hard,
        targetMoves: 9,
        blocked: _blocks(n, 7, 7, 3 + n % 3),
        bonusNodes: bonus,
        objective: bonus > 0
            ? LevelObjectiveType.bonusCollection
            : LevelObjectiveType.normal,
      );
    }
    if (n <= 80) {
      return _LevelSpec(
        rows: 8,
        cols: 8,
        colors: 5,
        difficulty: n <= 75 ? Difficulty.hard : Difficulty.expert,
        targetMoves: 10,
        blocked: _blocks(n, 8, 8, 4 + n % 4),
        bonusNodes: n.isEven ? 2 : 0,
      );
    }
    if (n <= 90) {
      return _LevelSpec(
        rows: 8,
        cols: 8,
        colors: n <= 85 ? 5 : 6,
        difficulty: Difficulty.expert,
        targetMoves: 11,
        blocked: _blocks(n, 8, 8, 5 + n % 3),
        bonusNodes: 1,
        objective: LevelObjectiveType.efficiency,
      );
    }
    const moveLimits = {
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
    return _LevelSpec(
      rows: 9,
      cols: 9,
      colors: 6,
      difficulty: Difficulty.expert,
      targetMoves: 12,
      blocked: _blocks(n, 9, 9, 6 + n % 4),
      moveLimit: moveLimits[n],
      timeLimit: n >= 98 ? 180 : null,
      objective: LevelObjectiveType.efficiency,
    );
  }

  List<GridPosition> _blocks(int seed, int rows, int cols, int count) {
    // Deterministic interior blocks spaced to keep grid connected.
    final cells = <GridPosition>[];
    final used = <String>{};
    var i = 0;
    var guard = 0;
    while (cells.length < count && guard < 100) {
      guard++;
      final r = 1 + ((seed * 3 + i * 5) % (rows - 2));
      final c = 1 + ((seed * 7 + i * 11) % (cols - 2));
      final key = '$r,$c';
      i++;
      if (used.add(key)) {
        cells.add(GridPosition(r, c));
      }
    }
    return cells;
  }
}

class _LevelSpec {
  const _LevelSpec({
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
