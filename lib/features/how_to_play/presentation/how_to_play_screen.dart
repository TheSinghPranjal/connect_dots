import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../gameplay/presentation/widgets/sky_style.dart';
import 'tutorial_demo.dart';

class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  static const String _background = 'assets/images/how_to_play_background.png';
  static const Color _teal = Color(0xFF138F80);

  final _controller = PageController();
  late final AnimationController _demo;
  var _page = 0;

  static const _steps = [
    (
      'Connect matching colors.',
      'Drag from one colored endpoint to its match.',
    ),
    ('Stay on the grid.', 'Paths move only horizontally or vertically.'),
    ('Paths cannot cross.', 'Each cell belongs to only one path.'),
    (
      'Fill every open cell.',
      'Connecting pairs is not enough — cover the board.',
    ),
    (
      'Complete the board to win.',
      'Undo, restart, and hints are always available.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _demo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(settingsControllerProvider).reducedMotion) {
        _demo.value = 0.72; // a representative still frame
      } else {
        _demo.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _demo.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    // Start each page's demo from the beginning.
    if (!ref.read(settingsControllerProvider).reducedMotion) {
      _demo
        ..value = 0
        ..repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final last = _page >= _steps.length - 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_background, fit: BoxFit.cover),
          Padding(
            padding: EdgeInsets.only(
              top: padding.top + 8,
              bottom: padding.bottom + 16,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 104,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        left: 14,
                        top: 10,
                        child: SkyRoundButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          size: 50,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        child: SizedBox(
                          width: math.min(width * 0.62, 290),
                          child: const WoodenSign(
                            text: 'How to Play',
                            height: 86,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        top: 16,
                        child: _SkipPill(onPressed: _finish),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, i) {
                      final step = _steps[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Expanded(
                              child: Center(
                                child: TutorialDemo(step: i, animation: _demo),
                              ),
                            ),
                            const SizedBox(height: 26),
                            _StepCard(
                              number: i + 1,
                              title: step.$1,
                              body: step.$2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: active ? 26 : 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: active ? _teal : const Color(0xFFC9D0DC),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30204070),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _NextButton(
                    label: last ? 'GOT IT' : 'NEXT',
                    icon: last
                        ? Icons.check_rounded
                        : Icons.chevron_right_rounded,
                    onPressed: () {
                      if (last) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  ),
                ),
              ],
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

class _SkipPill extends StatelessWidget {
  const _SkipPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFEFF3F8)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xFFC9D6E8), offset: Offset(0, 3)),
              BoxShadow(
                color: Color(0x30204070),
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            'SKIP',
            style: SkyStyle.text(
              17,
              weight: FontWeight.w700,
              color: _HowToPlayScreenState._teal,
            ).copyWith(letterSpacing: 0.8),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          // Same height on every page so the demo board doesn't jump.
          constraints: const BoxConstraints(minHeight: 172),
          padding: const EdgeInsets.fromLTRB(20, 38, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.96),
                const Color(0xFFF1F6FA).withValues(alpha: 0.94),
              ],
            ),
            border: Border.all(color: const Color(0xFFB9E4DC), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF9FD3C8), offset: Offset(0, 4)),
              BoxShadow(
                color: Color(0x33204070),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: SkyStyle.text(25, weight: FontWeight.w700, height: 1.15),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: SkyStyle.text(
                  17,
                  weight: FontWeight.w500,
                  color: const Color(0xFF5B6785),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -26,
          child: Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2CC0A8), Color(0xFF0E8B7A)],
              ),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40204070),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$number',
              style: SkyStyle.text(
                24,
                weight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
        const Positioned(
          left: -14,
          bottom: -10,
          child: LeafCluster(size: 52, flower: false),
        ),
        Positioned(
          right: -14,
          bottom: -10,
          child: Transform.flip(
            flipX: true,
            child: const LeafCluster(size: 52, flower: false),
          ),
        ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3FCBB5), Color(0xFF18A390), Color(0xFF0E8B7A)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xFF0A6D60), offset: Offset(0, 5)),
              BoxShadow(
                color: Color(0x40204070),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style:
                    SkyStyle.text(
                      26,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ).copyWith(
                      letterSpacing: 0.8,
                      shadows: const [
                        Shadow(color: Color(0x800A6D60), offset: Offset(0, 2)),
                      ],
                    ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}
