import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/services/pack_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../presets.dart';
import '../../../styles.dart';
import '../../gallery/providers/gallery_notifier.dart';
import '../../generation/providers/generation_notifier.dart';
import '../providers/wildcard_notifier.dart';

class PackManager extends StatefulWidget {
  const PackManager({super.key});

  @override
  State<PackManager> createState() => _PackManagerState();
}

class _PackManagerState extends State<PackManager> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return Padding(
      padding: EdgeInsets.all(mobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.packTitle,
            style: TextStyle(
              color: t.textSecondary,
              fontSize: t.fontSize(mobile ? 14 : 11),
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.packDesc,
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 12 : 9)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _PackActionCard(
                  icon: Icons.file_upload_outlined,
                  label: l.packExportLabel,
                  description: l.packExportDesc,
                  color: t.accent,
                  onTap: () => _showExportDialog(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PackActionCard(
                  icon: Icons.file_download_outlined,
                  label: l.packImportLabel,
                  description: l.packImportDesc,
                  color: t.accentSuccess,
                  onTap: () => _importPack(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: t.borderSubtle),
          const SizedBox(height: 16),
          Text(
            l.packGalleryExport,
            style: TextStyle(
              color: t.textSecondary,
              fontSize: t.fontSize(mobile ? 14 : 11),
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.packGalleryExportDesc,
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 12 : 9)),
          ),
          const SizedBox(height: 16),
          _PackActionCard(
            icon: Icons.photo_library_outlined,
            label: l.packExportGalleryZip,
            description: l.packExportGalleryZipDesc,
            color: t.accentEdit,
            onTap: () => _showGalleryExportDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final gen = context.read<GenerationNotifier>();
    final wildcard = context.read<WildcardNotifier>();

    // Load current data
    final presets = await PresetStorage.loadPresets(gen.presetsFilePath);
    final styles = await StyleStorage.loadStyles(gen.stylesFilePath);

    // Load wildcard files
    final wcDir = Directory(wildcard.wildcardDir);
    final wcFiles = <File>[];
    if (await wcDir.exists()) {
      await for (final entity in wcDir.list()) {
        if (entity is File && p.extension(entity.path).toLowerCase() == '.txt') {
          wcFiles.add(entity);
        }
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _ExportDialog(
        presets: presets,
        styles: styles,
        wildcardFiles: wcFiles,
      ),
    );
  }

  void _showGalleryExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _GalleryExportDialog(),
    );
  }

  Future<void> _importPack(BuildContext context) async {
    final t = context.tRead;
    final l = context.l;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['vpack'],
      dialogTitle: l.packImportDialogTitle,
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    PackContents contents;
    try {
      contents = PackService.importPack(bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l.packFailedRead(e.toString()), style: TextStyle(color: t.accentDanger)),
          backgroundColor: t.surfaceHigh,
        ));
      }
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _ImportDialog(contents: contents),
    );
  }
}

class _PackActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _PackActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(mobile ? 20 : 16),
        decoration: BoxDecoration(
          color: t.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: mobile ? 28 : 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: t.fontSize(mobile ? 12 : 10),
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 10 : 8)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Export Dialog ───────────────────────────────────────────

class _ExportDialog extends StatefulWidget {
  final List<GenerationPreset> presets;
  final List<PromptStyle> styles;
  final List<File> wildcardFiles;

