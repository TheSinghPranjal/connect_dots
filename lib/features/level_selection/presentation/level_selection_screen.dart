import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/dimensions.dart';
import '../../../core/providers/app_providers.dart';

class LevelSelectionScreen extends ConsumerWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider).value;
    final unlocked = progress?.highestUnlockedLevel ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: 10,
        itemBuilder: (context, section) {
          final start = section * 10 + 1;
          final end = start + 9;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '$start – $end',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 10,
                itemBuilder: (context, i) {
                  final level = start + i;
                  final isLocked = level > unlocked;
                  final entry = progress?.entryFor(level);
                  final isMilestone = level % 10 == 0;
                  final isCurrent =
                      level == unlocked && !(entry?.completed ?? false);

                  return _LevelTile(
                    level: level,
                    locked: isLocked,
                    stars: entry?.stars ?? 0,
                    completed: entry?.completed ?? false,
                    milestone: isMilestone,
                    current: isCurrent,
                    onTap: isLocked
                        ? null
                        : () => Navigator.pushNamed(context, '/game/$level'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.locked,
    required this.stars,
    required this.completed,
    required this.milestone,
    required this.current,
    required this.onTap,
  });

  final int level;
  final bool locked;
  final int stars;
  final bool completed;
  final bool milestone;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = current
        ? Border.all(color: AppColors.brandTeal, width: 2.5)
        : null;

    return Material(
      color: locked
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(
        milestone ? AppDimensions.radiusMd : AppDimensions.radiusSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked)
                const Icon(Icons.lock_rounded, size: 18)
              else
                Text(
                  '$level',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: milestone ? 18 : 16,
                      ),
                ),
              if (!locked && (completed || stars > 0)) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 10,
                      color: AppColors.brandAmber,
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
