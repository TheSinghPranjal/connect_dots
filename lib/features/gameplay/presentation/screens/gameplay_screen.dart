import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/dimensions.dart';
import '../../../../core/constants/game_constants.dart';
import '../../domain/models/cell_type.dart';
import '../../domain/models/game_session_state.dart';
import '../../providers/game_controller.dart';
import '../widgets/game_board.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.levelId});

  final int levelId;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen>
    with WidgetsBindingObserver {
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(gameControllerProvider.notifier).loadLevel(widget.levelId);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unable to load this puzzle.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = isDark ? AppColors.darkBackgroundTop : AppColors.lightBackgroundTop;
    final bottom =
        isDark ? AppColors.darkBackgroundBottom : AppColors.lightBackgroundBottom;

    ref.listen(gameControllerProvider, (prev, next) {
      if (next?.status == GameplayStatus.completed &&
          prev?.status != GameplayStatus.completed) {
        _showComplete(next!);
      } else if (next?.status == GameplayStatus.failed &&
          prev?.status != GameplayStatus.failed) {
        _showFailed(next!);
      } else if (next?.status == GameplayStatus.paused &&
          prev?.status != GameplayStatus.paused &&
          prev?.status == GameplayStatus.playing) {
        _showPause();
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorBody(message: _error!, onRetry: _load, onLevels: () {
                    Navigator.of(context).pop();
                  })
                : Column(
                    children: [
                      GameHud(
                        onBack: () => Navigator.of(context).pop(),
                        onPause: () =>
                            ref.read(gameControllerProvider.notifier).pause(),
                      ),
                      if (session?.score.comboMultiplier != null &&
                          session!.score.comboMultiplier > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'COMBO x${session.score.comboMultiplier}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: AppColors.brandAmber),
                          ),
                        ),
                      const Expanded(child: GameBoard()),
                      const GameControls(),
                    ],
                  ),
      ),
    );
  }

  Future<void> _showComplete(GameSessionState session) async {
    final result = session.result;
    if (result == null || !mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (context, anim, secondary) {
        return Center(
          child: _ResultCard(
            title: session.level.levelNumber == 100
                ? 'CAMPAIGN COMPLETE'
                : session.level.levelNumber == 50
                    ? 'HALFWAY THERE!'
                    : session.level.levelNumber == 10
                        ? "You're getting the flow."
                        : 'LEVEL COMPLETE',
            subtitle: session.level.levelNumber == 100
                ? '100 / 100'
                : session.level.levelNumber == 50
                    ? '50 / 100'
                    : null,
            stars: result.stars,
            score: result.score,
            moves: result.movesUsed,
            coins: result.coinsEarned,
            perfect: result.wasPerfect,
            onContinue: () {
              Navigator.of(context).pop();
              final next = session.level.levelNumber + 1;
              if (next <= GameConstants.totalCampaignLevels) {
                Navigator.of(this.context).pushReplacementNamed(
                  '/game/$next',
                );
              } else {
                Navigator.of(this.context).pop();
              }
            },
            onReplay: () {
              Navigator.of(context).pop();
              ref.read(gameControllerProvider.notifier).restart();
            },
            onLevels: () {
              Navigator.of(context).pop();
              Navigator.of(this.context).pushNamedAndRemoveUntil(
                '/levels',
                (route) => route.settings.name == '/home' || route.isFirst,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showFailed(GameSessionState session) async {
    if (!mounted) return;
    final reason = session.failReason == ChallengeFailReason.timeUp
        ? "TIME'S UP"
        : 'OUT OF MOVES';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(reason),
        content: Text(
          session.failReason == ChallengeFailReason.timeUp
              ? 'Nice attempt!\nMoves: ${session.movesUsed}'
              : 'You were close!\nMoves: ${session.movesUsed}/${session.level.moveLimit}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(this.context).pop();
            },
            child: const Text('Levels'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameControllerProvider.notifier).useHint();
              ref.read(gameControllerProvider.notifier).restart();
            },
            child: const Text('Use Hint'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameControllerProvider.notifier).restart();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPause() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PAUSED'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(this.context).pop();
            },
            child: const Text('Level Select'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameControllerProvider.notifier).restart();
            },
            child: const Text('Restart'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameControllerProvider.notifier).resume();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.stars,
    required this.score,
    required this.moves,
    required this.coins,
    required this.perfect,
    required this.onContinue,
    required this.onReplay,
    required this.onLevels,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int stars;
  final int score;
  final int moves;
  final int coins;
  final bool perfect;
  final VoidCallback onContinue;
  final VoidCallback onReplay;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.titleMedium),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.brandAmber,
                    size: 36,
                  );
                }),
              ),
              if (perfect) ...[
                const SizedBox(height: 8),
                Text(
                  'PERFECT!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Score  $score'),
              Text('Moves  $moves'),
              Text('Reward  +$coins coins'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Text('CONTINUE'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReplay,
                      child: const Text('Replay'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onLevels,
                      child: const Text('Levels'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
