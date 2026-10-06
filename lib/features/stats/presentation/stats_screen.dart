import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/progress/domain/player_progress_state.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider).value;
    final completed = progress?.levelsCompleted ?? 0;
    final stars = progress?.totalStars ?? 0;
    final perfect = progress?.perfectCompletions ?? 0;
    final bonus = progress?.totalBonusNodesCollected ?? 0;
    final coins = progress?.coins ?? 0;

    int? bestScore;
    var moveSum = 0;
    var moveCount = 0;
    for (final LevelProgressEntry e
        in progress?.levels.values ?? const <LevelProgressEntry>[]) {
      if (e.bestScore > (bestScore ?? 0)) bestScore = e.bestScore;
      if (e.bestMoves != null) {
        moveSum += e.bestMoves!;
        moveCount++;
      }
    }
    final avgMoves = moveCount == 0 ? 0.0 : moveSum / moveCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        children: [
          _tile(context, 'Levels completed',
              '$completed / ${GameConstants.totalCampaignLevels}'),
          _tile(context, 'Total stars', '$stars / 300'),
          _tile(context, 'Best score', '${bestScore ?? 0}'),
          _tile(context, 'Average best moves', avgMoves.toStringAsFixed(1)),
          _tile(context, 'Perfect completions', '$perfect'),
          _tile(context, 'Bonus nodes collected', '$bonus'),
          _tile(context, 'Coins', '$coins'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
