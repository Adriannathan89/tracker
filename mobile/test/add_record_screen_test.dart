import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'feature_flows_test.dart' show Fixture;
import 'test_helpers.dart';

Future<void> openAmount(WidgetTester tester) async {
  final fixture = Fixture();
  addTearDown(() => fixture.close(tester));
  await fixture.pump(tester);
  await tester.tap(find.byTooltip('Tambah catatan'));
  await tester.pumpAndSettle();
}

Future<void> press(WidgetTester tester, String key) async {
  final finder = key == 'del'
      ? find.byTooltip('Hapus angka')
      : find.widgetWithText(OutlinedButton, key);
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keypad formats rupiah without opening the system keyboard', (
    tester,
  ) async {
    await openAmount(tester);
    expect(find.byType(TextFormField), findsNothing);
    for (final key in ['1', '2', '5', '0', '0']) {
      await press(tester, key);
    }
    expect(find.text('Rp 12.500'), findsOneWidget);
    expect(tester.testTextInput.isVisible, false);
    await press(tester, 'del');
    expect(find.text('Rp 1.250'), findsOneWidget);
    await press(tester, '000');
    expect(find.text('Rp 1.250.000'), findsOneWidget);
    await reveal(tester, find.text('Lanjutkan'));
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Ubah jumlah'));
    await tester.tap(find.text('Ubah jumlah'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 1.250.000'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
    'keypad preserves decimal zeros and limits input to two decimal places',
    (tester) async {
      await openAmount(tester);
      for (final key in ['1', '000', ',', '0', '5', '9', ',']) {
        await press(tester, key);
      }
      expect(find.text('Rp 1.000,05'), findsOneWidget);
      await press(tester, 'del');
      expect(find.text('Rp 1.000,0'), findsOneWidget);
      await press(tester, 'del');
      expect(find.text('Rp 1.000,'), findsOneWidget);
    },
  );

  testWidgets('zero cannot proceed and leading zeros do not accumulate', (
    tester,
  ) async {
    await openAmount(tester);
    await press(tester, '000');
    await press(tester, '0');
    expect(find.text('Rp 0'), findsOneWidget);
    await reveal(tester, find.text('Lanjutkan'));
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Detail catatan'), findsNothing);
    expect(
      find.text('Masukkan jumlah positif dengan maksimal 2 angka desimal.'),
      findsOneWidget,
    );
    await press(tester, '5');
    expect(find.text('Rp 5'), findsOneWidget);
    await press(tester, 'del');
    await press(tester, 'del');
    expect(find.text('Rp 0'), findsOneWidget);
  });
}
