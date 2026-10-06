import '../models/color_id.dart';
import '../models/endpoint.dart';
import '../models/grid_position.dart';
import '../models/level_definition.dart';

class SolverResult {
  const SolverResult({
    required this.solved,
    this.paths = const {},
    this.message,
  });

  final bool solved;
  /// color -> ordered cells from endpoint A to B
  final Map<ColorId, List<GridPosition>> paths;
  final String? message;
}

/// Development/test solver for Numberlink-style full-board flows.
/// Uses backtracking with dead-region pruning. Not for per-frame use.
class LevelSolver {
  SolverResult solve(LevelDefinition level, {int maxNodes = 250000}) {
    final rows = level.rows;
    final cols = level.columns;
    final blocked = level.blockedCells.toSet();
    final colors = level.colors.toList();

    // Pair endpoints
    final pairs = <ColorId, (GridPosition, GridPosition)>{};
    for (final color in colors) {
      final eps = level.endpointsForColor(color);
      if (eps.length != 2) {
        return SolverResult(
          solved: false,
          message: 'Color $color does not have exactly 2 endpoints',
        );
      }
      pairs[color] = (eps[0].position, eps[1].position);
    }

    // Grid occupancy: -1 empty, -2 blocked, >=0 color index
    final grid = List.generate(rows, (_) => List.filled(cols, -1));
    for (final b in blocked) {
      if (b.isInside(rows, cols)) grid[b.row][b.column] = -2;
    }

    // Color index map
    final colorIndex = <ColorId, int>{};
    for (var i = 0; i < colors.length; i++) {
      colorIndex[colors[i]] = i;
    }

    // Mark endpoints
    for (final color in colors) {
      final (a, b) = pairs[color]!;
      final idx = colorIndex[color]!;
      grid[a.row][a.column] = idx;
      grid[b.row][b.column] = idx;
    }

    // Sort colors by Manhattan distance ascending (harder first sometimes better)
    colors.sort((a, b) {
      final pa = pairs[a]!;
      final pb = pairs[b]!;
      final da = (pa.$1.row - pa.$2.row).abs() + (pa.$1.column - pa.$2.column).abs();
      final db = (pb.$1.row - pb.$2.row).abs() + (pb.$1.column - pb.$2.column).abs();
      return db.compareTo(da); // longer first
    });

    var nodes = 0;
    final solution = <ColorId, List<GridPosition>>{};

    bool search(int colorIdx) {
      if (nodes++ > maxNodes) return false;
      if (colorIdx >= colors.length) {
        // All colors connected — check fill
        for (var r = 0; r < rows; r++) {
          for (var c = 0; c < cols; c++) {
            if (grid[r][c] == -1) return false;
          }
        }
        return true;
      }

      final color = colors[colorIdx];
      final (start, end) = pairs[color]!;
      final idx = colorIndex[color]!;

      // Clear path cells for this color except endpoints (they stay marked)
      // Actually endpoints already marked; we grow from start.

      final path = <GridPosition>[start];
      final visited = List.generate(rows, (_) => List.filled(cols, false));
      visited[start.row][start.column] = true;

      bool dfs(GridPosition cur) {
        if (nodes++ > maxNodes) return false;
        if (cur == end) {
          // Commit path to grid
          for (final p in path) {
            grid[p.row][p.column] = idx;
          }
          // Quick dead-cell check for remaining empties connectivity
          if (!_remainingFeasible(grid, rows, cols, colors, colorIdx, pairs, colorIndex)) {
            // rollback non-endpoints
            for (final p in path) {
              if (p != start && p != end) grid[p.row][p.column] = -1;
            }
            return false;
          }
          solution[color] = List.from(path);
          if (search(colorIdx + 1)) return true;
          solution.remove(color);
          for (final p in path) {
            if (p != start && p != end) grid[p.row][p.column] = -1;
          }
          return false;
        }

        // Neighbors — prefer toward end
        final neighbors = cur.orthogonalNeighbors
            .where((n) => n.isInside(rows, cols))
            .toList()
          ..sort((a, b) {
            final da = (a.row - end.row).abs() + (a.column - end.column).abs();
            final db = (b.row - end.row).abs() + (b.column - end.column).abs();
            return da.compareTo(db);
          });

        for (final n in neighbors) {
          if (visited[n.row][n.column]) continue;
          final cell = grid[n.row][n.column];
          if (cell == -2) continue; // blocked
          if (n == end) {
            // can always go to own end
          } else if (cell != -1) {
            continue; // occupied by other color or own endpoint wrongly
          }

          visited[n.row][n.column] = true;
          path.add(n);
          if (n != end) grid[n.row][n.column] = idx;

          if (dfs(n)) return true;

          if (n != end) grid[n.row][n.column] = -1;
          path.removeLast();
          visited[n.row][n.column] = false;
        }
        return false;
      }

      return dfs(start);
    }

    final solved = search(0);
    return SolverResult(
      solved: solved,
      paths: Map.unmodifiable(solution),
      message: solved ? null : 'No solution found (nodes=$nodes)',
    );
  }

