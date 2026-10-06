import '../../../../core/constants/game_constants.dart';
import '../models/board_state.dart';
import '../models/color_id.dart';
import '../models/flow_path.dart';
import '../models/grid_position.dart';
import '../models/level_definition.dart';
import '../models/level_result.dart';
import '../validators/path_validator.dart';

enum EngineFeedback {
  none,
  pathStarted,
  pathExtended,
  pathBacktracked,
  pathCompleted,
  collisionTruncated,
  invalidMove,
  levelCompleted,
  outOfMoves,
}

class EngineActionResult {
  const EngineActionResult({
    required this.board,
    this.feedback = EngineFeedback.none,
    this.pathCompleted = false,
    this.levelCompleted = false,
    this.invalidCell,
    this.completedPathLength = 0,
    this.bonusCollected = false,
    this.truncatedCells = 0,
  });

  final BoardState board;
  final EngineFeedback feedback;
  final bool pathCompleted;
  final bool levelCompleted;
  final GridPosition? invalidCell;
  final int completedPathLength;
  final bool bonusCollected;
  final int truncatedCells;
}

/// Pure Dart game engine — no Flutter dependencies.
class FlowGameEngine {
  FlowGameEngine({PathValidator? validator})
      : _validator = validator ?? const PathValidator();

  final PathValidator _validator;

  BoardState createBoard(LevelDefinition level) => BoardState.initial(level);

  EngineActionResult startPath(BoardState board, GridPosition position) {
    if (!position.isInside(board.rows, board.columns)) {
      return EngineActionResult(
        board: board,
        feedback: EngineFeedback.invalidMove,
        invalidCell: position,
      );
    }
    if (board.level.isBlocked(position)) {
      return EngineActionResult(
        board: board,
        feedback: EngineFeedback.invalidMove,
        invalidCell: position,
      );
    }

    final endpoint = board.level.endpointAt(position);
    final owner = board.ownerAt(position);

    // Start from endpoint
    if (endpoint != null) {
      final existing = board.pathForColor(endpoint.color);
      var paths = List<FlowPath>.from(board.paths);

      if (existing != null) {
        // Restart path from this endpoint
        paths = paths.where((p) => p.color != endpoint.color).toList();
      }

      return EngineActionResult(
        board: board.copyWith(
          paths: List.unmodifiable(paths),
          activeColor: endpoint.color,
          activePathCells: List.unmodifiable([position]),
          clearPointerPreview: true,
        ),
        feedback: EngineFeedback.pathStarted,
      );
    }

    // Start editing an existing path from a cell on it
    if (owner != null) {
      final path = board.pathForColor(owner);
      if (path == null) {
        return EngineActionResult(
          board: board,
          feedback: EngineFeedback.invalidMove,
        );
      }
      final idx = path.indexOf(position);
      if (idx < 0) {
        return EngineActionResult(
          board: board,
          feedback: EngineFeedback.invalidMove,
        );
      }

      final truncated = path.truncateTo(idx);
      final paths = board.paths
          .map((p) => p.color == owner ? truncated.copyWith(isComplete: false) : p)
          .where((p) => p.cells.isNotEmpty)
          .toList();

      // Move truncated path into active
      final without = paths.where((p) => p.color != owner).toList();

      return EngineActionResult(
        board: board.copyWith(
          paths: List.unmodifiable(without),
          activeColor: owner,
          activePathCells: List.unmodifiable(truncated.cells),
        ),
        feedback: EngineFeedback.pathStarted,
        truncatedCells: path.length - truncated.length,
      );
    }

    return EngineActionResult(
      board: board,
      feedback: EngineFeedback.invalidMove,
      invalidCell: position,
    );
  }

