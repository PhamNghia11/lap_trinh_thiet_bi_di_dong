import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final AppPreferences instance = AppPreferences._();

  bool notifications = true;
  bool autoPlayTrailer = false;
  bool wifiOnly = true;
  String videoQuality = 'Tự động';
  bool cinematicNoir = true;
  int appRating = 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notifications = prefs.getBool('notifications') ?? true;
    autoPlayTrailer = prefs.getBool('autoPlayTrailer') ?? false;
    wifiOnly = prefs.getBool('wifiOnly') ?? true;
    videoQuality = prefs.getString('videoQuality') ?? 'Tự động';
    cinematicNoir = prefs.getBool('cinematicNoir') ?? true;
    appRating = prefs.getInt('appRating') ?? 0;
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    notifications = value;
    await (await SharedPreferences.getInstance())
        .setBool('notifications', value);
    notifyListeners();
  }

  Future<void> setAutoPlayTrailer(bool value) async {
    autoPlayTrailer = value;
    await (await SharedPreferences.getInstance())
        .setBool('autoPlayTrailer', value);
    notifyListeners();
  }

  Future<void> setWifiOnly(bool value) async {
    wifiOnly = value;
    await (await SharedPreferences.getInstance()).setBool('wifiOnly', value);
    notifyListeners();
  }

  Future<void> setVideoQuality(String value) async {
    videoQuality = value;
    await (await SharedPreferences.getInstance())
        .setString('videoQuality', value);
    notifyListeners();
  }

  Future<void> setCinematicNoir(bool value) async {
    cinematicNoir = value;
    await (await SharedPreferences.getInstance())
        .setBool('cinematicNoir', value);
    notifyListeners();
  }

  Future<void> setAppRating(int value) async {
    appRating = value;
    await (await SharedPreferences.getInstance()).setInt('appRating', value);
    notifyListeners();
  }
}
