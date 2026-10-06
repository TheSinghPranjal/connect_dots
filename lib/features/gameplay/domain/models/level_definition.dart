import 'package:equatable/equatable.dart';

import 'cell_type.dart';
import 'color_id.dart';
import 'endpoint.dart';
import 'grid_position.dart';

class SpecialTile extends Equatable {
  const SpecialTile({
    required this.position,
    required this.type,
    this.required = false,
    this.direction,
  });

  final GridPosition position;
  final SpecialTileType type;
  final bool required;
  final String? direction;

  @override
  List<Object?> get props => [position, type, required, direction];

  Map<String, dynamic> toJson() => {
        'row': position.row,
        'column': position.column,
        'type': type.name,
        'required': required,
        if (direction != null) 'direction': direction,
      };

  factory SpecialTile.fromJson(Map<String, dynamic> json) => SpecialTile(
        position: GridPosition(json['row'] as int, json['column'] as int),
        type: SpecialTileType.values.byName(json['type'] as String),
        required: json['required'] as bool? ?? false,
        direction: json['direction'] as String?,
      );
}

class LevelDefinition extends Equatable {
  const LevelDefinition({
    required this.levelNumber,
    required this.rows,
    required this.columns,
    required this.endpoints,
    this.blockedCells = const [],
    this.specialTiles = const [],
    this.difficulty = Difficulty.easy,
    this.targetMoves,
    this.timeLimitSeconds,
    this.moveLimit,
    this.objective = LevelObjectiveType.normal,
    this.requiredBonusNodes = 0,
    this.tutorialData,
  });

  final int levelNumber;
  final int rows;
  final int columns;
  final List<Endpoint> endpoints;
  final List<GridPosition> blockedCells;
  final List<SpecialTile> specialTiles;
  final Difficulty difficulty;
  final int? targetMoves;
  final int? timeLimitSeconds;
  final int? moveLimit;
  final LevelObjectiveType objective;
  final int requiredBonusNodes;
  final Map<String, dynamic>? tutorialData;

  int get totalCells => rows * columns;
  int get fillableCellCount => totalCells - blockedCells.length;

  Set<ColorId> get colors => endpoints.map((e) => e.color).toSet();

  int get colorCount => colors.length;

  bool get isChallenge => moveLimit != null || timeLimitSeconds != null;

  bool isBlocked(GridPosition pos) => blockedCells.contains(pos);

  Endpoint? endpointAt(GridPosition pos) {
    for (final e in endpoints) {
      if (e.position == pos) return e;
    }
    return null;
  }

  List<Endpoint> endpointsForColor(ColorId color) =>
      endpoints.where((e) => e.color == color).toList();

  List<SpecialTile> get bonusNodes => specialTiles
      .where((t) => t.type == SpecialTileType.bonusNode)
      .toList();

  @override
  List<Object?> get props => [
        levelNumber,
        rows,
        columns,
        endpoints,
        blockedCells,
        specialTiles,
        difficulty,
        targetMoves,
        timeLimitSeconds,
        moveLimit,
        objective,
        requiredBonusNodes,
      ];

  Map<String, dynamic> toJson() => {
        'level': levelNumber,
        'rows': rows,
        'columns': columns,
        'difficulty': difficulty.name,
        'endpoints': endpoints.map((e) => e.toJson()).toList(),
        'blockedCells': blockedCells.map((p) => p.toJson()).toList(),
        'specialTiles': specialTiles.map((t) => t.toJson()).toList(),
        if (targetMoves != null) 'targetMoves': targetMoves,
        if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
        if (moveLimit != null) 'moveLimit': moveLimit,
        'objective': objective.name,
        'requiredBonusNodes': requiredBonusNodes,
        if (tutorialData != null) 'tutorialData': tutorialData,
      };

  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    final endpointsJson = json['endpoints'] as List<dynamic>;
    final blockedJson = json['blockedCells'] as List<dynamic>? ?? [];
    final specialJson = json['specialTiles'] as List<dynamic>? ?? [];

    return LevelDefinition(
      levelNumber: json['level'] as int,
      rows: json['rows'] as int,
      columns: json['columns'] as int,
      endpoints: endpointsJson
          .map((e) => Endpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      blockedCells: blockedJson
          .map((e) => GridPosition.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialTiles: specialJson
          .map((e) => SpecialTile.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: Difficulty.values.byName(
        json['difficulty'] as String? ?? 'easy',
      ),
      targetMoves: json['targetMoves'] as int?,
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      moveLimit: json['moveLimit'] as int?,
      objective: LevelObjectiveType.values.byName(
        json['objective'] as String? ?? 'normal',
      ),
      requiredBonusNodes: json['requiredBonusNodes'] as int? ?? 0,
      tutorialData: json['tutorialData'] as Map<String, dynamic>?,
    );
  }
}
