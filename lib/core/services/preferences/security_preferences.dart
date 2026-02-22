import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityPreferences {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  SecurityPreferences(this._prefs, this._secure);

  // — Key constants —
  static const String _kApiKey = 'nai_api_key';
  static const String _kSecureApiKey = 'nai_api_key_secure';
  static const String _kPinEnabled = 'pin_lock_enabled';
  static const String _kPinHash = 'pin_lock_hash';
  static const String _kPinSalt = 'pin_lock_salt';
  static const String _kPinOnResume = 'pin_lock_on_resume';
  static const String _kPinBiometric = 'pin_biometric_enabled';
  static const String _kPinVersion = 'pin_hash_version';

  // — API Key Migration —

  Future<void> migrateApiKey() async {
    final plaintext = _prefs.getString(_kApiKey) ?? '';
    if (plaintext.isNotEmpty) {
      await _secure.write(key: _kSecureApiKey, value: plaintext);
      await _prefs.remove(_kApiKey);
    }
  }

  // — API Key —

  Future<String> getApiKey() async {
    return await _secure.read(key: _kSecureApiKey) ?? '';
  }

  Future<void> setApiKey(String value) async {
    await _secure.write(key: _kSecureApiKey, value: value);
  }

  // — PIN Enabled —

  bool get pinEnabled => _prefs.getBool(_kPinEnabled) ?? false;

  Future<void> setPinEnabled(bool value) async {
    await _prefs.setBool(_kPinEnabled, value);
  }

  // — PIN Hash —

  String get pinHash => _prefs.getString(_kPinHash) ?? '';

  Future<void> setPinHash(String value) async {
    await _prefs.setString(_kPinHash, value);
  }

  // — PIN Salt —

  String get pinSalt => _prefs.getString(_kPinSalt) ?? '';

  Future<void> setPinSalt(String value) async {
    await _prefs.setString(_kPinSalt, value);
  }

  // — PIN Lock on Resume —

  bool get pinLockOnResume => _prefs.getBool(_kPinOnResume) ?? false;

  Future<void> setPinLockOnResume(bool value) async {
    await _prefs.setBool(_kPinOnResume, value);
  }

  // — PIN Biometric —

  bool get pinBiometricEnabled => _prefs.getBool(_kPinBiometric) ?? false;

  Future<void> setPinBiometricEnabled(bool value) async {
    await _prefs.setBool(_kPinBiometric, value);
  }

  // — PIN Hash Version —

  int get pinHashVersion => _prefs.getInt(_kPinVersion) ?? 1;

  Future<void> setPinHashVersion(int value) async {
    await _prefs.setInt(_kPinVersion, value);
  }
}
