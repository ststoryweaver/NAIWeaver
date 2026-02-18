import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../tools/canvas/services/canvas_gallery_service.dart';
import '../models/gallery_album.dart';

class ImportResult {
  final int total;
  final int succeeded;
  final int withMetadata;
  final int converted;
  final List<String> errors;

  ImportResult({
    required this.total,
    required this.succeeded,
    required this.withMetadata,
    required this.converted,
    required this.errors,
  });
}

enum GallerySortMode { dateDesc, dateAsc, nameAsc, nameDesc, sizeDesc, sizeAsc }

class GalleryItem {
  final File file;
  final DateTime date;
  Map<String, String>? metadata;
  String? prompt;
  bool isFavorite;
  bool isDemoSafe;
  bool hasCanvasState;

  GalleryItem({
    required this.file,
    required this.date,
    this.metadata,
    this.prompt,
    this.isFavorite = false,
    this.isDemoSafe = false,
    this.hasCanvasState = false,
  });

  String get basename => p.basename(file.path);
}

class GalleryNotifier extends ChangeNotifier {
  String outputDir;
  final PreferencesService _prefs;
  List<GalleryItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = "";
  Set<String> _favorites = {};
  bool _showFavoritesOnly = false;
  Set<String> _demoSafe = {};
  bool _demoMode = false;
  GallerySortMode _sortMode = GallerySortMode.dateDesc;
  List<GalleryAlbum> _albums = [];
  String? _activeAlbumId;
  List<String> _clipboard = [];

  List<GalleryItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get demoMode => _demoMode;
  GallerySortMode get sortMode => _sortMode;
  List<GalleryAlbum> get albums => _albums;
  String? get activeAlbumId => _activeAlbumId;
  List<String> get clipboard => _clipboard;
  bool get hasClipboard => _clipboard.isNotEmpty;

