import 'package:equatable/equatable.dart';

import 'color_id.dart';
import 'grid_position.dart';

class Endpoint extends Equatable {
  const Endpoint({
    required this.id,
    required this.color,
    required this.position,
  });

  final String id;
  final ColorId color;
  final GridPosition position;

  @override
  List<Object?> get props => [id, color, position];

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.name,
        'row': position.row,
        'column': position.column,
      };

  factory Endpoint.fromJson(Map<String, dynamic> json) => Endpoint(
        id: json['id'] as String,
        color: ColorId.tryParse(json['color'] as String)!,
        position: GridPosition(json['row'] as int, json['column'] as int),
      );
}
