import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _steps = [
    ('Connect matching colors.', 'Drag from one colored endpoint to its match.'),
    ('Stay on the grid.', 'Paths move only horizontally or vertically.'),
    ('Paths cannot cross.', 'Each cell belongs to only one path.'),
    ('Fill every open cell.', 'Connecting pairs is not enough — cover the board.'),
    ('Complete the board to win.', 'Undo, restart, and hints are always available.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('SKIP'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final step = _steps[i];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text('${i + 1}'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step.$1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.$2,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_page >= _steps.length - 1) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Text(_page >= _steps.length - 1 ? 'GOT IT' : 'NEXT'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finish() {
    ref.read(settingsControllerProvider.notifier).markHowToPlaySeen();
    Navigator.pop(context);
  }
}
