import 'package:shared_preferences/shared_preferences.dart';

class MlPreferences {
  final SharedPreferences _prefs;

  MlPreferences(this._prefs);

  // — Key constants —
  static const String _kSelectedBgRemovalModel = 'selected_bg_removal_model';
  static const String _kSelectedUpscaleModel = 'selected_upscale_model';
  static const String _kSelectedSegmentationModel = 'selected_segmentation_model';
  static const String _kUpscaleBackend = 'upscale_backend';
  static const String _kBgRemovalBackend = 'bg_removal_backend';

  // — BG Removal Model —

  String? get selectedBgRemovalModel =>
      _prefs.getString(_kSelectedBgRemovalModel);

  Future<void> setSelectedBgRemovalModel(String? id) async {
    if (id == null) {
      await _prefs.remove(_kSelectedBgRemovalModel);
    } else {
      await _prefs.setString(_kSelectedBgRemovalModel, id);
    }
  }

  // — Upscale Model —

  String? get selectedUpscaleModel =>
      _prefs.getString(_kSelectedUpscaleModel);

  Future<void> setSelectedUpscaleModel(String? id) async {
    if (id == null) {
      await _prefs.remove(_kSelectedUpscaleModel);
    } else {
      await _prefs.setString(_kSelectedUpscaleModel, id);
    }
  }

  // — Upscale Backend —

  String get upscaleBackend => _prefs.getString(_kUpscaleBackend) ?? 'novelai';

  Future<void> setUpscaleBackend(String value) async {
    await _prefs.setString(_kUpscaleBackend, value);
  }

  // — BG Removal Backend —

  String get bgRemovalBackend =>
      _prefs.getString(_kBgRemovalBackend) ?? 'novelai';

  Future<void> setBgRemovalBackend(String value) async {
    await _prefs.setString(_kBgRemovalBackend, value);
  }

  // — Segmentation Model —

  String? get selectedSegmentationModel =>
      _prefs.getString(_kSelectedSegmentationModel);

  Future<void> setSelectedSegmentationModel(String? id) async {
    if (id == null) {
      await _prefs.remove(_kSelectedSegmentationModel);
    } else {
      await _prefs.setString(_kSelectedSegmentationModel, id);
    }
  }
}