  EngineActionResult extendPath(BoardState board, GridPosition target) {
    final color = board.activeColor;
    final cells = board.activePathCells;
    if (color == null || cells.isEmpty) {
      return EngineActionResult(board: board);
    }

    final head = cells.last;
    if (target == head) {
      return EngineActionResult(board: board.copyWith(pointerPreview: target));
    }

    // Interpolate for fast drags
    final sequence = cells.length == 1
        ? _orthogonalSteps(head, target)
        : _orthogonalSteps(head, target);

    var current = board;
    EngineFeedback lastFeedback = EngineFeedback.none;
    var completed = false;
    var completedLength = 0;
    var bonusCollected = false;
    GridPosition? invalidCell;

    for (final step in sequence) {
      if (step == current.activePathCells.last) continue;

      final result = _extendOneStep(current, step);
      current = result.board;
      lastFeedback = result.feedback;
      if (result.bonusCollected) bonusCollected = true;

      if (result.feedback == EngineFeedback.invalidMove) {
        invalidCell = result.invalidCell;
        break;
      }
      if (result.pathCompleted) {
        completed = true;
        completedLength = result.completedPathLength;
        break;
      }
    }

    final levelDone = completed && isLevelComplete(current);

    return EngineActionResult(
      board: current,
      feedback: levelDone
          ? EngineFeedback.levelCompleted
          : (completed
              ? EngineFeedback.pathCompleted
              : lastFeedback),
      pathCompleted: completed,
      levelCompleted: levelDone,
      invalidCell: invalidCell,
      completedPathLength: completedLength,
      bonusCollected: bonusCollected,
    );
  }

  EngineActionResult endPath(BoardState board) {
    if (board.activeColor == null || board.activePathCells.isEmpty) {
      return EngineActionResult(board: board);
    }

    // If path only has one cell (just the endpoint), discard active.
    if (board.activePathCells.length <= 1) {
      return EngineActionResult(
        board: board.copyWith(clearActive: true, clearPointerPreview: true),
      );
    }

    // Commit incomplete path
    final color = board.activeColor!;
    final path = FlowPath(
      color: color,
      cells: List.unmodifiable(board.activePathCells),
      startEndpointId: board.level.endpointAt(board.activePathCells.first)?.id,
      isComplete: false,
    );

    final paths = [
      ...board.paths.where((p) => p.color != color),
      path,
    ];

    return EngineActionResult(
      board: board.copyWith(
        paths: List.unmodifiable(paths),
        clearActive: true,
        clearPointerPreview: true,
      ),
    );
  }

