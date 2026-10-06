import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

/// Local placeholder daily challenge — picks a campaign level from the date seed.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final levelId = 20 + (seed % 70); // levels 20–89
    final progress = ref.watch(progressControllerProvider).value;
    final doneToday = progress?.dailyChallengeDate == _dateKey(today) &&
        (progress?.dailyChallengeCompleted ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              doneToday
                  ? 'Completed for today. Come back tomorrow!'
                  : 'Today\'s puzzle is campaign level $levelId.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: doneToday
                  ? null
                  : () => Navigator.pushNamed(context, '/game/$levelId'),
              child: Text(doneToday ? 'DONE' : 'PLAY DAILY'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
