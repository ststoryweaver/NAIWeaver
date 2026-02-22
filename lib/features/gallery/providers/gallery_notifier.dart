import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../tools/canvas/services/canvas_gallery_service.dart';
import '../models/gallery_album.dart';
import '../services/album_service.dart';
import '../services/gallery_import_service.dart';

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
  DateTime date;
  final int fileSize;
  Map<String, String>? metadata;
  String? prompt;
  bool isFavorite;
  bool isDemoSafe;
  bool hasCanvasState;

  GalleryItem({
    required this.file,
    required this.date,
    this.fileSize = 0,
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
  late final AlbumService _albumService;
  final GalleryImportService _importService = GalleryImportService();
  List<GalleryItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = "";
  Set<String> _favorites = {};
  bool _showFavoritesOnly = false;
  Set<String> _demoSafe = {};
  bool _demoMode = false;
  GallerySortMode _sortMode = GallerySortMode.dateDesc;
  String? _activeAlbumId;
  List<String> _clipboard = [];

  List<GalleryItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get demoMode => _demoMode;
  GallerySortMode get sortMode => _sortMode;
  List<GalleryAlbum> get albums => _albumService.albums;
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
      final album = _albumService.albums.where((a) => a.id == _activeAlbumId).firstOrNull;
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
        sorted.sort((a, b) => b.fileSize.compareTo(a.fileSize));
      case GallerySortMode.sizeAsc:
        sorted.sort((a, b) => a.fileSize.compareTo(b.fileSize));
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
    _albumService = AlbumService(prefs: _prefs);
    _favorites = _prefs.favorites;
    _demoSafe = _prefs.demoSafe;
    _demoMode = _prefs.demoMode;
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
              fileSize: stat.size,
            ));
          }
        }

        // Sort by date descending (newest first)
        newItems.sort((a, b) => b.date.compareTo(a.date));
        _items = newItems;
        _applyFavorites();
        _applyDemoSafe();
        _applyCanvasState();

        // Start indexing metadata and recovering original dates in background
        _indexMetadata();
        _recoverOriginalDates();
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

  /// Recovers original creation dates from OriginalDate PNG text chunks.
  /// This corrects dates that were lost due to setLastModified failures
  /// (e.g., some Android versions) by reading the embedded chunk.
  Future<void> _recoverOriginalDates() async {
    bool changed = false;
    for (final item in _items) {
      try {
        final metadata = await getMetadata(item);
        if (metadata != null && metadata.containsKey('OriginalDate')) {
          final origDate = DateTime.tryParse(metadata['OriginalDate']!);
          if (origDate != null && origDate != item.date) {
            item.date = origDate;
            changed = true;
          }
        }
      } catch (_) {}
    }
    if (changed) notifyListeners();
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
      _albumService.addToAlbum(defaultAlbumId, [newItem.basename]);
    }

    notifyListeners();

    // Trigger metadata indexing for this new item
    _indexMetadataForItem(newItem);
  }

  /// Save an ML-processed result (BG removal, upscale) to the output directory.
  Future<void> saveMLResult(Uint8List bytes, String filename) async {
    final destPath = p.join(outputDir, filename);
    final file = File(destPath);
    await file.writeAsBytes(bytes);
    addFile(file, DateTime.now());
  }

  /// Save an ML result with metadata copied from the source image.
  Future<void> saveMLResultWithMetadata(Uint8List bytes, String filename, {Uint8List? sourceBytes}) async {
    Uint8List finalBytes = bytes;
    if (sourceBytes != null) {
      final result = await compute(convertToPngPreservingMetadata, {
        'bytes': bytes,
        'originalBytes': sourceBytes,
      });
      if (result != null) finalBytes = result;
    }
    final destPath = p.join(outputDir, filename);
    final file = File(destPath);
    await file.writeAsBytes(finalBytes);
    addFile(file, DateTime.now());
  }

  Future<ImportResult> importFiles(
    List<String> filePaths, {
    void Function(int current, int total)? onProgress,
  }) {
    return _importService.importFiles(
      filePaths,
      outputDir: outputDir,
      onFileImported: (file, date) => addFile(file, date),
      onProgress: onProgress,
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
    if (_clipboard.isNotEmpty) {
      _albumService.addToAlbum(albumId, _clipboard);
      _clipboard = [];
      notifyListeners();
    }
  }

  void clearClipboard() {
    _clipboard = [];
    notifyListeners();
  }

  // — Albums —

  void setActiveAlbum(String? albumId) {
    _activeAlbumId = albumId;
    notifyListeners();
  }

  void createAlbum(String name) {
    _albumService.createAlbum(name);
    notifyListeners();
  }

  void deleteAlbum(String id) {
    _albumService.deleteAlbum(id);
    if (_activeAlbumId == id) _activeAlbumId = null;
    notifyListeners();
  }

  void renameAlbum(String id, String newName) {
    _albumService.renameAlbum(id, newName);
    notifyListeners();
  }

  void addToAlbum(String albumId, List<GalleryItem> items) {
    _albumService.addToAlbum(albumId, items.map((i) => i.basename).toList());
    notifyListeners();
  }

  void removeFromAlbum(String albumId, List<GalleryItem> items) {
    _albumService.removeFromAlbum(albumId, items.map((i) => i.basename).toList());
    notifyListeners();
  }

  int albumItemCount(String albumId) {
    return _albumService.albumItemCount(
        albumId, _items.map((i) => i.basename).toList());
  }
}
