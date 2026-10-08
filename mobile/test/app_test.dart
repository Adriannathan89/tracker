import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/app.dart';
import 'package:tracker/core/api_client.dart';
import 'package:tracker/core/app_controller.dart';
import 'api_client_test.dart' show MemoryStore, StubTransport, ok;
import 'package:tracker/core/session_store.dart';

void main() {
  testWidgets('login validation, four destinations and draft creation use actual API payloads', (tester) async {
    final calls = <String>[];
    final bodies = <String, Object?>{};
    final base = Uri.parse('https://tracker.example.com/api/');
    final controller = AppController(ApiClient(base, SessionStore(base, MemoryStore()),
      StubTransport((method, uri, headers, body) async {
        calls.add('$method ${uri.path}'); bodies[uri.path] = body;
        if (uri.path.endsWith('user/profile')) return ok({'id': 'me', 'username': 'adrian',
          'discord': {'connected': false, 'username': '', 'commitNotifEnabled': false, 'weeklyNotifEnabled': false}});
        if (uri.path.endsWith('user/records')) return ok({'expenses': [], 'incomes': [], 'debts': [],
          'cash': 100, 'debt': 0, 'receivable': 0, 'balance': 100});
        if (uri.path.endsWith('debt') || uri.path.endsWith('debt/owed')) return ok({'debts': []});
        if (uri.path.contains('user/friend')) return ok([]);
        return ok();
      })), MemoryStore());
    controller.state = SessionState.signedOut;
    await tester.pumpWidget(TrackerApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();
    expect(find.text('Masukkan username.'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'Username'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'adrian');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo Bersih'), findsOneWidget);
    for (final label in ['Catatan', 'Teman', 'Saya', 'Beranda']) {
      await tester.tap(find.byTooltip(label)); await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Tambah catatan')); await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Jumlah (Rp)'), '12500');
    await tester.tap(find.text('Lanjutkan')); await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Judul'), 'Makan siang');
    await tester.ensureVisible(find.text('Simpan catatan'));
    await tester.tap(find.text('Simpan catatan')); await tester.pumpAndSettle();
    expect(calls, contains('POST /api/user/record'));
    expect((bodies['/api/user/record'] as Map)['amount'], 12500);
    expect((bodies['/api/user/record'] as Map)['title'], 'Makan siang');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
