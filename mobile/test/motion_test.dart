import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/ui/motion.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('entrance reaches rest and does not replay on data rebuild', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MotionEntrance(child: Text('First'))));
    final finder = find.descendant(
      of: find.byType(MotionEntrance),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(finder).opacity.value, 0);
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(finder).opacity.value, 1);
    await tester.pumpWidget(host(const MotionEntrance(child: Text('Updated'))));
    expect(tester.widget<FadeTransition>(finder).opacity.value, 1);
    expect(find.text('Updated'), findsOneWidget);
  });
  testWidgets('reduced motion shows final value and skips entrance and shake', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            const MotionEntrance(child: Text('Visible')),
            AnimatedAmount(value: 12500, format: (n) => n.toStringAsFixed(0)),
            const ShakeFeedback(trigger: 1, child: Text('Invalid')),
          ],
        ),
        reduced: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12500'), findsOneWidget);
    final entrance = find.descendant(
      of: find.byType(MotionEntrance),
      matching: find.byType(FadeTransition),
    );
    expect(tester.widget<FadeTransition>(entrance).opacity.value, 1);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets(
    'amount retargets from the visible value and exposes final semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        Widget amount(double value) => host(
          AnimatedAmount(value: value, format: (n) => n.toStringAsFixed(0)),
        );
        await tester.pumpWidget(amount(100));
        await tester.pumpAndSettle();
        await tester.pumpWidget(amount(200));
        await tester.pump(const Duration(milliseconds: 100));
        final visible = double.parse(
          tester.widget<Text>(find.byType(Text).last).data!,
        );
        expect(visible, greaterThan(100));
        expect(visible, lessThan(200));
        expect(find.bySemanticsLabel('200'), findsOneWidget);
        await tester.pumpWidget(amount(-50));
        expect(
          double.parse(tester.widget<Text>(find.byType(Text).last).data!),
          closeTo(visible, 1),
        );
        await tester.pumpAndSettle();
        expect(find.text('-50'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('tab changes retain page state and mute inactive tickers', (
    tester,
  ) async {
    Widget tabs(int index) => host(
      MotionTabs(
        index: index,
        children: const [
          TextField(key: ValueKey('search')),
          Text('Second tab'),
        ],
      ),
    );
    await tester.pumpWidget(tabs(0));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'retained');
    await tester.pumpWidget(tabs(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(tabs(0));
    await tester.pumpAndSettle();
    expect(find.text('retained'), findsOneWidget);
    final tickers = tester.widgetList<TickerMode>(
      find.byType(TickerMode, skipOffstage: false),
    );
    expect(tickers.any((t) => !t.enabled), true);
  });
  testWidgets('shake returns to zero after repeated validation failures', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const ShakeFeedback(trigger: 0, child: Text('Form'))),
    );
    await tester.pumpWidget(
      host(const ShakeFeedback(trigger: 1, child: Text('Form'))),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final transform = find.descendant(
      of: find.byType(ShakeFeedback),
      matching: find.byType(Transform),
    );
    expect(tester.widget<Transform>(transform).transform.storage[12], isNot(0));
    await tester.pumpWidget(
      host(const ShakeFeedback(trigger: 2, child: Text('Form'))),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Transform>(transform).transform.storage[12],
      closeTo(0, 0.001),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'turning reduced motion on mid-animation preserves input and settles',
    (tester) async {
      Widget form(bool reduced) =>
          host(const MotionEntrance(child: TextField()), reduced: reduced);
      await tester.pumpWidget(form(false));
      await tester.enterText(find.byType(TextField), 'keep me');
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(form(true));
      await tester.pumpAndSettle();
      expect(find.text('keep me'), findsOneWidget);
      final entrance = find.descendant(
        of: find.byType(MotionEntrance),
        matching: find.byType(FadeTransition),
      );
      expect(tester.widget<FadeTransition>(entrance).opacity.value, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'muted amounts adopt refreshed totals without a hidden animation',
    (tester) async {
      Widget amount(double value) => host(
        TickerMode(
          enabled: false,
          child: AnimatedAmount(
            value: value,
            format: (n) => n.toStringAsFixed(0),
          ),
        ),
      );
      await tester.pumpWidget(amount(100));
      expect(find.text('100'), findsOneWidget);
      await tester.pumpWidget(amount(500));
      expect(find.text('500'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
  testWidgets('a hidden entrance stops scheduling and advancing frames', (
    tester,
  ) async {
    Widget page(bool visible) => host(
      TickerMode(
        enabled: visible,
        child: const MotionEntrance(child: Text('Card')),
      ),
    );
    await tester.pumpWidget(page(true));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(page(false));
    final fade = find.descendant(
      of: find.byType(MotionEntrance),
      matching: find.byType(FadeTransition),
    );
    final paused = tester.widget<FadeTransition>(fade).opacity.value;
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<FadeTransition>(fade).opacity.value, paused);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
  });
}
