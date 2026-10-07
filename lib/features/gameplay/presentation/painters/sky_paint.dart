import 'package:flutter/material.dart';

/// Canvas drawing shared by the game board and the tutorial demos.
class SkyPaint {
  SkyPaint._();

  static Color _dark(Color c) => Color.lerp(c, Colors.black, 0.25)!;

  static Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  /// Glossy tube through [points]: soft glow, saturated rim, lighter core and
  /// a specular streak.
  static void pipe(
    Canvas canvas,
    List<Offset> points,
    Color base,
    double width, {
    bool glow = true,
    double glowAlpha = 0.3,
    double sheenAlpha = 0.28,
  }) {
    if (points.isEmpty) return;
    if (glow) {
      strokePoints(
        canvas,
        points,
        _stroke(base.withValues(alpha: glowAlpha), width * 1.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.25),
      );
    }
    strokePoints(canvas, points, _stroke(base, width));
    strokePoints(
      canvas,
      points,
      _stroke(Color.lerp(base, Colors.white, 0.2)!, width * 0.62),
    );
    strokePoints(
      canvas,
      points,
      _stroke(Colors.white.withValues(alpha: sheenAlpha), width * 0.18),
      offset: Offset(-width * 0.12, -width * 0.12),
    );
  }

  static void strokePoints(
    Canvas canvas,
    List<Offset> points,
    Paint paint, {
    Offset offset = Offset.zero,
  }) {
    if (points.length == 1) {
      canvas.drawCircle(
        points.first + offset,
        paint.strokeWidth / 2,
        Paint()
          ..color = paint.color
          ..maskFilter = paint.maskFilter,
      );
      return;
    }
    final path = Path()
      ..moveTo(points.first.dx + offset.dx, points.first.dy + offset.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx + offset.dx, points[i].dy + offset.dy);
    }
    canvas.drawPath(path, paint);
  }

  /// Glossy disc with a pale halo and a light core. [pulse] grows the halo.
  static void ringEndpoint(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double pulse = 0,
  }) {
    final dark = _dark(color);
    canvas.drawCircle(
      center,
      radius * (1.0 + pulse),
      Paint()..color = Color.lerp(color, Colors.white, 0.62)!,
    );
    final disc = radius * 0.74;
    canvas.drawCircle(
      center + Offset(0, disc * 0.06),
      disc,
      Paint()..color = dark.withValues(alpha: 0.5),
    );
    canvas.drawCircle(
      center,
      disc,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [Color.lerp(color, Colors.white, 0.25)!, color, dark],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: disc)),
    );
    final core = disc * 0.45;
    canvas.drawCircle(
      center,
      core,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [
            Color.lerp(color, Colors.white, 0.75)!,
            Color.lerp(color, Colors.white, 0.3)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: core)),
    );
    canvas.drawCircle(
      center + Offset(-core * 0.35, -core * 0.4),
      core * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  /// Grey stone tile marked with an X.
  static void blockedTile(Canvas canvas, Rect rect) {
    final radius = Radius.circular(rect.width * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 2)), radius),
      Paint()..color = const Color(0xFF7D8696),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC9CFD9), Color(0xFF9CA5B4)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF8A93A3),
    );
    final x = Paint()
      ..color = const Color(0xFF7A8393)
      ..strokeWidth = 1.6;
    final inner = rect.deflate(rect.width * 0.06);
    canvas.drawLine(inner.topLeft, inner.bottomRight, x);
    canvas.drawLine(inner.topRight, inner.bottomLeft, x);
  }

  /// Flat white board with thin grid lines.
  static void flatGrid(Canvas canvas, Size size, int rows, int columns) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.03),
      ),
      Paint()..color = const Color(0xFFFBFCFF),
    );
    final line = Paint()
      ..color = const Color(0xFFD8DFEC)
      ..strokeWidth = 1.2;
    for (var r = 1; r < rows; r++) {
      final y = r * size.height / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (var c = 1; c < columns; c++) {
      final x = c * size.width / columns;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }
}
