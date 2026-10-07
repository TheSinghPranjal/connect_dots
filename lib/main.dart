import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/audio/audio_manager.dart';
import 'core/providers/app_providers.dart';
import 'features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final audio = NoOpAudioManager();
  await audio.init();

  // Warm level cache off the critical path after first frame.
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioManagerProvider.overrideWithValue(audio),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _Bootstrap(child: FlowDotsApp()),
    ),
  );

  // Prefetch levels
  // ignore: unawaited_futures
  container.read(levelRepositoryProvider).getAllLevels();
}

class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressControllerProvider);
    return progress.when(
      data: (_) => widget.child,
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(autoNavigate: false),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to start. Please restart the app.'),
                  const SizedBox(height: 12),
                  Text('$e', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
