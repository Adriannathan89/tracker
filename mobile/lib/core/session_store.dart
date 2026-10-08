import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
class SecureStore implements KeyValueStore {
  final _storage = const FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Only the backend's host-only, root-path session cookies are accepted.
/// Expiry is stored as an absolute instant so restarts cannot extend Max-Age.
class SessionStore {
  SessionStore(this.base, this.storage, {DateTime Function()? now})
      : _now = now ?? DateTime.now;
  final Uri base;
  final KeyValueStore storage;
  final DateTime Function() _now;
  final _cookies = <String, Map<String, dynamic>>{};
  Future<void> _writes = Future.value();
  String get _key => 'tracker.session.${base.origin}';
  String get cookieHeader => _cookies.entries.where((entry) {
    final expiry = DateTime.parse(entry.value['expires'] as String);
    return expiry.isAfter(_now()) &&
        (entry.value['secure'] != true || base.scheme == 'https');
  }).map((entry) => '${entry.key}=${entry.value['value']}').join('; ');
  bool get hasSession => cookieHeader.isNotEmpty;
  Future<void> restore() async {
    _cookies.clear();
    final value = await storage.read(_key);
    if (value == null) return;
    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      for (final name in ['token', 'refresh_token']) {
        final item = data[name];
        if (item is Map<String, dynamic> && item['value'] is String &&
            item['secure'] is bool && item['expires'] is String &&
            DateTime.tryParse(item['expires'] as String) != null) {
          _cookies[name] = item;
        }
      }
    } on FormatException {
      await clear();
    } on TypeError {
      await clear();
    }
  }
  Future<void> accept(List<String> values) async {
    for (final value in values) {
      final cookie = Cookie.fromSetCookieValue(value);
      if (!['token', 'refresh_token'].contains(cookie.name) ||
          cookie.domain != null || (cookie.path != null && cookie.path != '/') ||
          (cookie.secure && base.scheme != 'https')) continue;
      final expiry = cookie.maxAge != null
          ? _now().add(Duration(seconds: cookie.maxAge!)) : cookie.expires;
      if (expiry == null) continue;
      if (cookie.value.isEmpty || !expiry.isAfter(_now())) {
        _cookies.remove(cookie.name);
      } else {
        _cookies[cookie.name] = {'value': cookie.value,
          'secure': cookie.secure, 'expires': expiry.toUtc().toIso8601String()};
      }
    }
    if (values.isNotEmpty) {
      final snapshot = jsonEncode(_cookies);
      await _persist(() => storage.write(_key, snapshot));
    }
  }
  Future<void> clear() async {
    _cookies.clear();
    await _persist(() => storage.delete(_key));
  }
  Future<void> _persist(Future<void> Function() operation) {
    // Serialize disk writes so a late cookie write cannot restore a logged-out session.
    final pending = _writes.then((_) => operation());
    _writes = pending.catchError((Object _) {});
    return pending;
  }
}
