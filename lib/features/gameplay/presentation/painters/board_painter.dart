import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/geometry/grid_geometry.dart';
import '../../domain/models/board_state.dart';
import '../../domain/models/color_id.dart';
import '../../domain/models/grid_position.dart';
import '../widgets/sky_style.dart';
import 'sky_paint.dart';

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
    this.flat = false,
  });

  final BoardState board;
  final BoardVisualConfig visual;
  final bool colorAssist;
  final List<GridPosition> hintCells;
  final GridPosition? invalidCell;
  final bool reducedMotion;
  final Offset? fingerPosition;
  final double glowPhase;

  /// Flat white grid with ring-style endpoints (daily challenge look).
  final bool flat;

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
    if (flat) {
      SkyPaint.flatGrid(canvas, size, board.rows, board.columns);
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.045),
      ),
      Paint()..color = SkyStyle.tileGap,
    );
  }

  /// Soft, slightly raised tiles like frosted sugar cubes.
  void _paintGrid(Canvas canvas, GridGeometry geometry) {
    if (flat) return; // drawn with the background
    final endpointTint = <GridPosition, Color>{
      for (final ep in board.level.endpoints)
        ep.position: AppColors.gameplayColor(ep.color),
    };
    final inset = geometry.cellWidth * 0.025;
    final radius = Radius.circular(geometry.cellWidth * 0.12);
    final edge = geometry.cellWidth * 0.035;

    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.columns; c++) {
        final pos = GridPosition(r, c);
        final rect = geometry.cellRect(pos, inset: inset);
        final tint = endpointTint[pos];

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          Paint()
            ..color = tint == null
                ? SkyStyle.tileEdge
                : Color.lerp(SkyStyle.tileEdge, tint, 0.25)!,
        );
        final face = Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom - edge,
        );
        final top = tint == null
            ? SkyStyle.tileTop
            : Color.lerp(SkyStyle.tileTop, tint, 0.12)!;
        final bottom = tint == null
            ? SkyStyle.tileBottom
            : Color.lerp(SkyStyle.tileBottom, tint, 0.2)!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(face, radius),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ).createShader(face),
        );
      }
    }
  }

  void _paintBlocked(Canvas canvas, GridGeometry geometry) {
    for (final cell in board.level.blockedCells) {
      SkyPaint.blockedTile(
        canvas,
        geometry.cellRect(cell, inset: geometry.cellWidth * 0.08),
      );
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
      canvas.drawCircle(center, radius, Paint()..color = AppColors.brandAmber);
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

    final points = <Offset>[for (final c in cells) geometry.cellToCenter(c)];
    if (isActive && finger != null && points.isNotEmpty) {
      points.add(finger);
    }

    final base = AppColors.gameplayColor(color);
    final width =
        geometry.cellWidth * visual.pathWidthFactor * (isActive ? 1.06 : 1.0);

    SkyPaint.pipe(
      canvas,
      points,
      base,
      width,
      glow: !reducedMotion,
      glowAlpha: isActive || isComplete ? 0.45 : 0.3,
      sheenAlpha: isActive ? 0.4 : 0.28,
    );
  }

  void _paintEndpoints(Canvas canvas, GridGeometry geometry) {
    for (final ep in board.level.endpoints) {
      final center = geometry.cellToCenter(ep.position);
      final radius = geometry.cellWidth * visual.endpointRadiusFactor;
      final color = AppColors.gameplayColor(ep.color);
      final path = board.pathForColor(ep.color);
      final connected = path?.isComplete ?? false;
      final isActiveStart =
          board.activeColor == ep.color &&
          board.activePathCells.isNotEmpty &&
          board.activePathCells.first == ep.position;

      if (flat) {
        _paintRingEndpoint(
          canvas,
          center,
          geometry.cellWidth * 0.44,
          ep.color,
          isActiveStart,
        );
      } else {
        if (!reducedMotion && isActiveStart) {
          final pulse = 0.15 + 0.1 * math.sin(glowPhase * math.pi * 2);
          canvas.drawCircle(
            center,
            radius * (1.2 + pulse),
            Paint()..color = color.withValues(alpha: 0.3),
          );
        }

        // Drop shadow
        canvas.drawCircle(
          center + Offset(0, radius * 0.12),
          radius,
          Paint()
            ..color = AppColors.gameplayDark(ep.color).withValues(alpha: 0.45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15),
        );

        // Glossy sphere
        final ball = Rect.fromCircle(center: center, radius: radius);
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.35),
              radius: 1.0,
              colors: [
                Color.lerp(color, Colors.white, 0.3)!,
                color,
                AppColors.gameplayDark(ep.color),
              ],
              stops: const [0.0, 0.6, 1.0],
            ).createShader(ball),
        );

        // Soft inner bubble
        canvas.drawCircle(
          center + Offset(-radius * 0.02, radius * 0.02),
          radius * 0.34,
          Paint()
            ..color = Colors.white.withValues(alpha: connected ? 0.4 : 0.28),
        );

        // Specular highlight
        canvas.save();
        canvas.translate(center.dx - radius * 0.42, center.dy - radius * 0.5);
        canvas.rotate(-0.5);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * 0.55,
            height: radius * 0.32,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
        canvas.restore();
      }

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

  void _paintRingEndpoint(
    Canvas canvas,
    Offset center,
    double radius,
    ColorId id,
    bool active,
  ) {
    SkyPaint.ringEndpoint(
      canvas,
      center,
      radius,
      AppColors.gameplayColor(id),
      pulse: !reducedMotion && active
          ? 0.06 * math.sin(glowPhase * math.pi * 2)
          : 0.0,
    );
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
    final rect = geometry.cellRect(
      invalidCell!,
      inset: geometry.cellWidth * 0.15,
    );
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
        oldDelegate.visual != visual ||
        oldDelegate.flat != flat;
  }
}
