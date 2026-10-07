import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../gameplay/presentation/widgets/sky_style.dart';
import '../../progress/domain/player_progress_state.dart';

class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() =>
      _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> {
  static const String _background = 'assets/images/levels_background.png';

  /// Source size of [_background] and where its painted "Levels" sign ends.
  static const Size _backgroundSize = Size(870, 1808);
  static const double _signBottom = 296;

  final _currentSectionKey = GlobalKey();
  var _scrolledToCurrent = false;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressControllerProvider).value;
    final unlocked = progress?.highestUnlockedLevel ?? 1;
    final currentSection = (unlocked - 1) ~/ 10;
    final padding = MediaQuery.paddingOf(context);
    final screen = MediaQuery.sizeOf(context);

    // Map the sign's position in the cover-fitted image to the screen.
    final scale = math.max(
      screen.width / _backgroundSize.width,
      screen.height / _backgroundSize.height,
    );
    final offsetY = (screen.height - _backgroundSize.height * scale) / 2;
    final listTop = math.max(
      _signBottom * scale + offsetY + 4,
      padding.top + 64,
    );
    const fade = 28.0;

    if (!_scrolledToCurrent && currentSection > 0) {
      _scrolledToCurrent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _currentSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, alignment: 0.05);
        }
      });
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_background, fit: BoxFit.cover),
          // Cards scroll in the area below the painted sign and fade out
          // as they reach it.
          Positioned(
            top: listTop - fade,
            left: 0,
            right: 0,
            bottom: 0,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [Colors.transparent, Colors.black],
                stops: [0, fade / rect.height],
              ).createShader(rect),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  fade + 4,
                  16,
                  padding.bottom + 24,
                ),
                itemCount: 10,
                itemBuilder: (context, section) {
                  final start = section * 10 + 1;
                  return Padding(
                    key: section == currentSection ? _currentSectionKey : null,
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _SectionCard(
                      start: start,
                      theme: _SectionTheme.forStart(start),
                      tiles: [
                        for (var level = start; level < start + 10; level++)
                          _tileFor(level, unlocked, progress?.entryFor(level)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: padding.top + 6,
            child: SkyRoundButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              size: 44,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileFor(int level, int unlocked, LevelProgressEntry? entry) {
    final locked = level > unlocked;
    final completed = entry?.completed ?? false;
    final stars = entry?.stars ?? 0;
    final current = level == unlocked && !completed;
    return _LevelTile(
      level: level,
      state: locked
          ? _TileState.locked
          : current
          ? _TileState.current
          : completed
          ? _TileState.completed
          : _TileState.open,
      stars: stars,
      onTap: locked ? null : () => Navigator.pushNamed(context, '/game/$level'),
    );
  }
}

class _SectionTheme {
  const _SectionTheme(this.label, this.badge, this.tintStart, this.tintEnd);

  final String label;
  final Color badge;
  final Color tintStart;
  final Color tintEnd;

  static _SectionTheme forStart(int start) {
    if (start <= 10) {
      return const _SectionTheme(
        'Tutorial',
        Color(0xFF1FA35B),
        Color(0xFFE3F7E9),
        Color(0xFFC6EEC4),
      );
    }
    if (start <= 20) {
      return const _SectionTheme(
        'Easy',
        Color(0xFF1E88F0),
        Color(0xFFE2F2FF),
        Color(0xFFBEE2FA),
      );
    }
    if (start <= 30) {
      return const _SectionTheme(
        'Warm-up',
        Color(0xFFFF6A2B),
        Color(0xFFFFEEDF),
        Color(0xFFFBDDB3),
      );
    }
    if (start <= 40) {
      return const _SectionTheme(
        'Medium',
        Color(0xFF7B3FF2),
        Color(0xFFEFE7FF),
        Color(0xFFDCCBFA),
      );
    }
    if (start <= 50) {
      return const _SectionTheme(
        'Milestone',
        Color(0xFFE09B00),
        Color(0xFFFFF6D8),
        Color(0xFFFCE6A0),
      );
    }
    if (start <= 60) {
      return const _SectionTheme(
        'Blocked',
        Color(0xFF5B6B86),
        Color(0xFFEDF1F7),
        Color(0xFFD5DDEA),
      );
    }
    if (start <= 70) {
      return const _SectionTheme(
        'Hard',
        Color(0xFFE11D48),
        Color(0xFFFFE6EC),
        Color(0xFFFBC9D5),
      );
    }
    if (start <= 80) {
      return const _SectionTheme(
        'Expert',
        Color(0xFF0E9F9A),
        Color(0xFFE0F7F5),
        Color(0xFFBDEBE6),
      );
    }
    if (start <= 90) {
      return const _SectionTheme(
        'Very Hard',
        Color(0xFFC026D3),
        Color(0xFFFBE6FD),
        Color(0xFFF1C6F6),
      );
    }
    return const _SectionTheme(
      'Challenge',
      SkyStyle.ink,
      Color(0xFFE4E9F7),
      Color(0xFFC9D3EE),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.start,
    required this.theme,
    required this.tiles,
  });

  final int start;
  final _SectionTheme theme;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            const Color(0xFFF2F5FB).withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD7E0EE), offset: Offset(0, 4)),
          BoxShadow(
            color: Color(0x33204070),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _SectionHeader(start: start, theme: theme),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final tileWidth = (constraints.maxWidth - 8 - gap * 4) / 5;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap + 2,
                  children: [
                    for (final tile in tiles)
                      SizedBox(
                        width: tileWidth,
                        height: tileWidth * 0.92,
                        child: tile,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.start, required this.theme});

  final int start;
  final _SectionTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: [theme.tintStart, theme.tintEnd]),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(right: 4, top: -10, child: LeafCluster(size: 58)),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 64),
            child: Row(
              children: [
                Text(
                  '$start – ${start + 9}',
                  style: SkyStyle.text(28, weight: FontWeight.w700),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.badge,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.badge.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      theme.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: SkyStyle.text(
                        18,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _TileState { locked, current, completed, open }

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.state,
    required this.stars,
    required this.onTap,
  });

  final int level;
  final _TileState state;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (colors, edge, border) = switch (state) {
      _TileState.locked => (
        const [Color(0xFFE6EBF2), Color(0xFFCBD3E0)],
        const Color(0xFFADB8C9),
        Colors.white.withValues(alpha: 0.8),
      ),
      _TileState.current => (
        const [Color(0xFF3FD8BC), Color(0xFF0FA38B)],
        const Color(0xFF0A7A68),
        Colors.white,
      ),
      _TileState.completed => (
        const [Color(0xFFFFE36E), Color(0xFFFFB524)],
        const Color(0xFFE88A00),
        const Color(0xFFFFF4C2),
      ),
      _TileState.open => (
        const [Colors.white, Color(0xFFEAF0F8)],
        const Color(0xFFC8D3E4),
        Colors.white,
      ),
    };

    return Semantics(
      button: onTap != null,
      label: state == _TileState.locked
          ? 'Level $level, locked'
          : 'Level $level',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            border: Border.all(
              color: border,
              width: state == _TileState.current ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(color: edge, offset: const Offset(0, 4)),
              if (state == _TileState.current)
                const BoxShadow(
                  color: Color(0xAAE9F76A),
                  blurRadius: 12,
                  spreadRadius: 3,
                )
              else
                const BoxShadow(
                  color: Color(0x22204070),
                  blurRadius: 6,
                  offset: Offset(0, 5),
                ),
            ],
          ),
          child: Stack(
            children: [
              // Glossy top sheen
              Positioned(
                left: 6,
                right: 6,
                top: 4,
                height: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Center(child: _content()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (state) {
      case _TileState.locked:
        return const Icon(
          Icons.lock_rounded,
          size: 30,
          color: Color(0xFF2E3550),
        );
      case _TileState.current:
        return _OutlinedNumber(level: level, size: 30);
      case _TileState.completed:
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level',
                style: SkyStyle.text(24, weight: FontWeight.w700, height: 1.1),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 17,
                      color: i < stars
                          ? const Color(0xFFFFF3A0)
                          : const Color(0xFFB86A00),
                      shadows: const [
                        Shadow(color: Color(0xFFD97706), blurRadius: 1.5),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      case _TileState.open:
        return Text(
          '$level',
          style: SkyStyle.text(26, weight: FontWeight.w700),
        );
    }
  }
}

/// White number with a navy outline, used on the current level tile.
class _OutlinedNumber extends StatelessWidget {
  const _OutlinedNumber({required this.level, required this.size});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = SkyStyle.text(size, weight: FontWeight.w700);
    return Stack(
      children: [
        Text(
          '$level',
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeJoin = StrokeJoin.round
              ..color = SkyStyle.ink,
          ),
        ),
        Text('$level', style: base.copyWith(color: Colors.white)),
      ],
    );
  }
}
