import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/geometry/grid_geometry.dart';
import '../../domain/models/board_state.dart';
import '../../domain/models/color_id.dart';
import '../../domain/models/grid_position.dart';

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.board,
    required this.visual,
    required this.colorAssist,
    required this.hintCells,
    required this.invalidCell,
    required this.reducedMotion,
    this.fingerPosition,
    this.glowPhase = 0,
  });

  final BoardState board;
  final BoardVisualConfig visual;
  final bool colorAssist;
  final List<GridPosition> hintCells;
  final GridPosition? invalidCell;
  final bool reducedMotion;
  final Offset? fingerPosition;
  final double glowPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = GridGeometry(
      origin: Offset.zero,
      boardSize: size.width,
      rows: board.rows,
      columns: board.columns,
    );

    _paintBoardBackground(canvas, size);
    _paintGrid(canvas, geometry);
    _paintBlocked(canvas, geometry);
    _paintBonusNodes(canvas, geometry);
    _paintPaths(canvas, geometry);
    _paintActivePath(canvas, geometry);
    _paintEndpoints(canvas, geometry);
    _paintHints(canvas, geometry);
    _paintInvalid(canvas, geometry);
  }

  void _paintBoardBackground(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = visual.boardFill,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = visual.gridLine.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintGrid(Canvas canvas, GridGeometry geometry) {
    final paint = Paint()
      ..color = visual.gridLine.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    for (var r = 0; r <= board.rows; r++) {
      final y = r * geometry.cellHeight;
      canvas.drawLine(Offset(0, y), Offset(geometry.boardSize, y), paint);
    }
    for (var c = 0; c <= board.columns; c++) {
      final x = c * geometry.cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, geometry.boardSize), paint);
    }
  }

  void _paintBlocked(Canvas canvas, GridGeometry geometry) {
    final paint = Paint()..color = visual.blockedFill.withValues(alpha: 0.55);
    for (final cell in board.level.blockedCells) {
      final rect = geometry.cellRect(cell, inset: geometry.cellWidth * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.2)),
        paint,
      );
      // Hatch
      final hatch = Paint()
        ..color = visual.blockedFill
        ..strokeWidth = 1.5;
      canvas.drawLine(rect.topLeft, rect.bottomRight, hatch);
      canvas.drawLine(rect.topRight, rect.bottomLeft, hatch);
    }
  }

  void _paintBonusNodes(Canvas canvas, GridGeometry geometry) {
    for (final tile in board.level.bonusNodes) {
      if (board.collectedBonusNodes.contains(tile.position)) continue;
      final center = geometry.cellToCenter(tile.position);
      final radius = geometry.cellWidth * 0.14;
      canvas.drawCircle(
        center,
        radius * 1.6,
        Paint()..color = AppColors.brandAmber.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = AppColors.brandAmber,
      );
    }
  }

  void _paintPaths(Canvas canvas, GridGeometry geometry) {
    for (final path in board.paths) {
      _drawPipe(
        canvas,
        geometry,
        path.cells,
        path.color,
        isActive: false,
        isComplete: path.isComplete,
      );
    }
  }

  void _paintActivePath(Canvas canvas, GridGeometry geometry) {
    final color = board.activeColor;
    final cells = board.activePathCells;
    if (color == null || cells.isEmpty) return;

    _drawPipe(
      canvas,
      geometry,
      cells,
      color,
      isActive: true,
      isComplete: false,
      finger: fingerPosition,
    );
  }

  void _drawPipe(
    Canvas canvas,
    GridGeometry geometry,
    List<GridPosition> cells,
    ColorId color, {
    required bool isActive,
    required bool isComplete,
    Offset? finger,
  }) {
    if (cells.isEmpty) return;

    final points = <Offset>[
      for (final c in cells) geometry.cellToCenter(c),
    ];
    if (isActive && finger != null && points.isNotEmpty) {
      points.add(finger);
    }

    final base = AppColors.gameplayColor(color);
    final width = geometry.cellWidth *
        visual.pathWidthFactor *
        (isActive ? 1.08 : 1.0);

    if (!reducedMotion && (isActive || isComplete)) {
      final glow = Paint()
        ..color = AppColors.gameplayGlow(color)
        ..strokeWidth = width * 1.55
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      _strokePoints(canvas, points, glow);
    }

    final body = Paint()
      ..color = isActive ? AppColors.gameplayLight(color) : base
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    _strokePoints(canvas, points, body);

    final core = Paint()
      ..color = Colors.white.withValues(alpha: isActive ? 0.35 : 0.18)
      ..strokeWidth = width * 0.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    _strokePoints(canvas, points, core);
  }

  void _strokePoints(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length == 1) {
      canvas.drawCircle(points.first, paint.strokeWidth / 2, Paint()..color = paint.color);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintEndpoints(Canvas canvas, GridGeometry geometry) {
    for (final ep in board.level.endpoints) {
      final center = geometry.cellToCenter(ep.position);
      final radius = geometry.cellWidth * visual.endpointRadiusFactor;
      final color = AppColors.gameplayColor(ep.color);
      final path = board.pathForColor(ep.color);
      final connected = path?.isComplete ?? false;
      final isActiveStart = board.activeColor == ep.color &&
          board.activePathCells.isNotEmpty &&
          board.activePathCells.first == ep.position;

      if (!reducedMotion) {
        final pulse = isActiveStart ? (0.15 + 0.1 * math.sin(glowPhase * math.pi * 2)) : 0.12;
        canvas.drawCircle(
          center,
          radius * (1.35 + pulse),
          Paint()..color = color.withValues(alpha: 0.28),
        );
      }

      canvas.drawCircle(center, radius, Paint()..color = color);
      canvas.drawCircle(
        center,
        radius * 0.55,
        Paint()..color = Colors.white.withValues(alpha: connected ? 0.85 : 0.55),
      );

      if (colorAssist) {
        final tp = TextPainter(
          text: TextSpan(
            text: ep.color.assistSymbol,
            style: TextStyle(
              color: AppColors.gameplayDark(ep.color),
              fontSize: radius * 0.7,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _paintHints(Canvas canvas, GridGeometry geometry) {
    if (hintCells.isEmpty) return;
    final paint = Paint()
      ..color = AppColors.brandAmber.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final cell in hintCells) {
      final rect = geometry.cellRect(cell, inset: geometry.cellWidth * 0.1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.25)),
        paint,
      );
    }
  }

  void _paintInvalid(Canvas canvas, GridGeometry geometry) {
    if (invalidCell == null) return;
    final rect = geometry.cellRect(invalidCell!, inset: geometry.cellWidth * 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.2)),
      Paint()..color = AppColors.brandCoral.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.colorAssist != colorAssist ||
        oldDelegate.hintCells != hintCells ||
        oldDelegate.invalidCell != invalidCell ||
        oldDelegate.fingerPosition != fingerPosition ||
        oldDelegate.glowPhase != glowPhase ||
        oldDelegate.visual != visual;
  }
}
