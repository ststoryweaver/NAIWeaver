import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class LocaleNotifier extends ChangeNotifier {
  final PreferencesService _prefs;
  late Locale _locale;

  LocaleNotifier(this._prefs) {
    final saved = _prefs.locale;
    _locale = saved.isNotEmpty ? Locale(saved) : const Locale('en');
  }

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _prefs.setLocale(locale.languageCode);
    notifyListeners();
  }
}
