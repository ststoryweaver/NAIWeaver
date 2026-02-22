import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences/gallery_preferences.dart';
import 'preferences/jukebox_preferences.dart';
import 'preferences/ml_preferences.dart';
import 'preferences/security_preferences.dart';

class PreferencesService {
  // — General key constants (remaining after domain split) —
  static const String _keyAutoSave = 'nai_auto_save';
  static const String _keyShowDirectorRefShelf = 'show_director_ref_shelf';
  static const String _keyShowVibeTransferShelf = 'show_vibe_transfer_shelf';
  static const String _keyBrightTheme = 'bright_theme';
  static const String _keyActiveThemeId = 'active_theme_id';
  static const String _keyActiveThemeJson = 'active_theme_json';
  static const String _keyUserThemes = 'user_themes';
  static const String _keyLastToolId = 'tools_last_tool_id';
  static const String _keyShowEditButton = 'show_edit_button';
  static const String _keyShowBgRemovalButton = 'show_bg_removal_button';
  static const String _keyShowUpscaleButton = 'show_upscale_button';
  static const String _keyShowEnhanceButton = 'show_enhance_button';
  static const String _keyShowDirectorToolsButton = 'show_director_tools_button';
  static const String _keySettingsSectionOrder = 'settings_section_order';
  static const String _keySmartStyleImport = 'smart_style_import';
  static const String _keyRememberSession = 'remember_session';
  static const String _keyLocale = 'app_locale';
  static const String _keyFurryMode = 'furry_mode';
  static const String _keyImg2ImgImportPrompt = 'img2img_import_prompt';
  static const String _keyShowAnlasTracker = 'show_anlas_tracker';
  static const String _keyCanvasAutoSave = 'canvas_auto_save';
  static const String _keyCustomOutputDir = 'custom_output_dir';
  static const String _keyCustomResolutions = 'custom_resolutions';
  static const String _keyCharacterEditorMode = 'character_editor_mode';
  static const String _keyCharacterPresets = 'character_presets';
  static const String _keyShowTooltips = 'show_tooltips';

  final SharedPreferences _prefs;

  late final ValueNotifier<bool> tooltipVisibilityNotifier;

  // — Domain-specific preference sub-classes —
  late final JukeboxPreferences jukebox;
  late final GalleryPreferences gallery;
  late final SecurityPreferences security;
  late final MlPreferences ml;

  PreferencesService(this._prefs, FlutterSecureStorage secure) {
    jukebox = JukeboxPreferences(_prefs);
    gallery = GalleryPreferences(_prefs);
    security = SecurityPreferences(_prefs, secure);
    ml = MlPreferences(_prefs);
    tooltipVisibilityNotifier = ValueNotifier(showTooltips);
  }

  /// Migrates API key from plaintext SharedPreferences to encrypted secure storage.
  Future<void> migrateApiKey() => security.migrateApiKey();

  Future<String> getApiKey() => security.getApiKey();

  Future<void> setApiKey(String value) => security.setApiKey(value);

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

  // — Tools Hub —

  String? get lastToolId => _prefs.getString(_keyLastToolId);

  Future<void> setLastToolId(String value) async {
    await _prefs.setString(_keyLastToolId, value);
  }

  // — Edit Button —

  bool get showEditButton => _prefs.getBool(_keyShowEditButton) ?? true;

  Future<void> setShowEditButton(bool value) async {
    await _prefs.setBool(_keyShowEditButton, value);
  }

  // — BG Removal Button —

  bool get showBgRemovalButton => _prefs.getBool(_keyShowBgRemovalButton) ?? true;

  Future<void> setShowBgRemovalButton(bool value) async {
    await _prefs.setBool(_keyShowBgRemovalButton, value);
  }

  // — Upscale Button —

  bool get showUpscaleButton => _prefs.getBool(_keyShowUpscaleButton) ?? true;

  Future<void> setShowUpscaleButton(bool value) async {
    await _prefs.setBool(_keyShowUpscaleButton, value);
  }

  // — Enhance Button —

  bool get showEnhanceButton => _prefs.getBool(_keyShowEnhanceButton) ?? false;

  Future<void> setShowEnhanceButton(bool value) async {
    await _prefs.setBool(_keyShowEnhanceButton, value);
  }

  // — Director Tools Button —

  bool get showDirectorToolsButton => _prefs.getBool(_keyShowDirectorToolsButton) ?? false;

