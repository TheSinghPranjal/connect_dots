import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/geometry/grid_geometry.dart';
import '../../../../core/providers/app_providers.dart';
import '../../providers/game_controller.dart';
import '../../domain/models/game_session_state.dart';
import '../painters/board_painter.dart';
import 'sky_style.dart';

class GameBoard extends ConsumerStatefulWidget {
  const GameBoard({super.key, this.daily = false});

  /// Flat grid look used by daily challenges.
  final bool daily;

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard>
    with SingleTickerProviderStateMixin {
  Offset? _fingerLocal;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final visual = BoardVisualConfig.light();

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = GridGeometry.boardSizeFor(
          availableWidth: constraints.maxWidth,
          availableHeight: constraints.maxHeight,
          maxSize: GameConstants.maxBoardLogicalWidth,
          padding: GameConstants.boardPadding,
        );
        final framePadding = frameSize * 0.04;
        final boardSize = frameSize - framePadding * 2;

        return Center(
          child: Container(
            width: frameSize,
            height: frameSize,
            padding: EdgeInsets.all(framePadding),
            decoration: SkyStyle.boardFrame(frameSize),
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Listener(
                  onPointerDown: session.inputLocked
                      ? null
                      : (e) => _onDown(
                          e,
                          boardSize,
                          session.board.rows,
                          session.board.columns,
                        ),
                  onPointerMove: session.inputLocked
                      ? null
                      : (e) => _onMove(
                          e,
                          boardSize,
                          session.board.rows,
                          session.board.columns,
                        ),
                  onPointerUp: session.inputLocked ? null : (_) => _onUp(),
                  onPointerCancel: session.inputLocked ? null : (_) => _onUp(),
                  child: CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: BoardPainter(
                      board: session.board,
                      visual: visual,
                      flat: widget.daily,
                      colorAssist: settings.colorAssist,
                      hintCells: session.hintHighlightCells,
                      invalidCell: session.invalidFeedbackCell,
                      reducedMotion: settings.reducedMotion,
                      fingerPosition: _fingerLocal,
                      glowPhase: settings.reducedMotion
                          ? 0
                          : _glowController.value,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  GridGeometry _geometry(double boardSize, int rows, int cols) => GridGeometry(
    origin: Offset.zero,
    boardSize: boardSize,
    rows: rows,
    columns: cols,
  );

  void _onDown(PointerDownEvent e, double boardSize, int rows, int cols) {
    final geometry = _geometry(boardSize, rows, cols);
    final cell = geometry.screenToCell(e.localPosition);
    setState(() => _fingerLocal = e.localPosition);
    if (cell == null) return;
    ref.read(gameControllerProvider.notifier).startPath(cell);
  }

  void _onMove(PointerMoveEvent e, double boardSize, int rows, int cols) {
    final geometry = _geometry(boardSize, rows, cols);
    setState(() => _fingerLocal = e.localPosition);
    final cell = geometry.screenToCell(e.localPosition);
    if (cell == null) return;

    // Soft snap: if near cell center, process
    final dist = geometry.distanceToCell(e.localPosition, cell);
    final threshold = geometry.cellWidth * 0.65;
    if (dist <= threshold) {
      ref.read(gameControllerProvider.notifier).continuePath(cell);
    }
  }

  void _onUp() {
    setState(() => _fingerLocal = null);
    ref.read(gameControllerProvider.notifier).endPath();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(gameControllerProvider.notifier).clearInvalidFeedback();
      }
    });
  }
}

class GameHud extends ConsumerWidget {
  const GameHud({
    super.key,
    required this.onBack,
    required this.onPause,
    this.daily = false,
  });

  final VoidCallback onBack;
  final VoidCallback onPause;
  final bool daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final level = session.level;
    final moveLimit = level.moveLimit;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            SkyRoundButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onPressed: onBack,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: daily
                  ? _dailyHeader(session)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LevelPill(levelNumber: level.levelNumber),
                        const SizedBox(height: 8),
                        _StatsPill(
                          children: [
                            _Stat(
                              icon: const Icon(
                                Icons.apps_rounded,
                                color: SkyStyle.iconBlue,
                                size: 32,
                              ),
                              label: 'Coverage',
                              value:
                                  '${session.board.coveragePercent.toStringAsFixed(0)}%',
                              valueColor: SkyStyle.coverageGreen,
                            ),
                            _Stat(
                              icon: const FootprintsIcon(),
                              label: 'Moves',
                              value: moveLimit == null
                                  ? '${session.movesUsed}'
                                  : '${session.movesUsed}/$moveLimit',
                              valueColor: level.isChallenge
                                  ? AppColors.brandCoral
                                  : SkyStyle.ink,
                            ),
                            if (session.remainingSeconds != null)
                              _Stat(
                                icon: const Icon(
                                  Icons.timer_rounded,
                                  color: SkyStyle.iconBlue,
                                  size: 28,
                                ),
                                label: 'Time',
                                value: _formatTime(session.remainingSeconds!),
                                valueColor: AppColors.brandCoral,
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            SkyRoundButton(
              icon: Icons.pause_rounded,
              tooltip: 'Pause',
              onPressed: onPause,
            ),
          ],
        ),
      ),
    );
  }

