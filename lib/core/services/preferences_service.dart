import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyApiKey = 'nai_api_key';
  static const String _keyAutoSave = 'nai_auto_save';
  static const String _keyShowDirectorRefShelf = 'show_director_ref_shelf';
  static const String _keyShowVibeTransferShelf = 'show_vibe_transfer_shelf';
  static const String _keyBrightTheme = 'bright_theme';
  static const String _keyGalleryFavorites = 'gallery_favorites';
  static const String _keyActiveThemeId = 'active_theme_id';
  static const String _keyActiveThemeJson = 'active_theme_json';
  static const String _keyUserThemes = 'user_themes';
  static const String _keyPinEnabled = 'pin_lock_enabled';
  static const String _keyPinHash = 'pin_lock_hash';
  static const String _keyPinSalt = 'pin_lock_salt';
  static const String _keyPinOnResume = 'pin_lock_on_resume';
  static const String _keyPinBiometric = 'pin_biometric_enabled';
  static const String _keyDemoSafe = 'gallery_demo_safe';
  static const String _keyDemoMode = 'demo_mode_active';
  static const String _keyDemoPositivePrefix = 'demo_positive_prefix';
  static const String _keyDemoNegativePrefix = 'demo_negative_prefix';
  static const String _keyGalleryAlbums = 'gallery_albums';
  static const String _keyLastToolId = 'tools_last_tool_id';
  static const String _keyGalleryGridColumns = 'gallery_grid_columns';
  static const String _keyShowEditButton = 'show_edit_button';
  static const String _keyStripMetadata = 'strip_metadata_on_export';
  static const String _keyPinVersion = 'pin_hash_version';
  static const String _keySettingsSectionOrder = 'settings_section_order';
  static const String _keySmartStyleImport = 'smart_style_import';
  static const String _keyRememberSession = 'remember_session';
  static const String _keyDefaultSaveAlbumId = 'default_save_album_id';
  static const String _keySlideshowConfigs = 'slideshow_configs';
  static const String _keyDefaultSlideshowId = 'default_slideshow_id';
  static const String _keyLocale = 'app_locale';

  static const String _secureKeyApiKey = 'nai_api_key_secure';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  PreferencesService(this._prefs, this._secure);

  /// Migrates API key from plaintext SharedPreferences to encrypted secure storage.
  Future<void> migrateApiKey() async {
    final plaintext = _prefs.getString(_keyApiKey) ?? '';
    if (plaintext.isNotEmpty) {
      await _secure.write(key: _secureKeyApiKey, value: plaintext);
      await _prefs.remove(_keyApiKey);
    }
  }

  Future<String> getApiKey() async {
    return await _secure.read(key: _secureKeyApiKey) ?? '';
  }

  Future<void> setApiKey(String value) async {
    await _secure.write(key: _secureKeyApiKey, value: value);
  }

  bool get autoSaveImages => _prefs.getBool(_keyAutoSave) ?? true;

  Future<void> setAutoSaveImages(bool value) async {
    await _prefs.setBool(_keyAutoSave, value);
  }

  bool get showDirectorRefShelf => _prefs.getBool(_keyShowDirectorRefShelf) ?? true;

  Future<void> setShowDirectorRefShelf(bool value) async {
    await _prefs.setBool(_keyShowDirectorRefShelf, value);
  }

  bool get showVibeTransferShelf => _prefs.getBool(_keyShowVibeTransferShelf) ?? true;

  Future<void> setShowVibeTransferShelf(bool value) async {
    await _prefs.setBool(_keyShowVibeTransferShelf, value);
  }

  bool get brightTheme => _prefs.getBool(_keyBrightTheme) ?? true;

  Future<void> setBrightTheme(bool value) async {
    await _prefs.setBool(_keyBrightTheme, value);
  }

  Set<String> get favorites =>
      (_prefs.getStringList(_keyGalleryFavorites) ?? []).toSet();

  Future<void> setFavorites(Set<String> value) async {
    await _prefs.setStringList(_keyGalleryFavorites, value.toList());
  }

  String get activeThemeId => _prefs.getString(_keyActiveThemeId) ?? '';

  Future<void> setActiveThemeId(String value) async {
    await _prefs.setString(_keyActiveThemeId, value);
  }

  String get activeThemeJson => _prefs.getString(_keyActiveThemeJson) ?? '';

  Future<void> setActiveThemeJson(String value) async {
    await _prefs.setString(_keyActiveThemeJson, value);
  }

  String get userThemes => _prefs.getString(_keyUserThemes) ?? '';

  Future<void> setUserThemes(String value) async {
    await _prefs.setString(_keyUserThemes, value);
  }

  // — PIN Lock —

  bool get pinEnabled => _prefs.getBool(_keyPinEnabled) ?? false;

  Future<void> setPinEnabled(bool value) async {
    await _prefs.setBool(_keyPinEnabled, value);
  }

  String get pinHash => _prefs.getString(_keyPinHash) ?? '';

  Future<void> setPinHash(String value) async {
    await _prefs.setString(_keyPinHash, value);
  }

  String get pinSalt => _prefs.getString(_keyPinSalt) ?? '';

  Future<void> setPinSalt(String value) async {
    await _prefs.setString(_keyPinSalt, value);
  }

  bool get pinLockOnResume => _prefs.getBool(_keyPinOnResume) ?? false;

  Future<void> setPinLockOnResume(bool value) async {
    await _prefs.setBool(_keyPinOnResume, value);
  }

  bool get pinBiometricEnabled => _prefs.getBool(_keyPinBiometric) ?? false;

  Future<void> setPinBiometricEnabled(bool value) async {
    await _prefs.setBool(_keyPinBiometric, value);
  }

  // — Demo Mode —

  Set<String> get demoSafe =>
      (_prefs.getStringList(_keyDemoSafe) ?? []).toSet();

  Future<void> setDemoSafe(Set<String> value) async {
    await _prefs.setStringList(_keyDemoSafe, value.toList());
  }

  bool get demoMode => _prefs.getBool(_keyDemoMode) ?? false;

  Future<void> setDemoMode(bool value) async {
    await _prefs.setBool(_keyDemoMode, value);
  }

  String get demoPositivePrefix =>
      _prefs.getString(_keyDemoPositivePrefix) ?? 'safe';

  Future<void> setDemoPositivePrefix(String value) async {
    await _prefs.setString(_keyDemoPositivePrefix, value);
  }

  String get demoNegativePrefix =>
      _prefs.getString(_keyDemoNegativePrefix) ?? 'nsfw, explicit';

  Future<void> setDemoNegativePrefix(String value) async {
    await _prefs.setString(_keyDemoNegativePrefix, value);
  }

  // — Gallery Albums —

  String get galleryAlbums => _prefs.getString(_keyGalleryAlbums) ?? '';

  Future<void> setGalleryAlbums(String value) async {
    await _prefs.setString(_keyGalleryAlbums, value);
  }

  // — Tools Hub —

  String? get lastToolId => _prefs.getString(_keyLastToolId);

  Future<void> setLastToolId(String value) async {
    await _prefs.setString(_keyLastToolId, value);
  }

  // — Gallery Grid —

  int? get galleryGridColumns => _prefs.getInt(_keyGalleryGridColumns);

  Future<void> setGalleryGridColumns(int value) async {
    await _prefs.setInt(_keyGalleryGridColumns, value);
  }

  // — Edit Button —

  bool get showEditButton => _prefs.getBool(_keyShowEditButton) ?? true;

  Future<void> setShowEditButton(bool value) async {
    await _prefs.setBool(_keyShowEditButton, value);
  }

  // — Export Privacy —

  bool get stripMetadataOnExport => _prefs.getBool(_keyStripMetadata) ?? false;

  Future<void> setStripMetadataOnExport(bool value) async {
    await _prefs.setBool(_keyStripMetadata, value);
  }

  // — PIN Hash Version —

  int get pinHashVersion => _prefs.getInt(_keyPinVersion) ?? 1;

  Future<void> setPinHashVersion(int value) async {
    await _prefs.setInt(_keyPinVersion, value);
  }

  // — Settings Section Order —

  List<String>? get settingsSectionOrder =>
      _prefs.getStringList(_keySettingsSectionOrder);

  Future<void> setSettingsSectionOrder(List<String> value) async {
    await _prefs.setStringList(_keySettingsSectionOrder, value);
  }

  // — Smart Style Import —

  bool get smartStyleImport => _prefs.getBool(_keySmartStyleImport) ?? true;

  Future<void> setSmartStyleImport(bool value) async {
    await _prefs.setBool(_keySmartStyleImport, value);
  }

  // — Remember Session —

  bool get rememberSession => _prefs.getBool(_keyRememberSession) ?? true;

  Future<void> setRememberSession(bool value) async {
    await _prefs.setBool(_keyRememberSession, value);
  }

  // — Slideshow Configs —

  String get slideshowConfigs => _prefs.getString(_keySlideshowConfigs) ?? '';

  Future<void> setSlideshowConfigs(String value) async {
    await _prefs.setString(_keySlideshowConfigs, value);
  }

  // — Default Slideshow —

  String? get defaultSlideshowId => _prefs.getString(_keyDefaultSlideshowId);

  Future<void> setDefaultSlideshowId(String? id) async {
    if (id == null) {
      await _prefs.remove(_keyDefaultSlideshowId);
    } else {
      await _prefs.setString(_keyDefaultSlideshowId, id);
    }
  }

  // — Locale —

  String get locale => _prefs.getString(_keyLocale) ?? '';

  Future<void> setLocale(String value) async {
    await _prefs.setString(_keyLocale, value);
  }

  // — Default Save Album —

  String? get defaultSaveAlbumId => _prefs.getString(_keyDefaultSaveAlbumId);

  Future<void> setDefaultSaveAlbumId(String? id) async {
    if (id == null) {
      await _prefs.remove(_keyDefaultSaveAlbumId);
    } else {
      await _prefs.setString(_keyDefaultSaveAlbumId, id);
    }
  }
}
