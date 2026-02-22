import 'package:shared_preferences/shared_preferences.dart';

class GalleryPreferences {
  final SharedPreferences _prefs;

  GalleryPreferences(this._prefs);

  // — Key constants —
  static const String _kFavorites = 'gallery_favorites';
  static const String _kDemoSafe = 'gallery_demo_safe';
  static const String _kDemoMode = 'demo_mode_active';
  static const String _kDemoPositivePrefix = 'demo_positive_prefix';
  static const String _kDemoNegativePrefix = 'demo_negative_prefix';
  static const String _kAlbums = 'gallery_albums';
  static const String _kGridColumns = 'gallery_grid_columns';
  static const String _kDefaultSaveAlbumId = 'default_save_album_id';
  static const String _kStripMetadata = 'strip_metadata_on_export';
  static const String _kDefaultSlideshowId = 'default_slideshow_id';
  static const String _kSlideshowConfigs = 'slideshow_configs';

  // — Favorites —

  Set<String> get favorites =>
      (_prefs.getStringList(_kFavorites) ?? []).toSet();

  Future<void> setFavorites(Set<String> value) async {
    await _prefs.setStringList(_kFavorites, value.toList());
  }

  // — Demo Safe —

  Set<String> get demoSafe =>
      (_prefs.getStringList(_kDemoSafe) ?? []).toSet();

  Future<void> setDemoSafe(Set<String> value) async {
    await _prefs.setStringList(_kDemoSafe, value.toList());
  }

  // — Demo Mode —

  bool get demoMode => _prefs.getBool(_kDemoMode) ?? false;

  Future<void> setDemoMode(bool value) async {
    await _prefs.setBool(_kDemoMode, value);
  }

  // — Demo Positive Prefix —

  String get demoPositivePrefix =>
      _prefs.getString(_kDemoPositivePrefix) ?? 'safe';

  Future<void> setDemoPositivePrefix(String value) async {
    await _prefs.setString(_kDemoPositivePrefix, value);
  }

  // — Demo Negative Prefix —

  String get demoNegativePrefix =>
      _prefs.getString(_kDemoNegativePrefix) ?? 'nsfw, explicit';

  Future<void> setDemoNegativePrefix(String value) async {
    await _prefs.setString(_kDemoNegativePrefix, value);
  }

  // — Albums —

  String get albums => _prefs.getString(_kAlbums) ?? '';

  Future<void> setAlbums(String value) async {
    await _prefs.setString(_kAlbums, value);
  }

  // — Grid Columns —

  int? get gridColumns => _prefs.getInt(_kGridColumns);

  Future<void> setGridColumns(int value) async {
    await _prefs.setInt(_kGridColumns, value);
  }

  // — Default Save Album —

  String? get defaultSaveAlbumId => _prefs.getString(_kDefaultSaveAlbumId);

  Future<void> setDefaultSaveAlbumId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kDefaultSaveAlbumId);
    } else {
      await _prefs.setString(_kDefaultSaveAlbumId, id);
    }
  }

  // — Strip Metadata on Export —

  bool get stripMetadataOnExport => _prefs.getBool(_kStripMetadata) ?? false;

  Future<void> setStripMetadataOnExport(bool value) async {
    await _prefs.setBool(_kStripMetadata, value);
  }

  // — Default Slideshow —

  String? get defaultSlideshowId => _prefs.getString(_kDefaultSlideshowId);

  Future<void> setDefaultSlideshowId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kDefaultSlideshowId);
    } else {
      await _prefs.setString(_kDefaultSlideshowId, id);
    }
  }

  // — Slideshow Configs —

  String get slideshowConfigs => _prefs.getString(_kSlideshowConfigs) ?? '';

  Future<void> setSlideshowConfigs(String value) async {
    await _prefs.setString(_kSlideshowConfigs, value);
  }
}
