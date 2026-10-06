import 'package:equatable/equatable.dart';

import 'color_id.dart';
import 'grid_position.dart';

class FlowPath extends Equatable {
  const FlowPath({
    required this.color,
    required this.cells,
    this.startEndpointId,
    this.endEndpointId,
    this.isComplete = false,
  });

  final ColorId color;
  final List<GridPosition> cells;
  final String? startEndpointId;
  final String? endEndpointId;
  final bool isComplete;

  bool get isEmpty => cells.isEmpty;
  int get length => cells.length;
  GridPosition? get head => cells.isEmpty ? null : cells.last;
  GridPosition? get start => cells.isEmpty ? null : cells.first;

  bool contains(GridPosition pos) => cells.contains(pos);

  int indexOf(GridPosition pos) => cells.indexOf(pos);

  FlowPath copyWith({
    ColorId? color,
    List<GridPosition>? cells,
    String? startEndpointId,
    String? endEndpointId,
    bool? isComplete,
    bool clearEndEndpoint = false,
  }) {
    return FlowPath(
      color: color ?? this.color,
      cells: cells ?? this.cells,
      startEndpointId: startEndpointId ?? this.startEndpointId,
      endEndpointId:
          clearEndEndpoint ? null : (endEndpointId ?? this.endEndpointId),
      isComplete: isComplete ?? this.isComplete,
    );
  }

  FlowPath truncateTo(int inclusiveIndex) {
    if (inclusiveIndex < 0 || inclusiveIndex >= cells.length) {
      return this;
    }
    return copyWith(
      cells: List.unmodifiable(cells.sublist(0, inclusiveIndex + 1)),
      isComplete: false,
      clearEndEndpoint: true,
    );
  }

  @override
  List<Object?> get props =>
      [color, cells, startEndpointId, endEndpointId, isComplete];
}
