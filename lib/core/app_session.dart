import 'package:flutter/foundation.dart';

import 'api_client.dart';

class AppSession extends ChangeNotifier {
  AppSession._();
  static final AppSession instance = AppSession._();

  Map<String, dynamic>? user;
  bool get isAuthenticated => ApiClient.instance.isAuthenticated;

  Future<void> restore() async {
    await ApiClient.instance.restoreToken();
    if (!isAuthenticated) return;
    try {
      user = Map<String, dynamic>.from(
          await ApiClient.instance.get('/me', authenticated: true));
    } catch (_) {
      await ApiClient.instance.clearToken();
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = Map<String, dynamic>.from(await ApiClient.instance.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    ));
    await ApiClient.instance.saveToken(data['accessToken'] as String);
    user = Map<String, dynamic>.from(data['user'] as Map);
    notifyListeners();
  }

  Future<void> register(String fullName, String email, String password) async {
    final data = Map<String, dynamic>.from(await ApiClient.instance.post(
      '/auth/register',
      body: {'fullName': fullName, 'email': email, 'password': password},
    ));
    await ApiClient.instance.saveToken(data['accessToken'] as String);
    user = Map<String, dynamic>.from(data['user'] as Map);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    user = Map<String, dynamic>.from(
        await ApiClient.instance.get('/me', authenticated: true));
    notifyListeners();
  }

  Future<void> updateProfile(String fullName, {String? avatarUrl}) async {
    user = Map<String, dynamic>.from(await ApiClient.instance.patch(
      '/me',
      authenticated: true,
      body: {
        'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl
      },
    ));
    notifyListeners();
  }

  Future<void> logout() async {
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
}
