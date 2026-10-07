import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../gameplay/presentation/painters/sky_paint.dart';
import '../../gameplay/presentation/widgets/sky_style.dart';

typedef _Cell = (int, int);

/// A solved 6×6 demo puzzle that every tutorial step is built from.
class _Demo {
  static const int size = 6;

  static const blue = Color(0xFF2F7BFF);
  static const red = Color(0xFFFF2D68);
  static const green = Color(0xFF22B455);
  static const yellow = Color(0xFFF7B500);
  static const purple = Color(0xFF8B46F0);

  static const List<(Color, List<_Cell>)> paths = [
    (blue, [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5)]),
    (
      red,
      [
        (1, 5), (1, 4), (1, 3), (1, 2), (1, 1), //
        (1, 0), (2, 0), (3, 0), (4, 0), (5, 0),
      ],
    ),
    (green, [(2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 5), (4, 5), (5, 5)]),
    (
      yellow,
      [(3, 1), (3, 2), (3, 3), (3, 4), (4, 4), (5, 4), (5, 3), (5, 2), (5, 1)],
    ),
    (purple, [(4, 1), (4, 2), (4, 3)]),
  ];

  static int get totalCells => size * size;

  /// Fraction of cells covered in the "fill every cell" step at time [t].
  static double fillCoverage(double t) {
    final covered = _filledCellCounts(t).fold<int>(0, (a, b) => a + b);
    return covered / totalCells;
  }

  /// How many cells of each path are drawn at time [t] in the fill step.
  static List<int> _filledCellCounts(double t) {
    final progress = (t / 0.8).clamp(0.0, 1.0) * totalCells;
    var remaining = progress;
    return [
      for (final (_, cells) in paths)
        () {
          final n = remaining.clamp(0, cells.length.toDouble()).floor();
          remaining -= cells.length;
          return math.max(n, 1);
        }(),
    ];
  }
}

/// Animated illustration for tutorial [step], driven by [animation] (0→1).
class TutorialDemo extends StatelessWidget {
  const TutorialDemo({super.key, required this.step, required this.animation});

