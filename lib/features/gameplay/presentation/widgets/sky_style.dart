import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual tokens for the "whimsical sky" gameplay skin.
class SkyStyle {
  SkyStyle._();

  static const String background = 'assets/images/gameplay_background.png';
  static const String fontFamily = 'Fredoka';

  static const Color ink = Color(0xFF1B2A6B);
  static const Color coverageGreen = Color(0xFF1FA34A);
  static const Color iconBlue = Color(0xFF2F95E6);

  static const Color pillTop = Color(0xFFEAF5FF);
  static const Color pillBottom = Color(0xFFCFE6FA);
  static const Color pillEdge = Color(0xFF9FC9EE);

  static const Color frameFill = Color(0xFFF7F9FF);
  static const Color frameEdge = Color(0xFFB7D2F2);
  static const Color tileGap = Color(0xFFDCE3F4);
  static const Color tileTop = Color(0xFFFDFDFF);
  static const Color tileBottom = Color(0xFFEDF0FA);
  static const Color tileEdge = Color(0xFFD3D9EC);

  static const Color undoEdge = Color(0xFF5AA8F0);
  static const Color restartEdge = Color(0xFFA7B4F2);
  static const Color hintEdge = Color(0xFF7FDCC4);
  static const Color neutralEdge = Color(0xFFC9D4E6);

  /// White rounded frame around a puzzle board of [size].
  static BoxDecoration boardFrame(double size) => BoxDecoration(
    borderRadius: BorderRadius.circular(size * 0.07),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, frameFill],
    ),
    border: Border.all(color: Colors.white, width: 2),
    boxShadow: const [
      BoxShadow(color: frameEdge, offset: Offset(0, 7)),
      BoxShadow(
        color: Color(0x40284B7A),
        blurRadius: 24,
        offset: Offset(0, 14),
      ),
    ],
  );

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = ink,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
    );
  }
}

/// Round white button with a soft blue under-edge (back / pause).
class SkyRoundButton extends StatelessWidget {
  const SkyRoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 56,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFEFF4FD)],
            ),
            boxShadow: [
              BoxShadow(color: SkyStyle.pillEdge, offset: Offset(0, 4)),
              BoxShadow(
                color: Color(0x33204070),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: SkyStyle.ink, size: size * 0.52),
        ),
      ),
    );
  }
}

/// Glossy yellow star decoration.
class SkyStar extends StatelessWidget {
  const SkyStar({super.key, required this.size, this.angle = 0});

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF27A), Color(0xFFFFC21A), Color(0xFFF59E0B)],
        ).createShader(rect),
        child: Icon(
          Icons.star_rounded,
          size: size,
          shadows: const [
            Shadow(
              color: Color(0x55B45309),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two little shoe prints, used as the "Moves" icon.
class FootprintsIcon extends StatelessWidget {
  const FootprintsIcon({
    super.key,
    this.size = 30,
    this.color = SkyStyle.iconBlue,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FootprintsPainter(color),
    );
  }
}

class _FootprintsPainter extends CustomPainter {
  _FootprintsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()..color = color;
    void print(Offset origin) {
      canvas.drawOval(
        Rect.fromLTWH(origin.dx, origin.dy, s * 0.3, s * 0.42),
        paint,
      );
      canvas.drawOval(
        Rect.fromLTWH(
          origin.dx + s * 0.04,
          origin.dy + s * 0.47,
          s * 0.22,
          s * 0.2,
        ),
        paint,
      );
    }

    print(Offset(s * 0.06, s * 0.28));
    print(Offset(s * 0.6, s * 0.06));
  }

  @override
  bool shouldRepaint(covariant _FootprintsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Shiny gold coin.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, required this.size, this.symbol = 'S'});

  final double size;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFE680), Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        border: Border.all(color: const Color(0xFFE08A00), width: 2),
      ),
      child: Text(
        symbol,
        style: SkyStyle.text(
          size * 0.55,
          weight: FontWeight.w700,
          color: const Color(0xFFB45309),
          height: 1,
        ),
      ),
    );
  }
}

/// Two glossy leaves and a little daisy tucked in the header's corner.
class LeafCluster extends StatelessWidget {
  const LeafCluster({super.key, required this.size, this.flower = true});

  final double size;
  final bool flower;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LeafPainter(flower),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter(this.flower);

  final bool flower;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    void leaf(Offset base, double angle, double length) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(length * 0.45, -length * 0.32, length, 0)
        ..quadraticBezierTo(length * 0.45, length * 0.32, 0, 0)
        ..close();
      final bounds = Rect.fromLTWH(0, -length * 0.3, length, length * 0.6);
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8EE05A), Color(0xFF2F9E3A)],
          ).createShader(bounds),
      );
      canvas.drawLine(
        Offset(length * 0.08, 0),
        Offset(length * 0.85, 0),
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..strokeWidth = 1.2,
      );
      canvas.restore();
    }

    final base = Offset(s * 0.35, s * 0.95);
    leaf(base, -2.2, s * 0.62);
    leaf(base, -1.35, s * 0.7);
    leaf(base, -0.6, s * 0.55);

    if (!flower) return;

    // Daisy
    final center = Offset(s * 0.82, s * 0.78);
    final petal = Paint()..color = Colors.white;
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * s * 0.07,
        s * 0.065,
        petal,
      );
    }
    canvas.drawCircle(
      center,
      s * 0.05,
      Paint()..color = const Color(0xFFFFB020),
    );
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) =>
      oldDelegate.flower != flower;
}

