import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../models/slideshow_config.dart';

class SlideshowNotifier extends ChangeNotifier {
  List<SlideshowConfig> _configs = [];
  SlideshowConfig? _activeConfig;
  String? _defaultConfigId;

  List<SlideshowConfig> get configs => _configs;
  SlideshowConfig? get activeConfig => _activeConfig;
  String? get defaultConfigId => _defaultConfigId;

  /// Resolves the default config ID against the current configs list.
  SlideshowConfig? get defaultConfig {
    if (_defaultConfigId == null) return null;
    return _configs.where((c) => c.id == _defaultConfigId).firstOrNull;
  }

  void setDefaultConfigId(String? id) {
    _defaultConfigId = id;
    notifyListeners();
  }

  /// Load saved configs from persisted JSON string.
  void loadFromJson(String json) {
    if (json.isEmpty) return;
    try {
      final List<dynamic> list = jsonDecode(json);
      _configs =
          list.map((j) => SlideshowConfig.fromJson(j as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading slideshow configs: $e');
    }
  }

  /// Serialise all configs to JSON string for persistence.
  String toJsonString() {
    return jsonEncode(_configs.map((c) => c.toJson()).toList());
  }

  void selectConfig(SlideshowConfig config) {
    _activeConfig = config;
    notifyListeners();
  }

  void addConfig(SlideshowConfig config) {
    _configs.add(config);
    _activeConfig = config;
    notifyListeners();
  }

  void updateConfig(SlideshowConfig config) {
    final idx = _configs.indexWhere((c) => c.id == config.id);
    if (idx >= 0) {
      _configs[idx] = config;
      if (_activeConfig?.id == config.id) _activeConfig = config;
      notifyListeners();
    }
  }

  void deleteConfig(String id) {
    _configs.removeWhere((c) => c.id == id);
    if (_activeConfig?.id == id) {
      _activeConfig = _configs.isNotEmpty ? _configs.first : null;
    }
    if (_defaultConfigId == id) {
      _defaultConfigId = null;
    }
    notifyListeners();
  }

  SlideshowConfig createNew() {
    final config = SlideshowConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Slideshow ${_configs.length + 1}',
    );
    addConfig(config);
    return config;
  }

  /// Build a playlist of gallery items from the config's source type.
  List<GalleryItem> buildPlaylist(
      SlideshowConfig config, GalleryNotifier gallery) {
    List<GalleryItem> items;
    switch (config.sourceType) {
      case ImageSourceType.allImages:
        items = List.of(gallery.activeItems);
      case ImageSourceType.album:
        if (config.albumId == null) return [];
        final album =
            gallery.albums.where((a) => a.id == config.albumId).firstOrNull;
        if (album == null) return [];
        items = gallery.items
            .where((i) => album.imageBasenames.contains(i.basename))
            .toList();
      case ImageSourceType.favorites:
        items = gallery.items.where((i) => i.isFavorite).toList();
      case ImageSourceType.custom:
        final basenames = config.customImageBasenames.toSet();
        items =
            gallery.items.where((i) => basenames.contains(i.basename)).toList();
    }
    if (config.shuffleEnabled) {
      items.shuffle();
    }
    return items;
  }
}
