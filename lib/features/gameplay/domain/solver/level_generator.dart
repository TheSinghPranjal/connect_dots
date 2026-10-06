import 'dart:math';

import '../models/cell_type.dart';
import '../models/color_id.dart';
import '../models/endpoint.dart';
import '../models/grid_position.dart';
import '../models/level_definition.dart';

/// Generates deterministic full-board flow puzzles in O(board size).
///
/// Strategy:
/// 1. Build a serpentine covering the open rectangle.
/// 2. Split into color segments.
/// 3. Optionally "punch" interior cells into blocked tiles by splitting
///    segments (keeps a known solution, no Hamiltonian search).
class LevelGenerator {
  static const _palette = ColorId.values;

  LevelDefinition? generate({
    required int levelNumber,
    required int rows,
    required int columns,
    required int colorCount,
    required Difficulty difficulty,
    required int seed,
    List<GridPosition> blockedCells = const [],
    int? targetMoves,
    int? moveLimit,
    int? timeLimitSeconds,
    LevelObjectiveType objective = LevelObjectiveType.normal,
    int requiredBonusNodes = 0,
    List<SpecialTile> specialTiles = const [],
    int maxAttempts = 40,
  }) {
    final desiredBlocks = blockedCells.length;
    // Need room: each block consumes one cell and adds one color split.
    final baseColors = max(1, colorCount - desiredBlocks);
    if (rows * columns < baseColors * 2 + desiredBlocks) return null;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = Random(seed + attempt * 7919);
      final snake = _serpentine(rows, columns, rng.nextBool());
      final path = rng.nextBool() ? snake : snake.reversed.toList();

      final segments = _splitSnake(path, baseColors, rng);
      if (segments == null) continue;

      final blocks = <GridPosition>[];
      var working = segments.map((s) => List<GridPosition>.from(s)).toList();

      // Punch preferred blocked positions first, then any interior.
      final preferred = List<GridPosition>.from(blockedCells)..shuffle(rng);
      for (final target in preferred) {
        if (blocks.length >= desiredBlocks) break;
        if (_punchBlock(working, blocks, preferred: target, rng: rng)) {
          continue;
        }
      }
      while (blocks.length < desiredBlocks) {
        if (!_punchBlock(working, blocks, rng: rng)) break;
      }

      // If we could not place enough blocks, still emit a valid open/partial puzzle.
      if (working.length > _palette.length) continue;
      if (working.any((s) => s.length < 2)) continue;

      final endpoints = <Endpoint>[];
      for (var i = 0; i < working.length; i++) {
        final color = _palette[i % _palette.length];
        final seg = working[i];
        endpoints.add(Endpoint(
          id: '${color.name}_a_l$levelNumber',
          color: color,
          position: seg.first,
        ));
        endpoints.add(Endpoint(
          id: '${color.name}_b_l$levelNumber',
          color: color,
          position: seg.last,
        ));
      }

      final fillable = <GridPosition>[];
      final blockSet = blocks.toSet();
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < columns; c++) {
          final p = GridPosition(r, c);
          if (!blockSet.contains(p)) fillable.add(p);
        }
      }

      final tiles = List<SpecialTile>.from(specialTiles);
      if (requiredBonusNodes > 0 && tiles.isEmpty) {
        final candidates = fillable
            .where((p) => !endpoints.any((e) => e.position == p))
            .toList()
          ..shuffle(rng);
        for (var i = 0; i < requiredBonusNodes && i < candidates.length; i++) {
          tiles.add(SpecialTile(
            position: candidates[i],
            type: SpecialTileType.bonusNode,
            required: objective == LevelObjectiveType.bonusCollection,
          ));
        }
      }

      return LevelDefinition(
        levelNumber: levelNumber,
        rows: rows,
        columns: columns,
        endpoints: List.unmodifiable(endpoints),
        blockedCells: List.unmodifiable(blocks),
        specialTiles: List.unmodifiable(tiles),
        difficulty: difficulty,
        targetMoves: targetMoves ?? working.length + (working.length ~/ 2),
        moveLimit: moveLimit,
        timeLimitSeconds: timeLimitSeconds,
        objective: objective,
        requiredBonusNodes: requiredBonusNodes,
      );
    }
    return null;
  }

  /// Remove an interior cell from a segment, splitting it into two paths.
  bool _punchBlock(
    List<List<GridPosition>> segments,
    List<GridPosition> blocks, {
    GridPosition? preferred,
    required Random rng,
  }) {
    final candidates = <(int segIndex, int cellIndex)>[];
    for (var s = 0; s < segments.length; s++) {
      final seg = segments[s];
      if (seg.length < 3) continue;
      for (var i = 1; i < seg.length - 1; i++) {
        if (preferred == null || seg[i] == preferred) {
          candidates.add((s, i));
        }
      }
    }
    if (candidates.isEmpty && preferred != null) {
      // preferred not available as interior — try any
      return _punchBlock(segments, blocks, rng: rng);
    }
    if (candidates.isEmpty) return false;

    final pick = candidates[rng.nextInt(candidates.length)];
    final seg = segments[pick.$1];
    final idx = pick.$2;
    final blocked = seg[idx];
    final left = seg.sublist(0, idx);
    final right = seg.sublist(idx + 1);
    if (left.length < 2 || right.length < 2) return false;

    segments.removeAt(pick.$1);
    segments.add(left);
    segments.add(right);
    blocks.add(blocked);
    return true;
  }

  List<GridPosition> _serpentine(int rows, int columns, bool flip) {
    final path = <GridPosition>[];
    for (var r = 0; r < rows; r++) {
      if ((r.isEven && !flip) || (r.isOdd && flip)) {
        for (var c = 0; c < columns; c++) {
          path.add(GridPosition(r, c));
        }
      } else {
        for (var c = columns - 1; c >= 0; c--) {
          path.add(GridPosition(r, c));
        }
      }
    }
    return path;
  }

  List<List<GridPosition>>? _splitSnake(
    List<GridPosition> snake,
    int colorCount,
    Random rng,
  ) {
    final n = snake.length;
    if (n < colorCount * 2) return null;

    final cuts = <int>[0];
    var remaining = n;
    var colorsLeft = colorCount;

    for (var i = 0; i < colorCount - 1; i++) {
      const minNeed = 2;
      final maxForThis = remaining - (colorsLeft - 1) * 2;
      if (maxForThis < minNeed) return null;

      final fair = remaining ~/ colorsLeft;
      var len = (fair + rng.nextInt(3) - 1).clamp(minNeed, maxForThis);
      if (rng.nextDouble() < 0.3) {
        len = (fair + rng.nextInt(max(1, maxForThis - fair + 1)))
            .clamp(minNeed, maxForThis);
      }

      cuts.add(cuts.last + len);
      remaining -= len;
      colorsLeft--;
    }
    cuts.add(n);

    final segments = <List<GridPosition>>[];
    for (var i = 0; i < colorCount; i++) {
      final seg = snake.sublist(cuts[i], cuts[i + 1]);
      if (seg.length < 2) return null;
      segments.add(rng.nextBool() ? seg.reversed.toList() : seg);
    }
    return segments;
  }
}
