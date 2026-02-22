import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/services/preferences_service.dart';
import '../models/gallery_album.dart';

/// Manages gallery albums: persistence and CRUD operations.
class AlbumService {
  final PreferencesService _prefs;
  List<GalleryAlbum> _albums = [];

  AlbumService({required PreferencesService prefs}) : _prefs = prefs {
    _loadAlbums();
  }

  List<GalleryAlbum> get albums => _albums;

  void _loadAlbums() {
    final raw = _prefs.galleryAlbums;
    if (raw.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(raw);
        _albums =
            list.map((j) => GalleryAlbum.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error loading albums: $e');
      }
    }
  }

  Future<void> _saveAlbums() async {
    await _prefs
        .setGalleryAlbums(json.encode(_albums.map((a) => a.toJson()).toList()));
  }

  void createAlbum(String name) {
    final album = GalleryAlbum(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _albums.add(album);
    _saveAlbums();
  }

  void deleteAlbum(String id) {
    _albums.removeWhere((a) => a.id == id);
    _saveAlbums();
  }

  void renameAlbum(String id, String newName) {
    final idx = _albums.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _albums[idx] = _albums[idx].copyWith(name: newName);
      _saveAlbums();
    }
  }

  void addToAlbum(String albumId, List<String> basenames) {
    final idx = _albums.indexWhere((a) => a.id == albumId);
    if (idx >= 0) {
      final updated = Set<String>.from(_albums[idx].imageBasenames)
        ..addAll(basenames);
      _albums[idx] = _albums[idx].copyWith(imageBasenames: updated);
      _saveAlbums();
    }
  }

  void removeFromAlbum(String albumId, List<String> basenames) {
    final idx = _albums.indexWhere((a) => a.id == albumId);
    if (idx >= 0) {
      final updated = Set<String>.from(_albums[idx].imageBasenames);
      for (final name in basenames) {
        updated.remove(name);
      }
      _albums[idx] = _albums[idx].copyWith(imageBasenames: updated);
      _saveAlbums();
    }
  }

  /// Count items in an album that exist in the provided items list.
  int albumItemCount(String albumId, List<String> allBasenames) {
    final album = _albums.where((a) => a.id == albumId).firstOrNull;
    if (album == null) return 0;
    return allBasenames
        .where((name) => album.imageBasenames.contains(name))
        .length;
  }
}
