import 'dart:math' as math;

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
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _LazyBearByline(),
          ),
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

/// Studio credit tucked under the loading label, inside the safe area.
///
/// The slot is a fixed height so the existing loading bar stays put, and the
/// credit scales down instead of overflowing on small phones or large text.
class _LazyBearByline extends StatelessWidget {
  const _LazyBearByline();

  static const String asset = 'assets/branding/lazy_bear_club.png';

  /// Room between this credit and the loading label anchored 72px up.
  static const double slotHeight = 56;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final gutter = math.max(20.0, math.max(padding.left, padding.right));
    // Light chip with dark ink. The splash artwork is a bright scene in both
    // themes, and the chip keeps the credit readable on that sand (and on the
    // dark scaffold that shows before the image paints).
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFF10204A) : SkyStyle.ink;

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, padding.bottom + 8),
      child: SizedBox(
        height: slotHeight,
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Semantics(
            label: 'by The Lazy Bear Club',
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 5, 14, 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: dark ? 0.96 : 0.94),
                      const Color(0xFFF1F5FB).withValues(alpha: 0.94),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33204070),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        asset,
                        width: 36,
                        height: 36,
                        filterQuality: FilterQuality.medium,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'by',
                          style: SkyStyle.text(
                            13,
                            weight: FontWeight.w600,
                            color: ink.withValues(alpha: 0.85),
                            height: 1,
                          ),
                        ),
                        Text(
                          'The Lazy Bear Club',
                          style: SkyStyle.text(
                            15,
                            weight: FontWeight.w700,
                            color: ink,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