  const _ExportDialog({
    required this.presets,
    required this.styles,
    required this.wildcardFiles,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  final _nameController = TextEditingController(text: 'My Pack');
  final _descController = TextEditingController();
  late Set<int> _selectedPresets;
  late Set<int> _selectedStyles;
  late Set<int> _selectedWildcards;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _selectedPresets = Set.from(List.generate(widget.presets.length, (i) => i));
    _selectedStyles = Set.from(List.generate(widget.styles.length, (i) => i));
    _selectedWildcards = Set.from(List.generate(widget.wildcardFiles.length, (i) => i));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(l.packExportDialogTitle, style: TextStyle(fontSize: t.fontSize(mobile ? 14 : 10), letterSpacing: 2, color: t.textSecondary, fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: mobile ? double.maxFinite : 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(mobile ? 14 : 12)),
                decoration: InputDecoration(
                  labelText: l.packName,
                  labelStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 1),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 13 : 11)),
                decoration: InputDecoration(
                  labelText: l.packDescriptionOptional,
                  labelStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 1),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.presets.isNotEmpty) ...[
                _sectionHeader(l.packPresetsSection(_selectedPresets.length, widget.presets.length), t),
                for (int i = 0; i < widget.presets.length; i++)
                  _checkTile(widget.presets[i].name, _selectedPresets.contains(i), (v) {
                    setState(() => v! ? _selectedPresets.add(i) : _selectedPresets.remove(i));
                  }, t, mobile),
                const SizedBox(height: 12),
              ],
              if (widget.styles.isNotEmpty) ...[
                _sectionHeader(l.packStylesSection(_selectedStyles.length, widget.styles.length), t),
                for (int i = 0; i < widget.styles.length; i++)
                  _checkTile(widget.styles[i].name, _selectedStyles.contains(i), (v) {
                    setState(() => v! ? _selectedStyles.add(i) : _selectedStyles.remove(i));
                  }, t, mobile),
                const SizedBox(height: 12),
              ],
              if (widget.wildcardFiles.isNotEmpty) ...[
                _sectionHeader(l.packWildcardsSection(_selectedWildcards.length, widget.wildcardFiles.length), t),
                for (int i = 0; i < widget.wildcardFiles.length; i++)
                  _checkTile(p.basenameWithoutExtension(widget.wildcardFiles[i].path), _selectedWildcards.contains(i), (v) {
                    setState(() => v! ? _selectedWildcards.add(i) : _selectedWildcards.remove(i));
                  }, t, mobile),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
        ),
        TextButton(
          onPressed: _exporting ? null : _export,
          child: _exporting
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: t.accent))
              : Text(l.commonExport, style: TextStyle(color: t.accent, fontSize: t.fontSize(9), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text, dynamic t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 2, fontWeight: FontWeight.bold)),
    );
  }

  Widget _checkTile(String name, bool checked, ValueChanged<bool?> onChanged, dynamic t, bool mobile) {
    return SizedBox(
      height: mobile ? 36 : 28,
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: checked,
        onChanged: onChanged,
        activeColor: t.accent,
        title: Text(name, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 12 : 10))),
      ),
    );
  }

  Future<void> _export() async {
    if (_nameController.text.trim().isEmpty) return;

    final saveDialogTitle = context.l.packSaveDialogTitle;

    setState(() => _exporting = true);

    try {
      final selectedPresets = _selectedPresets.map((i) => widget.presets[i]).toList();
      final selectedStyles = _selectedStyles.map((i) => widget.styles[i]).toList();

      final wildcards = <String, String>{};
      for (final i in _selectedWildcards) {
        final file = widget.wildcardFiles[i];
        wildcards[p.basename(file.path)] = await file.readAsString();
      }

      final packBytes = PackService.exportPack(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        presets: selectedPresets,
        styles: selectedStyles,
        wildcards: wildcards,
      );

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: saveDialogTitle,
        fileName: '${_nameController.text.trim()}.vpack',
      );

      if (savePath != null) {
        await File(savePath).writeAsBytes(packBytes);
        if (mounted) {
          Navigator.pop(context);
          final t = context.tRead;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l.packExportSuccess, style: TextStyle(color: t.accentSuccess)),
            backgroundColor: t.surfaceHigh,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        final t = context.tRead;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l.packExportFailed(e.toString()), style: TextStyle(color: t.accentDanger)),
          backgroundColor: t.surfaceHigh,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

// ─── Import Dialog ───────────────────────────────────────────

class _ImportDialog extends StatefulWidget {
  final PackContents contents;

  const _ImportDialog({required this.contents});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  late Set<int> _selectedPresets;
  late Set<int> _selectedStyles;
  late Set<String> _selectedWildcards;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _selectedPresets = Set.from(List.generate(widget.contents.presets.length, (i) => i));
    _selectedStyles = Set.from(List.generate(widget.contents.styles.length, (i) => i));
    _selectedWildcards = Set.from(widget.contents.wildcards.keys);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);
    final m = widget.contents.manifest;
    final total = _selectedPresets.length + _selectedStyles.length + _selectedWildcards.length;

    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(l.packImportDialogTitle2, style: TextStyle(fontSize: t.fontSize(mobile ? 14 : 10), letterSpacing: 2, color: t.textSecondary, fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: mobile ? double.maxFinite : 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name, style: TextStyle(color: t.accent, fontSize: t.fontSize(mobile ? 16 : 13), fontWeight: FontWeight.bold)),
              if (m.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(m.description, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 12 : 10))),
                ),
              const SizedBox(height: 16),
              if (widget.contents.presets.isNotEmpty) ...[
                _sectionHeader(l.packPresetsSection(_selectedPresets.length, widget.contents.presets.length), t),
                for (int i = 0; i < widget.contents.presets.length; i++)
                  _checkTile(widget.contents.presets[i].name, _selectedPresets.contains(i), (v) {
                    setState(() => v! ? _selectedPresets.add(i) : _selectedPresets.remove(i));
                  }, t, mobile),
                const SizedBox(height: 12),
              ],
              if (widget.contents.styles.isNotEmpty) ...[
                _sectionHeader(l.packStylesSection(_selectedStyles.length, widget.contents.styles.length), t),
                for (int i = 0; i < widget.contents.styles.length; i++)
                  _checkTile(widget.contents.styles[i].name, _selectedStyles.contains(i), (v) {
                    setState(() => v! ? _selectedStyles.add(i) : _selectedStyles.remove(i));
                  }, t, mobile),
                const SizedBox(height: 12),
              ],
              if (widget.contents.wildcards.isNotEmpty) ...[
                _sectionHeader(l.packWildcardsSection(_selectedWildcards.length, widget.contents.wildcards.length), t),
                for (final key in widget.contents.wildcards.keys)
                  _checkTile(p.basenameWithoutExtension(key), _selectedWildcards.contains(key), (v) {
                    setState(() => v! ? _selectedWildcards.add(key) : _selectedWildcards.remove(key));
                  }, t, mobile),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
        ),
        TextButton(
          onPressed: _importing || total == 0 ? null : _import,
          child: _importing
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: t.accentSuccess))
              : Text(l.packImportCount(total), style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(9), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text, dynamic t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 2, fontWeight: FontWeight.bold)),
    );
  }

  Widget _checkTile(String name, bool checked, ValueChanged<bool?> onChanged, dynamic t, bool mobile) {
    return SizedBox(
      height: mobile ? 36 : 28,
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: checked,
        onChanged: onChanged,
        activeColor: t.accent,
        title: Text(name, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 12 : 10))),
      ),
    );
  }

  Future<void> _import() async {
    setState(() => _importing = true);

    try {
      final gen = context.read<GenerationNotifier>();
      final wildcard = context.read<WildcardNotifier>();

      // Import presets
      if (_selectedPresets.isNotEmpty) {
        final existing = await PresetStorage.loadPresets(gen.presetsFilePath);
        final existingNames = existing.map((p) => p.name).toSet();
        for (final i in _selectedPresets) {
          var preset = widget.contents.presets[i];
          // Rename duplicates
          var name = preset.name;
          while (existingNames.contains(name)) {
            name = '$name (imported)';
          }
          if (name != preset.name) {
            preset = GenerationPreset(
              name: name,
              prompt: preset.prompt,
              negativePrompt: preset.negativePrompt,
              width: preset.width,
              height: preset.height,
              scale: preset.scale,
              steps: preset.steps,
              sampler: preset.sampler,
              smea: preset.smea,
              smeaDyn: preset.smeaDyn,
              decrisper: preset.decrisper,
              characters: preset.characters,
              interactions: preset.interactions,
              directorReferences: preset.directorReferences,
            );
          }
          existing.add(preset);
          existingNames.add(name);
        }
        await PresetStorage.savePresets(gen.presetsFilePath, existing);
      }

      // Import styles
      if (_selectedStyles.isNotEmpty) {
        final existing = await StyleStorage.loadStyles(gen.stylesFilePath);
        final existingNames = existing.map((s) => s.name).toSet();
        for (final i in _selectedStyles) {
          var style = widget.contents.styles[i];
          var name = style.name;
          while (existingNames.contains(name)) {
            name = '$name (imported)';
          }
          if (name != style.name) {
            style = PromptStyle(
              name: name,
              prefix: style.prefix,
              suffix: style.suffix,
              negativeContent: style.negativeContent,
              isDefault: false,
            );
          }
          existing.add(style);
          existingNames.add(name);
        }
        await StyleStorage.saveStyles(gen.stylesFilePath, existing);
      }

      // Import wildcards
      if (_selectedWildcards.isNotEmpty) {
        for (final key in _selectedWildcards) {
          final content = widget.contents.wildcards[key]!;
          var filename = key;
          var targetPath = p.join(wildcard.wildcardDir, filename);
          // Rename if exists
          while (await File(targetPath).exists()) {
            final base = p.basenameWithoutExtension(filename);
            filename = '${base}_imported.txt';
            targetPath = p.join(wildcard.wildcardDir, filename);
          }
          await File(targetPath).writeAsString(content);
        }
        wildcard.refreshFiles();
      }

      // Refresh generation notifier to pick up new presets/styles
      gen.reloadPresetsAndStyles();

      if (mounted) {
        Navigator.pop(context);
        final t = context.tRead;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l.packImportSuccess, style: TextStyle(color: t.accentSuccess)),
          backgroundColor: t.surfaceHigh,
        ));
      }
    } catch (e) {
      if (mounted) {
        final t = context.tRead;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l.packImportFailed(e.toString()), style: TextStyle(color: t.accentDanger)),
          backgroundColor: t.surfaceHigh,
        ));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}

