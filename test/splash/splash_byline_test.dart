import 'package:connect_dots/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSplash(
    WidgetTester tester, {
    required Size size,
    ThemeData? theme,
    double textScale = 1,
    double bottomInset = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    tester.view.padding = FakeViewPadding(bottom: bottomInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: const SplashScreen(autoNavigate: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  void expectBylineFits(WidgetTester tester) {
    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final screen = tester.getSize(find.byType(SplashScreen));
    final loading = tester.getRect(find.text('Loading...'));
    final byline = tester.getRect(find.text('The Lazy Bear Club'));
    final credit = tester.getRect(find.text('by'));

    expect(loading.bottom, lessThanOrEqualTo(credit.top));
    expect(byline.left, greaterThanOrEqualTo(0));
    expect(byline.right, lessThanOrEqualTo(screen.width + 0.5));
    expect(byline.bottom, lessThanOrEqualTo(screen.height));
    expect(byline.width, greaterThan(0));
    expect(byline.height, greaterThan(0));
  }

  testWidgets('splash keeps the loading bar and adds the studio byline', (
    tester,
  ) async {
    await pumpSplash(tester, size: const Size(390, 844), bottomInset: 34);
    expectBylineFits(tester);
    expect(
      find.bySemanticsLabel('by The Lazy Bear Club'),
      findsOneWidget,
    );
  });

  testWidgets('byline stays on screen for small phones, tablets, and dark mode', (
    tester,
  ) async {
    await pumpSplash(tester, size: const Size(320, 568));
    expectBylineFits(tester);

    await pumpSplash(tester, size: const Size(800, 360), textScale: 1.6);
    expectBylineFits(tester);

    await pumpSplash(
      tester,
      size: const Size(834, 1194),
      theme: ThemeData.dark(),
      textScale: 1.3,
      bottomInset: 20,
    );
    expectBylineFits(tester);
  });
}
