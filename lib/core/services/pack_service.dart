import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../../features/gallery/models/gallery_album.dart';
import '../../features/gallery/providers/gallery_notifier.dart';
import '../utils/image_utils.dart';
import 'presets.dart';
import 'styles.dart';

class PackManifest {
  final String name;
  final String description;
  final String version;
  final int presetCount;
  final int styleCount;
  final int wildcardCount;

  PackManifest({
    required this.name,
    this.description = '',
    this.version = '1.0',
    this.presetCount = 0,
    this.styleCount = 0,
    this.wildcardCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'version': version,
        'presetCount': presetCount,
        'styleCount': styleCount,
        'wildcardCount': wildcardCount,
      };

  factory PackManifest.fromJson(Map<String, dynamic> json) => PackManifest(
        name: json['name'] as String? ?? 'Unnamed Pack',
        description: json['description'] as String? ?? '',
        version: json['version'] as String? ?? '1.0',
        presetCount: json['presetCount'] as int? ?? 0,
        styleCount: json['styleCount'] as int? ?? 0,
        wildcardCount: json['wildcardCount'] as int? ?? 0,
      );
}

class PackContents {
  final PackManifest manifest;
  final List<GenerationPreset> presets;
  final List<PromptStyle> styles;
  final Map<String, String> wildcards; // filename → content

