import 'package:flutter/foundation.dart';
import '../models/nai_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/resizable_lines.dart';
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
  static const String _keyShowExportButton = 'show_export_button';
  static const String _keyShowCopyButton = 'show_copy_button';
  static const String _keyAutoExportToDevice = 'auto_export_to_device';
  static const String _keyExportAlbumName = 'export_album_name';
  static const String _keySettingsSectionOrder = 'settings_section_order';
  static const String _keySmartStyleImport = 'smart_style_import';
  static const String _keyCharInsertTarget = 'char_insert_target';
  static const String _keyRememberSession = 'remember_session';
  static const String _keyLocale = 'app_locale';
  static const String _keyLastUpdateCheck = 'last_update_check';
  static const String _keySkippedUpdateVersion = 'skipped_update_version';
  static const String _keyFurryMode = 'furry_mode';
  static const String _keyUseCurated = 'use_curated';
  static const String _keyNaiModel = 'nai_model';
  static const String _keyImg2ImgImportPrompt = 'img2img_import_prompt';
  static const String _keyShowSeedControl = 'show_seed_control';
  static const String _keyShowAnlasTracker = 'show_anlas_tracker';
  static const String _keyImportDisabledCategories = 'import_disabled_categories';
  static const String _keyExportFolderPath = 'export_folder_path';
  static const String _keyCanvasAutoSave = 'canvas_auto_save';
  static const String _keyCustomOutputDir = 'custom_output_dir';
  static const String _keySdMigrationSource = 'sd_migration_source';
  static const String _keyFilenamePattern = 'filename_pattern';
  static const String _keySavePathPattern = 'save_path_pattern';
  static const String _keyCustomResolutions = 'custom_resolutions';
  static const String _keyCharacterEditorMode = 'character_editor_mode';
  static const String _keyCharacterPresets = 'character_presets';
  static const String _keyShowTooltips = 'show_tooltips';
  static const String _keyHideTagValues = 'hide_tag_values';
  static const String _keyHonorOutfitState = 'honor_outfit_state';
  static const String _keyUiStylesExpanded = 'ui_styles_expanded';
  static const String _keyUiCharShowTitle = 'ui_char_show_title';
  static const String _keyUiCharShowUc = 'ui_char_show_uc';
  static const String _keyUiCharShowPosition = 'ui_char_show_position';
  static const String _keyUiCharShowPresets = 'ui_char_show_presets';
  static const String _keyUiCharPromptLines = 'ui_char_prompt_lines';
  static const String _keyRefLastStrength = 'ref_last_strength';
  static const String _keyRefLastFidelity = 'ref_last_fidelity';
  static const String _keySidebarLayoutMode = 'sidebar_layout_mode';
  static const String _keySidebarPromptPosition = 'sidebar_prompt_position';
  static const String _keySidebarWidthMode = 'sidebar_width_mode';
  static const String _keyWindowX = 'window_x';
  static const String _keyWindowY = 'window_y';
  static const String _keyWindowW = 'window_w';
  static const String _keyWindowH = 'window_h';
  static const String _keyWindowMax = 'window_maximized';

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

  // — Export Button —

  bool get showExportButton => _prefs.getBool(_keyShowExportButton) ?? false;

  Future<void> setShowExportButton(bool value) async {
    await _prefs.setBool(_keyShowExportButton, value);
  }

  bool get showCopyButton => _prefs.getBool(_keyShowCopyButton) ?? false;

  Future<void> setShowCopyButton(bool value) async {
    await _prefs.setBool(_keyShowCopyButton, value);
  }

  // — Auto Export to Device —

  bool get autoExportToDevice => _prefs.getBool(_keyAutoExportToDevice) ?? false;

  Future<void> setAutoExportToDevice(bool value) async {
    await _prefs.setBool(_keyAutoExportToDevice, value);
  }

  // — Export Album Name —

  String get exportAlbumName => _prefs.getString(_keyExportAlbumName) ?? 'NAIWeaver';

  Future<void> setExportAlbumName(String value) async {
    await _prefs.setString(_keyExportAlbumName, value);
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

  // — Saved-Character Insert Target —

  /// Where a saved character picked from the main prompt box's autocomplete is
  /// inserted: `'editor'` (default) adds a new character card; `'main'` inserts
  /// its expanded tags into the main prompt as plain text. Stored as a string so
  /// the intent is self-documenting and future targets can be added.
  String get charInsertTarget =>
      _prefs.getString(_keyCharInsertTarget) ?? 'editor';

  Future<void> setCharInsertTarget(String value) async {
    await _prefs.setString(_keyCharInsertTarget, value);
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

  // — Update Check —

  /// Epoch millis of the last automatic update check (0 if never). Used to
  /// throttle the launch-time check to roughly once per day.
  int get lastUpdateCheck => _prefs.getInt(_keyLastUpdateCheck) ?? 0;

  Future<void> setLastUpdateCheck(int epochMs) async {
    await _prefs.setInt(_keyLastUpdateCheck, epochMs);
  }

  /// A version the user chose to skip; the launch-time prompt won't re-nag for
  /// it (empty = nothing skipped).
  String get skippedUpdateVersion => _prefs.getString(_keySkippedUpdateVersion) ?? '';

  Future<void> setSkippedUpdateVersion(String version) async {
    await _prefs.setString(_keySkippedUpdateVersion, version);
  }

  // — Furry Mode —

  bool get furryMode => _prefs.getBool(_keyFurryMode) ?? false;

  Future<void> setFurryMode(bool value) async {
    await _prefs.setBool(_keyFurryMode, value);
  }

  // — Image model —

  /// Selected NovelAI image model (`nai_model`, stored as the wire id).
  /// Falls back to the pre-V5 `use_curated` boolean so existing installs keep
  /// their V4.5 choice; nobody is auto-migrated to V5 (it is metered on Opus).
  NaiModel get naiModel {
    final stored = NaiModel.tryParse(_prefs.getString(_keyNaiModel));
    if (stored != null) return stored;
    return NaiModel.fromLegacyCurated(_prefs.getBool(_keyUseCurated) ?? false);
  }

  Future<void> setNaiModel(NaiModel model) async {
    await _prefs.setString(_keyNaiModel, model.id);
    // Keep the legacy flag coherent for older builds / backups.
    await _prefs.setBool(_keyUseCurated, model.isCurated);
  }

  // — Curated Model (legacy; prefer [naiModel]) —

  bool get useCurated => _prefs.getBool(_keyUseCurated) ?? false;

  Future<void> setUseCurated(bool value) async {
    await _prefs.setBool(_keyUseCurated, value);
  }

  // — Img2Img Import Prompt —

  bool get img2imgImportPrompt => _prefs.getBool(_keyImg2ImgImportPrompt) ?? true;

  Future<void> setImg2ImgImportPrompt(bool value) async {
    await _prefs.setBool(_keyImg2ImgImportPrompt, value);
  }

  // — Seed Control —

  bool get showSeedControl => _prefs.getBool(_keyShowSeedControl) ?? false;

  Future<void> setShowSeedControl(bool value) async {
    await _prefs.setBool(_keyShowSeedControl, value);
  }

  // — Import Disabled Categories —

  Set<String> get importDisabledCategories {
    final raw = _prefs.getString(_keyImportDisabledCategories) ?? '';
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  Future<void> setImportDisabledCategories(Set<String> value) async {
    await _prefs.setString(_keyImportDisabledCategories, value.join(','));
  }

  // — Export Folder Path —

  String get exportFolderPath => _prefs.getString(_keyExportFolderPath) ?? '';

  Future<void> setExportFolderPath(String value) async {
    await _prefs.setString(_keyExportFolderPath, value);
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

  // — Pending SD-card migration (issue #21) —
  //
  // Absolute path of the previous output dir while a move to the SD card is
  // still incomplete, so the USE SD CARD button can offer to resume after an
  // interruption. Empty when no move is pending. Deliberately device-local:
  // not in the exportable-settings allowlist.

  String get sdMigrationSource => _prefs.getString(_keySdMigrationSource) ?? '';

  Future<void> setSdMigrationSource(String value) async {
    if (value.isEmpty) {
      await _prefs.remove(_keySdMigrationSource);
    } else {
      await _prefs.setString(_keySdMigrationSource, value);
    }
  }

  // — Custom filename / save-path patterns (issue #27). Empty string means
  // "use the built-in NAI-style name / no subfolders", so existing users see
  // no change until they opt in.

  String get filenamePattern => _prefs.getString(_keyFilenamePattern) ?? '';

  Future<void> setFilenamePattern(String value) async {
    if (value.isEmpty) {
      await _prefs.remove(_keyFilenamePattern);
    } else {
      await _prefs.setString(_keyFilenamePattern, value);
    }
  }

  String get savePathPattern => _prefs.getString(_keySavePathPattern) ?? '';

  Future<void> setSavePathPattern(String value) async {
    if (value.isEmpty) {
      await _prefs.remove(_keySavePathPattern);
    } else {
      await _prefs.setString(_keySavePathPattern, value);
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

  // — Tag Suggestions —

  bool get hideTagValues => _prefs.getBool(_keyHideTagValues) ?? false;

  Future<void> setHideTagValues(bool value) async {
    await _prefs.setBool(_keyHideTagValues, value);
  }

  /// When true (default), inserting a `[OCNAME (OUTFITNAME)]` autocomplete
  /// entry routes the outfit through the outfit-state renderer (concealment
  /// + `nsfw` append if dishevelled). When false, the flat tag string is
  /// inserted. Per-insertion toggle in the suggestion overlay; this stores
  /// the most-recent value as a UX convenience.
  bool get honorOutfitState => _prefs.getBool(_keyHonorOutfitState) ?? true;

  Future<void> setHonorOutfitState(bool value) async {
    await _prefs.setBool(_keyHonorOutfitState, value);
  }

  // — UI State Persistence —

  bool get uiStylesExpanded => _prefs.getBool(_keyUiStylesExpanded) ?? false;

  Future<void> setUiStylesExpanded(bool value) async {
    await _prefs.setBool(_keyUiStylesExpanded, value);
  }

  bool get uiCharShowTitle => _prefs.getBool(_keyUiCharShowTitle) ?? false;

  Future<void> setUiCharShowTitle(bool value) async {
    await _prefs.setBool(_keyUiCharShowTitle, value);
  }

  bool get uiCharShowUc => _prefs.getBool(_keyUiCharShowUc) ?? false;

  Future<void> setUiCharShowUc(bool value) async {
    await _prefs.setBool(_keyUiCharShowUc, value);
  }

  bool get uiCharShowPosition => _prefs.getBool(_keyUiCharShowPosition) ?? false;

  Future<void> setUiCharShowPosition(bool value) async {
    await _prefs.setBool(_keyUiCharShowPosition, value);
  }

  bool get uiCharShowPresets => _prefs.getBool(_keyUiCharShowPresets) ?? false;

  Future<void> setUiCharShowPresets(bool value) async {
    await _prefs.setBool(_keyUiCharShowPresets, value);
  }

  /// Visible-line cap of character prompt boxes; drag-resizable in the
  /// character editors and persistent across sessions (issue #15).
  int get uiCharPromptLines =>
      (_prefs.getInt(_keyUiCharPromptLines) ?? kCharPromptDefaultLines)
          .clamp(kCharPromptMinLines, kCharPromptMaxLines);

  Future<void> setUiCharPromptLines(int value) async {
    await _prefs.setInt(_keyUiCharPromptLines,
        value.clamp(kCharPromptMinLines, kCharPromptMaxLines));
  }

  // — Reference defaults (last applied) —

  double get refLastStrength => _prefs.getDouble(_keyRefLastStrength) ?? 1.0;

  Future<void> setRefLastStrength(double value) async {
    await _prefs.setDouble(_keyRefLastStrength, value);
  }

  double get refLastFidelity => _prefs.getDouble(_keyRefLastFidelity) ?? 0.8;

  Future<void> setRefLastFidelity(double value) async {
    await _prefs.setDouble(_keyRefLastFidelity, value);
  }

  // — Sidebar Layout —

  String get sidebarLayoutMode => _prefs.getString(_keySidebarLayoutMode) ?? 'auto';

  Future<void> setSidebarLayoutMode(String value) async {
    await _prefs.setString(_keySidebarLayoutMode, value);
  }

  String get sidebarPromptPosition => _prefs.getString(_keySidebarPromptPosition) ?? 'left';

  Future<void> setSidebarPromptPosition(String value) async {
    await _prefs.setString(_keySidebarPromptPosition, value);
  }

  String get sidebarWidthMode => _prefs.getString(_keySidebarWidthMode) ?? 'normal';

  Future<void> setSidebarWidthMode(String value) async {
    await _prefs.setString(_keySidebarWidthMode, value);
  }

  // — Window state (desktop) —
  ({double x, double y, double w, double h})? get windowBounds {
    final x = _prefs.getDouble(_keyWindowX);
    final y = _prefs.getDouble(_keyWindowY);
    final w = _prefs.getDouble(_keyWindowW);
    final h = _prefs.getDouble(_keyWindowH);
    if (x == null || y == null || w == null || h == null) return null;
    return (x: x, y: y, w: w, h: h);
  }

  bool get windowMaximized => _prefs.getBool(_keyWindowMax) ?? false;

  Future<void> saveWindowState({
    required double x,
    required double y,
    required double w,
    required double h,
    required bool maximized,
  }) async {
    await _prefs.setDouble(_keyWindowX, x);
    await _prefs.setDouble(_keyWindowY, y);
    await _prefs.setDouble(_keyWindowW, w);
    await _prefs.setDouble(_keyWindowH, h);
    await _prefs.setBool(_keyWindowMax, maximized);
  }

  // — Portable settings backup (pack export/import) —
  //
  // An explicit allowlist of literal SharedPreferences keys that are safe to
  // include in a shareable `.vpack` backup. This deliberately EXCLUDES:
  //   • security-sensitive data — API key (secure storage), PIN hash/salt/
  //     version, biometric flag;
  //   • device-local state — window bounds, custom output/export folder paths,
  //     last-opened tool;
  //   • the active theme pointers (`active_theme_*`) — restored via the themes
  //     pack category instead, since the active id may not exist on the target;
  //   • gallery membership / id pointers that self-heal or reference local files.
  static const List<String> _exportableSettingKeys = [
    // App settings (general)
    _keyAutoSave, _keyShowDirectorRefShelf, _keyShowVibeTransferShelf,
    _keyBrightTheme, _keyShowEditButton, _keyShowBgRemovalButton,
    _keyShowUpscaleButton, _keyShowEnhanceButton, _keyShowDirectorToolsButton,
    _keyShowExportButton, _keyShowCopyButton, _keyAutoExportToDevice,
    _keyExportAlbumName, _keySettingsSectionOrder, _keySmartStyleImport,
    _keyCharInsertTarget,
    _keyRememberSession, _keyLocale, _keyFurryMode, _keyUseCurated,
    _keyNaiModel,
    _keyImg2ImgImportPrompt, _keyShowSeedControl, _keyShowAnlasTracker,
    _keyCanvasAutoSave, _keyCustomResolutions, _keyCharacterEditorMode,
    _keyFilenamePattern, _keySavePathPattern,
    _keyShowTooltips, _keyHideTagValues, _keyHonorOutfitState,
    _keyUiStylesExpanded, _keyUiCharShowTitle, _keyUiCharShowUc,
    _keyUiCharShowPosition, _keyUiCharShowPresets,
    _keyRefLastStrength, _keyRefLastFidelity,
    _keySidebarLayoutMode, _keySidebarPromptPosition, _keySidebarWidthMode,
    // Gallery prefs (non file-path, non-membership)
    'demo_positive_prefix', 'demo_negative_prefix', 'gallery_grid_columns',
    'strip_metadata_on_export', 'slideshow_configs',
    // Jukebox (settings + opaque blobs like high scores / song durations)
    'jukebox_volume', 'jukebox_soundfont_id', 'jukebox_shuffle',
    'jukebox_repeat', 'jukebox_song_durations',
    'jukebox_karaoke_highlight_color', 'jukebox_karaoke_upcoming_color',
    'jukebox_karaoke_next_line_color', 'jukebox_karaoke_font_family',
    'jukebox_karaoke_font_scale', 'jukebox_show_mini_lyric',
    'jukebox_show_karaoke_in_panel', 'jukebox_visualizer_color',
    'jukebox_visualizer_style', 'jukebox_viz_intensity', 'jukebox_viz_speed',
    'jukebox_viz_density', 'jukebox_high_scores', 'jukebox_keyboard_volume',
  ];

  // Keys stored as doubles. JSON serialization collapses whole-number doubles
  // (e.g. 1.0) to ints, so on import we must coerce int → double for these,
  // otherwise the matching getDouble() call throws a type error.
  static const Set<String> _doubleSettingKeys = {
    _keyRefLastStrength, _keyRefLastFidelity,
    'jukebox_volume', 'jukebox_karaoke_font_scale', 'jukebox_viz_intensity',
    'jukebox_viz_speed', 'jukebox_viz_density', 'jukebox_keyboard_volume',
  };

  /// Snapshot of allowlisted settings for inclusion in a backup pack.
  /// Only keys that are actually set are emitted.
  Map<String, Object> exportableSettings() {
    final out = <String, Object>{};
    for (final key in _exportableSettingKeys) {
      final value = _prefs.get(key);
      if (value != null) out[key] = value;
    }
    return out;
  }

  /// Restores allowlisted settings from a backup pack. Keys not on the
  /// allowlist are ignored, and values are written by their runtime type.
  Future<void> importSettings(Map<String, Object> data) async {
    for (final entry in data.entries) {
      if (!_exportableSettingKeys.contains(entry.key)) continue;
      final key = entry.key;
      final value = entry.value;
      if (_doubleSettingKeys.contains(key) && value is num) {
        await _prefs.setDouble(key, value.toDouble());
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is List) {
        await _prefs.setStringList(key, value.cast<String>());
      }
    }
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
  String get bgRemovalBackend => ml.bgRemovalBackend;
  Future<void> setBgRemovalBackend(String value) => ml.setBgRemovalBackend(value);

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
  String get jukeboxHighScores => jukebox.highScores;
  Future<void> setJukeboxHighScores(String value) => jukebox.setHighScores(value);
  double get jukeboxKeyboardVolume => jukebox.keyboardVolume;
  Future<void> setJukeboxKeyboardVolume(double value) => jukebox.setKeyboardVolume(value);
}
