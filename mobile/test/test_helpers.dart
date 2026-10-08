import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // Scroll the page, rather than a TextField's internal Scrollable.
    final pageScroll = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(finder, 220, scrollable: pageScroll);
  }
  // Center controls inside the viewport, clear of the bottom navigation bar.
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
}
