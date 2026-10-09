import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/api_client.dart';
import 'package:tracker/core/app_controller.dart';
import 'package:tracker/core/session_store.dart';
import 'api_client_test.dart' show MemoryStore, StubTransport, ok;

Map<String, Object?> profile() => {
  'id': 'me',
  'username': 'adrian',
  'discord': {'connected': false},
};
Map<String, Object?> overview(int balance) => {
  'expenses': [],
  'incomes': [],
  'debts': [],
  'cash': balance,
  'debt': 0,
  'receivable': 0,
  'balance': balance,
};
void main() {
  test(
    'an older overlapping reload cannot overwrite a newer balance',
    () async {
      final old = Completer<void>();
      var reads = 0;
      final base = Uri.parse('https://tracker.example.com/api/');
      final controller = AppController(
        ApiClient(
          base,
          SessionStore(base, MemoryStore()),
          StubTransport((m, uri, h, b) async {
            if (uri.path.endsWith('user/profile')) {
              return ok(profile());
            }
            if (uri.path.endsWith('user/records')) {
              reads++;
              if (reads == 1) {
                await old.future;
                return ok(overview(10));
              }
              return ok(overview(20));
            }
            if (uri.path.endsWith('debt') || uri.path.endsWith('debt/owed')) {
              return ok({'debts': []});
            }
            return ok([]);
          }),
        ),
        MemoryStore(),
      );
      controller.state = SessionState.signedIn;
      final first = controller.reload();
      await Future<void>.delayed(Duration.zero);
      await controller.reload();
      expect(controller.overview?.balance, 20);
      old.complete();
      await first;
      expect(controller.overview?.balance, 20);
      controller.dispose();
    },
  );
  test(
    'unavailable server at startup preserves session and offers retry',
    () async {
      final base = Uri.parse('https://tracker.example.com/api/');
      final session = SessionStore(base, MemoryStore());
      await session.accept([
        'refresh_token=refresh; Max-Age=2592000; Path=/; Secure',
      ]);
      final controller = AppController(
        ApiClient(
          base,
          session,
          StubTransport((m, u, h, b) async {
            throw const ApiException('Offline');
          }),
        ),
        MemoryStore(),
      );
      await controller.start();
      expect(controller.state, SessionState.unavailable);
      expect(session.hasSession, true);
      expect(controller.error, 'Offline');
      controller.dispose();
    },
  );
}