  EngineActionResult _extendOneStep(BoardState board, GridPosition to) {
    final color = board.activeColor!;
    final cells = List<GridPosition>.from(board.activePathCells);
    final from = cells.last;

    // Backtrack
    if (cells.length >= 2 && cells[cells.length - 2] == to) {
      cells.removeLast();
      return EngineActionResult(
        board: board.copyWith(
          activePathCells: List.unmodifiable(cells),
          pointerPreview: to,
        ),
        feedback: EngineFeedback.pathBacktracked,
      );
    }

    // Truncate if revisiting own path (not just previous)
    final existingIdx = cells.indexOf(to);
    if (existingIdx >= 0) {
      final truncated = cells.sublist(0, existingIdx + 1);
      return EngineActionResult(
        board: board.copyWith(
          activePathCells: List.unmodifiable(truncated),
          pointerPreview: to,
        ),
        feedback: EngineFeedback.pathBacktracked,
      );
    }

    if (!from.isAdjacentTo(to)) {
      return EngineActionResult(
        board: board,
        feedback: EngineFeedback.invalidMove,
        invalidCell: to,
      );
    }

    if (board.level.isBlocked(to)) {
      return EngineActionResult(
        board: board,
        feedback: EngineFeedback.invalidMove,
        invalidCell: to,
      );
    }

    final endpoint = board.level.endpointAt(to);

    // Wrong color endpoint
    if (endpoint != null && endpoint.color != color) {
      return EngineActionResult(
        board: board,
        feedback: EngineFeedback.invalidMove,
        invalidCell: to,
      );
    }

    // Own other endpoint — complete (must not be the start)
    if (endpoint != null &&
        endpoint.color == color &&
        to != cells.first) {
      cells.add(to);

      // Collect bonus nodes along path
      final collected = Set<GridPosition>.from(board.collectedBonusNodes);
      var bonusHit = false;
      for (final cell in cells) {
        for (final bonus in board.level.bonusNodes) {
          if (bonus.position == cell && collected.add(cell)) {
            bonusHit = true;
          }
        }
      }

      final completedPath = FlowPath(
        color: color,
        cells: List.unmodifiable(cells),
        startEndpointId: board.level.endpointAt(cells.first)?.id,
        endEndpointId: endpoint.id,
        isComplete: true,
      );

      final paths = [
        ...board.paths.where((p) => p.color != color),
        completedPath,
      ];

      final newBoard = board.copyWith(
        paths: List.unmodifiable(paths),
        collectedBonusNodes: collected,
        clearActive: true,
        clearPointerPreview: true,
      );

      return EngineActionResult(
        board: newBoard,
        feedback: EngineFeedback.pathCompleted,
        pathCompleted: true,
        completedPathLength: cells.length,
        bonusCollected: bonusHit,
        levelCompleted: isLevelComplete(newBoard),
      );
    }

    // Collision with another path — truncate other path
    final otherOwner = _otherOwner(board, to, color);
    if (otherOwner != null) {
      final otherPath = board.pathForColor(otherOwner);
      if (otherPath != null) {
        final collisionIdx = otherPath.indexOf(to);
        // Cannot overwrite another color's endpoint
        final otherEp = board.level.endpointAt(to);
        if (otherEp != null) {
          return EngineActionResult(
            board: board,
            feedback: EngineFeedback.invalidMove,
            invalidCell: to,
          );
        }

        FlowPath? truncatedOther;
        if (collisionIdx > 0) {
          truncatedOther = otherPath.truncateTo(collisionIdx - 1);
          if (truncatedOther.cells.isEmpty) truncatedOther = null;
        }

        final paths = board.paths.where((p) => p.color != otherOwner).toList();
        if (truncatedOther != null) {
          paths.add(truncatedOther.copyWith(isComplete: false));
        }

        cells.add(to);
        final collected = _collectBonuses(board, cells);

        return EngineActionResult(
          board: board.copyWith(
            paths: List.unmodifiable(paths),
            activePathCells: List.unmodifiable(cells),
            collectedBonusNodes: collected.set,
            pointerPreview: to,
          ),
          feedback: EngineFeedback.collisionTruncated,
          truncatedCells: otherPath.length - (truncatedOther?.length ?? 0),
          bonusCollected: collected.hit,
        );
      }
    }

    // Normal extension
    cells.add(to);
    final collected = _collectBonuses(board, cells);

    return EngineActionResult(
      board: board.copyWith(
        activePathCells: List.unmodifiable(cells),
        collectedBonusNodes: collected.set,
        pointerPreview: to,
      ),
      feedback: EngineFeedback.pathExtended,
      bonusCollected: collected.hit,
    );
  }

  ColorId? _otherOwner(BoardState board, GridPosition pos, ColorId active) {
    for (final path in board.paths) {
      if (path.color == active) continue;
      if (path.contains(pos)) return path.color;
    }
    return null;
  }

  ({Set<GridPosition> set, bool hit}) _collectBonuses(
    BoardState board,
    List<GridPosition> cells,
  ) {
    final collected = Set<GridPosition>.from(board.collectedBonusNodes);
    var hit = false;
    for (final cell in cells) {
      for (final bonus in board.level.bonusNodes) {
        if (bonus.position == cell && collected.add(cell)) {
          hit = true;
        }
      }
    }
    return (set: collected, hit: hit);
  }

  List<GridPosition> _orthogonalSteps(GridPosition from, GridPosition to) {
    final path = <GridPosition>[];
    var r = from.row;
    var c = from.column;
    // Move column first, then row (orthogonal only)
    while (c != to.column) {
      c += c < to.column ? 1 : -1;
      path.add(GridPosition(r, c));
    }
    while (r != to.row) {
      r += r < to.row ? 1 : -1;
      path.add(GridPosition(r, c));
    }
    return path;
  }

  bool areAllPairsConnected(BoardState board) => board.allPairsConnected;

  bool isBoardFilled(BoardState board) => board.allFillableCellsOccupied;

  bool allPathsValid(BoardState board) {
    for (final path in board.paths) {
      final result = _validator.validatePath(path, board);
      if (!result.isValid) return false;
    }
    return true;
  }

  bool hasCollisions(BoardState board) {
    final seen = <GridPosition, ColorId>{};
    for (final path in board.paths) {
      for (final cell in path.cells) {
        final prev = seen[cell];
        if (prev != null && prev != path.color) return true;
        seen[cell] = path.color;
      }
    }
    return false;
  }

