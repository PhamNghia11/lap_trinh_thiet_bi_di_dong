import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'flix_access_token';
  static const _refreshTokenKey = 'flix_refresh_token';
  static const _cachePrefix = 'flix_cache.';
  static const _storage = FlutterSecureStorage();
  final http.Client _http = http.Client();
  static const _configuredBaseUrl = String.fromEnvironment('FLIX_API_URL');
  static const _webBaseUrl =
      'https://lap-trinh-thiet-bi-di-dong.onrender.com/api/v1';
  static const _androidBaseUrl = 'http://10.0.2.2:3000/api/v1';

  @visibleForTesting
  static String resolveBaseUrl({
    required bool isWeb,
    String configuredBaseUrl = _configuredBaseUrl,
  }) {
    final selected = configuredBaseUrl.isNotEmpty
        ? configuredBaseUrl
        : (isWeb ? _webBaseUrl : _androidBaseUrl);
    return selected.endsWith('/')
        ? selected.substring(0, selected.length - 1)
        : selected;
  }

  final String baseUrl = resolveBaseUrl(isWeb: kIsWeb);

  String? _token;
  String? _refreshToken;
  Future<bool>? _refreshInFlight;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Called once when an authenticated request proves the token is invalid.
  Future<void> Function()? onUnauthorized;

  Future<void> restoreToken() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _refreshTokenKey),
    ]);
    _token = values[0];
    _refreshToken = values[1];
  }

  Future<void> saveSession(String accessToken, String refreshToken) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _tokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> logout() async {
    final refreshToken = _refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await post('/auth/logout', body: {'refreshToken': refreshToken});
      }
    } finally {
      await clearToken();
    }
  }

  Future<dynamic> get(String path, {bool authenticated = false}) =>
      _request('GET', path, authenticated: authenticated);

  /// Persistent cache for public read-only endpoints. Expired data is only
  /// returned when the network is unavailable.
  Future<dynamic> getCached(
    String path, {
    Duration ttl = const Duration(minutes: 10),
    bool forceRefresh = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key =
        '$_cachePrefix${base64Url.encode(utf8.encode('$baseUrl$path'))}';
    final stored = preferences.getString(key);
    Map<String, dynamic>? cached;
    if (stored != null) {
      try {
        cached = Map<String, dynamic>.from(jsonDecode(stored) as Map);
        final savedAt = DateTime.tryParse(cached['savedAt'] as String? ?? '');
        if (!forceRefresh &&
            savedAt != null &&
            DateTime.now().difference(savedAt) <= ttl) {
          return cached['data'];
        }
      } catch (_) {
        await preferences.remove(key);
        cached = null;
      }
    }

    try {
      final data = await get(path);
      await preferences.setString(
        key,
        jsonEncode({'savedAt': DateTime.now().toIso8601String(), 'data': data}),
      );
      return data;
    } catch (_) {
      if (cached != null && cached.containsKey('data')) return cached['data'];
      rethrow;
    }
  }

  Future<int> cacheSizeBytes() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences
        .getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .fold<int>(
            0,
            (sum, key) =>
                sum + utf8.encode(preferences.getString(key) ?? '').length);
  }

  Future<void> clearCache() async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait(preferences
        .getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .map(preferences.remove));
  }

  Future<dynamic> post(String path,
          {Object? body, bool authenticated = false}) =>
      _request('POST', path, body: body, authenticated: authenticated);
  Future<dynamic> put(String path,
          {Object? body, bool authenticated = false}) =>
      _request('PUT', path, body: body, authenticated: authenticated);
  Future<dynamic> patch(String path,
          {Object? body, bool authenticated = false}) =>
      _request('PATCH', path, body: body, authenticated: authenticated);
  Future<dynamic> delete(String path, {bool authenticated = false}) =>
      _request('DELETE', path, authenticated: authenticated);

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    bool authenticated = false,
    bool allowRefresh = true,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final requestToken = authenticated ? _token : null;
    if (authenticated) {
      if (!isAuthenticated) {
        throw const ApiException('Vui lòng đăng nhập để tiếp tục',
            statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $requestToken';
    }
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    late final http.Response response;
    try {
      final streamed =
          await _http.send(request).timeout(const Duration(seconds: 15));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        'Máy chủ phản hồi quá chậm. Vui lòng thử lại.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.',
      );
    }
    final decoded = decodeResponseBody(
      response.body,
      statusCode: response.statusCode,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 &&
          requestToken != null &&
          requestToken == _token) {
        if (allowRefresh && await _refreshSession()) {
          return _request(
            method,
            path,
            body: body,
            authenticated: authenticated,
            allowRefresh: false,
          );
        }
        if (requestToken == _token) {
          await clearToken();
          await onUnauthorized?.call();
        }
      }
      final message =
          decoded is Map<String, dynamic> ? decoded['message'] : null;
      throw ApiException(
        message is List
            ? message.join(', ')
            : (message?.toString() ?? 'Yêu cầu không thành công'),
        statusCode: response.statusCode,
      );
    }
    return decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
  }

  Future<bool> _refreshSession() async {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final refresh = _performRefresh();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final data = Map<String, dynamic>.from(await _request(
        'POST',
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        allowRefresh: false,
      ));
      await saveSession(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  static dynamic decodeResponseBody(
    String body, {
    required int statusCode,
  }) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw ApiException(
        statusCode >= 500
            ? 'Máy chủ đang tạm thời không ổn định. Vui lòng thử lại.'
            : 'Máy chủ trả về dữ liệu không hợp lệ.',
        statusCode: statusCode,
      );
    }
  }
}
