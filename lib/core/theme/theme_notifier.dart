import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/preferences_service.dart';
import 'app_theme_config.dart';
import 'built_in_themes.dart';
import 'vision_tokens.dart';

class ThemeNotifier extends ChangeNotifier {
  static const defaultSectionOrder = [
    'dimensions_seed',
    'steps_scale',
    'sampler_post',
    'styles',
    'negative_prompt',
    'presets',
    'save_to_album',
  ];

  final PreferencesService _prefs;

  AppThemeConfig _activeConfig;
  late VisionTokens _tokens;
  List<AppThemeConfig> _userThemes = [];
  List<String> _sectionOrder = List.of(defaultSectionOrder);

  /// Temporary preview config (non-null while user is previewing edits).
  AppThemeConfig? _previewConfig;

  ThemeNotifier(this._prefs) : _activeConfig = BuiltInThemes.defaultTheme {
    _tokens = VisionTokens(_activeConfig);
    _loadFromPrefs();
  }

  // — Public getters —
  AppThemeConfig get activeConfig => _previewConfig ?? _activeConfig;
  VisionTokens get tokens => _previewConfig != null ? VisionTokens(_previewConfig!) : _tokens;
  List<AppThemeConfig> get allThemes => [...BuiltInThemes.all, ..._userThemes];
  List<AppThemeConfig> get userThemes => _userThemes;
  String get activeThemeId => _activeConfig.id;
  bool get isPreviewing => _previewConfig != null;
  List<String> get sectionOrder => List.unmodifiable(_sectionOrder);

  ThemeData get themeData => _buildThemeData(activeConfig);

