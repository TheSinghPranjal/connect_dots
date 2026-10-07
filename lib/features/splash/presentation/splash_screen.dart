import 'package:flutter/material.dart';

import '../../gameplay/presentation/widgets/sky_style.dart';
import '../../home/presentation/home_screen.dart';

/// Branded launch screen on the home artwork with a filling loading bar.
///
/// With [autoNavigate] it replaces itself with the home screen once the bar
/// fills; without it, it just animates (used while app state loads).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    if (widget.autoNavigate) _continue();
  }

  Future<void> _continue() async {
    // Warm the images the next screens need while the bar fills.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage(SkyStyle.background), context);
    });
    await _progress.forward().orCancel.catchError((_) {});
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(HomeScreen.background, fit: BoxFit.cover),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom + 72,
            child: Column(
              children: [
                Container(
                  width: 220,
                  height: 18,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: Colors.white.withValues(alpha: 0.75),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40204070),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: Curves.easeInOut.transform(
                          _progress.value,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF5BE3C9), Color(0xFF14A38B)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading...',
                  style:
                      SkyStyle.text(
                        20,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ).copyWith(
                        shadows: const [
                          Shadow(color: Color(0x99204070), blurRadius: 6),
                          Shadow(
                            color: Color(0x66204070),
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
