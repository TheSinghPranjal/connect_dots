import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'sky_style.dart';

/// Shows the celebratory "level complete" popup over a blurred game screen.
Future<void> showLevelCompleteDialog(
  BuildContext context, {
  required String title,
  required String? subtitle,
  required int stars,
  required int score,
  required int moves,
  required int coins,
  required bool perfect,
  required String continueLabel,
  required bool reducedMotion,
  required void Function(BuildContext dialogContext) onContinue,
  required void Function(BuildContext dialogContext) onReplay,
  required void Function(BuildContext dialogContext) onLevels,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 450),
    pageBuilder: (dialogContext, _, _) {
      return PopScope(
        canPop: false,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: ColoredBox(color: Colors.white.withValues(alpha: 0.12)),
              ),
              _Confetti(animate: !reducedMotion),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: LevelCompleteCard(
                      title: title,
                      subtitle: subtitle,
                      stars: stars,
                      score: score,
                      moves: moves,
                      coins: coins,
                      perfect: perfect,
                      continueLabel: continueLabel,
                      onContinue: () => onContinue(dialogContext),
                      onReplay: () => onReplay(dialogContext),
                      onLevels: () => onLevels(dialogContext),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final scale = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(scale),
          child: child,
        ),
      );
    },
  );
}

class LevelCompleteCard extends StatelessWidget {
  const LevelCompleteCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stars,
    required this.score,
    required this.moves,
    required this.coins,
    required this.perfect,
    required this.continueLabel,
    required this.onContinue,
    required this.onReplay,
    required this.onLevels,
  });

  final String title;
  final String? subtitle;
  final int stars;
  final int score;
  final int moves;
  final int coins;
  final bool perfect;
  final String continueLabel;
  final VoidCallback onContinue;
  final VoidCallback onReplay;
  final VoidCallback onLevels;

  static const double _starsHeight = 132;
  static const double _ribbonTop = 118;
  static const double _ribbonHeight = 78;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _ribbonTop + 26),
            child: _buildCard(),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _starsHeight,
            child: _HeroStars(),
          ),
          Positioned(
            top: _ribbonTop,
            left: -18,
            right: -18,
            height: _ribbonHeight,
            child: _Ribbon(text: title),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFEFF), Color(0xFFEAF2FC)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD3E3F6), offset: Offset(0, 4)),
          BoxShadow(
            color: Color(0x30204070),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(subtitle!, style: SkyStyle.text(24, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: i < stars
                      ? const SkyStar(size: 48)
                      : const _EmptyStar(size: 48),
                ),
            ],
          ),
          if (perfect) ...[
            const SizedBox(height: 2),
            Text(
              'PERFECT!',
              style: SkyStyle.text(
                18,
                weight: FontWeight.w700,
                color: SkyStyle.coverageGreen,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _StatsPanel(score: score, moves: moves, coins: coins),
          const SizedBox(height: 18),
          _NextButton(label: continueLabel, onPressed: onContinue),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  icon: Icons.refresh_rounded,
                  label: 'Replay',
                  highlighted: true,
                  onPressed: onReplay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Levels',
                  highlighted: false,
                  onPressed: onLevels,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Three big stars with a soft burst of light behind them.
class _HeroStars extends StatelessWidget {
  const _HeroStars();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowRaysPainter(),
      child: const Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 30,
            bottom: 8,
            child: SkyStar(size: 96, angle: -0.22),
          ),
          Positioned(
            right: 30,
            bottom: 8,
            child: SkyStar(size: 96, angle: 0.22),
          ),
          Positioned(top: -8, child: SkyStar(size: 124)),
        ],
      ),
    );
  }
}

class _GlowRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);
    final radius = size.width * 0.42;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF7C2).withValues(alpha: 0.7),
            const Color(0xFFFFF7C2).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final ray = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1));
    const count = 12;
    for (var i = 0; i < count; i++) {
      final a = math.pi + (i + 0.5) * math.pi / count;
      final spread = math.pi / count * 0.3;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(a - spread) * radius * 1.1,
          center.dy + math.sin(a - spread) * radius * 1.1,
        )
        ..lineTo(
          center.dx + math.cos(a + spread) * radius * 1.1,
          center.dy + math.sin(a + spread) * radius * 1.1,
        )
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowRaysPainter oldDelegate) => false;
}