  bool _remainingFeasible(
    List<List<int>> grid,
    int rows,
    int cols,
    List<ColorId> colors,
    int solvedUpTo,
    Map<ColorId, (GridPosition, GridPosition)> pairs,
    Map<ColorId, int> colorIndex,
  ) {
    // For each unsolved color, endpoints must be connectable through empty + own endpoints
    for (var i = solvedUpTo + 1; i < colors.length; i++) {
      final color = colors[i];
      final (a, b) = pairs[color]!;
      final idx = colorIndex[color]!;
      if (!_canReach(grid, rows, cols, a, b, idx)) return false;
    }

    // No tiny isolated empty regions that can't fit a path (size 1 with no endpoint)
    final visited = List.generate(rows, (_) => List.filled(cols, false));
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (grid[r][c] != -1 || visited[r][c]) continue;
        var size = 0;
        final queue = <GridPosition>[GridPosition(r, c)];
        visited[r][c] = true;
        while (queue.isNotEmpty) {
          final p = queue.removeLast();
          size++;
          for (final n in p.orthogonalNeighbors) {
            if (!n.isInside(rows, cols)) continue;
            if (visited[n.row][n.column]) continue;
            if (grid[n.row][n.column] == -1) {
              visited[n.row][n.column] = true;
              queue.add(n);
            }
          }
        }
        if (size == 0) return false;
      }
    }
    return true;
  }

  bool _canReach(
    List<List<int>> grid,
    int rows,
    int cols,
    GridPosition start,
    GridPosition end,
    int colorIdx,
  ) {
    final visited = List.generate(rows, (_) => List.filled(cols, false));
    final queue = <GridPosition>[start];
    visited[start.row][start.column] = true;
    while (queue.isNotEmpty) {
      final p = queue.removeAt(0);
      if (p == end) return true;
      for (final n in p.orthogonalNeighbors) {
        if (!n.isInside(rows, cols)) continue;
        if (visited[n.row][n.column]) continue;
        final cell = grid[n.row][n.column];
        if (cell == -2) continue;
        if (cell == -1 || n == end || (cell == colorIdx && (n == start || n == end))) {
          visited[n.row][n.column] = true;
          queue.add(n);
        }
      }
    }
    return false;
  }
}

class LevelValidationIssue {
  const LevelValidationIssue(this.message);
  final String message;
}

class LevelValidator {
  LevelValidator({LevelSolver? solver}) : _solver = solver ?? LevelSolver();

  final LevelSolver _solver;

  List<LevelValidationIssue> validateSchema(LevelDefinition level) {
    final issues = <LevelValidationIssue>[];
    if (level.rows < 2 || level.columns < 2) {
      issues.add(const LevelValidationIssue('Board too small'));
    }
    if (level.endpoints.isEmpty) {
      issues.add(const LevelValidationIssue('No endpoints'));
    }

    final byColor = <ColorId, List<Endpoint>>{};
    for (final e in level.endpoints) {
      byColor.putIfAbsent(e.color, () => []).add(e);
      if (!e.position.isInside(level.rows, level.columns)) {
        issues.add(LevelValidationIssue('Endpoint ${e.id} out of bounds'));
      }
      if (level.isBlocked(e.position)) {
        issues.add(LevelValidationIssue('Endpoint ${e.id} on blocked cell'));
      }
    }
    for (final entry in byColor.entries) {
      if (entry.value.length != 2) {
        issues.add(LevelValidationIssue(
          'Color ${entry.key.name} has ${entry.value.length} endpoints',
        ));
      }
    }

    final positions = <GridPosition>{};
    for (final e in level.endpoints) {
      if (!positions.add(e.position)) {
        issues.add(LevelValidationIssue('Duplicate endpoint at ${e.position}'));
      }
    }

    for (final b in level.blockedCells) {
      if (!b.isInside(level.rows, level.columns)) {
        issues.add(LevelValidationIssue('Blocked cell out of bounds: $b'));
      }
    }

    for (final t in level.specialTiles) {
      if (!t.position.isInside(level.rows, level.columns)) {
        issues.add(LevelValidationIssue('Special tile out of bounds'));
      }
      if (level.isBlocked(t.position)) {
        issues.add(const LevelValidationIssue('Special tile on blocked cell'));
      }
    }

    return issues;
  }

  List<LevelValidationIssue> validateSolvable(
    LevelDefinition level, {
    bool runSolver = true,
  }) {
    final issues = validateSchema(level);
    if (issues.isNotEmpty) return issues;

    if (runSolver) {
      final result = _solver.solve(level);
      if (!result.solved) {
        issues.add(LevelValidationIssue(
          'Level ${level.levelNumber} unsolvable: ${result.message}',
        ));
      }
    }
    return issues;
  }
}
