import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../gameplay/domain/models/board_state.dart';
import '../../gameplay/domain/models/level_definition.dart';
import '../../gameplay/presentation/painters/board_painter.dart';
import '../../gameplay/presentation/widgets/sky_style.dart';

/// Local placeholder daily challenge — picks a campaign level from the date seed.
class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  static const Color _teal = Color(0xFF138F80);

  late final DateTime _today = DateTime.now();
  late final int _levelId = _levelFor(_today);
  late final Future<LevelDefinition> _level = ref
      .read(levelRepositoryProvider)
      .getLevel(_levelId);

  static int _levelFor(DateTime d) {
    final seed = d.year * 10000 + d.month * 100 + d.day;
    return 20 + (seed % 70); // levels 20–89
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressControllerProvider).value;
    final doneToday =
        progress?.dailyChallengeDate == _dateKey(_today) &&
        (progress?.dailyChallengeCompleted ?? false);
    final padding = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(SkyStyle.background, fit: BoxFit.cover),
          Padding(
            padding: EdgeInsets.only(
              top: padding.top + 8,
              bottom: padding.bottom + 16,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        left: 16,
                        top: 4,
                        child: SkyRoundButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          size: 52,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Positioned(
                        top: 18,
                        child: SizedBox(
                          width: math.min(width * 0.8, 340),
                          child: const WoodenSign(
                            text: 'Daily',
                            subtitle: 'Challenge',
                            height: 124,
                            crown: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DatePill(text: _dateKey(_today)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text.rich(
                    TextSpan(
                      children: doneToday
                          ? const [
                              TextSpan(
                                text:
                                    'Completed for today. '
                                    'Come back tomorrow!',
                              ),
                            ]
                          : [
                              const TextSpan(
                                text: "Today's puzzle is campaign ",
                              ),
                              TextSpan(
                                text: 'level $_levelId.',
                                style: const TextStyle(color: _teal),
                              ),
                            ],
                    ),
                    textAlign: TextAlign.center,
                    style: SkyStyle.text(18).copyWith(
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _BoardPreview(level: _level),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _PlayDailyButton(
                    label: doneToday ? 'DONE' : 'PLAY DAILY',
                    onPressed: doneToday
                        ? null
                        : () => Navigator.pushNamed(
                            context,
                            '/daily/game/$_levelId',
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

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEAF1FA)],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFFC9D6E8), offset: Offset(0, 3)),
          BoxShadow(
            color: Color(0x30204070),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: SkyStyle.ink,
            size: 28,
          ),
          const SizedBox(width: 18),
          Text(text, style: SkyStyle.text(26, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Non-interactive look at today's starting board.
class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.level});

  final Future<LevelDefinition> level;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LevelDefinition>(
      future: level,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final frame = math.min(constraints.maxWidth, constraints.maxHeight);
            if (frame < 120) return const SizedBox.shrink();
            final inset = frame * 0.035;
            return Center(
              child: Container(
                width: frame,
                height: frame,
                padding: EdgeInsets.all(inset),
                decoration: SkyStyle.boardFrame(frame),
                child: CustomPaint(
                  painter: BoardPainter(
                    board: BoardState.initial(data),
                    visual: BoardVisualConfig.light(),
                    colorAssist: false,
                    hintCells: const [],
                    invalidCell: null,
                    reducedMotion: true,
                    flat: true,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlayDailyButton extends StatelessWidget {
  const _PlayDailyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.6,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3FCBB5),
                  Color(0xFF18A390),
                  Color(0xFF0E8B7A),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xFF0A6D60), offset: Offset(0, 6)),
                BoxShadow(
                  color: Color(0x40204070),
                  blurRadius: 16,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style:
                      SkyStyle.text(
                        30,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ).copyWith(
                        letterSpacing: 0.8,
                        shadows: const [
                          Shadow(
                            color: Color(0x800A6D60),
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
