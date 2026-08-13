import 'package:flutter/foundation.dart';

import 'api_client.dart';

class AppSession extends ChangeNotifier {
  AppSession._() {
    ApiClient.instance.onUnauthorized = _handleUnauthorized;
  }
  static final AppSession instance = AppSession._();

  Map<String, dynamic>? user;
  bool _sessionExpired = false;
  bool get isAuthenticated => ApiClient.instance.isAuthenticated;

  bool consumeSessionExpired() {
    if (!_sessionExpired) return false;
    _sessionExpired = false;
    return true;
  }

  Future<void> _handleUnauthorized() async {
    user = null;
    _sessionExpired = true;
    notifyListeners();
  }

  Future<void> restore() async {
    await ApiClient.instance.restoreToken();
    if (!isAuthenticated) return;
    try {
      user = Map<String, dynamic>.from(
          await ApiClient.instance.get('/me', authenticated: true));
    } catch (error) {
      if (error is ApiException && error.statusCode == 401) {
        await ApiClient.instance.clearToken();
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = Map<String, dynamic>.from(await ApiClient.instance.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    ));
    await ApiClient.instance.saveSession(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    user = Map<String, dynamic>.from(data['user'] as Map);
    notifyListeners();
  }

  Future<void> register(String fullName, String email, String password) async {
    final data = Map<String, dynamic>.from(await ApiClient.instance.post(
      '/auth/register',
      body: {'fullName': fullName, 'email': email, 'password': password},
    ));
    await ApiClient.instance.saveSession(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    user = Map<String, dynamic>.from(data['user'] as Map);
    notifyListeners();
  }

  Future<void> completeSocialLogin(
      String accessToken, String refreshToken) async {
    await ApiClient.instance.saveSession(accessToken, refreshToken);
    try {
      user = Map<String, dynamic>.from(
          await ApiClient.instance.get('/me', authenticated: true));
      notifyListeners();
    } catch (_) {
      await ApiClient.instance.clearToken();
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    user = Map<String, dynamic>.from(
        await ApiClient.instance.get('/me', authenticated: true));
    notifyListeners();
  }

  Future<void> updateProfile(String fullName,
      {String? avatarUrl, String? coverUrl}) async {
    user = Map<String, dynamic>.from(await ApiClient.instance.patch(
      '/me',
      authenticated: true,
      body: {
        'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (coverUrl != null) 'coverUrl': coverUrl,
      },
    ));
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiClient.instance.logout();
    user = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await ApiClient.instance.delete('/me', authenticated: true);
    await ApiClient.instance.clearToken();
    user = null;
    notifyListeners();
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await ApiClient.instance.patch(
      '/auth/password',
      authenticated: true,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await ApiClient.instance.post(
      '/auth/password/forgot',
      body: {'email': email.trim()},
    );
  }

  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    await ApiClient.instance.post(
      '/auth/password/reset',
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  }
}