  final int step;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = math.min(constraints.maxWidth, constraints.maxHeight);
        if (frame < 100) return const SizedBox.shrink();
        final inset = frame * 0.05;
        return SizedBox.square(
          dimension: frame,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(inset),
                decoration: SkyStyle.boardFrame(frame),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DemoPainter(step, animation),
                ),
              ),
              if (step == 3)
                Positioned(
                  top: -16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) => _Chip(
                        text:
                            'Coverage ${(_Demo.fillCoverage(animation.value) * 100).round()}%',
                        color: SkyStyle.coverageGreen,
                      ),
                    ),
                  ),
                ),
              if (step == 4)
                Positioned(
                  top: -22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        final t = animation.value;
                        final pop = Curves.elasticOut.transform(
                          ((t - 0.1) / 0.45).clamp(0.0, 1.0),
                        );
                        return Opacity(
                          opacity: (t / 0.1).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.4 + 0.6 * pop,
                            child: const _SolvedBadge(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30204070),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: SkyStyle.text(16, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _SolvedBadge extends StatelessWidget {
  const _SolvedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 18, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(
          color: SkyStyle.coverageGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40204070),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkyStar(size: 26, angle: -0.15),
          const SkyStar(size: 32),
          const SkyStar(size: 26, angle: 0.15),
          const SizedBox(width: 8),
          Text(
            'SOLVED!',
            style: SkyStyle.text(
              22,
              weight: FontWeight.w700,
              color: SkyStyle.coverageGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPainter extends CustomPainter {
  _DemoPainter(this.step, this.animation) : super(repaint: animation);

  final int step;
  final Animation<double> animation;

  late double _cell;

  Offset _at(_Cell c) => Offset((c.$2 + 0.5) * _cell, (c.$1 + 0.5) * _cell);

  List<Offset> _points(List<_Cell> cells) => [for (final c in cells) _at(c)];

  @override
  void paint(Canvas canvas, Size size) {
    _cell = size.width / _Demo.size;
    final t = animation.value;
    SkyPaint.flatGrid(canvas, size, _Demo.size, _Demo.size);

    switch (step) {
      case 0:
        _connect(canvas, t);
      case 1:
        _stayOnGrid(canvas, t);
      case 2:
        _noCrossing(canvas, t);
      case 3:
        _fill(canvas, t);
      default:
        _complete(canvas, t);
    }
  }

  double get _pipeWidth => _cell * 0.4;

  void _pipe(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    double glow = 0.3,
  }) {
    SkyPaint.pipe(canvas, points, color, _pipeWidth, glowAlpha: glow);
  }

  void _endpoints(Canvas canvas, {Set<Color> pulsing = const {}}) {
    final pulse = 0.06 * math.sin(animation.value * math.pi * 6);
    for (final (color, cells) in _Demo.paths) {
      for (final c in [cells.first, cells.last]) {
        SkyPaint.ringEndpoint(
          canvas,
          _at(c),
          _cell * 0.42,
          color,
          pulse: pulsing.contains(color) ? pulse : 0,
        );
      }
    }
  }

  /// Drag a path along [cells] with progress [p] (0→1); returns the tip.
  Offset _partial(Canvas canvas, List<_Cell> cells, Color color, double p) {
    final points = _points(cells);
    final pts = _trim(points, p);
    _pipe(canvas, pts, color, glow: 0.45);
    return pts.last;
  }

  static List<Offset> _trim(List<Offset> points, double p) {
    if (points.length < 2) return points;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    var left = total * p.clamp(0.0, 1.0);
    final out = <Offset>[points.first];
    for (var i = 1; i < points.length; i++) {
      final seg = (points[i] - points[i - 1]).distance;
      if (left >= seg) {
        out.add(points[i]);
        left -= seg;
      } else {
        out.add(Offset.lerp(points[i - 1], points[i], left / seg)!);
        break;
      }
    }
    return out;
  }

  // Step 1: drag blue from one dot to the other.
  void _connect(Canvas canvas, double t) {
    final p = Curves.easeInOut.transform((t / 0.65).clamp(0.0, 1.0));
    final (color, cells) = _Demo.paths[0];
    _endpoints(canvas, pulsing: {color});
    final tip = _partial(canvas, cells, color, p);
    SkyPaint.ringEndpoint(canvas, _at(cells.first), _cell * 0.42, color);
    if (p >= 1) {
      SkyPaint.ringEndpoint(canvas, _at(cells.last), _cell * 0.42, color);
      _sparkles(canvas, _at(cells.last), (t - 0.65) / 0.35);
    }
    if (t < 0.85) _hand(canvas, tip);
  }

  // Step 2: red turns a right angle; a diagonal shortcut is crossed out.
  void _stayOnGrid(Canvas canvas, double t) {
    final (color, cells) = _Demo.paths[1];
    final from = _at(cells.first);
    final to = _at(cells.last);

    final dash = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final d = to - from;
    const n = 14;
    for (var i = 0; i < n; i += 2) {
      canvas.drawLine(from + d * (i / n), from + d * ((i + 1) / n), dash);
    }
    _endpoints(canvas, pulsing: {color});
    _crossMark(canvas, Offset.lerp(from, to, 0.5)!, _cell * 0.32, 1);

    final p = Curves.easeInOut.transform((t / 0.75).clamp(0.0, 1.0));
    final tip = _partial(canvas, cells, color, p);
    SkyPaint.ringEndpoint(canvas, from, _cell * 0.42, color);
    if (p >= 1) SkyPaint.ringEndpoint(canvas, to, _cell * 0.42, color);
    if (t < 0.88) _hand(canvas, tip);
  }

  // Step 3: green is placed; red tries to cut through it and is rejected.
  void _noCrossing(Canvas canvas, double t) {
    final (green, greenCells) = _Demo.paths[2];
    final (red, _) = _Demo.paths[1];
    _endpoints(canvas);
    _pipe(canvas, _points(greenCells), green);
    SkyPaint.ringEndpoint(canvas, _at(greenCells.first), _cell * 0.42, green);
    SkyPaint.ringEndpoint(canvas, _at(greenCells.last), _cell * 0.42, green);

    // Red heads down from its dot into green's path and bounces back.
    const start = (1, 5);
    const blocked = (2, 5);
    final reach = t < 0.35
        ? Curves.easeOut.transform(t / 0.35)
        : t < 0.7
        ? 1.0
        : 1 - Curves.easeIn.transform((t - 0.7) / 0.3);
    final shake = t >= 0.35 && t < 0.7
        ? math.sin((t - 0.35) * math.pi * 16) * _cell * 0.06
        : 0.0;
    final a = _at(start);
    final b = Offset.lerp(a, _at(blocked), 0.55 * reach)! + Offset(shake, 0);
    _pipe(canvas, [a, b], red, glow: 0.45);
    SkyPaint.ringEndpoint(canvas, a, _cell * 0.42, red);
    _hand(canvas, b);
    if (t >= 0.35 && t < 0.85) {
      final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.15;
      _crossMark(canvas, _at(blocked), _cell * 0.36, fade);
    }
  }

  // Step 4: every path grows until the whole board is covered.
  void _fill(Canvas canvas, double t) {
    final counts = _Demo._filledCellCounts(t);
    for (var i = 0; i < _Demo.paths.length; i++) {
      final (color, cells) = _Demo.paths[i];
      final drawn = cells.take(counts[i]).toList();
      for (final c in drawn) {
        canvas.drawRect(
          Rect.fromLTWH(c.$2 * _cell, c.$1 * _cell, _cell, _cell).deflate(1),
          Paint()..color = color.withValues(alpha: 0.1),
        );
      }
      if (drawn.length > 1) _pipe(canvas, _points(drawn), color);
    }
    _endpoints(canvas);
  }

  // Step 5: the solved board glows.
  void _complete(Canvas canvas, double t) {
    final glow = 0.3 + 0.25 * (0.5 + 0.5 * math.sin(t * math.pi * 4));
    for (final (color, cells) in _Demo.paths) {
      _pipe(canvas, _points(cells), color, glow: glow);
    }
    _endpoints(canvas);
  }

  void _crossMark(Canvas canvas, Offset center, double r, double opacity) {
    canvas.drawCircle(
      center,
      r,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFE11D48).withValues(alpha: opacity),
    );
    final x = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: opacity)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final k = r * 0.45;
    canvas.drawLine(center + Offset(-k, -k), center + Offset(k, k), x);
    canvas.drawLine(center + Offset(k, -k), center + Offset(-k, k), x);
  }

  void _sparkles(Canvas canvas, Offset center, double p) {
    if (p <= 0 || p >= 1) return;
    final paint = Paint()
      ..color = const Color(0xFFFFC21A).withValues(alpha: 1 - p)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      final r0 = _cell * (0.5 + 0.2 * p);
      canvas.drawLine(
        center + dir * r0,
        center + dir * (r0 + _cell * 0.18),
        paint,
      );
    }
  }

  /// Cartoon pointing hand with its fingertip at [tip].
  void _hand(Canvas canvas, Offset tip) {
    final icon = Icons.touch_app_rounded;
    final size = _cell * 1.05;
    TextPainter glyph(Paint paint) => TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // The glyph's fingertip sits about 40% across and 8% down its box.
    final origin = tip - Offset(size * 0.4, size * 0.08);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    glyph(
      Paint()
        ..color = const Color(0x55204070)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    ).paint(canvas, const Offset(2, 4));
    glyph(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..color = SkyStyle.ink,
    ).paint(canvas, Offset.zero);
    glyph(Paint()..color = Colors.white).paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DemoPainter oldDelegate) =>
      oldDelegate.step != step;
}
