import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider).value;
    final completed = progress?.levelsCompleted ?? 0;
    final stars = progress?.totalStars ?? 0;
    final coins = progress?.coins ?? 0;
    final nextLevel = progress?.highestUnlockedLevel ?? 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    AppColors.darkBackgroundTop,
                    AppColors.darkBackgroundBottom,
                  ]
                : const [
                    AppColors.lightBackgroundTop,
                    AppColors.lightBackgroundBottom,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  GameConstants.gameName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandTeal,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  GameConstants.gameTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkMuted
                            : AppColors.lightMuted,
                      ),
                ),
                const SizedBox(height: 28),
                _ProgressStrip(
                  completed: completed,
                  stars: stars,
                  coins: coins,
                ),
                const Spacer(flex: 2),
                ElevatedButton(
                  onPressed: () {
                    final id = nextLevel.clamp(
                      1,
                      GameConstants.totalCampaignLevels,
                    );
                    Navigator.pushNamed(context, '/game/$id');
                  },
                  child: const Text('PLAY'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/levels'),
                  child: const Text('LEVELS'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/daily'),
                        child: const Text('DAILY'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/how-to-play'),
                        child: const Text('HOW TO PLAY'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/stats'),
                  child: const Text('Stats'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({
    required this.completed,
    required this.stars,
    required this.coins,
  });

  final int completed;
  final int stars;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatChip(
          label: '$completed / ${GameConstants.totalCampaignLevels}',
          icon: Icons.grid_view_rounded,
        ),
        _StatChip(label: '$stars ★', icon: Icons.star_rounded),
        _StatChip(label: '$coins', icon: Icons.monetization_on_rounded),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.brandTeal),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
