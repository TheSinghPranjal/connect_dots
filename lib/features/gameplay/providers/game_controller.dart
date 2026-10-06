import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_manager.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/models/board_state.dart';
import '../domain/models/cell_type.dart';
import '../domain/models/game_session_state.dart';
import '../domain/models/grid_position.dart';
import '../domain/models/level_definition.dart';
import '../domain/rules/flow_game_engine.dart';
import '../domain/solver/level_solver.dart';

final gameEngineProvider = Provider<FlowGameEngine>((ref) => FlowGameEngine());

final gameControllerProvider =
    NotifierProvider<GameController, GameSessionState?>(GameController.new);

class GameController extends Notifier<GameSessionState?> {
  FlowGameEngine get _engine => ref.read(gameEngineProvider);
  Timer? _ticker;
  bool _restartedThisAttempt = false;
  GridPosition? _lastProcessedCell;

  @override
  GameSessionState? build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return null;
  }

  Future<void> loadLevel(int levelId) async {
    _ticker?.cancel();
    _restartedThisAttempt = false;
    _lastProcessedCell = null;

    try {
      final level =
          await ref.read(levelRepositoryProvider).getLevel(levelId);
      state = GameSessionState.initial(level);
      ref.read(analyticsServiceProvider).logEvent('levelStarted', {
        'levelId': levelId,
      });
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  void startPath(GridPosition position) {
    final session = state;
    if (session == null || session.inputLocked) return;

    final result = _engine.startPath(session.board, position);
    if (result.feedback == EngineFeedback.invalidMove) {
      state = session.copyWith(
        invalidFeedbackCell: result.invalidCell,
      );
      ref.read(audioManagerProvider).play(SoundEvent.invalidMove);
      ref.read(hapticsManagerProvider).warning();
      return;
    }

    final stack = [
      ...session.undoStack,
      session.board.copyWith(clearActive: true, clearPointerPreview: true),
    ];
    while (stack.length > GameConstants.maxUndoStack) {
      stack.removeAt(0);
    }

    _lastProcessedCell = position;
    var next = session.copyWith(
      board: result.board,
      status: GameplayStatus.playing,
      undoStack: List.unmodifiable(stack),
      clearInvalidFeedback: true,
      clearHints: true,
    );
    if (session.status == GameplayStatus.ready) {
      _startTickerIfNeeded(next);
    }
    state = next;
    ref.read(audioManagerProvider).play(SoundEvent.pathStart);
    ref.read(hapticsManagerProvider).light();
  }

  void continuePath(GridPosition position) {
    final session = state;
    if (session == null || session.inputLocked) return;
    if (session.board.activeColor == null) return;
    if (_lastProcessedCell == position) return;

    final result = _engine.extendPath(session.board, position);
    _lastProcessedCell = position;

    var score = session.score;
    var moves = session.movesUsed;
    var perfect = session.isPerfectAttempt;
    var status = session.status;

    if (result.feedback == EngineFeedback.invalidMove) {
      state = session.copyWith(
        board: result.board,
        invalidFeedbackCell: result.invalidCell,
      );
      ref.read(audioManagerProvider).play(SoundEvent.invalidMove);
      ref.read(hapticsManagerProvider).warning();
      return;
    }

    if (result.feedback == EngineFeedback.collisionTruncated) {
      perfect = false;
      score = _engine.resetCombo(score);
    }

    if (result.pathCompleted) {
      moves += 1;
      score = _engine.scorePathCompletion(
        current: score,
        pathLength: result.completedPathLength,
        bonusNode: result.bonusCollected,
      );
      ref.read(audioManagerProvider).play(SoundEvent.pathComplete);
      ref.read(hapticsManagerProvider).medium();

      // Challenge move limit check
      final limit = session.level.moveLimit;
      if (limit != null && moves > limit && !result.levelCompleted) {
        state = session.copyWith(
          board: result.board,
          score: score,
          movesUsed: moves,
          isPerfectAttempt: perfect,
          status: GameplayStatus.failed,
          failReason: ChallengeFailReason.outOfMoves,
        );
        _ticker?.cancel();
        ref.read(audioManagerProvider).play(SoundEvent.challengeFailed);
        ref.read(analyticsServiceProvider).logEvent('levelFailed', {
          'levelId': session.level.levelNumber,
          'reason': 'outOfMoves',
        });
        return;
      }
    } else if (result.feedback == EngineFeedback.pathExtended) {
      ref.read(audioManagerProvider).play(SoundEvent.pathMove);
    }

    if (result.levelCompleted) {
      status = GameplayStatus.completing;
      _ticker?.cancel();
      final completedSession = session.copyWith(
        board: result.board,
        score: score,
        movesUsed: moves,
        isPerfectAttempt: perfect,
        status: status,
        clearInvalidFeedback: true,
      );
      state = completedSession;
      _finalizeCompletion(completedSession);
      return;
    }

    state = session.copyWith(
      board: result.board,
      score: score,
      movesUsed: moves,
      isPerfectAttempt: perfect,
      status: GameplayStatus.playing,
      clearInvalidFeedback: true,
    );
  }

  void endPath() {
    final session = state;
    if (session == null || session.inputLocked) return;
    if (session.board.activeColor == null) return;

    final result = _engine.endPath(session.board);
    var moves = session.movesUsed;
    // Committing a partial path counts as a move
    if (result.board.paths.length != session.board.paths.length ||
        result.board.paths.any((p) =>
            session.board.pathForColor(p.color)?.cells.length != p.cells.length)) {
      if (session.board.activePathCells.length > 1) {
        moves += 1;
      }
    }

    var next = session.copyWith(
      board: result.board,
      movesUsed: moves,
      clearInvalidFeedback: true,
    );

    if (_engine.isLevelComplete(result.board)) {
      next = next.copyWith(status: GameplayStatus.completing);
      state = next;
      _finalizeCompletion(next);
      return;
    }

    // Move limit after commit
    final limit = session.level.moveLimit;
    if (limit != null && moves > limit) {
      state = next.copyWith(
        status: GameplayStatus.failed,
        failReason: ChallengeFailReason.outOfMoves,
      );
      _ticker?.cancel();
      return;
    }

    state = next;
    _lastProcessedCell = null;
  }

  void _finalizeCompletion(GameSessionState session) {
    final progress = ref.read(progressControllerProvider).value;
    final best = progress?.entryFor(session.level.levelNumber)?.bestScore;

    final result = _engine.calculateResult(
      level: session.level,
      board: session.board,
      score: session.score,
      movesUsed: session.movesUsed,
      timeUsedSeconds: session.elapsedSeconds,
      usedHint: session.usedHint,
      wasPerfect: session.isPerfectAttempt,
      restarted: _restartedThisAttempt,
      bestScore: best,
    );

    state = session.copyWith(
      status: GameplayStatus.completed,
      result: result,
    );

    ref.read(audioManagerProvider).play(SoundEvent.levelComplete);
    ref.read(hapticsManagerProvider).success();
    ref.read(analyticsServiceProvider).logEvent('levelCompleted', {
      'levelId': session.level.levelNumber,
      'stars': result.stars,
      'score': result.score,
    });

    ref.read(progressControllerProvider.notifier).applyLevelResult(
          levelId: session.level.levelNumber,
          stars: result.stars,
          score: result.score,
          moves: result.movesUsed,
          timeSeconds: result.timeUsedSeconds,
          coinsEarned: result.coinsEarned,
          wasPerfect: result.wasPerfect,
          bonusCollected: result.bonusCollected,
          totalLevels: GameConstants.totalCampaignLevels,
        );

    ref.read(progressRepositoryProvider).clearSession();
  }

  void undo() {
    final session = state;
    if (session == null || session.inputLocked) return;
    if (session.undoStack.isEmpty) return;

    final previous = session.undoStack.last;
    final newStack = session.undoStack.sublist(0, session.undoStack.length - 1);

    state = session.copyWith(
      board: previous,
      undoStack: List.unmodifiable(newStack),
      isPerfectAttempt: false,
      score: _engine.resetCombo(session.score),
      clearHints: true,
      clearInvalidFeedback: true,
    );
    _lastProcessedCell = null;
    ref.read(audioManagerProvider).play(SoundEvent.undo);
    ref.read(analyticsServiceProvider).logEvent('undoUsed');
  }

  void restart({bool confirm = true}) {
    final session = state;
    if (session == null) return;
    final level = session.level;
    _restartedThisAttempt = true;
    _lastProcessedCell = null;
    _ticker?.cancel();
    state = GameSessionState.initial(level).copyWith(
      isPerfectAttempt: false,
      status: GameplayStatus.ready,
    );
    ref.read(audioManagerProvider).play(SoundEvent.restart);
    ref.read(analyticsServiceProvider).logEvent('restartUsed');
  }

  Future<void> useHint() async {
    final session = state;
    if (session == null || session.inputLocked) return;

    final progress = ref.read(progressControllerProvider).value;
    if (progress == null || progress.hints <= 0) return;

    await ref.read(progressControllerProvider.notifier).spendHint();

    final hintLevel = session.hintLevel + 1;
    final highlights = _computeHint(session.level, session.board, hintLevel);

    state = session.copyWith(
      usedHint: true,
      isPerfectAttempt: false,
      hintLevel: hintLevel,
      hintHighlightCells: highlights,
      score: session.score.copyWith(
        total: (session.score.total - GameConstants.hintPenalty)
            .clamp(0, 999999),
        hintPenalty: session.score.hintPenalty + GameConstants.hintPenalty,
      ),
    );

    ref.read(audioManagerProvider).play(SoundEvent.hint);
    ref.read(analyticsServiceProvider).logEvent('hintUsed', {
      'levelId': session.level.levelNumber,
      'hintLevel': hintLevel,
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      final current = state;
      if (current == null) return;
      if (current.level.levelNumber != session.level.levelNumber) return;
      state = current.copyWith(clearHints: true);
    });
  }

  List<GridPosition> _computeHint(
    LevelDefinition level,
    BoardState board,
    int hintLevel,
  ) {
    // Prefer unsolved color with fewest free neighbors near an endpoint
    final unsolved = level.colors.where((c) {
      final path = board.pathForColor(c);
      return path == null || !path.isComplete;
    }).toList();

    if (unsolved.isEmpty) return const [];

    final color = unsolved.first;
    final endpoints = level.endpointsForColor(color);
    if (endpoints.isEmpty) return const [];

    if (hintLevel == 1) {
      return endpoints.map((e) => e.position).toList();
    }

    // Try solver for a short segment
    final solved = LevelSolver().solve(level, maxNodes: 80000);
    if (solved.solved && solved.paths.containsKey(color)) {
      final path = solved.paths[color]!;
      if (hintLevel == 2 && path.length >= 2) {
        return [path[0], path[1]];
      }
      if (hintLevel >= 3 && path.length >= 4) {
        return path.take(4).toList();
      }
      return path.take(2).toList();
    }

    return [endpoints.first.position];
  }

  void pause() {
    final session = state;
    if (session == null) return;
    if (session.status != GameplayStatus.playing &&
        session.status != GameplayStatus.ready) {
      return;
    }
    _ticker?.cancel();
    state = session.copyWith(status: GameplayStatus.paused);
    _persistSession();
  }

  void resume() {
    final session = state;
    if (session == null || session.status != GameplayStatus.paused) return;
    state = session.copyWith(status: GameplayStatus.playing);
    _startTickerIfNeeded(state!);
  }

  void _startTickerIfNeeded(GameSessionState session) {
    _ticker?.cancel();
    if (session.level.timeLimitSeconds == null) {
      // Still track elapsed for stats
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final s = state;
        if (s == null || s.status != GameplayStatus.playing) return;
        state = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
      });
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      if (s == null || s.status != GameplayStatus.playing) return;
      final remaining = (s.remainingSeconds ?? 0) - 1;
      final elapsed = s.elapsedSeconds + 1;
      if (remaining <= 0) {
        _ticker?.cancel();
        state = s.copyWith(
          remainingSeconds: 0,
          elapsedSeconds: elapsed,
          status: GameplayStatus.failed,
          failReason: ChallengeFailReason.timeUp,
        );
        ref.read(audioManagerProvider).play(SoundEvent.challengeFailed);
        ref.read(analyticsServiceProvider).logEvent('levelFailed', {
          'levelId': s.level.levelNumber,
          'reason': 'timeUp',
        });
        return;
      }
      state = s.copyWith(
        remainingSeconds: remaining,
        elapsedSeconds: elapsed,
      );
    });
  }

  Future<void> _persistSession() async {
    final session = state;
    if (session == null) return;
    if (session.status == GameplayStatus.completed ||
        session.status == GameplayStatus.failed) {
      return;
    }
    await ref
        .read(progressRepositoryProvider)
        .saveSession(session.toSessionJson());
  }

  void clearInvalidFeedback() {
    final session = state;
    if (session == null) return;
    state = session.copyWith(clearInvalidFeedback: true);
  }
}