/// Glossy blue banner with folded tails.
class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final label = text == 'LEVEL COMPLETE' ? 'LEVEL COMPLETE!' : text;
    final base = SkyStyle.text(
      32,
      weight: FontWeight.w700,
    ).copyWith(letterSpacing: 0.5);
    return CustomPaint(
      painter: _RibbonPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(46, 4, 46, 28),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(
              children: [
                Text(
                  label,
                  style: base.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 5
                      ..strokeJoin = StrokeJoin.round
                      ..color = const Color(0xFF1C55B8),
                  ),
                ),
                Text(
                  label,
                  style: base.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0x661C3F8A), offset: Offset(0, 3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bandBottom = h * 0.68;
    const tail = 40.0;
    const sag = 10.0;

    // Tails hanging below each end of the band.
    final tailPaint = Paint()..color = const Color(0xFF2A74DB);
    final foldPaint = Paint()..color = const Color(0xFF1A4FA6);
    for (final mirror in [false, true]) {
      double x(double v) => mirror ? w - v : v;
      canvas.drawPath(
        Path()
          ..moveTo(x(0), h * 0.36)
          ..lineTo(x(tail + 8), h * 0.36)
          ..lineTo(x(tail + 8), h)
          ..lineTo(x(0), h * 0.94)
          ..lineTo(x(14), h * 0.66)
          ..close(),
        tailPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x(tail), bandBottom - 4)
          ..lineTo(x(tail + 8), h)
          ..lineTo(x(tail + 24), bandBottom + 2)
          ..close(),
        foldPaint,
      );
    }

    // Main arched band.
    final band = Path()
      ..moveTo(tail - 10, sag + 4)
      ..quadraticBezierTo(w / 2, -sag, w - tail + 10, sag + 4)
      ..lineTo(w - tail + 10, bandBottom + sag)
      ..quadraticBezierTo(w / 2, bandBottom - sag, tail - 10, bandBottom + sag)
      ..close();
    final bounds = Rect.fromLTWH(0, 0, w, bandBottom + sag);
    canvas.drawShadow(band, const Color(0xFF0B2E6B), 6, false);
    canvas.drawPath(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7CC8FF), Color(0xFF3A8EF0), Color(0xFF2367D4)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );

    // Glossy highlight along the top edge.
    canvas.drawPath(
      Path()
        ..moveTo(tail, sag + 9)
        ..quadraticBezierTo(w / 2, -sag + 6, w - tail, sag + 9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) => false;
}

class _EmptyStar extends StatelessWidget {
  const _EmptyStar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.star_rounded, size: size, color: Colors.white),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD43B), Color(0xFFF59E0B)],
          ).createShader(rect),
          child: Icon(Icons.star_outline_rounded, size: size),
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.score,
    required this.moves,
    required this.coins,
  });

  final int score;
  final int moves;
  final int coins;

  @override
  Widget build(BuildContext context) {
    const divider = Padding(
      padding: EdgeInsets.only(left: 46),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFD3DEEE)),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFDFE9F7).withValues(alpha: 0.75),
      ),
      child: Column(
        children: [
          _StatRow(
            icon: const SkyStar(size: 34),
            label: 'Score',
            value: '$score',
          ),
          divider,
          _StatRow(
            icon: const FootprintsIcon(size: 30),
            label: 'Moves',
            value: '$moves',
          ),
          divider,
          _StatRow(
            icon: const CoinIcon(size: 30),
            label: 'Reward',
            value: '+$coins coins',
            valueColor: SkyStyle.coverageGreen,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = SkyStyle.ink,
  });

  final Widget icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(width: 34, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: SkyStyle.text(18, color: const Color(0xFF4B5B8C)),
            ),
          ),
          Text(
            value,
            style: SkyStyle.text(
              19,
              weight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5BE37D), Color(0xFF22C55E), Color(0xFF16A34A)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xFF138A3E), offset: Offset(0, 5)),
              BoxShadow(
                color: Color(0x4016A34A),
                blurRadius: 14,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 44,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style:
                    SkyStyle.text(
                      26,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ).copyWith(
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(color: Color(0x80137A36), offset: Offset(0, 2)),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: highlighted
                  ? const [SkyStyle.pillTop, SkyStyle.pillBottom]
                  : const [Colors.white, Color(0xFFF1F4FB)],
            ),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFF6FB2F0)
                  : const Color(0xFFD2DBEE),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26204070),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 30,
                color: highlighted ? SkyStyle.ink : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Text(label, style: SkyStyle.text(20, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gently falling confetti and sparkles behind the card.
class _Confetti extends StatefulWidget {
  const _Confetti({required this.animate});

  final bool animate;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    const colors = [
      Color(0xFFFF6FB5),
      Color(0xFF6BDB4A),
      Color(0xFFFFD43B),
      Color(0xFF38B6FF),
    ];
    _pieces = List.generate(36, (i) {
      return _Piece(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.08 + random.nextDouble() * 0.1,
        angle: random.nextDouble() * math.pi * 2,
        spin: (random.nextDouble() - 0.5) * 4,
        color: colors[i % colors.length],
        size: 10 + random.nextDouble() * 10,
        sparkle: i % 6 == 0,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ConfettiPainter(_pieces, _controller)),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.y,
    required this.speed,
    required this.angle,
    required this.spin,
    required this.color,
    required this.size,
    required this.sparkle,
  });

  final double x;
  final double y;
  final double speed;
  final double angle;
  final double spin;
  final Color color;
  final double size;
  final bool sparkle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress) : super(repaint: progress);

  final List<_Piece> pieces;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    for (final p in pieces) {
      final y = ((p.y + t * p.speed * 10) % 1.1) - 0.05;
      final x = p.x + math.sin((t * 2 + p.y) * math.pi * 2) * 0.01;
      final center = Offset(x * size.width, y * size.height);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(p.angle + t * p.spin * math.pi * 2);
      if (p.sparkle) {
        _drawSparkle(canvas, p.size * 0.6);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.6,
          height: p.size * 0.8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(p.size * 0.2)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(p.color, Colors.white, 0.35)!, p.color],
            ).createShader(rect),
        );
      }
      canvas.restore();
    }
  }

  void _drawSparkle(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..quadraticBezierTo(0, 0, 0, r)
      ..quadraticBezierTo(0, 0, -r, 0)
      ..quadraticBezierTo(0, 0, 0, -r)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFFBE0));
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
