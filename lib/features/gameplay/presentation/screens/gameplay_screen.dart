import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/cell_type.dart';
import '../../domain/models/game_session_state.dart';
import '../../providers/game_controller.dart';
import '../widgets/game_board.dart';
import '../widgets/level_complete_dialog.dart';
import '../widgets/sky_style.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.levelId, this.daily = false});

  final int levelId;

  /// Daily challenge runs use the wooden-sign / flat-grid look.
  final bool daily;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen>
    with WidgetsBindingObserver {
  var _loading = true;
  String? _error;
  var _showingOverlay = false;
  late int _currentLevelId;

  @override
  void initState() {
    super.initState();
    _currentLevelId = widget.levelId;
    WidgetsBinding.instance.addObserver(this);
    _load(_currentLevelId);
  }

  @override
  void didUpdateWidget(covariant GameplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelId != widget.levelId) {
      _currentLevelId = widget.levelId;
      _load(_currentLevelId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(gameControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.pause();
    }
  }

  Future<void> _load(int levelId) async {
    setState(() {
      _loading = true;
      _error = null;
      _showingOverlay = false;
    });
    try {
      await ref.read(gameControllerProvider.notifier).loadLevel(levelId);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load this puzzle.';
      });
    }
  }

  Future<void> _goToNextLevel(int nextLevel) async {
    if (nextLevel < 1 || nextLevel > GameConstants.totalCampaignLevels) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _currentLevelId = nextLevel;
    await _load(nextLevel);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    ref.listen(gameControllerProvider, (prev, next) {
      if (!mounted || _showingOverlay) return;
      if (next?.status == GameplayStatus.completed &&
          prev?.status != GameplayStatus.completed) {
        _showingOverlay = true;
        _showComplete(next!);
      } else if (next?.status == GameplayStatus.failed &&
          prev?.status != GameplayStatus.failed) {
        _showingOverlay = true;
        _showFailed(next!);
      } else if (next?.status == GameplayStatus.paused &&
          prev?.status != GameplayStatus.paused &&
          prev?.status == GameplayStatus.playing) {
        _showingOverlay = true;
        _showPause();
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(SkyStyle.background, fit: BoxFit.cover),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _ErrorBody(
              message: _error!,
              onRetry: () => _load(_currentLevelId),
              onLevels: () => Navigator.of(context).pop(),
            )
          else
            Column(
              children: [
                GameHud(
                  daily: widget.daily,
                  onBack: () => Navigator.of(context).pop(),
                  onPause: () =>
                      ref.read(gameControllerProvider.notifier).pause(),
                ),
                if (widget.daily)
                  const SizedBox(height: 20)
                else
                  SizedBox(
                    height: 48,
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 36,
                          top: 4,
                          child: SkyStar(size: 52, angle: -0.12),
                        ),
                        const Positioned(
                          right: 40,
                          top: 16,
                          child: SkyStar(size: 40, angle: 0.15),
                        ),
                        if (session != null &&
                            session.score.comboMultiplier > 1)
                          Center(
                            child: Text(
                              'COMBO x${session.score.comboMultiplier}',
                              style:
                                  SkyStyle.text(
                                    18,
                                    weight: FontWeight.w700,
                                    color: AppColors.brandAmber,
                                  ).copyWith(
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 32),
                    child: GameBoard(daily: widget.daily),
                  ),
                ),
                GameControls(daily: widget.daily),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showComplete(GameSessionState session) async {
    final result = session.result;
    if (result == null || !mounted) {
      _showingOverlay = false;
      return;
    }

    final levelNumber = session.level.levelNumber;
    final nextLevel = levelNumber + 1;
    final hasNext =
        !widget.daily && nextLevel <= GameConstants.totalCampaignLevels;

    await showLevelCompleteDialog(
      context,
      title: levelNumber >= GameConstants.totalCampaignLevels
          ? 'CAMPAIGN COMPLETE'
          : levelNumber == 50
          ? 'HALFWAY THERE!'
          : levelNumber == 10
          ? "You're getting the flow."
          : 'LEVEL COMPLETE',
      subtitle: levelNumber >= GameConstants.totalCampaignLevels
          ? '${GameConstants.totalCampaignLevels} / ${GameConstants.totalCampaignLevels}'
          : levelNumber == 50
          ? '50 / ${GameConstants.totalCampaignLevels}'
          : 'Level $levelNumber',
      stars: result.stars,
      score: result.score,
      moves: result.movesUsed,
      coins: result.coinsEarned,
      perfect: result.wasPerfect,
      continueLabel: hasNext ? 'NEXT LEVEL' : 'DONE',
      reducedMotion: ref.read(settingsControllerProvider).reducedMotion,
      onContinue: (dialogContext) {
        Navigator.of(dialogContext).pop();
        _showingOverlay = false;
        if (hasNext) {
          _goToNextLevel(nextLevel);
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      },
      onReplay: (dialogContext) {
        Navigator.of(dialogContext).pop();
        _showingOverlay = false;
        ref.read(gameControllerProvider.notifier).restart();
      },
      onLevels: (dialogContext) {
        Navigator.of(dialogContext).pop();
        _showingOverlay = false;
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/levels',
          (route) => route.settings.name == '/home' || route.isFirst,
        );
      },
    );
    _showingOverlay = false;
  }

  Future<void> _showFailed(GameSessionState session) async {
    if (!mounted) {
      _showingOverlay = false;
      return;
    }
    final reason = session.failReason == ChallengeFailReason.timeUp
        ? "TIME'S UP"
        : 'OUT OF MOVES';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(reason),
        content: Text(
          session.failReason == ChallengeFailReason.timeUp
              ? 'Nice attempt!\nMoves: ${session.movesUsed}'
              : 'You were close!\nMoves: ${session.movesUsed}/${session.level.moveLimit}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showingOverlay = false;
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Levels'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showingOverlay = false;
              ref.read(gameControllerProvider.notifier).useHint();
              ref.read(gameControllerProvider.notifier).restart();
            },
            child: const Text('Use Hint'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showingOverlay = false;
              ref.read(gameControllerProvider.notifier).restart();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
    _showingOverlay = false;
  }

  Future<void> _showPause() async {
    if (!mounted) {
      _showingOverlay = false;
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('PAUSED'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showingOverlay = false;
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Level Select'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showingOverlay = false;
              ref.read(gameControllerProvider.notifier).restart();
            },
            child: const Text('Restart'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showingOverlay = false;
              ref.read(gameControllerProvider.notifier).resume();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    _showingOverlay = false;
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onLevels,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            TextButton(onPressed: onLevels, child: const Text('Levels')),
          ],
        ),
      ),
    );
  }
}
