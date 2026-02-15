import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../tag_service.dart';

/// Provides wildcard file listing and favorites management for auto-completion.
class WildcardService {
  final String wildcardDir;
  List<String> _wildcardNames = [];
  Set<String> _favorites = {};

  String get _favoritesPath => p.join(wildcardDir, '.wildcard_favorites.json');

  WildcardService({required this.wildcardDir});

  List<String> get wildcardNames => _wildcardNames;

  Future<void> refresh() async {
    await _loadFavorites();
    await _scanWildcards();
  }

  Future<void> _scanWildcards() async {
    try {
      final dir = Directory(wildcardDir);
      if (!await dir.exists()) {
        _wildcardNames = [];
        return;
      }

      _wildcardNames = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.txt')
          .map((f) => p.basenameWithoutExtension(f.path))
          .toList()
        ..sort((a, b) {
          final aFav = _favorites.contains(a);
          final bFav = _favorites.contains(b);
          if (aFav && !bFav) return -1;
          if (!aFav && bFav) return 1;
          return a.compareTo(b);
        });
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

  bool isFavorite(String name) => _favorites.contains(name);

  Future<void> toggleFavorite(String name) async {
    if (_favorites.contains(name)) {
      _favorites.remove(name);
    } else {
      _favorites.add(name);
    }
    await _saveFavorites();
    await _scanWildcards(); // Re-sort
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
