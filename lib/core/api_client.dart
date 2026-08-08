import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
  static const _storage = FlutterSecureStorage();
  final http.Client _http = http.Client();
  final String baseUrl = const String.fromEnvironment(
    'FLIX_API_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  String? _token;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> restoreToken() async => _token = await _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<dynamic> get(String path, {bool authenticated = false}) =>
      _request('GET', path, authenticated: authenticated);
  Future<dynamic> post(String path, {Object? body, bool authenticated = false}) =>
      _request('POST', path, body: body, authenticated: authenticated);
  Future<dynamic> put(String path, {Object? body, bool authenticated = false}) =>
      _request('PUT', path, body: body, authenticated: authenticated);
  Future<dynamic> patch(String path, {Object? body, bool authenticated = false}) =>
      _request('PATCH', path, body: body, authenticated: authenticated);
  Future<dynamic> delete(String path, {bool authenticated = false}) =>
      _request('DELETE', path, authenticated: authenticated);

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    bool authenticated = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      if (!isAuthenticated) throw const ApiException('Vui lòng đăng nhập để tiếp tục', statusCode: 401);
      headers['Authorization'] = 'Bearer $_token';
    }
    final request = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _http.send(request).timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) await clearToken();
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      throw ApiException(
        message is List ? message.join(', ') : (message?.toString() ?? 'Yêu cầu không thành công'),
        statusCode: response.statusCode,
      );
    }
    return decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
  }
}
