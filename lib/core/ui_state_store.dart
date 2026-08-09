import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent, non-sensitive UI state shared by all screens.
class UiStateStore {
  UiStateStore._();

  static final UiStateStore instance = UiStateStore._();
  static const _prefix = 'flix_ui.';

  SharedPreferences? _preferences;
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    _preferences = await SharedPreferences.getInstance();
    _ready = true;
  }

  String? string(String key) => _preferences?.getString('$_prefix$key');
  bool? boolean(String key) => _preferences?.getBool('$_prefix$key');
  int? integer(String key) => _preferences?.getInt('$_prefix$key');
  double? decimal(String key) => _preferences?.getDouble('$_prefix$key');
  List<String>? strings(String key) =>
      _preferences?.getStringList('$_prefix$key');

  Map<String, dynamic>? json(String key) {
    final value = string(key);
    if (value == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (_) {
      unawaited(remove(key));
      return null;
    }
  }

  Future<void> setString(String key, String value) async {
    await _preferences?.setString('$_prefix$key', value);
  }

  Future<void> setBool(String key, bool value) async {
    await _preferences?.setBool('$_prefix$key', value);
  }

  Future<void> setInt(String key, int value) async {
    await _preferences?.setInt('$_prefix$key', value);
  }

  Future<void> setDouble(String key, double value) async {
    await _preferences?.setDouble('$_prefix$key', value);
  }

  Future<void> setStrings(String key, Iterable<String> value) async {
    await _preferences?.setStringList('$_prefix$key', value.toList());
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));
  Future<void> remove(String key) async {
    await _preferences?.remove('$_prefix$key');
  }
}

/// Saves scroll position without writing to storage for every rendered pixel.
class PersistentScrollController extends ScrollController {
  PersistentScrollController(this.stateKey)
      : super(
            initialScrollOffset: UiStateStore.instance.decimal(stateKey) ?? 0) {
    addListener(_scheduleSave);
  }

  final String stateKey;
  Timer? _saveTimer;

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), _save);
  }

  void _save() {
    if (hasClients) {
      unawaited(UiStateStore.instance.setDouble(stateKey, offset));
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save();
    removeListener(_scheduleSave);
    super.dispose();
  }
}
