import 'package:connect_dots/core/geometry/grid_geometry.dart';
import 'package:connect_dots/features/gameplay/domain/models/color_id.dart';
import 'package:connect_dots/features/gameplay/domain/models/endpoint.dart';
import 'package:connect_dots/features/gameplay/domain/models/grid_position.dart';
import 'package:connect_dots/features/gameplay/domain/models/level_definition.dart';
import 'package:connect_dots/features/gameplay/domain/models/cell_type.dart';
import 'package:connect_dots/features/gameplay/domain/rules/flow_game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GridPosition', () {
    test('adjacency is orthogonal only', () {
      const a = GridPosition(1, 1);
      expect(a.isAdjacentTo(const GridPosition(1, 2)), isTrue);
      expect(a.isAdjacentTo(const GridPosition(2, 1)), isTrue);
      expect(a.isAdjacentTo(const GridPosition(2, 2)), isFalse);
      expect(a.isAdjacentTo(const GridPosition(1, 1)), isFalse);
    });
  });

  group('GridGeometry.interpolateCells', () {
    test('fills skipped cells on fast horizontal drag', () {
      final cells = GridGeometry.interpolateCells(
        const GridPosition(1, 1),
        const GridPosition(1, 4),
      );
      expect(cells, contains(const GridPosition(1, 2)));
      expect(cells, contains(const GridPosition(1, 3)));
      expect(cells.last, const GridPosition(1, 4));
    });
  });

  group('FlowGameEngine', () {
    late FlowGameEngine engine;
    late LevelDefinition level;

    setUp(() {
      engine = FlowGameEngine();
      // 3x2 board, one color — must fill all 6 cells
      // Path solution: (0,0)-(0,1)-(0,2)-(1,2)-(1,1)-(1,0)
      level = const LevelDefinition(
        levelNumber: 1,
        rows: 2,
        columns: 3,
        difficulty: Difficulty.tutorial,
        targetMoves: 1,
        endpoints: [
          Endpoint(
            id: 'red_a',
            color: ColorId.red,
            position: GridPosition(0, 0),
          ),
          Endpoint(
            id: 'red_b',
            color: ColorId.red,
            position: GridPosition(1, 0),
          ),
        ],
      );
    });

    test('connecting without fill is not complete', () {
      var board = engine.createBoard(level);
      board = engine.startPath(board, const GridPosition(0, 0)).board;
      // Direct short path leaving empties: down to (1,0) — adjacent and completes pair
      board = engine.extendPath(board, const GridPosition(1, 0)).board;
      expect(engine.areAllPairsConnected(board), isTrue);
      expect(engine.isBoardFilled(board), isFalse);
      expect(engine.isLevelComplete(board), isFalse);
    });

    test('full fill wins', () {
      var board = engine.createBoard(level);
      board = engine.startPath(board, const GridPosition(0, 0)).board;
      for (final p in const [
        GridPosition(0, 1),
        GridPosition(0, 2),
        GridPosition(1, 2),
        GridPosition(1, 1),
        GridPosition(1, 0),
      ]) {
        board = engine.extendPath(board, p).board;
      }
      expect(engine.isLevelComplete(board), isTrue);
    });

    test('backtracking truncates path', () {
      var board = engine.createBoard(level);
      board = engine.startPath(board, const GridPosition(0, 0)).board;
      board = engine.extendPath(board, const GridPosition(0, 1)).board;
      board = engine.extendPath(board, const GridPosition(0, 2)).board;
      expect(board.activePathCells.length, 3);
      board = engine.extendPath(board, const GridPosition(0, 1)).board;
      expect(board.activePathCells.length, 2);
      expect(board.activePathCells.last, const GridPosition(0, 1));
    });

    test('blocked cells are rejected and not required for fill', () {
      final blockedLevel = LevelDefinition(
        levelNumber: 2,
        rows: 2,
        columns: 3,
        difficulty: Difficulty.easy,
        blockedCells: const [GridPosition(0, 1)],
        endpoints: const [
          Endpoint(
            id: 'blue_a',
            color: ColorId.blue,
            position: GridPosition(0, 0),
          ),
          Endpoint(
            id: 'blue_b',
            color: ColorId.blue,
            position: GridPosition(1, 0),
          ),
        ],
      );
      // This level may be unsolvable — just test blocked rejection
      var board = engine.createBoard(blockedLevel);
      board = engine.startPath(board, const GridPosition(0, 0)).board;
      final result = engine.extendPath(board, const GridPosition(0, 1));
      expect(result.feedback, EngineFeedback.invalidMove);
      expect(blockedLevel.fillableCellCount, 5);
    });

    test('diagonal movement is not taken directly', () {
      var board = engine.createBoard(level);
      board = engine.startPath(board, const GridPosition(0, 0)).board;
      // Jump to diagonal — engine walks orthogonally via column then row
      final result = engine.extendPath(board, const GridPosition(1, 1));
      // Should have processed (0,1) then (1,1)
      expect(result.board.activePathCells, isNotEmpty);
      for (var i = 1; i < result.board.activePathCells.length; i++) {
        expect(
          result.board.activePathCells[i - 1]
              .isAdjacentTo(result.board.activePathCells[i]),
          isTrue,
        );
      }
    });

    test('star calculation', () {
      expect(
        engine.calculateStars(
          targetMoves: 10,
          movesUsed: 9,
          usedHint: false,
          wasPerfect: true,
          restarted: false,
        ),
        3,
      );
      expect(
        engine.calculateStars(
          targetMoves: 10,
          movesUsed: 12,
          usedHint: false,
          wasPerfect: false,
          restarted: false,
        ),
        2,
      );
      expect(
        engine.calculateStars(
          targetMoves: 10,
          movesUsed: 17,
          usedHint: true,
          wasPerfect: false,
          restarted: true,
        ),
        1,
      );
    });
  });
}