  PackContents({
    required this.manifest,
    this.presets = const [],
    this.styles = const [],
    this.wildcards = const {},
  });
}

class PackService {
  /// Creates a .vpack ZIP archive with selected presets, styles, and wildcards.
  static Uint8List exportPack({
    required String name,
    String description = '',
    List<GenerationPreset> presets = const [],
    List<PromptStyle> styles = const [],
    Map<String, String> wildcards = const {},
  }) {
    final archive = Archive();
    int refIndex = 0;

    // Process presets — extract base64 director reference images to separate files
    final processedPresets = <Map<String, dynamic>>[];
    for (final preset in presets) {
      final presetJson = preset.toJson();

      // Extract director reference images
      if (presetJson['directorReferences'] != null) {
        final refs = presetJson['directorReferences'] as List<dynamic>;
        for (int i = 0; i < refs.length; i++) {
          final ref = refs[i] as Map<String, dynamic>;
          if (ref.containsKey('originalImageBytes')) {
            final base64Str = ref['originalImageBytes'] as String;
            final filename = 'ref_${refIndex}_$i.png';
            try {
              final bytes = base64Decode(base64Str);
              archive.addFile(ArchiveFile('references/$filename', bytes.length, bytes));
              ref['originalImageBytes'] = '@ref:$filename';
            } catch (_) {
              // If decode fails, leave as-is
            }
          }
        }
      }

      processedPresets.add(presetJson);
      refIndex++;
    }

    // Add presets
    for (int i = 0; i < processedPresets.length; i++) {
      final content = utf8.encode(const JsonEncoder.withIndent('  ').convert(processedPresets[i]));
      archive.addFile(ArchiveFile('presets/${_sanitize(presets[i].name)}.json', content.length, content));
    }

    // Add styles
    for (final style in styles) {
      final content = utf8.encode(const JsonEncoder.withIndent('  ').convert(style.toJson()));
      archive.addFile(ArchiveFile('styles/${_sanitize(style.name)}.json', content.length, content));
    }

    // Add wildcards
    for (final entry in wildcards.entries) {
      final content = utf8.encode(entry.value);
      archive.addFile(ArchiveFile('wildcards/${entry.key}', content.length, content));
    }

    // Generate manifest
    final manifest = PackManifest(
      name: name,
      description: description,
      presetCount: presets.length,
      styleCount: styles.length,
      wildcardCount: wildcards.length,
    );
    final manifestContent = utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
    archive.addFile(ArchiveFile('pack.json', manifestContent.length, manifestContent));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Parses a .vpack ZIP archive and returns its contents.
  static PackContents importPack(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    // Read manifest
    PackManifest manifest = PackManifest(name: 'Unnamed Pack');
    final manifestFile = archive.findFile('pack.json');
    if (manifestFile != null) {
      final json = jsonDecode(utf8.decode(manifestFile.content as List<int>));
      manifest = PackManifest.fromJson(json as Map<String, dynamic>);
    }

    // Collect reference images
    final refImages = <String, Uint8List>{};
    for (final file in archive) {
      if (file.name.startsWith('references/') && !file.isFile) continue;
      if (file.name.startsWith('references/') && file.isFile) {
        final filename = file.name.replaceFirst('references/', '');
        if (filename.contains('..') || filename.startsWith('/')) continue;
        refImages[filename] = Uint8List.fromList(file.content as List<int>);
      }
    }

    // Load presets
    final presets = <GenerationPreset>[];
    for (final file in archive) {
      if (file.name.startsWith('presets/') && file.name.endsWith('.json') && file.isFile) {
        final presetFilename = file.name.replaceFirst('presets/', '');
        if (presetFilename.contains('..') || presetFilename.startsWith('/')) continue;
        try {
          final json = jsonDecode(utf8.decode(file.content as List<int>)) as Map<String, dynamic>;

          // Restore director reference images from file pointers
          if (json['directorReferences'] != null) {
            final refs = json['directorReferences'] as List<dynamic>;
            for (final ref in refs) {
              if (ref is Map<String, dynamic> && ref['originalImageBytes'] is String) {
                final pointer = ref['originalImageBytes'] as String;
                if (pointer.startsWith('@ref:')) {
                  final filename = pointer.substring(5);
                  if (refImages.containsKey(filename)) {
                    ref['originalImageBytes'] = base64Encode(refImages[filename]!);
                  }
                }
              }
            }
          }

          presets.add(GenerationPreset.fromJson(json));
        } catch (_) {
          // Skip malformed preset files
        }
      }
    }

    // Load styles
    final styles = <PromptStyle>[];
    for (final file in archive) {
      if (file.name.startsWith('styles/') && file.name.endsWith('.json') && file.isFile) {
        final styleFilename = file.name.replaceFirst('styles/', '');
        if (styleFilename.contains('..') || styleFilename.startsWith('/')) continue;
        try {
          final json = jsonDecode(utf8.decode(file.content as List<int>)) as Map<String, dynamic>;
          styles.add(PromptStyle.fromJson(json));
        } catch (_) {
          // Skip malformed style files
        }
      }
    }

    // Load wildcards
    final wildcards = <String, String>{};
    for (final file in archive) {
      if (file.name.startsWith('wildcards/') && file.isFile) {
        final filename = file.name.replaceFirst('wildcards/', '');
        if (filename.contains('..') || filename.startsWith('/')) continue;
        wildcards[filename] = utf8.decode(file.content as List<int>);
      }
    }

    return PackContents(
      manifest: manifest,
      presets: presets,
      styles: styles,
      wildcards: wildcards,
    );
  }

  /// Exports gallery images as a ZIP archive with album folder hierarchy.
  static Future<Uint8List> exportGalleryZip({
    required List<GalleryAlbum> albums,
    required List<GalleryItem> allItems,
    required Set<String> selectedAlbumIds,
    required bool includeUnsorted,
    required bool stripMeta,
    required bool favoritesOnly,
  }) async {
    final archive = Archive();

    // Build set of basenames that belong to any selected album
    final albumBasenames = <String>{};
    for (final album in albums) {
      if (!selectedAlbumIds.contains(album.id)) continue;
      albumBasenames.addAll(album.imageBasenames);
    }

    // Filter items
    var items = allItems;
    if (favoritesOnly) {
      items = items.where((i) => i.isFavorite).toList();
    }

    // Add album images
    for (final album in albums) {
      if (!selectedAlbumIds.contains(album.id)) continue;
      final folderName = _sanitize(album.name);
      for (final item in items) {
        if (!album.imageBasenames.contains(item.basename)) continue;
        if (!item.file.existsSync()) continue;
        var bytes = await item.file.readAsBytes();
        if (stripMeta) {
          bytes = stripMetadata(bytes);
        }
        archive.addFile(ArchiveFile('$folderName/${item.basename}', bytes.length, bytes));
      }
    }

    // Add unsorted images (not in any album at all)
    if (includeUnsorted) {
      final allAlbumBasenames = <String>{};
      for (final album in albums) {
        allAlbumBasenames.addAll(album.imageBasenames);
      }
      for (final item in items) {
        if (allAlbumBasenames.contains(item.basename)) continue;
        if (!item.file.existsSync()) continue;
        var bytes = await item.file.readAsBytes();
        if (stripMeta) {
          bytes = stripMetadata(bytes);
        }
        archive.addFile(ArchiveFile('Unsorted/${item.basename}', bytes.length, bytes));
      }
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
