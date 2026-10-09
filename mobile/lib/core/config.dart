class AppConfig {
  static const apiUrl = String.fromEnvironment(
    'TRACKER_API_URL',
    defaultValue: 'https://tracker.adrianportofolio.my.id/api/',
  );
  static Uri get apiBase {
    final uri = Uri.parse(apiUrl.endsWith('/') ? apiUrl : '$apiUrl/');
    if (!['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'TRACKER_API_URL harus berupa URL API HTTP/HTTPS.',
      );
    }
    const release = bool.fromEnvironment('dart.vm.product');
    if (release && uri.scheme != 'https') {
      throw const FormatException('APK release membutuhkan API HTTPS.');
    }
    return uri;
  }
}
