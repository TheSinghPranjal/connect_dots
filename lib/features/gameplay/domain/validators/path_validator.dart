import '../models/board_state.dart';
import '../models/color_id.dart';
import '../models/flow_path.dart';
import '../models/grid_position.dart';

enum PathInvalidReason {
  outOfBounds,
  blocked,
  diagonal,
  wrongEndpoint,
  selfLoop,
  empty,
  notAdjacent,
}

class PathValidationResult {
  const PathValidationResult({
    required this.isValid,
    this.reason,
    this.conflictCell,
    this.conflictingColor,
    this.reachedEndpoint = false,
    this.reachedEndpointId,
  });

  final bool isValid;
  final PathInvalidReason? reason;
  final GridPosition? conflictCell;
  final ColorId? conflictingColor;
  final bool reachedEndpoint;
  final String? reachedEndpointId;

  factory PathValidationResult.valid({
    bool reachedEndpoint = false,
    String? reachedEndpointId,
  }) =>
      PathValidationResult(
        isValid: true,
        reachedEndpoint: reachedEndpoint,
        reachedEndpointId: reachedEndpointId,
      );

  factory PathValidationResult.invalid(
    PathInvalidReason reason, {
    GridPosition? conflictCell,
    ColorId? conflictingColor,
  }) =>
      PathValidationResult(
        isValid: false,
        reason: reason,
        conflictCell: conflictCell,
        conflictingColor: conflictingColor,
      );
}

class PathValidator {
  const PathValidator();

  PathValidationResult validatePath(FlowPath path, BoardState board) {
    if (path.cells.isEmpty) {
      return PathValidationResult.invalid(PathInvalidReason.empty);
    }

    for (var i = 0; i < path.cells.length; i++) {
      final cell = path.cells[i];
      if (!cell.isInside(board.rows, board.columns)) {
        return PathValidationResult.invalid(
          PathInvalidReason.outOfBounds,
          conflictCell: cell,
        );
      }
      if (board.level.isBlocked(cell)) {
        return PathValidationResult.invalid(
          PathInvalidReason.blocked,
          conflictCell: cell,
        );
      }
      if (i > 0 && !path.cells[i - 1].isAdjacentTo(cell)) {
        return PathValidationResult.invalid(
          PathInvalidReason.notAdjacent,
          conflictCell: cell,
        );
      }
    }

    // No duplicate cells (self-intersection)
    final seen = <GridPosition>{};
    for (final cell in path.cells) {
      if (!seen.add(cell)) {
        return PathValidationResult.invalid(
          PathInvalidReason.selfLoop,
          conflictCell: cell,
        );
      }
    }

    if (path.isComplete) {
      final endpoints = board.level.endpointsForColor(path.color);
      if (endpoints.length != 2) {
        return PathValidationResult.invalid(PathInvalidReason.wrongEndpoint);
      }
      final start = path.cells.first;
      final end = path.cells.last;
      final positions = endpoints.map((e) => e.position).toSet();
      if (!positions.contains(start) || !positions.contains(end)) {
        return PathValidationResult.invalid(PathInvalidReason.wrongEndpoint);
      }
      return PathValidationResult.valid(
        reachedEndpoint: true,
        reachedEndpointId: endpoints
            .firstWhere((e) => e.position == end)
            .id,
      );
    }

    return PathValidationResult.valid();
  }

  PathValidationResult canEnterCell({
    required BoardState board,
    required ColorId color,
    required GridPosition from,
    required GridPosition to,
    required List<GridPosition> currentPath,
  }) {
    if (!to.isInside(board.rows, board.columns)) {
      return PathValidationResult.invalid(
        PathInvalidReason.outOfBounds,
        conflictCell: to,
      );
    }
    if (board.level.isBlocked(to)) {
      return PathValidationResult.invalid(
        PathInvalidReason.blocked,
        conflictCell: to,
      );
    }
    if (!from.isAdjacentTo(to)) {
      return PathValidationResult.invalid(
        PathInvalidReason.notAdjacent,
        conflictCell: to,
      );
    }

    // Backtrack into own path is handled by engine, not invalid.
    if (currentPath.contains(to)) {
      return PathValidationResult.valid();
    }

    final endpoint = board.level.endpointAt(to);
    if (endpoint != null && endpoint.color != color) {
      return PathValidationResult.invalid(
        PathInvalidReason.wrongEndpoint,
        conflictCell: to,
        conflictingColor: endpoint.color,
      );
    }

    final owner = _ownerExcludingActive(board, to, color);
    if (owner != null && owner != color) {
      return PathValidationResult.invalid(
        PathInvalidReason.selfLoop, // reused as collision signal via conflict
        conflictCell: to,
        conflictingColor: owner,
      );
    }

    if (endpoint != null && endpoint.color == color) {
      return PathValidationResult.valid(
        reachedEndpoint: true,
        reachedEndpointId: endpoint.id,
      );
    }

    return PathValidationResult.valid();
  }

  ColorId? _ownerExcludingActive(
    BoardState board,
    GridPosition pos,
    ColorId activeColor,
  ) {
    for (final path in board.paths) {
      if (path.color == activeColor) continue;
      if (path.contains(pos)) return path.color;
    }
    return null;
  }
}
