import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../gameplay/presentation/widgets/sky_style.dart';
import 'board_preview.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String background = 'assets/images/home_background.png';

  /// Source size of [background] and where its baked-in logo ends.
  static const Size _backgroundSize = Size(867, 1815);
  static const double _logoBottomFraction = 0.352;

  static const Color teal = Color(0xFF138F80);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider).value;
    final completed = progress?.levelsCompleted ?? 0;
    final stars = progress?.totalStars ?? 0;
    final coins = progress?.coins ?? 0;
    final nextLevel = progress?.highestUnlockedLevel ?? 1;
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Map the logo's position in the cover-fitted image to the screen
          // so the content always starts right below it.
          final scale = math.max(
            constraints.maxWidth / _backgroundSize.width,
            constraints.maxHeight / _backgroundSize.height,
          );
          final offsetY =
              (constraints.maxHeight - _backgroundSize.height * scale) / 2;
          final logoBottom =
              _backgroundSize.height * _logoBottomFraction * scale + offsetY;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(background, fit: BoxFit.cover),
              Column(
                children: [
                  SizedBox(height: math.max(logoBottom, padding.top + 64)),
                  Text(
                    GameConstants.gameTagline,
                    style: SkyStyle.text(22).copyWith(
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: _ProgressPill(
                      completed: completed,
                      stars: stars,
                      coins: coins,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final size = math.min(
                          box.maxHeight * 0.92,
                          box.maxWidth * 0.6,
                        );
                        if (size < 80) return const SizedBox.shrink();
                        return Center(child: BoardPreview(size: size));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _PlayButton(
                          label:
                              (progress?.entryFor(nextLevel)?.completed ??
                                  false)
                              ? 'PLAY'
                              : 'PLAY LEVEL $nextLevel',
                          onPressed: () {
                            final id = nextLevel.clamp(
                              1,
                              GameConstants.totalCampaignLevels,
                            );
                            Navigator.pushNamed(context, '/game/$id');
                          },
                        ),
                        const SizedBox(height: 12),
                        _MenuButton(
                          icon: Icons.grid_view_rounded,
                          label: 'LEVELS',
                          centered: true,
                          onPressed: () =>
                              Navigator.pushNamed(context, '/levels'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MenuButton(
                                icon: Icons.calendar_month_outlined,
                                label: 'DAILY',
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/daily'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MenuButton(
                                icon: Icons.lightbulb_outline_rounded,
                                label: 'HOW TO PLAY',
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/how-to-play',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/stats'),
                    child: Text(
                      'Stats',
                      style:
                          SkyStyle.text(
                            20,
                            weight: FontWeight.w700,
                            color: teal,
                          ).copyWith(
                            shadows: const [
                              Shadow(color: Colors.white, blurRadius: 8),
                            ],
                          ),
                    ),
                  ),
                  SizedBox(height: padding.bottom + 4),
                ],
              ),
              Positioned(
                top: padding.top + 12,
                right: 16,
                child: SkyRoundButton(
                  icon: Icons.settings_rounded,
                  tooltip: 'Settings',
                  size: 52,
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.completed,
    required this.stars,
    required this.coins,
  });

  final int completed;
  final int stars;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final value = SkyStyle.text(18, weight: FontWeight.w700);
    Widget divider() =>
        Container(width: 1.5, height: 44, color: const Color(0xFFD5DEEC));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFF1F5FB).withValues(alpha: 0.88),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30204070),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillStat(
              icon: const Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF16A68E),
                size: 32,
              ),
              value: Text(
                '$completed / ${GameConstants.totalCampaignLevels}',
                style: value,
              ),
            ),
          ),
          divider(),
          Expanded(
            child: _PillStat(
              icon: const SkyStar(size: 34),
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$stars ', style: value),
                  const Icon(Icons.star_rounded, size: 20, color: Colors.black),
                ],
              ),
            ),
          ),
          divider(),
          Expanded(
            child: _PillStat(
              icon: const CoinIcon(size: 30, symbol: r'$'),
              value: Text('$coins', style: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  const _PillStat({required this.icon, required this.value});

  final Widget icon;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 34, child: Center(child: icon)),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: value),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3FCBB5), Color(0xFF18A390), Color(0xFF0E8B7A)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xFF0A6D60), offset: Offset(0, 5)),
              BoxShadow(
                color: Color(0x40204070),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFCFF5EE)],
                ).createShader(rect),
                child: const Icon(Icons.play_arrow_rounded, size: 46),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style:
                        SkyStyle.text(
                          26,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ).copyWith(
                          letterSpacing: 0.6,
                          shadows: const [
                            Shadow(
                              color: Color(0x800A6D60),
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.centered = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        style: SkyStyle.text(
          18,
          weight: FontWeight.w700,
          color: HomeScreen.teal,
        ).copyWith(letterSpacing: 0.6),
      ),
    );
    final glyph = Icon(icon, size: 28, color: HomeScreen.teal);

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFEFF3F8)],
            ),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0xFFD3DCE8), offset: Offset(0, 3)),
              BoxShadow(
                color: Color(0x30204070),
                blurRadius: 12,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: centered
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    glyph,
                    const SizedBox(width: 16),
                    Flexible(child: text),
                  ],
                )
              : Row(
                  children: [
                    glyph,
                    const SizedBox(width: 6),
                    Expanded(child: Center(child: text)),
                  ],
                ),
        ),
      ),
    );
  }
}
