import 'dart:math' as math;
import 'dart:ui';

import '../../features/gameplay/domain/models/grid_position.dart';

/// Converts between screen coordinates and grid cells.
class GridGeometry {
  const GridGeometry({
    required this.origin,
    required this.boardSize,
    required this.rows,
    required this.columns,
  });

  final Offset origin;
  final double boardSize;
  final int rows;
  final int columns;

  double get cellWidth => boardSize / columns;
  double get cellHeight => boardSize / rows;

  bool isInsideBoard(Offset local) {
    return local.dx >= origin.dx &&
        local.dy >= origin.dy &&
        local.dx < origin.dx + boardSize &&
        local.dy < origin.dy + boardSize;
  }

  GridPosition? screenToCell(Offset local) {
    if (!isInsideBoard(local)) return null;
    final col = ((local.dx - origin.dx) / cellWidth).floor();
    final row = ((local.dy - origin.dy) / cellHeight).floor();
    final pos = GridPosition(row, col);
    if (!pos.isInside(rows, columns)) return null;
    return pos;
  }

  Offset cellToCenter(GridPosition pos) {
    return Offset(
      origin.dx + (pos.column + 0.5) * cellWidth,
      origin.dy + (pos.row + 0.5) * cellHeight,
    );
  }

  Rect cellRect(GridPosition pos, {double inset = 0}) {
    return Rect.fromLTWH(
      origin.dx + pos.column * cellWidth + inset,
      origin.dy + pos.row * cellHeight + inset,
      cellWidth - inset * 2,
      cellHeight - inset * 2,
    );
  }

  double distanceToCell(Offset local, GridPosition pos) {
    final center = cellToCenter(pos);
    return (local - center).distance;
  }

  /// Bresenham-style traversal of cells between two positions.
  /// Ensures fast drags do not skip cells.
  static List<GridPosition> interpolateCells(
    GridPosition from,
    GridPosition to,
  ) {
    if (from == to) return [to];

    final cells = <GridPosition>[];
    var x0 = from.column;
    var y0 = from.row;
    final x1 = to.column;
    final y1 = to.row;

    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var err = dx - dy;

    while (true) {
      cells.add(GridPosition(y0, x0));
      if (x0 == x1 && y0 == y1) break;
      final e2 = 2 * err;
      // Prefer orthogonal steps; when both needed, step one axis at a time.
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
        cells.add(GridPosition(y0, x0));
        if (x0 == x1 && y0 == y1) break;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }

    // Deduplicate while preserving order, and keep only orthogonal steps.
    final result = <GridPosition>[];
    GridPosition? prev;
    for (final cell in cells) {
      if (prev == null) {
        result.add(cell);
        prev = cell;
        continue;
      }
      if (cell == prev) continue;
      if (!prev.isAdjacentTo(cell)) {
        // Insert Manhattan path for any diagonal jump.
        result.addAll(_manhattanBridge(prev, cell).skip(1));
      } else {
        result.add(cell);
      }
      prev = cell;
    }
    return result;
  }

  static List<GridPosition> _manhattanBridge(GridPosition a, GridPosition b) {
    final path = <GridPosition>[a];
    var r = a.row;
    var c = a.column;
    while (c != b.column) {
      c += c < b.column ? 1 : -1;
      path.add(GridPosition(r, c));
    }
    while (r != b.row) {
      r += r < b.row ? 1 : -1;
      path.add(GridPosition(r, c));
    }
    return path;
  }

  static List<GridPosition> getAdjacentCells(
    GridPosition pos,
    int rows,
    int columns,
  ) {
    return pos.orthogonalNeighbors
        .where((n) => n.isInside(rows, columns))
        .toList();
  }

  static double boardSizeFor({
    required double availableWidth,
    required double availableHeight,
    required double maxSize,
    required double padding,
  }) {
    final w = availableWidth - padding * 2;
    final h = availableHeight - padding * 2;
    return math.min(math.min(w, h), maxSize);
  }
}