// ─── Gallery Export Dialog ──────────────────────────────────

class _GalleryExportDialog extends StatefulWidget {
  const _GalleryExportDialog();

  @override
  State<_GalleryExportDialog> createState() => _GalleryExportDialogState();
}

class _GalleryExportDialogState extends State<_GalleryExportDialog> {
  late Set<String> _selectedAlbumIds;
  bool _includeUnsorted = true;
  bool _stripMetadata = false;
  bool _favoritesOnly = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final gallery = context.read<GalleryNotifier>();
    _selectedAlbumIds = gallery.albums.map((a) => a.id).toSet();
    _stripMetadata = context.read<PreferencesService>().stripMetadataOnExport;
  }

  int _countImages(GalleryNotifier gallery) {
    var items = gallery.items;
    if (_favoritesOnly) {
      items = items.where((i) => i.isFavorite).toList();
    }

    final counted = <String>{};

    // Count album images
    for (final album in gallery.albums) {
      if (!_selectedAlbumIds.contains(album.id)) continue;
      for (final item in items) {
        if (album.imageBasenames.contains(item.basename)) {
          counted.add(item.basename);
        }
      }
    }

    // Count unsorted
    if (_includeUnsorted) {
      final allAlbumBasenames = <String>{};
      for (final album in gallery.albums) {
        allAlbumBasenames.addAll(album.imageBasenames);
      }
      for (final item in items) {
        if (!allAlbumBasenames.contains(item.basename)) {
          counted.add(item.basename);
        }
      }
    }

    return counted.length;
  }

  int _albumImageCount(GalleryNotifier gallery, String albumId) {
    final album = gallery.albums.where((a) => a.id == albumId).firstOrNull;
    if (album == null) return 0;
    var items = gallery.items;
    if (_favoritesOnly) {
      items = items.where((i) => i.isFavorite).toList();
    }
    return items.where((i) => album.imageBasenames.contains(i.basename)).length;
  }

  int _unsortedCount(GalleryNotifier gallery) {
    final allAlbumBasenames = <String>{};
    for (final album in gallery.albums) {
      allAlbumBasenames.addAll(album.imageBasenames);
    }
    var items = gallery.items;
    if (_favoritesOnly) {
      items = items.where((i) => i.isFavorite).toList();
    }
    return items.where((i) => !allAlbumBasenames.contains(i.basename)).length;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);
    final gallery = context.watch<GalleryNotifier>();
    final totalCount = _countImages(gallery);

    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(l.packExportGalleryTitle, style: TextStyle(fontSize: t.fontSize(mobile ? 14 : 10), letterSpacing: 2, color: t.textSecondary, fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: mobile ? double.maxFinite : 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Albums
              if (gallery.albums.isNotEmpty) ...[
                _sectionHeader(l.packAlbums, t),
                for (final album in gallery.albums)
                  _checkTile(
                    '${album.name} (${_albumImageCount(gallery, album.id)})',
                    _selectedAlbumIds.contains(album.id),
                    (v) => setState(() => v! ? _selectedAlbumIds.add(album.id) : _selectedAlbumIds.remove(album.id)),
                    t,
                    mobile,
                  ),
                const SizedBox(height: 12),
              ],

              // Unsorted
              _checkTile(
                l.packUnsortedCount(_unsortedCount(gallery)),
                _includeUnsorted,
                (v) => setState(() => _includeUnsorted = v!),
                t,
                mobile,
              ),
              const SizedBox(height: 16),

              // Toggles
              _sectionHeader(l.packOptions, t),
              _checkTile(
                l.packStripMetadata,
                _stripMetadata,
                (v) => setState(() => _stripMetadata = v!),
                t,
                mobile,
              ),
              _checkTile(
                l.packFavoritesOnly,
                _favoritesOnly,
                (v) => setState(() => _favoritesOnly = v!),
                t,
                mobile,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
        ),
        TextButton(
          onPressed: _exporting || totalCount == 0 ? null : _export,
          child: _exporting
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: t.accentEdit))
              : Text(l.packExportCount(totalCount), style: TextStyle(color: t.accentEdit, fontSize: t.fontSize(9), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text, dynamic t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 2, fontWeight: FontWeight.bold)),
    );
  }

  Widget _checkTile(String name, bool checked, ValueChanged<bool?> onChanged, dynamic t, bool mobile) {
    return SizedBox(
      height: mobile ? 36 : 28,
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: checked,
        onChanged: onChanged,
        activeColor: t.accent,
        title: Text(name, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 12 : 10))),
      ),
    );
  }

  Future<void> _export() async {
    final exportDialogTitle = context.l.packExportGalleryZipDialog;

    setState(() => _exporting = true);

    try {
      final gallery = context.read<GalleryNotifier>();

      final zipBytes = await PackService.exportGalleryZip(
        albums: gallery.albums,
        allItems: gallery.items,
        selectedAlbumIds: _selectedAlbumIds,
        includeUnsorted: _includeUnsorted,
        stripMeta: _stripMetadata,
        favoritesOnly: _favoritesOnly,
      );

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: exportDialogTitle,
        fileName: 'gallery_export.zip',
      );

      if (savePath != null) {
        await File(savePath).writeAsBytes(zipBytes);
        if (mounted) {
          Navigator.pop(context);
          final t = context.tRead;
          final count = _countImages(gallery);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l.packExportedToZip(count), style: TextStyle(color: t.accentSuccess)),
            backgroundColor: t.surfaceHigh,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        final t = context.tRead;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l.packExportFailed(e.toString()), style: TextStyle(color: t.accentDanger)),
          backgroundColor: t.surfaceHigh,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
