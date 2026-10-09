import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'feature_flows_test.dart' show Fixture, debt;
import 'test_helpers.dart';

void main() {
  testWidgets('home mirrors the web quick actions and compact balance strip', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.pump(tester);
    expect(find.text('Tunai'), findsOneWidget);
    expect(find.text('Piutang'), findsOneWidget);
    expect(find.text('Hutang'), findsOneWidget);
    for (final label in ['Tambah', 'Tagih', 'Split']) {
      expect(find.text(label), findsOneWidget);
    }
    await reveal(tester, find.text('Tagih'));
    await tester.tap(find.text('Tagih'));
    await tester.pumpAndSettle();
    expect(find.text('budi'), findsWidgets);
    await fixture.close(tester);
  });

  testWidgets('record list mirrors web totals and grouped draft badges', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.pump(tester);
    await tester.tap(find.byTooltip('Catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengeluaran'), findsWidgets);
    expect(find.text('Pemasukan'), findsWidgets);
    await reveal(tester, find.text('Makan siang'));
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('makanan'), findsOneWidget);
    await fixture.close(tester);
  });

  testWidgets('mobile shell keeps web surfaces in dark mode', (tester) async {
    final fixture = Fixture();
    fixture.controller.dark = true;
    await fixture.pump(tester);
    final theme = Theme.of(tester.element(find.text('Tunai')));
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0D0D0A));
    expect(theme.colorScheme.outline, const Color(0xFF242219));
    await fixture.close(tester);
  });
  testWidgets('multiple debts remain selectable and repay the chosen debt ID', (
    tester,
  ) async {
    final fixture = Fixture(
      owedDebts: [
        debt(),
        {...debt(), 'id': 'd2', 'amount': 20000, 'description': 'Makan malam'},
      ],
    );
    await fixture.pump(tester);
    await tester.tap(find.byTooltip('Teman'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Bayar'));
    await tester.tap(find.text('Bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Tiket'), findsOneWidget);
    expect(find.text('Makan malam'), findsOneWidget);
    await reveal(tester, find.text('Tandai lunas').last);
    await tester.tap(find.text('Tandai lunas').last);
    await tester.pumpAndSettle();
    expect(fixture.calls.containsKey('PUT /api/debt/finish'), false);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(fixture.calls['PUT /api/debt/finish'], {'debtId': 'd2'});
    await fixture.close(tester);
  });

  testWidgets(
    'header and category controls remain usable with large Android text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fixture = Fixture();
      await fixture.pump(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Catatan'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Makan siang'));
      await tester.tap(find.text('Makan siang'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byTooltip('Kategori gaji'));
      await tester.tap(find.byTooltip('Kategori gaji'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    },
  );
  testWidgets(
    'balance detail retains receivables and debts outside the friend list',
    (tester) async {
      final fixture = Fixture(
        owedDebts: [
          {
            ...debt(),
            'ownerId': 'outside',
            'owner': {'id': 'outside', 'username': 'rina'},
          },
        ],
        ownedDebts: [
          {
            ...debt(),
            'id': 'receivable',
            'ownerId': 'me',
            'debtorId': 'friend',
            'owner': {'id': 'me', 'username': 'adrian'},
            'debtor': {'id': 'friend', 'username': 'budi'},
            'description': 'Pinjaman makan',
          },
        ],
      );
      await fixture.pump(tester);
      await tester.tap(find.byTooltip('Teman'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byTooltip('Rincian saldo teman'));
      await tester.tap(find.byTooltip('Rincian saldo teman'));
      await tester.pumpAndSettle();
      expect(find.text('rina'), findsOneWidget);
      await reveal(tester, find.text('Pinjaman makan'));
      expect(find.text('Pinjaman makan'), findsOneWidget);
      expect(find.text('Tandai lunas'), findsOneWidget);
      await fixture.close(tester);
    },
  );
}