  Future<void> setShowDirectorToolsButton(bool value) async {
    await _prefs.setBool(_keyShowDirectorToolsButton, value);
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

  // — Locale —

  String get locale => _prefs.getString(_keyLocale) ?? '';

  Future<void> setLocale(String value) async {
    await _prefs.setString(_keyLocale, value);
  }

  // — Furry Mode —

  bool get furryMode => _prefs.getBool(_keyFurryMode) ?? false;

  Future<void> setFurryMode(bool value) async {
    await _prefs.setBool(_keyFurryMode, value);
  }

  // — Img2Img Import Prompt —

  bool get img2imgImportPrompt => _prefs.getBool(_keyImg2ImgImportPrompt) ?? true;

  Future<void> setImg2ImgImportPrompt(bool value) async {
    await _prefs.setBool(_keyImg2ImgImportPrompt, value);
  }

  // — Anlas Tracker —

  bool get showAnlasTracker => _prefs.getBool(_keyShowAnlasTracker) ?? true;

  Future<void> setShowAnlasTracker(bool value) async {
    await _prefs.setBool(_keyShowAnlasTracker, value);
  }

  // — Canvas Auto-Save —

  bool get canvasAutoSave => _prefs.getBool(_keyCanvasAutoSave) ?? true;

  Future<void> setCanvasAutoSave(bool value) async {
    await _prefs.setBool(_keyCanvasAutoSave, value);
  }

  // — Custom Output Directory —

  String get customOutputDir => _prefs.getString(_keyCustomOutputDir) ?? '';

  Future<void> setCustomOutputDir(String value) async {
    if (value.isEmpty) {
      await _prefs.remove(_keyCustomOutputDir);
    } else {
      await _prefs.setString(_keyCustomOutputDir, value);
    }
  }

  // — Custom Resolutions —

  String get customResolutions => _prefs.getString(_keyCustomResolutions) ?? '';

  Future<void> setCustomResolutions(String value) async {
    await _prefs.setString(_keyCustomResolutions, value);
  }

  // — Character Editor Mode —

  String get characterEditorMode =>
      _prefs.getString(_keyCharacterEditorMode) ?? 'expanded';

  Future<void> setCharacterEditorMode(String value) async {
    await _prefs.setString(_keyCharacterEditorMode, value);
  }

  // — Character Presets —

  String get characterPresets =>
      _prefs.getString(_keyCharacterPresets) ?? '';

  Future<void> setCharacterPresets(String value) async {
    await _prefs.setString(_keyCharacterPresets, value);
  }

  // — Tooltips —

  bool get showTooltips => _prefs.getBool(_keyShowTooltips) ?? true;

  Future<void> setShowTooltips(bool value) async {
    await _prefs.setBool(_keyShowTooltips, value);
    tooltipVisibilityNotifier.value = value;
  }

  // — Delegating getters for backward compatibility —
  // These delegate to domain sub-classes so existing code that hasn't
  // been migrated yet continues to compile.

  // Gallery delegates
  Set<String> get favorites => gallery.favorites;
  Future<void> setFavorites(Set<String> value) => gallery.setFavorites(value);
  Set<String> get demoSafe => gallery.demoSafe;
  Future<void> setDemoSafe(Set<String> value) => gallery.setDemoSafe(value);
  bool get demoMode => gallery.demoMode;
  Future<void> setDemoMode(bool value) => gallery.setDemoMode(value);
  String get demoPositivePrefix => gallery.demoPositivePrefix;
  Future<void> setDemoPositivePrefix(String value) => gallery.setDemoPositivePrefix(value);
  String get demoNegativePrefix => gallery.demoNegativePrefix;
  Future<void> setDemoNegativePrefix(String value) => gallery.setDemoNegativePrefix(value);
  String get galleryAlbums => gallery.albums;
  Future<void> setGalleryAlbums(String value) => gallery.setAlbums(value);
  int? get galleryGridColumns => gallery.gridColumns;
  Future<void> setGalleryGridColumns(int value) => gallery.setGridColumns(value);
  String? get defaultSaveAlbumId => gallery.defaultSaveAlbumId;
  Future<void> setDefaultSaveAlbumId(String? id) => gallery.setDefaultSaveAlbumId(id);
  bool get stripMetadataOnExport => gallery.stripMetadataOnExport;
  Future<void> setStripMetadataOnExport(bool value) => gallery.setStripMetadataOnExport(value);
  String get slideshowConfigs => gallery.slideshowConfigs;
  Future<void> setSlideshowConfigs(String value) => gallery.setSlideshowConfigs(value);
  String? get defaultSlideshowId => gallery.defaultSlideshowId;
  Future<void> setDefaultSlideshowId(String? id) => gallery.setDefaultSlideshowId(id);

  // Security delegates
  bool get pinEnabled => security.pinEnabled;
  Future<void> setPinEnabled(bool value) => security.setPinEnabled(value);
  String get pinHash => security.pinHash;
  Future<void> setPinHash(String value) => security.setPinHash(value);
  String get pinSalt => security.pinSalt;
  Future<void> setPinSalt(String value) => security.setPinSalt(value);
  bool get pinLockOnResume => security.pinLockOnResume;
  Future<void> setPinLockOnResume(bool value) => security.setPinLockOnResume(value);
  bool get pinBiometricEnabled => security.pinBiometricEnabled;
  Future<void> setPinBiometricEnabled(bool value) => security.setPinBiometricEnabled(value);
  int get pinHashVersion => security.pinHashVersion;
  Future<void> setPinHashVersion(int value) => security.setPinHashVersion(value);

  // ML delegates
  String? get selectedBgRemovalModel => ml.selectedBgRemovalModel;
  Future<void> setSelectedBgRemovalModel(String? id) => ml.setSelectedBgRemovalModel(id);
  String? get selectedUpscaleModel => ml.selectedUpscaleModel;
  Future<void> setSelectedUpscaleModel(String? id) => ml.setSelectedUpscaleModel(id);
  String? get selectedSegmentationModel => ml.selectedSegmentationModel;
  Future<void> setSelectedSegmentationModel(String? id) => ml.setSelectedSegmentationModel(id);
  String get upscaleBackend => ml.upscaleBackend;
  Future<void> setUpscaleBackend(String value) => ml.setUpscaleBackend(value);

  // Jukebox delegates
  double get jukeboxVolume => jukebox.volume;
  Future<void> setJukeboxVolume(double value) => jukebox.setVolume(value);
  String? get jukeboxSoundFontId => jukebox.soundFontId;
  Future<void> setJukeboxSoundFontId(String? id) => jukebox.setSoundFontId(id);
  bool get jukeboxShuffle => jukebox.shuffle;
  Future<void> setJukeboxShuffle(bool value) => jukebox.setShuffle(value);
  String get jukeboxRepeat => jukebox.repeat;
  Future<void> setJukeboxRepeat(String value) => jukebox.setRepeat(value);
  String get jukeboxSongDurations => jukebox.songDurations;
  Future<void> setJukeboxSongDurations(String value) => jukebox.setSongDurations(value);
  int? get jukeboxKaraokeHighlightColor => jukebox.karaokeHighlightColor;
  Future<void> setJukeboxKaraokeHighlightColor(int? value) => jukebox.setKaraokeHighlightColor(value);
  int? get jukeboxKaraokeUpcomingColor => jukebox.karaokeUpcomingColor;
  Future<void> setJukeboxKaraokeUpcomingColor(int? value) => jukebox.setKaraokeUpcomingColor(value);
  int? get jukeboxKaraokeNextLineColor => jukebox.karaokeNextLineColor;
  Future<void> setJukeboxKaraokeNextLineColor(int? value) => jukebox.setKaraokeNextLineColor(value);
  String? get jukeboxKaraokeFontFamily => jukebox.karaokeFontFamily;
  Future<void> setJukeboxKaraokeFontFamily(String? value) => jukebox.setKaraokeFontFamily(value);
  double get jukeboxKaraokeFontScale => jukebox.karaokeFontScale;
  Future<void> setJukeboxKaraokeFontScale(double value) => jukebox.setKaraokeFontScale(value);
  bool get jukeboxShowMiniLyric => jukebox.showMiniLyric;
  Future<void> setJukeboxShowMiniLyric(bool value) => jukebox.setShowMiniLyric(value);
  bool get jukeboxShowKaraokeInPanel => jukebox.showKaraokeInPanel;
  Future<void> setJukeboxShowKaraokeInPanel(bool value) => jukebox.setShowKaraokeInPanel(value);
  int? get jukeboxVisualizerColor => jukebox.visualizerColor;
  Future<void> setJukeboxVisualizerColor(int? value) => jukebox.setVisualizerColor(value);
  String get jukeboxVisualizerStyle => jukebox.visualizerStyle;
  Future<void> setJukeboxVisualizerStyle(String value) => jukebox.setVisualizerStyle(value);
  double get jukeboxVizIntensity => jukebox.vizIntensity;
  Future<void> setJukeboxVizIntensity(double value) => jukebox.setVizIntensity(value);
  double get jukeboxVizSpeed => jukebox.vizSpeed;
  Future<void> setJukeboxVizSpeed(double value) => jukebox.setVizSpeed(value);
  double get jukeboxVizDensity => jukebox.vizDensity;
  Future<void> setJukeboxVizDensity(double value) => jukebox.setVizDensity(value);
}
