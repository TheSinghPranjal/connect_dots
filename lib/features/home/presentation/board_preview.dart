import 'package:flutter/material.dart';

import '../../gameplay/presentation/widgets/sky_style.dart';

/// Decorative tilted mini puzzle shown on the home screen.
class BoardPreview extends StatelessWidget {
  const BoardPreview({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final thickness = size * 0.06;
    final radius = BorderRadius.circular(size * 0.09);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0018)
        ..rotateX(0.5)
        ..rotateZ(-0.12),
      child: SizedBox(
        width: size,
        height: size + thickness,
        child: Stack(
          children: [
            // Slab side, visible below the face.
            Positioned(
              left: 0,
              right: 0,
              top: thickness,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: const Color(0xFFD7DCEA),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55284B2A),
                      blurRadius: 24,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: size,
              child: Container(
                padding: EdgeInsets.all(size * 0.07),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF3F1F8)],
                  ),
                ),
                child: const CustomPaint(painter: _PreviewPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter();

  static const _n = 5;
  static const _red = Color(0xFFFF2D68);
  static const _green = Color(0xFF3DCC3A);
  static const _blue = Color(0xFF2F7BFF);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    Offset at(int r, int c) => Offset((c + 0.5) * cell, (r + 0.5) * cell);

    _paintTiles(canvas, size, cell);

    final red = [at(0, 1), at(0, 0), at(4, 0), at(4, 3)];
    final green = [at(0, 2), at(0, 4), at(1, 4), at(1, 2)];
    final blue = [at(2, 1), at(3, 1), at(3, 4)];

    for (final (points, color) in [
      (red, _red),
      (green, _green),
      (blue, _blue),
    ]) {
      _pipe(canvas, points, color, cell * 0.36);
    }
    for (final (center, color) in [
      (at(0, 1), _red),
      (at(4, 0), _red),
      (at(0, 2), _green),
      (at(1, 2), _green),
      (at(2, 1), _blue),
      (at(3, 4), _blue),
    ]) {
      _ball(canvas, center, cell * 0.42, color);
    }
  }

  void _paintTiles(Canvas canvas, Size size, double cell) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * 0.2)),
      Paint()..color = const Color(0xFFF1E4EC),
    );
    final inset = cell * 0.05;
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final rect = Rect.fromLTWH(
          c * cell + inset,
          r * cell + inset,
          cell - inset * 2,
          cell - inset * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.14)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFBFD), SkyStyle.tileBottom],
            ).createShader(rect),
        );
      }
    }
  }

  void _pipe(Canvas canvas, List<Offset> points, Color color, double width) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      path,
      stroke(color.withValues(alpha: 0.4), width * 1.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.25),
    );
    canvas.drawPath(path, stroke(color, width));
    canvas.drawPath(
      path,
      stroke(Color.lerp(color, Colors.white, 0.2)!, width * 0.6),
    );
    canvas.drawPath(
      path.shift(Offset(-width * 0.12, -width * 0.12)),
      stroke(Colors.white.withValues(alpha: 0.35), width * 0.18),
    );
  }

  void _ball(Canvas canvas, Offset center, double radius, Color color) {
    final dark = Color.lerp(color, Colors.black, 0.25)!;
    canvas.drawCircle(
      center + Offset(0, radius * 0.12),
      radius,
      Paint()
        ..color = dark.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [Color.lerp(color, Colors.white, 0.35)!, color, dark],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.save();
    canvas.translate(center.dx - radius * 0.38, center.dy - radius * 0.45);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.6,
        height: radius * 0.34,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => false;
}