  // — Load from prefs —
  void _loadFromPrefs() {
    final activeId = _prefs.activeThemeId;
    final activeJson = _prefs.activeThemeJson;
    final userThemesJson = _prefs.userThemes;

    // Load user themes
    if (userThemesJson.isNotEmpty) {
      try {
        final list = jsonDecode(userThemesJson) as List;
        _userThemes = list
            .map((e) => AppThemeConfig.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _userThemes = [];
      }
    }

    // Load active theme
    if (activeJson.isNotEmpty) {
      try {
        _activeConfig = AppThemeConfig.fromJsonString(activeJson);
      } catch (_) {
        _activeConfig = _resolveById(activeId);
      }
    } else if (activeId.isNotEmpty) {
      _activeConfig = _resolveById(activeId);
    }

    // Migrate brightTheme pref into config
    final legacyBright = _prefs.brightTheme;
    if (_activeConfig.brightMode != legacyBright) {
      _activeConfig = _activeConfig.copyWith(brightMode: legacyBright);
    }

    // Load section order
    final savedOrder = _prefs.settingsSectionOrder;
    if (savedOrder != null) {
      // Add any new section IDs not in saved order
      final missing = defaultSectionOrder.where((id) => !savedOrder.contains(id)).toList();
      _sectionOrder = [...savedOrder, ...missing];
      // Remove any IDs no longer in defaults
      _sectionOrder.removeWhere((id) => !defaultSectionOrder.contains(id));
    }

    _tokens = VisionTokens(_activeConfig);
    notifyListeners();
  }

  AppThemeConfig _resolveById(String id) {
    for (final t in BuiltInThemes.all) {
      if (t.id == id) return t;
    }
    for (final t in _userThemes) {
      if (t.id == id) return t;
    }
    return BuiltInThemes.defaultTheme;
  }

  // — Switch theme —
  Future<void> setActiveTheme(String themeId) async {
    _previewConfig = null;
    final resolved = _resolveById(themeId);
    _activeConfig = resolved.copyWith(
      fontFamily: _activeConfig.fontFamily,
      fontScale: _activeConfig.fontScale,
      promptFontSize: _activeConfig.promptFontSize,
      promptMaxLines: _activeConfig.promptMaxLines,
    );
    _tokens = VisionTokens(_activeConfig);
    await _persist();
    notifyListeners();
  }

  // — Toggle bright mode —
  Future<void> toggleBrightMode() async {
    _activeConfig = _activeConfig.copyWith(brightMode: !_activeConfig.brightMode);
    _tokens = VisionTokens(_activeConfig);
    await _prefs.setBrightTheme(_activeConfig.brightMode);
    await _persist();
    notifyListeners();
  }

  bool get brightMode => activeConfig.brightMode;

  // — Preview (live edit, not persisted) —
  void previewConfig(AppThemeConfig config) {
    _previewConfig = config;
    notifyListeners();
  }

  void clearPreview() {
    _previewConfig = null;
    notifyListeners();
  }

  // — Commit preview to active —
  Future<void> commitPreview() async {
    if (_previewConfig == null) return;
    _activeConfig = _previewConfig!;
    _previewConfig = null;
    _tokens = VisionTokens(_activeConfig);

    // Update user themes list if this is a user theme
    if (!_activeConfig.isBuiltIn) {
      final idx = _userThemes.indexWhere((t) => t.id == _activeConfig.id);
      if (idx >= 0) {
        _userThemes[idx] = _activeConfig;
      }
    }

    await _persist();
    notifyListeners();
  }

  // — Save current config as a new user theme —
  Future<AppThemeConfig> saveAsUserTheme(String name, AppThemeConfig config) async {
    final newConfig = config.copyWith(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isBuiltIn: false,
    );
    _userThemes.add(newConfig);
    _activeConfig = newConfig;
    _previewConfig = null;
    _tokens = VisionTokens(_activeConfig);
    await _persist();
    notifyListeners();
    return newConfig;
  }

  // — Update an existing user theme —
  Future<void> updateUserTheme(AppThemeConfig config) async {
    final idx = _userThemes.indexWhere((t) => t.id == config.id);
    if (idx >= 0) {
      _userThemes[idx] = config;
      if (_activeConfig.id == config.id) {
        _activeConfig = config;
        _tokens = VisionTokens(_activeConfig);
      }
    }
    await _persist();
    notifyListeners();
  }

  // — Delete a user theme —
  Future<void> deleteUserTheme(String themeId) async {
    _userThemes.removeWhere((t) => t.id == themeId);
    if (_activeConfig.id == themeId) {
      _activeConfig = BuiltInThemes.defaultTheme;
      _tokens = VisionTokens(_activeConfig);
    }
    _previewConfig = null;
    await _persist();
    notifyListeners();
  }

  // — Section order —
  Future<void> reorderSections(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _sectionOrder.removeAt(oldIndex);
    _sectionOrder.insert(newIndex, item);
    await _prefs.setSettingsSectionOrder(_sectionOrder);
    notifyListeners();
  }

  Future<void> resetSectionOrder() async {
    _sectionOrder = List.of(defaultSectionOrder);
    await _prefs.setSettingsSectionOrder(_sectionOrder);
    notifyListeners();
  }

  // — Persistence —
  Future<void> _persist() async {
    await _prefs.setActiveThemeId(_activeConfig.id);
    await _prefs.setActiveThemeJson(_activeConfig.toJsonString());
    final userJson = jsonEncode(_userThemes.map((t) => t.toJson()).toList());
    await _prefs.setUserThemes(userJson);
  }

  // — Build ThemeData from config —
  ThemeData _buildThemeData(AppThemeConfig config) {
    String? fontFamily;
    try {
      fontFamily = GoogleFonts.getFont(config.fontFamily).fontFamily;
    } catch (_) {
      fontFamily = GoogleFonts.getFont('JetBrains Mono').fontFamily;
    }

    return ThemeData(
      scaffoldBackgroundColor: config.background,
      colorScheme: ColorScheme.dark(
        primary: config.accent,
        surface: config.background,
        onSurface: config.textPrimary,
        onPrimary: config.background,
        secondary: config.accent,
      ),
      fontFamily: fontFamily,
      textTheme: const TextTheme().apply(
        bodyColor: config.textPrimary,
        displayColor: config.textPrimary,
        fontFamily: fontFamily,
      ),
      iconTheme: IconThemeData(color: config.textPrimary),
      dividerTheme: DividerThemeData(color: config.borderStrong),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.background,
        labelStyle: TextStyle(color: config.textSecondary),
        hintStyle: TextStyle(color: config.textTertiary),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: config.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: config.accent),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: config.borderStrong),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      cardTheme: CardThemeData(
        color: config.background,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: config.borderMedium, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.accent,
          foregroundColor: config.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}
