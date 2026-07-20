import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

typedef ListSyncCallback = Future<void> Function(String key, List<Map<String, dynamic>> items);
typedef ListLoadCallback = Future<List<Map<String, dynamic>>?> Function(String key);

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  SharedPreferences? _prefs;
  ListSyncCallback? onSaveList;
  ListLoadCallback? onLoadList;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final old = getString('couple_id');
    if (old == 'diego_yosmari' || old == 'novios' || old == null || old == 'default_couple_id' || old.isEmpty) {
      await setString('couple_id', 'default_couple_id');
    }
  }

  // General storage helpers
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  // App Security
  bool isSecurityEnabled() => getBool('security_enabled', defaultValue: false);
  String? getPin() => getString('app_pin');
  String? getSecurityQuestion() => getString('security_question');
  String? getSecurityAnswer() => getString('security_answer');

  Future<void> setSecurity({
    required bool enabled,
    String? pin,
    String? question,
    String? answer,
  }) async {
    await setBool('security_enabled', enabled);
    if (pin != null) await setString('app_pin', pin);
    if (question != null) await setString('security_question', question);
    if (answer != null) await setString('security_answer', answer);
  }

  // Couple Settings
  String? getUserId() => getString('user_id');
  String? getUserName() => getString('user_name');
  String? getPartnerName() => getString('partner_name');
  String? getAnniversaryDate() => getString('anniversary_date');
  String? getMetDate() => getString('met_date');
  String? getDatingDate() => getString('dating_date');
  String? getWeddingDate() => getString('wedding_date');

  Future<void> saveUserProfile({
    required String id,
    required String name,
    String? partnerName,
    String? anniversaryDate,
  }) async {
    await setString('user_id', id);
    await setString('user_name', name);
    if (partnerName != null) await setString('partner_name', partnerName);
    if (anniversaryDate != null) await setString('anniversary_date', anniversaryDate);
  }

  // Backup lists for offline / local-first storage (auto-sync to Firebase)
  Future<void> saveLocalList(String key, List<Map<String, dynamic>> list) async {
    final jsonList = list.map((item) => jsonEncode(item)).toList();
    await _prefs?.setStringList(key, jsonList);
    if (onSaveList != null) {
      await onSaveList!(key, list);
    }
  }

  List<Map<String, dynamic>> getLocalList(String key) {
    final stringList = _prefs?.getStringList(key) ?? [];
    return stringList.map((item) {
      try {
        return jsonDecode(item) as Map<String, dynamic>;
      } catch (e) {
        return <String, dynamic>{};
      }
    }).where((element) => element.isNotEmpty).toList();
  }

  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }
}
