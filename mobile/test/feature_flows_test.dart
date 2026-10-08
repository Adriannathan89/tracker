import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/app.dart';
import 'package:tracker/core/api_client.dart';
import 'package:tracker/core/app_controller.dart';
import 'package:tracker/core/models.dart';
import 'package:tracker/core/session_store.dart';
import 'api_client_test.dart' show MemoryStore, StubTransport, ok;
import 'test_helpers.dart';

Map<String, dynamic> record({bool committed = false}) => {
  'id': 'r1',
  'title': 'Makan siang',
  'description': 'Nasi goreng',
  'amount': 25000,
  'type': 'expense',
  'createdAt': '2026-10-09T08:00:00Z',
  'isCommitted': committed,
  'categories': [
    {'id': 'p', 'name': 'makanan', 'type': 'primary'},
    {'id': 's', 'name': 'jajanan', 'type': 'secondary'},
  ],
};
Map<String, dynamic> debt() => {
  'id': 'd1',
  'ownerId': 'friend',
  'debtorId': 'me',
  'owner': {'id': 'friend', 'username': 'budi'},
  'debtor': {'id': 'me', 'username': 'adrian'},
  'amount': 15000,
  'description': 'Tiket',
  'status': 'pending',
};

class Fixture {
  final calls = <String, Object?>{};
  late final AppController controller;
  Fixture({bool committed = false}) {
    final base = Uri.parse('https://tracker.example.com/api/');
    controller = AppController(
      ApiClient(
        base,
        SessionStore(base, MemoryStore()),
        StubTransport((method, uri, headers, body) async {
          if (method != 'GET') {
            calls['$method ${uri.path}'] = body;
            return ok();
          }
          if (uri.path.endsWith('user/profile')) {
            return ok({
              'id': 'me',
              'username': 'adrian',
              'discord': {
                'connected': false,
                'username': '',
                'commitNotifEnabled': false,
                'weeklyNotifEnabled': false,
              },
            });
          }
          if (uri.path.endsWith('user/records')) {
            return ok({
              'expenses': [record(committed: committed)],
              'incomes': [],
              'debts': [],
              'cash': 10,
              'debt': 15000,
              'receivable': 0,
              'balance': -14990,
            });
          }
          if (uri.path.endsWith('user/friend/request')) {
            return ok([
              {
                'id': 'q1',
                'sender': {'id': 'other', 'username': 'siti'},
                'receiver': {'id': 'me', 'username': 'adrian'},
              },
            ]);
          }
          if (uri.path.endsWith('user/friend')) {
            return ok([
              {'id': 'friend', 'username': 'budi', 'status': 'accepted'},
            ]);
          }
          if (uri.path.endsWith('debt/owed')) {
            return ok({
              'debts': [debt()],
            });
          }
          return ok({'debts': []});
        }),
      ),
      MemoryStore(),
    );
    controller.state = SessionState.signedIn;
  }
  Future<void> pump(WidgetTester tester) async {
    await controller.reload();
    await tester.pumpWidget(TrackerApp(controller: controller));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  }
}

void main() {
  testWidgets(
    'correcting primary resets secondary and confirms backend draft',
    (tester) async {
      final fixture = Fixture();
      await fixture.pump(tester);
      await tester.tap(find.byTooltip('Catatan'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Makan siang'));
      await tester.tap(find.text('Makan siang'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('💰 gaji'));
      await tester.tap(find.text('💰 gaji'));
      await tester.pumpAndSettle();
      final commit = find.widgetWithText(FilledButton, 'Konfirmasi catatan');
      await reveal(tester, commit);
      await tester.tap(commit);
      await tester.pumpAndSettle();
      expect(fixture.calls['PUT /api/user/record/commit'], {
        'recordId': 'r1',
        'category': 'gaji',
        'secondaryCategory': 'gaji',
      });
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    },
  );
  testWidgets(
    'friends accepts incoming requests and creates debt with friend ID',
    (tester) async {
      final fixture = Fixture();
      await fixture.pump(tester);
      await tester.tap(find.byTooltip('Teman'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Terima'));
      await tester.tap(find.text('Terima'));
      await tester.pumpAndSettle();
      expect(fixture.calls['PUT /api/user/friend/request/response'], {
        'friendRequestId': 'q1',
        'action': 'accept',
      });
      await reveal(tester, find.text('Tambah piutang'));
      await tester.tap(find.text('Tambah piutang'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Jumlah piutang (Rp)'),
        '12000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Untuk apa?'),
        'Makan bersama',
      );
      await reveal(tester, find.text('Simpan piutang'));
      await tester.tap(find.text('Simpan piutang'));
      await tester.pumpAndSettle();
      expect(fixture.calls['POST /api/debt/create'], {
        'amount': 12000,
        'description': 'Makan bersama',
        'debtorId': 'friend',
      });
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    },
  );
  testWidgets('debtor confirms repayment before sending finish request', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.pump(tester);
    await tester.tap(find.byTooltip('Teman'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Tandai lunas'));
    await tester.tap(find.text('Tandai lunas'));
    await tester.pumpAndSettle();
    expect(fixture.calls.containsKey('PUT /api/debt/finish'), false);
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(fixture.calls['PUT /api/debt/finish'], {'debtId': 'd1'});
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });
  testWidgets('profile validates rename and persists dark preference', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.pump(tester);
    await tester.tap(find.byTooltip('Saya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah username'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'a');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(fixture.calls.containsKey('PUT /api/user/profile'), false);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'adrianbaru',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(fixture.calls['PUT /api/user/profile'], {'username': 'adrianbaru'});
    await reveal(tester, find.text('Mode gelap'));
    await tester.tap(find.text('Mode gelap'));
    await tester.pumpAndSettle();
    expect(fixture.controller.dark, true);
    expect(await fixture.controller.preferences.read('tracker.dark'), 'true');
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });
  testWidgets('committed records expose no deletion or recommit', (
    tester,
  ) async {
    final fixture = Fixture(committed: true);
    await fixture.pump(tester);
    await tester.tap(find.byTooltip('Catatan'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Makan siang'));
    await tester.tap(find.text('Makan siang'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus draft'), findsNothing);
    expect(find.text('Konfirmasi catatan'), findsNothing);
    expect(tester.takeException(), isNull);
    await fixture.close(tester);
  });
  test('friend balances count only pending debts', () {
    final fixture = Fixture();
    fixture.controller.owed = [
      Debt.fromJson(debt()),
      Debt.fromJson({...debt(), 'status': 'completed'}),
    ];
    expect(fixture.controller.friendDebt('friend'), 15000);
    fixture.controller.dispose();
  });
}
