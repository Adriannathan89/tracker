import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'session_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}
class ApiResponse {
  ApiResponse(this.status, this.body, {this.cookies = const []});
  final int status;
  final Object? body;
  final List<String> cookies;
}
abstract interface class ApiTransport {
  Future<ApiResponse> send(String method, Uri uri, Map<String, String> headers, Object? body);
  void close();
}
class IoTransport implements ApiTransport {
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  @override
  Future<ApiResponse> send(String method, Uri uri, Map<String, String> headers, Object? body) async {
    HttpClientRequest? request;
    try {
      request = await _client.openUrl(method, uri).timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 30));
      final bytes = await response.fold<List<int>>([], (acc, part) {
        if (acc.length + part.length > 8 * 1024 * 1024) {
          throw const ApiException('Respons server terlalu besar.');
        }
        return acc..addAll(part);
      }).timeout(const Duration(seconds: 30));
      Object? payload;
      if (bytes.isNotEmpty) {
        try { payload = jsonDecode(utf8.decode(bytes)); }
        on FormatException { throw const ApiException('Respons server tidak valid. Periksa URL API.'); }
      }
      return ApiResponse(response.statusCode, payload,
          cookies: response.headers[HttpHeaders.setCookieHeader] ?? []);
    } on TimeoutException {
      request?.abort();
      throw const ApiException('Server terlalu lama merespons. Muat ulang data sebelum mencoba lagi.');
    } on SocketException {
      throw const ApiException('Tidak dapat terhubung. Periksa koneksi internet dan server.');
    } on HandshakeException {
      throw const ApiException('Sertifikat HTTPS server tidak dapat diverifikasi.');
    } on HttpException {
      throw const ApiException('Koneksi server terputus. Muat ulang data sebelum mencoba lagi.');
    }
  }
  @override
  void close() => _client.close(force: true);
}
class ApiClient {
  ApiClient(this.base, this.session, this.transport);
  final Uri base;
  final SessionStore session;
  final ApiTransport transport;
  final sessionExpired = ValueNotifier(false);
  Future<void>? _refresh;
  int _revision = 0;
  int _identity = 0;
  bool _closed = false;
  static const _authPaths = {'auth/login', 'auth/logout', 'auth/refresh', 'user/register'};
  Future<Object?> request(String method, String path, {Object? body}) async {
    if (path.startsWith('/') || path.contains('..') || Uri.parse(path).hasScheme) {
      throw ArgumentError('API path must be relative.');
    }
    final identity = _identity;
    final revision = _revision;
    var response = await _send(method, path, body, identity);
    if (response.status == 401 && !_authPaths.contains(path)) {
      if (identity != _identity) throw const ApiException('Sesi telah berubah.', status: 401);
      if (revision == _revision) {
        final refresh = _refresh ??= _refreshSession(identity);
        try { await refresh; }
        finally { if (identical(_refresh, refresh)) _refresh = null; }
      }
      response = await _send(method, path, body, identity);
      if (response.status == 401) await _expire(identity);
    }
    _check(response);
    return (response.body as Map<String, dynamic>?)?['data'];
  }
  Future<ApiResponse> _send(String method, String path, Object? body, int identity) async {
    if (_closed) throw const ApiException('Aplikasi sudah ditutup.');
    final response = await transport.send(method, base.resolve(path), {
      'Accept': 'application/json', 'Content-Type': 'application/json',
      if (session.cookieHeader.isNotEmpty) 'Cookie': session.cookieHeader,
    }, body);
    if (_closed || identity != _identity) throw const ApiException('Sesi telah berubah.', status: 401);
    // Error responses must not replace a still valid refresh cookie.
    if (response.status >= 200 && response.status < 300) await session.accept(response.cookies);
    return response;
  }
  Future<void> _refreshSession(int identity) async {
    final response = await _send('POST', 'auth/refresh', null, identity);
    if (response.status == 401) await _expire(identity);
    _check(response);
    _revision++;
  }
  Future<void> _expire(int identity) async {
    if (identity != _identity) return;
    _identity++;
    await session.clear();
    if (!_closed) sessionExpired.value = true;
  }
  void _check(ApiResponse response) {
    if (response.status >= 200 && response.status < 300) return;
    final data = response.body;
    var message = data is Map && data['message'] is String
        ? data['message'] as String : 'Permintaan gagal (${response.status}).';
    if (response.status == 401) message = 'Username/password salah atau sesi telah berakhir.';
    if (response.status == 503) message = 'Fitur ini belum tersedia di server. Coba lagi nanti.';
    throw ApiException(message, status: response.status);
  }
  Future<void> login(String username, String password) async {
    _identity++;
    await session.clear();
    sessionExpired.value = false;
    await request('POST', 'auth/login', body: {'username': username, 'password': password});
  }
  Future<void> logout() async {
    try { await request('POST', 'auth/logout'); }
    finally {
      _identity++;
      await session.clear();
      if (!_closed) sessionExpired.value = true;
    }
  }
  void close() { _closed = true; _identity++; transport.close(); sessionExpired.dispose(); }
}
