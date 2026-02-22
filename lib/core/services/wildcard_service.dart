import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'tag_service.dart';
import 'wildcard_processor.dart';

/// Provides wildcard file listing and favorites management for auto-completion.
class WildcardService {
  final String wildcardDir;
  List<String> _wildcardNames = [];
  Set<String> _favorites = {};
  List<String> _customOrder = [];
  Map<String, WildcardMode> _modes = {};

  String get _favoritesPath => p.join(wildcardDir, '.wildcard_favorites.json');
  String get _orderPath => p.join(wildcardDir, '.wildcard_order.json');
  String get _modesPath => p.join(wildcardDir, '.wildcard_modes.json');

  WildcardService({required this.wildcardDir});

  List<String> get wildcardNames => _wildcardNames;

  Future<void> refresh() async {
    await _loadFavorites();
    await _loadOrder();
    await _loadModes();
    await _scanWildcards();
  }

  Future<void> _scanWildcards() async {
    try {
      final dir = Directory(wildcardDir);
      if (!await dir.exists()) {
        _wildcardNames = [];
        return;
      }

      final diskNames = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.txt')
          .map((f) => p.basenameWithoutExtension(f.path))
          .toSet();

      if (_customOrder.isNotEmpty) {
        // Keep only names that still exist on disk, preserving custom order
        final ordered = _customOrder.where((n) => diskNames.contains(n)).toList();
        // Append any new files not yet in the custom order
        final newNames = diskNames.where((n) => !_customOrder.contains(n)).toList()..sort();
        ordered.addAll(newNames);
        _wildcardNames = ordered;
        // Update persisted order to include new files
        if (newNames.isNotEmpty) {
          _customOrder = List<String>.from(ordered);
          await _saveOrder();
        }
      } else {
        // No custom order: default sort (favorites first, then alphabetical)
        _wildcardNames = diskNames.toList()
          ..sort((a, b) {
            final aFav = _favorites.contains(a);
            final bFav = _favorites.contains(b);
            if (aFav && !bFav) return -1;
            if (!aFav && bFav) return 1;
            return a.compareTo(b);
          });
      }
    } catch (e) {
      debugPrint('Error scanning wildcards: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final file = File(_favoritesPath);
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        _favorites = Set<String>.from(json as List);
      }
    } catch (e) {
      debugPrint('Error loading wildcard favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final file = File(_favoritesPath);
      await file.writeAsString(jsonEncode(_favorites.toList()));
    } catch (e) {
      debugPrint('Error saving wildcard favorites: $e');
    }
  }

  Future<void> _loadOrder() async {
    try {
      final file = File(_orderPath);
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        _customOrder = List<String>.from(json as List);
      }
    } catch (e) {
      debugPrint('Error loading wildcard order: $e');
    }
  }

  Future<void> _saveOrder() async {
    try {
      final file = File(_orderPath);
      await file.writeAsString(jsonEncode(_customOrder));
    } catch (e) {
      debugPrint('Error saving wildcard order: $e');
    }
  }

  Future<void> _loadModes() async {
    try {
      final file = File(_modesPath);
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _modes = json.map((k, v) => MapEntry(k, WildcardMode.values.firstWhere(
          (m) => m.name == v,
          orElse: () => WildcardMode.random,
        )));
      }
    } catch (e) {
      debugPrint('Error loading wildcard modes: $e');
    }
  }

  Future<void> _saveModes() async {
    try {
      final file = File(_modesPath);
      final json = _modes.map((k, v) => MapEntry(k, v.name));
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving wildcard modes: $e');
    }
  }

  bool isFavorite(String name) => _favorites.contains(name);

  Future<void> toggleFavorite(String name) async {
    if (_favorites.contains(name)) {
      _favorites.remove(name);
    } else {
      _favorites.add(name);
    }
    await _saveFavorites();
    // Only re-sort if there's no custom order (custom order takes precedence)
    if (_customOrder.isEmpty) {
      await _scanWildcards();
    }
  }

  Future<void> reorderWildcard(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _wildcardNames.removeAt(oldIndex);
    _wildcardNames.insert(newIndex, item);
    _customOrder = List<String>.from(_wildcardNames);
    await _saveOrder();
  }

  WildcardMode getMode(String name) => _modes[name] ?? WildcardMode.random;

  Future<void> setMode(String name, WildcardMode mode) async {
    if (mode == WildcardMode.random) {
      _modes.remove(name);
    } else {
      _modes[name] = mode;
    }
    await _saveModes();
  }

  /// Returns wildcard suggestions matching [query] as DanbooruTag objects
  /// with typeName 'wildcard' or 'wildcard_favorite'.
  List<DanbooruTag> getSuggestions(String query) {
    final lowerQuery = query.toLowerCase();
    return _wildcardNames
        .where((name) => name.toLowerCase().contains(lowerQuery))
        .map((name) => DanbooruTag(
              tag: '__${name}__',
              count: 0,
              typeName: _favorites.contains(name) ? 'wildcard_favorite' : 'wildcard',
              isFavorite: _favorites.contains(name),
            ))
        .toList();
  }

  /// Returns all wildcards (for when user just types `__` with no filter).
  List<DanbooruTag> getAll() {
    return _wildcardNames
        .map((name) => DanbooruTag(
              tag: '__${name}__',
              count: 0,
              typeName: _favorites.contains(name) ? 'wildcard_favorite' : 'wildcard',
              isFavorite: _favorites.contains(name),
            ))
        .toList();
  }
}
