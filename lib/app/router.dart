import 'package:flutter/material.dart';

import '../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../features/gameplay/presentation/screens/gameplay_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/how_to_play/presentation/how_to_play_screen.dart';
import '../features/level_selection/presentation/level_selection_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/home';

    if (name == '/' || name == '/home') {
      return _fade(const HomeScreen(), name);
    }
    if (name == '/levels') {
      return _fade(const LevelSelectionScreen(), name);
    }
    if (name == '/settings') {
      return _fade(const SettingsScreen(), name);
    }
    if (name == '/how-to-play') {
      return _fade(const HowToPlayScreen(), name);
    }
    if (name == '/stats') {
      return _fade(const StatsScreen(), name);
    }
    if (name == '/daily') {
      return _fade(const DailyChallengeScreen(), name);
    }

    final gameMatch = RegExp(r'^/game/(\d+)$').firstMatch(name);
    if (gameMatch != null) {
      final id = int.parse(gameMatch.group(1)!);
      return _fade(GameplayScreen(levelId: id), name);
    }

    return _fade(const HomeScreen(), '/home');
  }

  static PageRoute _fade(Widget child, String name) {
    return PageRouteBuilder(
      settings: RouteSettings(name: name),
      pageBuilder: (context, animation, secondary) => child,
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 220),
    );
  }
}
