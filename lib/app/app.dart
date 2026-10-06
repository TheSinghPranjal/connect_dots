import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../core/providers/app_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class FlowDotsApp extends ConsumerWidget {
  const FlowDotsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp(
      title: GameConstants.gameName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.flutterThemeMode,
      initialRoute: '/home',
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
