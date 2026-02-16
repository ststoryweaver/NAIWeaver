import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class LocaleNotifier extends ChangeNotifier {
  final PreferencesService _prefs;
  late Locale _locale;

  static const _buildDefault =
      String.fromEnvironment('DEFAULT_LOCALE', defaultValue: 'en');

  LocaleNotifier(this._prefs) {
    final saved = _prefs.locale;
    if (saved.isNotEmpty) {
      _locale = Locale(saved);
    } else {
      _locale = _resolveDefault();
    }
  }

  Locale _resolveDefault() {
    // On web, URL param overrides build default
    if (kIsWeb) {
      final lang = Uri.base.queryParameters['lang'];
      if (lang == 'ja') return const Locale('ja');
      if (lang == 'en') return const Locale('en');
    }
    // Fall back to build-time default
    return Locale(_buildDefault);
  }

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _prefs.setLocale(locale.languageCode);
    notifyListeners();
  }
}
