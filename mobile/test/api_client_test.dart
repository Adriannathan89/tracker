import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/api_client.dart';
import 'package:tracker/core/session_store.dart';

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async { values[key] = value; }
  @override
  Future<void> delete(String key) async { values.remove(key); }
}
class StubTransport implements ApiTransport {
  StubTransport(this.handler);
  final Future<ApiResponse> Function(String, Uri, Map<String, String>, Object?) handler;
  @override
  Future<ApiResponse> send(String method, Uri uri, Map<String, String> headers, Object? body) => handler(method, uri, headers, body);
  @override
  void close() {}
}
ApiResponse ok([Object? data]) => ApiResponse(200, {'data': data});
void main() {
  final base = Uri.parse('https://tracker.example.com/api/');
  test('expired access disappears while refresh survives persisted restart', () async {
    final storage = MemoryStore();
    final now = DateTime.utc(2026, 10, 9);
    final session = SessionStore(base, storage, now: () => now);
    await session.accept([
      'token=access; Max-Age=600; Path=/; Secure; HttpOnly',
      'refresh_token=refresh; Max-Age=2592000; Path=/; Secure; HttpOnly',
    ]);
    final restored = SessionStore(base, storage, now: () => now.add(const Duration(minutes: 11)));
    await restored.restore();
    expect(restored.cookieHeader, 'refresh_token=refresh');
  });
  test('concurrent unauthorized requests share refresh and retry once', () async {
    var refreshes = 0;
    var authorized = false;
    final barrier = Completer<void>();
    var initial = 0;
    final api = ApiClient(base, SessionStore(base, MemoryStore()), StubTransport((m, uri, h, b) async {
      if (uri.path.endsWith('/auth/refresh')) {
        refreshes++;
        await barrier.future;
        authorized = true;
        return ok();
      }
      if (!authorized) {
        initial++;
        if (initial == 2) { barrier.complete(); }
        return ApiResponse(401, {'message': 'Unauthorized'});
      }
      return ok('loaded');
    }));
    expect(await Future.wait([api.request('GET', 'user/profile'), api.request('GET', 'user/records')]), ['loaded', 'loaded']);
    expect(refreshes, 1);
  });
  test('wrong login does not refresh', () async {
    var calls = 0;
    final api = ApiClient(base, SessionStore(base, MemoryStore()), StubTransport((m, u, h, b) async {
      calls++;
      return ApiResponse(401, {'message': 'Unauthorized'});
    }));
    await expectLater(api.request('POST', 'auth/login', body: {}), throwsA(isA<ApiException>()));
    expect(calls, 1);
    expect(api.sessionExpired.value, false);
  });
  test('failed refresh clears credentials and expires session', () async {
    final session = SessionStore(base, MemoryStore());
    await session.accept(['refresh_token=r; Max-Age=10000; Path=/; Secure']);
    final api = ApiClient(base, session, StubTransport((m, u, h, b) async => ApiResponse(401, {'message': 'Unauthorized'})));
    await expectLater(api.request('GET', 'user/profile'), throwsA(isA<ApiException>()));
    expect(session.cookieHeader, isEmpty);
    expect(api.sessionExpired.value, true);
  });
  test('network errors do not replay writes or erase credentials', () async {
    final session = SessionStore(base, MemoryStore());
    await session.accept(['refresh_token=r; Max-Age=10000; Path=/; Secure']);
    var calls = 0;
    final api = ApiClient(base, session, StubTransport((m, u, h, b) async {
      calls++;
      throw const ApiException('Tidak ada koneksi.');
    }));
    await expectLater(api.request('POST', 'user/record', body: {}), throwsA(isA<ApiException>()));
    expect(calls, 1);
    expect(session.cookieHeader, contains('refresh_token=r'));
    expect(api.sessionExpired.value, false);
  });
  test('a network failure during refresh retains login for a later retry', () async {
    final session = SessionStore(base, MemoryStore());
    await session.accept(['refresh_token=r; Max-Age=10000; Path=/; Secure']);
    final api = ApiClient(base, session, StubTransport((m, u, h, b) async {
      if (u.path.endsWith('auth/refresh')) { throw const ApiException('Offline'); }
      return ApiResponse(401, {'message': 'Unauthorized'});
    }));
    await expectLater(api.request('GET', 'user/profile'), throwsA(isA<ApiException>()));
    expect(session.hasSession, true);
    expect(api.sessionExpired.value, false);
  });
  test('secure cookies cannot be persisted for an HTTP backend', () async {
    final session = SessionStore(Uri.parse('http://localhost:8080/'), MemoryStore());
    await session.accept(['token=secret; Max-Age=600; Path=/; Secure']);
    expect(session.hasSession, false);
  });
  test('logout clears device session even when server is offline', () async {
    final session = SessionStore(base, MemoryStore());
    await session.accept(['refresh_token=r; Max-Age=10000; Path=/; Secure']);
    final api = ApiClient(base, session, StubTransport((m, u, h, b) async {
      throw const ApiException('Offline');
    }));
    await expectLater(api.logout(), throwsA(isA<ApiException>()));
    expect(session.hasSession, false);
    expect(api.sessionExpired.value, true);
  });
  test('pending encrypted writes finish before logout deletion', () async {
    final storage = DelayedStore();
    final session = SessionStore(base, storage);
    final saving = session.accept(['refresh_token=r; Max-Age=10000; Path=/; Secure']);
    await Future<void>.delayed(Duration.zero);
    final clearing = session.clear();
    storage.release.complete();
    await Future.wait([saving, clearing]);
    final restored = SessionStore(base, storage);
    await restored.restore();
    expect(restored.hasSession, false);
  });
}
class DelayedStore extends MemoryStore {
  final release = Completer<void>();
  @override
  Future<void> write(String key, String value) async {
    await release.future;
    await super.write(key, value);
  }
}