  /// Wooden sign title, one-line stats and a crown combo badge.
  Widget _dailyHeader(GameSessionState session) {
    final moveLimit = session.level.moveLimit;
    final parts = <String>[
      'Coverage ${session.board.coveragePercent.toStringAsFixed(0)}%',
      moveLimit == null
          ? 'Moves ${session.movesUsed}'
          : 'Moves ${session.movesUsed}/$moveLimit',
      if (session.remainingSeconds != null)
        _formatTime(session.remainingSeconds!),
    ];
    final combo = session.score.comboMultiplier;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WoodenSign(text: 'LEVEL ${session.level.levelNumber}'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SkyStyle.pillTop, SkyStyle.pillBottom],
            ),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30204070),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              parts.join('   ·   '),
              style: SkyStyle.text(17, weight: FontWeight.w500),
            ),
          ),
        ),
        if (combo > 1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFAE6), Color(0xFFFFEDB5)],
              ),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30B45309),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CrownIcon(size: 28),
                const SizedBox(width: 10),
                Text(
                  'COMBO x$combo',
                  style: SkyStyle.text(
                    19,
                    weight: FontWeight.w700,
                    color: const Color(0xFFE07A00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(double seconds) {
    final s = seconds.toInt();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.levelNumber});

  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SkyStyle.pillTop, SkyStyle.pillBottom],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: SkyStyle.pillEdge, offset: Offset(0, 4)),
          BoxShadow(
            color: Color(0x30204070),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        'LEVEL $levelNumber',
        textAlign: TextAlign.center,
        style: SkyStyle.text(
          28,
          weight: FontWeight.w700,
          height: 1.1,
        ).copyWith(letterSpacing: 0.5),
      ),
    );
  }
}

class _StatsPill extends StatelessWidget {
  const _StatsPill({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          Container(
            width: 1.5,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: SkyStyle.pillEdge.withValues(alpha: 0.8),
          ),
        );
      }
      items.add(children[i]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x80B9D7F3), offset: Offset(0, 3)),
          BoxShadow(
            color: Color(0x22204070),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final Widget icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: SkyStyle.text(13, height: 1.1)),
            Text(
              value,
              style: SkyStyle.text(
                20,
                weight: FontWeight.w700,
                color: valueColor,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class GameControls extends ConsumerWidget {
  const GameControls({super.key, this.daily = false});

  final bool daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final progress = ref.watch(progressControllerProvider).value;
    final hints = progress?.hints ?? 0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(daily ? 36 : 56, 0, daily ? 36 : 56, 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ControlButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              edgeColor: daily ? SkyStyle.neutralEdge : SkyStyle.undoEdge,
              labelPill: daily,
              onPressed: session == null || session.undoStack.isEmpty
                  ? null
                  : () => ref.read(gameControllerProvider.notifier).undo(),
            ),
            _ControlButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              edgeColor: daily ? SkyStyle.neutralEdge : SkyStyle.restartEdge,
              labelPill: daily,
              onPressed: () => _confirmRestart(context, ref),
            ),
            _ControlButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint ($hints)',
              edgeColor: daily ? SkyStyle.neutralEdge : SkyStyle.hintEdge,
              labelPill: daily,
              onPressed: hints <= 0
                  ? null
                  : () => ref.read(gameControllerProvider.notifier).useHint(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart level?'),
        content: const Text('Your current paths will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(gameControllerProvider.notifier).restart();
    }
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.edgeColor,
    required this.onPressed,
    this.labelPill = false,
  });

  final IconData icon;
  final String label;
  final Color edgeColor;
  final VoidCallback? onPressed;

  /// Show the label inside a small white pill (daily look).
  final bool labelPill;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF1F4FC)],
                ),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(color: edgeColor, offset: const Offset(0, 6)),
                  const BoxShadow(
                    color: Color(0x33204070),
                    blurRadius: 12,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 34,
                color: onPressed == null
                    ? SkyStyle.ink.withValues(alpha: 0.45)
                    : SkyStyle.ink,
              ),
            ),
            SizedBox(height: labelPill ? 8 : 10),
            if (labelPill)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.9),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26204070),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: SkyStyle.text(18, weight: FontWeight.w600),
                ),
              )
            else
              Text(
                label,
                style: SkyStyle.text(19, weight: FontWeight.w700).copyWith(
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 6),
                    Shadow(color: Colors.white, blurRadius: 2),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