  set showFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
    notifyListeners();
  }

  set demoMode(bool value) {
    _demoMode = value;
    _prefs.setDemoMode(value);
    notifyListeners();
  }

  List<GalleryItem> get filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      final prompt = item.prompt?.toLowerCase() ?? "";
      return prompt.contains(query);
    }).toList();
  }

  List<GalleryItem> get activeItems {
    var list = _searchQuery.isEmpty ? _items : filteredItems;
    if (_demoMode) {
      list = list.where((item) => item.isDemoSafe).toList();
    }
    if (_showFavoritesOnly) {
      list = list.where((item) => item.isFavorite).toList();
    }
    if (_activeAlbumId != null) {
      final album = _albums.where((a) => a.id == _activeAlbumId).firstOrNull;
      if (album != null) {
        list = list.where((item) => album.imageBasenames.contains(item.basename)).toList();
      }
    }
    return _applySortMode(list);
  }

  List<GalleryItem> _applySortMode(List<GalleryItem> list) {
    final sorted = List<GalleryItem>.from(list);
    switch (_sortMode) {
      case GallerySortMode.dateDesc:
        sorted.sort((a, b) => b.date.compareTo(a.date));
      case GallerySortMode.dateAsc:
        sorted.sort((a, b) => a.date.compareTo(b.date));
      case GallerySortMode.nameAsc:
        sorted.sort((a, b) => a.basename.compareTo(b.basename));
      case GallerySortMode.nameDesc:
        sorted.sort((a, b) => b.basename.compareTo(a.basename));
      case GallerySortMode.sizeDesc:
        sorted.sort((a, b) => b.file.lengthSync().compareTo(a.file.lengthSync()));
      case GallerySortMode.sizeAsc:
        sorted.sort((a, b) => a.file.lengthSync().compareTo(b.file.lengthSync()));
    }
    return sorted;
  }

  void setSortMode(GallerySortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  /// All items ignoring demo mode filter (for demo image picker).
  List<GalleryItem> get allItems => _items;

  GalleryNotifier({required this.outputDir, required PreferencesService prefs})
      : _prefs = prefs {
    _favorites = _prefs.favorites;
    _demoSafe = _prefs.demoSafe;
    _demoMode = _prefs.demoMode;
    _loadAlbums();
    refresh();
  }

  void setOutputDir(String dir) {
    outputDir = dir;
    refresh();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dir = Directory(outputDir);
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        final List<GalleryItem> newItems = [];

        for (var entity in entities) {
          if (entity is File && p.extension(entity.path).toLowerCase() == '.png') {
            final stat = await entity.stat();
            newItems.add(GalleryItem(
              file: entity,
              date: stat.modified,
            ));
          }
        }

        // Sort by date descending (newest first)
        newItems.sort((a, b) => b.date.compareTo(a.date));
        _items = newItems;
        _applyFavorites();
        _applyDemoSafe();
        _applyCanvasState();

        // Start indexing metadata in background
        _indexMetadata();
      }
    } catch (e) {
      debugPrint("Gallery refresh error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _indexMetadata() async {
    for (var item in _items) {
      if (item.prompt == null) {
        final metadata = await getMetadata(item);
        if (metadata != null && metadata.containsKey('Comment')) {
          final settings = parseCommentJson(metadata['Comment']!);
          item.prompt = settings?['prompt']?.toString() ?? "";
          if (_searchQuery.isNotEmpty) {
            notifyListeners();
          }
        } else {
          item.prompt = ""; // Mark as tried
        }
      }
    }
  }

  Future<Map<String, String>?> getMetadata(GalleryItem item) async {
    if (item.metadata != null) return item.metadata;

    try {
      final bytes = await item.file.readAsBytes();
      final metadata = await compute(extractMetadata, bytes);
      item.metadata = metadata;
      return metadata;
    } catch (e) {
      debugPrint("Error extracting metadata for ${item.file.path}: $e");
      return null;
    }
  }

  Future<void> deleteItem(GalleryItem item) async {
    try {
      if (await item.file.exists()) {
        await item.file.delete();
        await CanvasGalleryService.deleteSidecars(item.file.path);
        _items.remove(item);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
  }

  void addFile(File file, DateTime date) {
    final newItem = GalleryItem(
      file: file,
      date: date,
    );
    _items.insert(0, newItem);

    // Auto-add to default save album if set
    final defaultAlbumId = _prefs.defaultSaveAlbumId;
    if (defaultAlbumId != null) {
      final idx = _albums.indexWhere((a) => a.id == defaultAlbumId);
      if (idx >= 0) {
        final updated = Set<String>.from(_albums[idx].imageBasenames)..add(newItem.basename);
        _albums[idx] = _albums[idx].copyWith(imageBasenames: updated);
        _saveAlbums();
      }
    }

    notifyListeners();

    // Trigger metadata indexing for this new item
    _indexMetadataForItem(newItem);
  }

  Future<ImportResult> importFiles(
    List<String> filePaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final fmt = DateFormat('yyyyMMdd_HHmmssSSS');
    int succeeded = 0;
    int withMetadata = 0;
    int converted = 0;
    final errors = <String>[];

    for (int i = 0; i < filePaths.length; i++) {
      onProgress?.call(i + 1, filePaths.length);
      try {
        final srcFile = File(filePaths[i]);
        final bytes = await srcFile.readAsBytes();
        Uint8List pngBytes;

        if (isPng(bytes)) {
          pngBytes = bytes;
        } else {
          // Check if the original file had a .png extension — Android's photo
          // picker may have transcoded it, losing PNG metadata chunks.
          final ext = p.extension(filePaths[i]).toLowerCase();
          if (ext == '.png') {
            // Source claimed to be PNG but bytes aren't — likely transcoded.
            // Try to recover metadata from original bytes and re-inject.
            final result = await compute(convertToPngPreservingMetadata, {
              'bytes': bytes,
              'originalBytes': bytes,
            });
            if (result == null) {
              errors.add(p.basename(filePaths[i]));
              continue;
            }
            pngBytes = result;
          } else {
            final result = await compute(convertToPng, bytes);
            if (result == null) {
              errors.add(p.basename(filePaths[i]));
              continue;
            }
            pngBytes = result;
          }
          converted++;
        }

        final now = DateTime.now();
        final destName = 'Imp_${fmt.format(now)}.png';
        final destPath = p.join(outputDir, destName);
        final destFile = File(destPath);
        await destFile.writeAsBytes(pngBytes);

        addFile(destFile, now);

        // Check for NovelAI metadata
        final metadata = await compute(extractMetadata, pngBytes);
        if (metadata != null && metadata.containsKey('Comment')) {
          withMetadata++;
        }

        succeeded++;
      } catch (e) {
        errors.add(p.basename(filePaths[i]));
      }
    }

    return ImportResult(
      total: filePaths.length,
      succeeded: succeeded,
      withMetadata: withMetadata,
      converted: converted,
      errors: errors,
    );
  }

  Future<void> _indexMetadataForItem(GalleryItem item) async {
    if (item.prompt == null) {
      final metadata = await getMetadata(item);
      if (metadata != null && metadata.containsKey('Comment')) {
        final settings = parseCommentJson(metadata['Comment']!);
        item.prompt = settings?['prompt']?.toString() ?? "";
        notifyListeners();
      } else {
        item.prompt = "";
      }
    }
  }

  void _applyDemoSafe() {
    final currentBasenames = <String>{};
    for (final item in _items) {
      final name = item.basename;
      currentBasenames.add(name);
      item.isDemoSafe = _demoSafe.contains(name);
    }
    // Prune stale entries
    final pruned = _demoSafe.intersection(currentBasenames);
    if (pruned.length != _demoSafe.length) {
      _demoSafe = pruned;
      _prefs.setDemoSafe(_demoSafe);
    }
  }

  void _applyCanvasState() {
    for (final item in _items) {
      item.hasCanvasState = CanvasGalleryService.hasCanvasState(item.file.path);
    }
  }

  void toggleDemoSafe(GalleryItem item) {
    item.isDemoSafe = !item.isDemoSafe;
    if (item.isDemoSafe) {
      _demoSafe.add(item.basename);
    } else {
      _demoSafe.remove(item.basename);
    }
    _prefs.setDemoSafe(_demoSafe);
    notifyListeners();
  }

  void addToDemoSafe(List<GalleryItem> items) {
    for (final item in items) {
      item.isDemoSafe = true;
      _demoSafe.add(item.basename);
    }
    _prefs.setDemoSafe(_demoSafe);
    notifyListeners();
  }

  void clearDemoSafe() {
    for (final item in _items) {
      item.isDemoSafe = false;
    }
    _demoSafe.clear();
    _prefs.setDemoSafe(_demoSafe);
    notifyListeners();
  }

  int get demoSafeCount => _demoSafe.length;

  void _applyFavorites() {
    final currentBasenames = <String>{};
    for (final item in _items) {
      final name = item.basename;
      currentBasenames.add(name);
      item.isFavorite = _favorites.contains(name);
    }
    // Prune stale favorites (deleted files)
    final pruned = _favorites.intersection(currentBasenames);
    if (pruned.length != _favorites.length) {
      _favorites = pruned;
      _prefs.setFavorites(_favorites);
    }
  }

  void toggleFavorite(GalleryItem item) {
    item.isFavorite = !item.isFavorite;
    if (item.isFavorite) {
      _favorites.add(item.basename);
    } else {
      _favorites.remove(item.basename);
    }
    _prefs.setFavorites(_favorites);
    notifyListeners();
  }

  void addToFavorites(List<GalleryItem> items) {
    for (final item in items) {
      item.isFavorite = true;
      _favorites.add(item.basename);
    }
    _prefs.setFavorites(_favorites);
    notifyListeners();
  }

  Future<void> deleteItems(List<GalleryItem> items) async {
    for (final item in items) {
      try {
        if (await item.file.exists()) {
          await item.file.delete();
        }
        await CanvasGalleryService.deleteSidecars(item.file.path);
      } catch (e) {
        debugPrint("Error deleting file: $e");
      }
      _favorites.remove(item.basename);
      _demoSafe.remove(item.basename);
      _items.remove(item);
    }
    _prefs.setFavorites(_favorites);
    _prefs.setDemoSafe(_demoSafe);
    notifyListeners();
  }

  // — Clipboard —

  void copyToClipboard(List<GalleryItem> items) {
    _clipboard = items.map((i) => i.basename).toList();
    notifyListeners();
  }

  void pasteToAlbum(String albumId) {
    final idx = _albums.indexWhere((a) => a.id == albumId);
    if (idx >= 0 && _clipboard.isNotEmpty) {
      final updated = Set<String>.from(_albums[idx].imageBasenames)..addAll(_clipboard);
      _albums[idx] = _albums[idx].copyWith(imageBasenames: updated);
      _saveAlbums();
      _clipboard = [];
      notifyListeners();
    }
  }

  void clearClipboard() {
    _clipboard = [];
    notifyListeners();
  }

  // — Albums —

  void _loadAlbums() {
    final raw = _prefs.galleryAlbums;
    if (raw.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(raw);
        _albums = list.map((j) => GalleryAlbum.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error loading albums: $e');
      }
    }
  }

  Future<void> _saveAlbums() async {
    await _prefs.setGalleryAlbums(json.encode(_albums.map((a) => a.toJson()).toList()));
  }

  void setActiveAlbum(String? albumId) {
    _activeAlbumId = albumId;
    notifyListeners();
  }

  void createAlbum(String name) {
    final album = GalleryAlbum(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _albums.add(album);
    _saveAlbums();
    notifyListeners();
  }

  void deleteAlbum(String id) {
    _albums.removeWhere((a) => a.id == id);
    if (_activeAlbumId == id) _activeAlbumId = null;
    _saveAlbums();
    notifyListeners();
  }

  void renameAlbum(String id, String newName) {
    final idx = _albums.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _albums[idx] = _albums[idx].copyWith(name: newName);
      _saveAlbums();
      notifyListeners();
    }
  }

  void addToAlbum(String albumId, List<GalleryItem> items) {
    final idx = _albums.indexWhere((a) => a.id == albumId);
    if (idx >= 0) {
      final updated = Set<String>.from(_albums[idx].imageBasenames);
      for (final item in items) {
        updated.add(item.basename);
      }
      _albums[idx] = _albums[idx].copyWith(imageBasenames: updated);
      _saveAlbums();
      notifyListeners();
    }
  }

  void removeFromAlbum(String albumId, List<GalleryItem> items) {
    final idx = _albums.indexWhere((a) => a.id == albumId);
    if (idx >= 0) {
      final updated = Set<String>.from(_albums[idx].imageBasenames);
      for (final item in items) {
        updated.remove(item.basename);
      }
      _albums[idx] = _albums[idx].copyWith(imageBasenames: updated);
      _saveAlbums();
      notifyListeners();
    }
  }

  int albumItemCount(String albumId) {
    final album = _albums.where((a) => a.id == albumId).firstOrNull;
    if (album == null) return 0;
    return _items.where((item) => album.imageBasenames.contains(item.basename)).length;
  }
}
