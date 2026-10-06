import 'package:equatable/equatable.dart';

import 'board_state.dart';
import 'cell_type.dart';
import 'grid_position.dart';
import 'level_definition.dart';
import 'level_result.dart';

class GameSessionState extends Equatable {
  const GameSessionState({
    required this.level,
    required this.board,
    this.status = GameplayStatus.ready,
    this.movesUsed = 0,
    this.score = const LevelScore(),
    this.isPerfectAttempt = true,
    this.usedHint = false,
    this.hintLevel = 0,
    this.elapsedSeconds = 0,
    this.remainingSeconds,
    this.undoStack = const [],
    this.result,
    this.failReason,
    this.invalidFeedbackCell,
    this.hintHighlightCells = const [],
    this.pathEditCount = 0,
  });

  final LevelDefinition level;
  final BoardState board;
  final GameplayStatus status;
  final int movesUsed;
  final LevelScore score;
  final bool isPerfectAttempt;
  final bool usedHint;
  final int hintLevel;
  final double elapsedSeconds;
  final double? remainingSeconds;
  final List<BoardState> undoStack;
  final LevelResult? result;
  final ChallengeFailReason? failReason;
  final GridPosition? invalidFeedbackCell;
  final List<GridPosition> hintHighlightCells;
  final int pathEditCount;

  bool get inputLocked =>
      status == GameplayStatus.paused ||
      status == GameplayStatus.completing ||
      status == GameplayStatus.completed ||
      status == GameplayStatus.failed;

  bool get isTimed => level.timeLimitSeconds != null;
  bool get hasMoveLimit => level.moveLimit != null;

  GameSessionState copyWith({
    LevelDefinition? level,
    BoardState? board,
    GameplayStatus? status,
    int? movesUsed,
    LevelScore? score,
    bool? isPerfectAttempt,
    bool? usedHint,
    int? hintLevel,
    double? elapsedSeconds,
    double? remainingSeconds,
    List<BoardState>? undoStack,
    LevelResult? result,
    ChallengeFailReason? failReason,
    GridPosition? invalidFeedbackCell,
    List<GridPosition>? hintHighlightCells,
    int? pathEditCount,
    bool clearResult = false,
    bool clearFailReason = false,
    bool clearInvalidFeedback = false,
    bool clearHints = false,
  }) {
    return GameSessionState(
      level: level ?? this.level,
      board: board ?? this.board,
      status: status ?? this.status,
      movesUsed: movesUsed ?? this.movesUsed,
      score: score ?? this.score,
      isPerfectAttempt: isPerfectAttempt ?? this.isPerfectAttempt,
      usedHint: usedHint ?? this.usedHint,
      hintLevel: hintLevel ?? this.hintLevel,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      undoStack: undoStack ?? this.undoStack,
      result: clearResult ? null : (result ?? this.result),
      failReason: clearFailReason ? null : (failReason ?? this.failReason),
      invalidFeedbackCell: clearInvalidFeedback
          ? null
          : (invalidFeedbackCell ?? this.invalidFeedbackCell),
      hintHighlightCells:
          clearHints ? const [] : (hintHighlightCells ?? this.hintHighlightCells),
      pathEditCount: pathEditCount ?? this.pathEditCount,
    );
  }

  factory GameSessionState.initial(LevelDefinition level) {
    return GameSessionState(
      level: level,
      board: BoardState.initial(level),
      remainingSeconds: level.timeLimitSeconds?.toDouble(),
    );
  }

  Map<String, dynamic> toSessionJson() => {
        'levelId': level.levelNumber,
        'movesUsed': movesUsed,
        'elapsedSeconds': elapsedSeconds,
        'remainingSeconds': remainingSeconds,
        'isPerfectAttempt': isPerfectAttempt,
        'usedHint': usedHint,
        'hintLevel': hintLevel,
        'status': status.name,
        'scoreTotal': score.total,
        'comboMultiplier': score.comboMultiplier,
        'pathEditCount': pathEditCount,
        'collectedBonus':
            board.collectedBonusNodes.map((p) => p.toJson()).toList(),
        'paths': board.paths
            .map(
              (p) => {
                'color': p.color.name,
                'cells': p.cells.map((c) => c.toJson()).toList(),
                'startEndpointId': p.startEndpointId,
                'endEndpointId': p.endEndpointId,
                'isComplete': p.isComplete,
              },
            )
            .toList(),
      };

  @override
  List<Object?> get props => [
        level,
        board,
        status,
        movesUsed,
        score,
        isPerfectAttempt,
        usedHint,
        hintLevel,
        elapsedSeconds,
        remainingSeconds,
        undoStack,
        result,
        failReason,
        invalidFeedbackCell,
        hintHighlightCells,
        pathEditCount,
      ];
}

/// Lightweight snapshot for undo (board + score bits).
class UndoSnapshot extends Equatable {
  const UndoSnapshot({
    required this.board,
    required this.score,
    required this.movesUsed,
  });

  final BoardState board;
  final LevelScore score;
  final int movesUsed;

  @override
  List<Object?> get props => [board, score, movesUsed];
}