/// Hanging wooden plank with rope loops and leafy ends, e.g. "LEVEL 87".
class WoodenSign extends StatelessWidget {
  const WoodenSign({
    super.key,
    required this.text,
    this.height = 84,
    this.subtitle,
    this.crown = false,
  });

  final String text;
  final double height;

  /// Optional second line, drawn in gold below [text].
  final String? subtitle;

  /// Show a small crown on top of the plank.
  final bool crown;

  @override
  Widget build(BuildContext context) {
    final base = SkyStyle.text(
      height * (subtitle == null ? 0.38 : 0.34),
      weight: FontWeight.w700,
    ).copyWith(letterSpacing: 1);
    final leaves = height * 0.8;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Leaves tucked behind the plank's ends.
          Positioned(
            left: -height * 0.12,
            top: height * 0.12,
            child: Transform.rotate(
              angle: -0.9,
              child: LeafCluster(size: leaves, flower: false),
            ),
          ),
          Positioned(
            right: -height * 0.12,
            top: height * 0.12,
            child: Transform.rotate(
              angle: 0.9,
              child: Transform.flip(
                flipX: true,
                child: LeafCluster(size: leaves, flower: false),
              ),
            ),
          ),
          Positioned.fill(
            top: height * 0.2,
            left: height * 0.32,
            right: height * 0.32,
            child: CustomPaint(painter: _PlankPainter()),
          ),
          for (final left in [true, false])
            Positioned(
              left: left ? height * 0.22 : null,
              right: left ? null : height * 0.22,
              top: height * 0.5,
              child: _Daisy(size: height * 0.26),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              height * (subtitle == null ? 0.62 : 0.42),
              height * 0.22,
              height * (subtitle == null ? 0.62 : 0.42),
              0,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _outlined(text, base, null),
                  if (subtitle != null)
                    _outlined(
                      subtitle!,
                      base,
                      const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFF27A), Color(0xFFFFC21A)],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (crown)
            Positioned(
              top: -height * 0.12,
              child: CrownIcon(size: height * 0.34),
            ),
        ],
      ),
    );
  }

  Widget _outlined(String value, TextStyle style, Gradient? fill) {
    Widget face = Text(
      value,
      style: style.copyWith(
        color: Colors.white,
        height: 1.05,
        shadows: const [Shadow(color: Color(0x995A2A10), offset: Offset(0, 3))],
      ),
    );
    if (fill != null) {
      face = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: fill.createShader,
        child: face,
      );
    }
    return Stack(
      children: [
        Text(
          value,
          style: style.copyWith(
            height: 1.05,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF5A2A10),
          ),
        ),
        face,
      ],
    );
  }
}

class _Daisy extends StatelessWidget {
  const _Daisy({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _DaisyPainter());
  }
}

class _DaisyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final petal = Paint()..color = Colors.white;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.5,
        r * 0.42,
        petal,
      );
    }
    canvas.drawCircle(c, r * 0.36, Paint()..color = const Color(0xFFFFB020));
  }

  @override
  bool shouldRepaint(covariant _DaisyPainter oldDelegate) => false;
}

class _PlankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final plank = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.28));

    // Ropes rising from the plank's top corners.
    final rope = Paint()
      ..color = const Color(0xFFB0773D)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [w * 0.12, w * 0.88]) {
      canvas.drawLine(Offset(x, -h * 0.35), Offset(x, h * 0.2), rope);
      canvas.drawCircle(
        Offset(x, h * 0.12),
        5,
        Paint()
          ..color = const Color(0xFF8A5528)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    canvas.drawRRect(
      plank.shift(const Offset(0, 4)),
      Paint()..color = const Color(0xFF8A4A1E),
    );
    canvas.drawRRect(
      plank,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2B067), Color(0xFFD9853C), Color(0xFFC06A2A)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      plank.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFD49A).withValues(alpha: 0.7),
    );

    // Wood grain.
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFA85C24).withValues(alpha: 0.45);
    for (final (y, from, to) in [
      (0.3, 0.08, 0.42),
      (0.72, 0.55, 0.92),
      (0.55, 0.15, 0.3),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(w * from, h * y)
          ..quadraticBezierTo(
            w * (from + to) / 2,
            h * (y - 0.06),
            w * to,
            h * y,
          ),
        grain,
      );
    }
    for (final x in [0.06, 0.94]) {
      canvas.drawCircle(
        Offset(w * x, h * 0.5),
        2.5,
        Paint()..color = const Color(0xFF7A3F16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlankPainter oldDelegate) => false;
}

/// Small golden crown.
class CrownIcon extends StatelessWidget {
  const CrownIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size * 0.8), painter: _CrownPainter());
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.3)
      ..lineTo(w * 0.3, h * 0.55)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.7, h * 0.55)
      ..lineTo(w * 0.92, h * 0.3)
      ..lineTo(w * 0.84, h * 0.88)
      ..lineTo(w * 0.16, h * 0.88)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE066), Color(0xFFF5A300)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFD97706),
    );
    final jewel = Paint()..color = const Color(0xFFFFF6C8);
    for (final x in [0.08, 0.5, 0.92]) {
      canvas.drawCircle(
        Offset(w * x, h * (x == 0.5 ? 0.12 : 0.3)),
        w * 0.07,
        jewel,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) => false;
}
