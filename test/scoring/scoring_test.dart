import 'package:connect_dots/features/gameplay/domain/models/color_id.dart';
import 'package:connect_dots/features/gameplay/domain/models/endpoint.dart';
import 'package:connect_dots/features/gameplay/domain/models/grid_position.dart';
import 'package:connect_dots/features/gameplay/domain/models/level_definition.dart';
import 'package:connect_dots/features/gameplay/domain/models/level_result.dart';
import 'package:connect_dots/features/gameplay/domain/rules/flow_game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score and coins are non-negative', () {
    final engine = FlowGameEngine();
    const level = LevelDefinition(
      levelNumber: 1,
      rows: 2,
      columns: 2,
      endpoints: [
        Endpoint(id: 'a', color: ColorId.red, position: GridPosition(0, 0)),
        Endpoint(id: 'b', color: ColorId.red, position: GridPosition(1, 1)),
      ],
      targetMoves: 1,
    );
    var board = engine.createBoard(level);
    board = engine.startPath(board, const GridPosition(0, 0)).board;
    board = engine.extendPath(board, const GridPosition(0, 1)).board;
    board = engine.extendPath(board, const GridPosition(1, 1)).board;

    final result = engine.calculateResult(
      level: level,
      board: board,
      score: const LevelScore(total: 10),
      movesUsed: 5,
      timeUsedSeconds: 12,
      usedHint: true,
      wasPerfect: false,
      restarted: true,
    );
    expect(result.score, greaterThanOrEqualTo(0));
    expect(result.coinsEarned, greaterThanOrEqualTo(0));
    expect(result.stars, inInclusiveRange(0, 3));
  });
}
