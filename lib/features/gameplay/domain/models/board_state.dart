import 'package:equatable/equatable.dart';

import 'color_id.dart';
import 'flow_path.dart';
import 'grid_position.dart';
import 'level_definition.dart';

/// Occupancy map for the board. Immutable.
class BoardState extends Equatable {
  const BoardState({
    required this.level,
    required this.paths,
    this.activeColor,
    this.activePathCells = const [],
    this.collectedBonusNodes = const {},
    this.pointerPreview,
  });

  final LevelDefinition level;
  final List<FlowPath> paths;
  final ColorId? activeColor;
  final List<GridPosition> activePathCells;
  final Set<GridPosition> collectedBonusNodes;
  final GridPosition? pointerPreview;

  int get rows => level.rows;
  int get columns => level.columns;
  int get fillableCellCount => level.fillableCellCount;

  /// Color owning a cell, or null if empty/blocked.
  ColorId? ownerAt(GridPosition pos) {
    if (level.isBlocked(pos)) return null;
    for (final path in paths) {
      if (path.contains(pos)) return path.color;
    }
    if (activePathCells.contains(pos) && activeColor != null) {
      return activeColor;
    }
    return null;
  }

  bool isOccupied(GridPosition pos) => ownerAt(pos) != null;

  bool isEndpoint(GridPosition pos) => level.endpointAt(pos) != null;

  FlowPath? pathForColor(ColorId color) {
    for (final p in paths) {
      if (p.color == color) return p;
    }
    return null;
  }

  int get occupiedFillableCells {
    final occupied = <GridPosition>{};
    for (final path in paths) {
      for (final cell in path.cells) {
        if (!level.isBlocked(cell)) occupied.add(cell);
      }
    }
    for (final cell in activePathCells) {
      if (!level.isBlocked(cell)) occupied.add(cell);
    }
    return occupied.length;
  }

  double get coveragePercent {
    if (fillableCellCount == 0) return 0;
    return occupiedFillableCells / fillableCellCount * 100;
  }

  bool get allFillableCellsOccupied =>
      occupiedFillableCells == fillableCellCount;

  bool get allPairsConnected {
    final colors = level.colors;
    for (final color in colors) {
      final path = pathForColor(color);
      if (path == null || !path.isComplete) return false;
    }
    return true;
  }

  BoardState copyWith({
    LevelDefinition? level,
    List<FlowPath>? paths,
    ColorId? activeColor,
    List<GridPosition>? activePathCells,
    Set<GridPosition>? collectedBonusNodes,
    GridPosition? pointerPreview,
    bool clearActive = false,
    bool clearPointerPreview = false,
  }) {
    return BoardState(
      level: level ?? this.level,
      paths: paths ?? this.paths,
      activeColor: clearActive ? null : (activeColor ?? this.activeColor),
      activePathCells:
          clearActive ? const [] : (activePathCells ?? this.activePathCells),
      collectedBonusNodes: collectedBonusNodes ?? this.collectedBonusNodes,
      pointerPreview: clearPointerPreview
          ? null
          : (pointerPreview ?? this.pointerPreview),
    );
  }

  factory BoardState.initial(LevelDefinition level) => BoardState(
        level: level,
        paths: const [],
      );

  @override
  List<Object?> get props => [
        level,
        paths,
        activeColor,
        activePathCells,
        collectedBonusNodes,
        pointerPreview,
      ];
}
