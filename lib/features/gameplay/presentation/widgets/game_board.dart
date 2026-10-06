import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/geometry/grid_geometry.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/game_session_state.dart';
import '../../providers/game_controller.dart';
import '../painters/board_painter.dart';

class GameBoard extends ConsumerStatefulWidget {
  const GameBoard({super.key});

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual =
        isDark ? BoardVisualConfig.dark() : BoardVisualConfig.light();

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = GridGeometry.boardSizeFor(
          availableWidth: constraints.maxWidth,
          availableHeight: constraints.maxHeight,
          maxSize: GameConstants.maxBoardLogicalWidth,
          padding: GameConstants.boardPadding,
        );

        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Listener(
                  onPointerDown: session.inputLocked
                      ? null
                      : (e) => _onDown(e, boardSize, session.board.rows,
                          session.board.columns),
                  onPointerMove: session.inputLocked
                      ? null
                      : (e) => _onMove(e, boardSize, session.board.rows,
                          session.board.columns),
                  onPointerUp: session.inputLocked ? null : (_) => _onUp(),
                  onPointerCancel: session.inputLocked ? null : (_) => _onUp(),
                  child: CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: BoardPainter(
                      board: session.board,
                      visual: visual,
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
  });

  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final level = session.level;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'LEVEL ${level.levelNumber}',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (level.isChallenge)
                    Text(
                      _challengeLabel(session),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.brandCoral,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Text(
                      'Coverage ${session.board.coveragePercent.toStringAsFixed(0)}%'
                      '  ·  Moves ${session.movesUsed}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
              tooltip: 'Pause',
            ),
          ],
        ),
      ),
    );
  }

  String _challengeLabel(GameSessionState session) {
    final parts = <String>[];
    if (session.level.moveLimit != null) {
      parts.add('Moves ${session.movesUsed}/${session.level.moveLimit}');
    }
    if (session.remainingSeconds != null) {
      final s = session.remainingSeconds!.toInt();
      final m = s ~/ 60;
      final r = s % 60;
      parts.add('${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}');
    }
    return parts.join('  ·  ');
  }
}

class GameControls extends ConsumerWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final progress = ref.watch(progressControllerProvider).value;
    final hints = progress?.hints ?? 0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onPressed: session == null || session.undoStack.isEmpty
                  ? null
                  : () => ref.read(gameControllerProvider.notifier).undo(),
            ),
            _ControlButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              onPressed: () => _confirmRestart(context, ref),
            ),
            _ControlButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint ($hints)',
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
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppDimensions.hudButtonSize,
          height: AppDimensions.hudButtonSize,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              onTap: onPressed,
              child: Icon(icon, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