  bool bonusObjectiveMet(BoardState board) {
    final required = board.level.requiredBonusNodes;
    if (required <= 0) return true;
    return board.collectedBonusNodes.length >= required;
  }

  bool isLevelComplete(BoardState board) {
    return areAllPairsConnected(board) &&
        isBoardFilled(board) &&
        allPathsValid(board) &&
        !hasCollisions(board) &&
        bonusObjectiveMet(board) &&
        board.activeColor == null;
  }

  LevelScore scorePathCompletion({
    required LevelScore current,
    required int pathLength,
    required bool bonusNode,
  }) {
    final base = pathLength * GameConstants.pointsPerCell;
    final mult = current.comboMultiplier;
    final pathPts = base * mult;
    final bonusPts = bonusNode ? GameConstants.bonusNodePoints : 0;
    final comboBonus = mult > 1 ? (mult - 1) * 10 : 0;

    return current.copyWith(
      pathPoints: current.pathPoints + pathPts,
      bonusNodePoints: current.bonusNodePoints + bonusPts,
      comboBonus: current.comboBonus + comboBonus,
      comboMultiplier: mult + 1,
      total: current.total + pathPts + bonusPts + comboBonus,
    );
  }

  LevelScore resetCombo(LevelScore score) =>
      score.copyWith(comboMultiplier: 1);

  LevelResult calculateResult({
    required LevelDefinition level,
    required BoardState board,
    required LevelScore score,
    required int movesUsed,
    required double timeUsedSeconds,
    required bool usedHint,
    required bool wasPerfect,
    required bool restarted,
    int? bestScore,
  }) {
    var finalScore = score;

    final completion =
        level.colorCount * GameConstants.completionColorBonus;
    final coverage = GameConstants.coverageBonus;
    var efficiency = 0;
    if (level.targetMoves != null) {
      efficiency = (level.targetMoves! - movesUsed)
              .clamp(0, level.targetMoves!) *
          GameConstants.efficiencyBonusPerMove;
    }
    final perfect = wasPerfect ? GameConstants.perfectBonus : 0;
    final hintPen = usedHint
        ? GameConstants.hintPenalty * 1
        : 0;

    final total = (finalScore.total +
            completion +
            coverage +
            efficiency +
            perfect -
            hintPen)
        .clamp(0, 999999);

    finalScore = finalScore.copyWith(
      completionBonus: completion,
      coverageBonus: coverage,
      efficiencyBonus: efficiency,
      perfectBonus: perfect,
      hintPenalty: hintPen,
      total: total,
    );

    final stars = calculateStars(
      targetMoves: level.targetMoves,
      movesUsed: movesUsed,
      usedHint: usedHint,
      wasPerfect: wasPerfect,
      restarted: restarted,
    );

    var coins = GameConstants.coinsPerLevel;
    if (stars >= 2) coins += GameConstants.coinsTwoStarBonus;
    if (stars >= 3) coins += GameConstants.coinsThreeStarBonus;
    if (wasPerfect) coins += GameConstants.coinsPerfectBonus;
    if (level.levelNumber == 50) coins += GameConstants.coinsMilestone50;
    if (level.levelNumber == 100) {
      coins += GameConstants.coinsCampaignComplete;
    }

    return LevelResult(
      levelId: level.levelNumber,
      completed: true,
      stars: stars,
      score: finalScore.total,
      movesUsed: movesUsed,
      timeUsedSeconds: timeUsedSeconds,
      coverage: board.coveragePercent,
      usedHint: usedHint,
      wasPerfect: wasPerfect,
      bonusCollected: board.collectedBonusNodes.length,
      coinsEarned: coins,
      bestScore: bestScore,
      isNewBest: bestScore == null || finalScore.total > bestScore,
    );
  }

  int calculateStars({
    required int? targetMoves,
    required int movesUsed,
    required bool usedHint,
    required bool wasPerfect,
    required bool restarted,
  }) {
    if (usedHint) return 1;

    final target = targetMoves ?? movesUsed;
    if (!restarted && wasPerfect && movesUsed <= target) {
      return 3;
    }
    if (movesUsed <= target + 3 || (!usedHint && !restarted)) {
      return 2;
    }
    return 1;
  }
}
