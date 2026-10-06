import 'package:equatable/equatable.dart';

/// Grid coordinates. Row increases downward, column increases rightward.
class GridPosition extends Equatable {
  const GridPosition(this.row, this.column);

  final int row;
  final int column;

  GridPosition get up => GridPosition(row - 1, column);
  GridPosition get down => GridPosition(row + 1, column);
  GridPosition get left => GridPosition(row, column - 1);
  GridPosition get right => GridPosition(row, column + 1);

  List<GridPosition> get orthogonalNeighbors => [up, down, left, right];

  bool isAdjacentTo(GridPosition other) {
    final dr = (row - other.row).abs();
    final dc = (column - other.column).abs();
    return (dr + dc) == 1;
  }

  bool isInside(int rows, int columns) =>
      row >= 0 && column >= 0 && row < rows && column < columns;

  @override
  List<Object?> get props => [row, column];

  @override
  String toString() => '($row,$column)';

  Map<String, dynamic> toJson() => {'row': row, 'column': column};

  factory GridPosition.fromJson(Map<String, dynamic> json) =>
      GridPosition(json['row'] as int, json['column'] as int);
}
