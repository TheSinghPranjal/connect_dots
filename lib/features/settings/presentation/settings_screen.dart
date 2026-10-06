import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../domain/settings_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound Effects'),
            value: settings.soundEnabled,
            onChanged: controller.setSoundEnabled,
          ),
          SwitchListTile(
            title: const Text('Music'),
            value: settings.musicEnabled,
            onChanged: controller.setMusicEnabled,
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: settings.hapticsEnabled,
            onChanged: controller.setHapticsEnabled,
          ),
          SwitchListTile(
            title: const Text('Color Assist'),
            subtitle: const Text('Show subtle symbols on endpoints'),
            value: settings.colorAssist,
            onChanged: controller.setColorAssist,
          ),
          ListTile(
            title: const Text('Dark Mode'),
            subtitle: Text(settings.themeMode.name),
            trailing: DropdownButton<ThemeModePreference>(
              value: settings.themeMode,
              items: ThemeModePreference.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.setThemeMode(v);
              },
            ),
          ),
          ListTile(
            title: const Text('Animations'),
            subtitle: Text(settings.animations.name),
            trailing: DropdownButton<AnimationPreference>(
              value: settings.animations,
              items: AnimationPreference.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.setAnimations(v);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Reset Progress'),
            textColor: Colors.red,
            onTap: () => _confirmReset(context, ref),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: Text('${GameConstants.gameName}  ·  v1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This will delete your level progress, stars, scores, coins and hints.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (second == true) {
      await ref.read(progressControllerProvider.notifier).resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset')),
        );
      }
    }
  }
}
