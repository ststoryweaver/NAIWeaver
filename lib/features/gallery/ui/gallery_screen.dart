import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/responsive.dart';
import '../providers/gallery_notifier.dart';
import '../../generation/providers/generation_notifier.dart';
import '../../director_ref/providers/director_ref_notifier.dart';
import '../../vibe_transfer/providers/vibe_transfer_notifier.dart';
import '../../tools/img2img/providers/img2img_notifier.dart';
import '../../tools/slideshow/models/slideshow_config.dart';
import '../../tools/slideshow/providers/slideshow_notifier.dart';
import '../../tools/slideshow/widgets/slideshow_player.dart';
import '../../tools/tools_hub_screen.dart';
import '../../../core/ml/ml_notifier.dart';
import '../../../core/ml/widgets/ml_processing_overlay.dart';
import '../../../core/ml/widgets/bg_removal_overlay.dart';
import '../../tools/canvas/providers/canvas_notifier.dart';
import '../../tools/canvas/widgets/canvas_editor.dart';
import '../../tools/ml/widgets/segmentation_overlay.dart';
import '../../../core/ml/widgets/upscale_comparison_view.dart';
import 'comparison_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridKey = GlobalKey();
  bool _isSearching = false;
  int? _crossAxisCount;

  // Selection mode
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  // Drag-to-select state (mobile long-press-then-drag)
  final Set<int> _dragSelectedIndices = {};
  bool _isDragging = false;

  // Desktop rectangle drag state
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _isRectDragging = false;

  // Info overlay (hover/long-press)
  int? _hoveredIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _crossAxisCount ??= context.read<PreferencesService>().galleryGridColumns ?? (isMobile(context) ? 2 : 3);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
      _dragSelectedIndices.clear();
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll(List<GalleryItem> items) {
    setState(() {
      if (_selectedIndices.length == items.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(List.generate(items.length, (i) => i));
      }
    });
  }

  // Compute grid cell index from local position relative to grid
  int? _cellIndexFromOffset(Offset localPosition, int itemCount) {
    final cols = _crossAxisCount!;
    const padding = 8.0;
    const spacing = 8.0;

    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final gridWidth = renderBox.size.width;
    final cellSize = (gridWidth - padding * 2 - spacing * (cols - 1)) / cols;
    if (cellSize <= 0) return null;

    final x = localPosition.dx;
    final y = localPosition.dy + _scrollController.offset;

    final col = ((x - padding) / (cellSize + spacing)).floor().clamp(0, cols - 1);
    final row = ((y - padding) / (cellSize + spacing)).floor();
    if (row < 0) return null;

    final index = row * cols + col;
    if (index < 0 || index >= itemCount) return null;
    return index;
  }

  // Desktop rectangle selection: compute all indices within rectangle
  Set<int> _indicesInRect(Offset start, Offset end, int itemCount) {
    final cols = _crossAxisCount!;
    const padding = 8.0;
    const spacing = 8.0;

    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return {};

    final gridWidth = renderBox.size.width;
    final cellSize = (gridWidth - padding * 2 - spacing * (cols - 1)) / cols;
    if (cellSize <= 0) return {};

    final scrollOff = _scrollController.offset;

    final left = min(start.dx, end.dx);
    final right = max(start.dx, end.dx);
    final top = min(start.dy, end.dy) + scrollOff;
    final bottom = max(start.dy, end.dy) + scrollOff;

    final result = <int>{};
    for (int i = 0; i < itemCount; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final cellLeft = padding + col * (cellSize + spacing);
      final cellTop = padding + row * (cellSize + spacing);
      final cellRight = cellLeft + cellSize;
      final cellBottom = cellTop + cellSize;

      // Check overlap
      if (cellRight > left && cellLeft < right && cellBottom > top && cellTop < bottom) {
        result.add(i);
      }
    }
    return result;
  }

  Future<Uint8List> _maybeStripMetadata(Uint8List bytes) async {
    final prefs = context.read<PreferencesService>();
    if (prefs.stripMetadataOnExport) {
      return stripMetadata(bytes);
    }
    return bytes;
  }

  Future<void> _bulkExport(List<GalleryItem> selectedItems) async {
    final t = context.tRead;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) await Gal.requestAccess();
        int saved = 0;
        for (final item in selectedItems) {
          var bytes = await item.file.readAsBytes();
          bytes = await _maybeStripMetadata(bytes);
          final name = p.basenameWithoutExtension(item.file.path);
          await Gal.putImageBytes(bytes, name: name);
          saved++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l.gallerySavedToDeviceCount(saved, selectedItems.length),
                style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
            backgroundColor: const Color(0xFF0A1A0A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
            ),
          ));
        }
      } else {
        final dirPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: context.l.galleryExportDialogTitle(selectedItems.length),
        );
        if (dirPath == null) return;

        int copied = 0;
        for (final item in selectedItems) {
          final dest = p.join(dirPath, item.basename);
          var bytes = await item.file.readAsBytes();
          bytes = await _maybeStripMetadata(bytes);
          await File(dest).writeAsBytes(bytes);
          copied++;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l.galleryExportedToFolder(copied, p.basename(dirPath)),
                style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
            backgroundColor: const Color(0xFF0A1A0A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
            ),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l.galleryExportFailed(e.toString()),
              style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
          backgroundColor: const Color(0xFF1A0A0A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: t.accentDanger.withValues(alpha: 0.3)),
          ),
        ));
      }
    }
    _exitSelectionMode();
  }

  Future<void> _bulkDelete(List<GalleryItem> selectedItems) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final t = context.tRead;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(
            context.l.galleryDeleteCount(selectedItems.length).toUpperCase(),
            style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary),
          ),
          content: Text(
            context.l.galleryCannotUndo,
            style: TextStyle(color: t.textDisabled, fontSize: isMobile(context) ? t.fontSize(12) : t.fontSize(10)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l.commonDelete.toUpperCase(), style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9))),
            ),
          ],
        );
      },
    );
    if (!mounted || confirm != true) return;
    await Provider.of<GalleryNotifier>(context, listen: false).deleteItems(selectedItems);
    if (!mounted) return;
    _exitSelectionMode();
  }

  void _bulkFavorite(List<GalleryItem> selectedItems) {
    Provider.of<GalleryNotifier>(context, listen: false).addToFavorites(selectedItems);
    _exitSelectionMode();
  }

  Future<void> _openSegmentation(GalleryItem item) async {
    _exitSelectionMode();
    final gallery = context.read<GalleryNotifier>();
    final imageBytes = await item.file.readAsBytes();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ChangeNotifierProvider.value(
          value: context.read<MLNotifier>(),
          child: Scaffold(
            backgroundColor: ctx.tRead.background,
            body: SafeArea(
              child: SegmentationOverlay(
                sourceImage: imageBytes,
                onSave: (resultBytes) async {
                  final baseName = p.basenameWithoutExtension(item.file.path);
                  final ts = DateTime.now().millisecondsSinceEpoch;
                  await gallery.saveMLResult(resultBytes, 'SEG_${baseName}_$ts.png');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                onDiscard: () => Navigator.pop(ctx),
                onSendToCanvas: (resultBytes) {
                  Navigator.pop(ctx);
                  final canvasNotifier = context.read<CanvasNotifier>();
                  canvasNotifier.addImageLayer(resultBytes, name: 'Segmented');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openInCanvas(GalleryItem item) async {
    _exitSelectionMode();
    final img2imgNotifier = context.read<Img2ImgNotifier>();
    final imageBytes = await item.file.readAsBytes();
    if (!mounted) return;

    // Load into img2img which decodes dimensions in isolate
    await img2imgNotifier.loadSourceImage(imageBytes, filePath: item.file.path);
    final session = img2imgNotifier.session;
    if (session == null || !mounted) return;

    // Start canvas from the loaded session
    final canvasNotifier = context.read<CanvasNotifier>();
    canvasNotifier.startSession(
      session.sourceImageBytes,
      session.sourceWidth,
      session.sourceHeight,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CanvasEditor()),
    );
  }

  Future<void> _bulkRemoveBg(List<GalleryItem> selectedItems) async {
    final ml = context.read<MLNotifier>();
    final gallery = context.read<GalleryNotifier>();
    final t = context.tRead;
    final total = selectedItems.length;
    int completed = 0;

    StateSetter? dialogSetState;
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            dialogSetState = setState;
            final t = ctx.tRead;
            return AlertDialog(
              backgroundColor: t.surfaceHigh,
              title: Text('REMOVING BACKGROUNDS', style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: t.borderSubtle,
                    color: t.accent,
                  ),
                  const SizedBox(height: 12),
                  Text('$completed/$total', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10))),
                ],
              ),
            );
          },
        ),
      );
    }

    for (final item in selectedItems) {
      final bytes = await item.file.readAsBytes();
      final result = await ml.removeBackground(bytes);
      if (result != null) {
        final baseName = p.basenameWithoutExtension(item.file.path);
        final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-T]'), '').substring(8, 14);
        await gallery.saveMLResult(result, 'BG_${baseName}_$timestamp.png');
      }
      completed++;
      dialogSetState?.call(() {});
    }

    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('BG REMOVED: $completed/$total IMAGES',
            style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(11))),
        backgroundColor: const Color(0xFF0A1A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
        ),
      ));
    }
    _exitSelectionMode();
  }

  Future<void> _bulkUpscale(List<GalleryItem> selectedItems) async {
    final ml = context.read<MLNotifier>();
    final gallery = context.read<GalleryNotifier>();
    final t = context.tRead;
    final total = selectedItems.length;
    int completed = 0;

    StateSetter? dialogSetState;
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            dialogSetState = setState;
            final t = ctx.tRead;
            return AlertDialog(
              backgroundColor: t.surfaceHigh,
              title: Text('UPSCALING IMAGES', style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    backgroundColor: t.borderSubtle,
                    color: t.accent,
                  ),
                  const SizedBox(height: 12),
                  Text('$completed/$total', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10))),
                ],
              ),
            );
          },
        ),
      );
    }

    for (final item in selectedItems) {
      final bytes = await item.file.readAsBytes();
      final result = await ml.upscaleImage(bytes);
      if (result != null) {
        final baseName = p.basenameWithoutExtension(item.file.path);
        final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-T]'), '').substring(8, 14);
        await gallery.saveMLResult(result, 'UP_${baseName}_$timestamp.png');
      }
      completed++;
      dialogSetState?.call(() {});
    }

    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('UPSCALED: $completed/$total IMAGES',
            style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(11))),
        backgroundColor: const Color(0xFF0A1A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
        ),
      ));
    }
    _exitSelectionMode();
  }

  Future<void> _importImages() async {
    final t = context.tRead;
    final gallery = context.read<GalleryNotifier>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final filePaths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
    if (filePaths.isEmpty) return;

    final showProgress = filePaths.length >= 3;
    int currentProgress = 0;
    int totalProgress = filePaths.length;
    StateSetter? dialogSetState;

    if (showProgress && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            dialogSetState = setState;
            final t = ctx.tRead;
            return AlertDialog(
              backgroundColor: t.surfaceHigh,
              title: Text(
                context.l.galleryImporting.toUpperCase(),
                style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: totalProgress > 0 ? currentProgress / totalProgress : 0,
                    backgroundColor: t.borderSubtle,
                    color: t.accent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentProgress > 0
                        ? context.l.galleryImportProgress(currentProgress, totalProgress)
                        : context.l.galleryImportPreparing,
                    style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10)),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    try {
      final importResult = await gallery.importFiles(
        filePaths,
        onProgress: (current, total) {
          currentProgress = current;
          totalProgress = total;
          dialogSetState?.call(() {});
        },
      );

      if (showProgress && mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      String message;
      if (importResult.converted > 0) {
        message = context.l.galleryImportConverted(importResult.succeeded, importResult.converted);
      } else {
        message = context.l.galleryImportSuccess(importResult.succeeded, importResult.withMetadata);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message,
            style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
        backgroundColor: const Color(0xFF0A1A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
        ),
      ));
    } catch (e) {
      if (showProgress && mounted) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l.galleryImportFailed(e.toString()),
            style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
        backgroundColor: const Color(0xFF1A0A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentDanger.withValues(alpha: 0.3)),
        ),
      ));
    }
  }

  String _sortModeLabel(BuildContext context, GallerySortMode mode) {
    switch (mode) {
      case GallerySortMode.dateDesc: return context.l.gallerySortDateNewest.toUpperCase();
      case GallerySortMode.dateAsc: return context.l.gallerySortDateOldest.toUpperCase();
      case GallerySortMode.nameAsc: return context.l.gallerySortNameAZ.toUpperCase();
      case GallerySortMode.nameDesc: return context.l.gallerySortNameZA.toUpperCase();
      case GallerySortMode.sizeDesc: return context.l.gallerySortSizeLargest.toUpperCase();
      case GallerySortMode.sizeAsc: return context.l.gallerySortSizeSmallest.toUpperCase();
    }
  }

  Widget _buildAlbumStrip(GalleryNotifier gallery, bool mobile) {
    final t = context.t;
    if (gallery.albums.isEmpty && !_isSelectionMode && !gallery.hasClipboard) return const SizedBox.shrink();

    return Container(
      height: mobile ? 42 : 34,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          _AlbumChip(
            label: context.l.galleryAll.toUpperCase(),
            count: gallery.items.length,
            isActive: gallery.activeAlbumId == null,
            mobile: mobile,
            onTap: () => gallery.setActiveAlbum(null),
          ),
          for (final album in gallery.albums)
            _AlbumChip(
              label: album.name,
              count: gallery.albumItemCount(album.id),
              isActive: gallery.activeAlbumId == album.id,
              mobile: mobile,
              onTap: () => gallery.setActiveAlbum(album.id),
              onLongPress: () => _showAlbumOptionsDialog(gallery, album.id, album.name),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCreateAlbumDialog(gallery),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.borderMedium),
                ),
                child: Icon(Icons.add, size: mobile ? 16 : 12, color: t.textDisabled),
              ),
            ),
          ),
          if (gallery.hasClipboard)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _showClipboardMenu(gallery),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: t.accentSuccess.withValues(alpha: 0.15),
                    border: Border.all(color: t.accentSuccess.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      context.l.galleryCopiedCount(gallery.clipboard.length).toUpperCase(),
                      style: TextStyle(
                        color: t.accentSuccess,
                        fontSize: t.fontSize(mobile ? 9 : 7),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showClipboardMenu(GalleryNotifier gallery) {
    final t = context.tRead;
    final mobile = isMobile(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.surfaceHigh,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.l.galleryImagesCopiedCount(gallery.clipboard.length).toUpperCase(),
                style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 12 : 10), letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ),
            for (final album in gallery.albums)
              ListTile(
                leading: Icon(Icons.paste, size: 18, color: t.accentSuccess),
                title: Text(
                  context.l.galleryPasteInto(album.name).toUpperCase(),
                  style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 13 : 11)),
                ),
                onTap: () {
                  final pasteCount = gallery.clipboard.length;
                  gallery.pasteToAlbum(album.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(context.l.galleryPastedIntoAlbum(pasteCount, album.name),
                        style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(11))),
                    backgroundColor: const Color(0xFF0A1A0A),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
                    ),
                  ));
                },
              ),
            ListTile(
              leading: Icon(Icons.clear, size: 18, color: t.accentDanger),
              title: Text(context.l.galleryClearClipboard.toUpperCase(), style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(mobile ? 13 : 11))),
              onTap: () {
                gallery.clearClipboard();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAlbumDialog(GalleryNotifier gallery) {
    final controller = TextEditingController();
    final t = context.tRead;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(context.l.galleryNewAlbum.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
          decoration: InputDecoration(
            hintText: context.l.galleryAlbumName.toUpperCase(),
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                gallery.createAlbum(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(ctx.l.commonCreate.toUpperCase(), style: TextStyle(color: t.accent, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );
  }

  void _showAlbumOptionsDialog(GalleryNotifier gallery, String albumId, String currentName) {
    final t = context.tRead;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.surfaceHigh,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, size: 18, color: t.textSecondary),
              title: Text(context.l.commonRename.toUpperCase(), style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(11), letterSpacing: 1)),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameAlbumDialog(gallery, albumId, currentName);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, size: 18, color: t.accentDanger),
              title: Text(context.l.commonDelete.toUpperCase(), style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(11), letterSpacing: 1)),
              onTap: () {
                Navigator.pop(ctx);
                gallery.deleteAlbum(albumId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameAlbumDialog(GalleryNotifier gallery, String albumId, String currentName) {
    final controller = TextEditingController(text: currentName);
    final t = context.tRead;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(context.l.galleryRenameAlbum.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                gallery.renameAlbum(albumId, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text(ctx.l.commonRename.toUpperCase(), style: TextStyle(color: t.accent, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );
  }

  void _showAddToAlbumDialog(List<GalleryItem> selectedItems) {
    final gallery = context.read<GalleryNotifier>();
    final t = context.tRead;
    final mobile = isMobile(context);

    if (gallery.albums.isEmpty) {
      // Offer to create one
      _showCreateAlbumDialog(gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: t.surfaceHigh,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.l.galleryAddToAlbum.toUpperCase(),
                style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 12 : 10), letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ),
            for (final album in gallery.albums)
              ListTile(
                leading: Icon(Icons.photo_album, size: 18, color: t.textDisabled),
                title: Text(
                  album.name,
                  style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 13 : 11)),
                ),
                trailing: Text(
                  '${gallery.albumItemCount(album.id)}',
                  style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 11 : 9)),
                ),
                onTap: () {
                  gallery.addToAlbum(album.id, selectedItems);
                  Navigator.pop(ctx);
                  _exitSelectionMode();
                },
              ),
            ListTile(
              leading: Icon(Icons.add, size: 18, color: t.accent),
              title: Text(context.l.galleryNewAlbum.toUpperCase(), style: TextStyle(color: t.accent, fontSize: t.fontSize(mobile ? 13 : 11))),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateAlbumDialog(gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final gallery = context.watch<GalleryNotifier>();
    final mobile = isMobile(context);
    final maxCols = mobile ? 3 : 5;
    final minCols = mobile ? 2 : 3;
    final activeItems = gallery.activeItems;

    return Scaffold(
      backgroundColor: t.background,
      appBar: _buildAppBar(gallery, activeItems, mobile, maxCols, minCols),
      body: Column(
        children: [
          // Album strip
          _buildAlbumStrip(gallery, mobile),
          // Grid content
          Expanded(
            child: gallery.isLoading
                ? Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: t.textMinimal))
                : activeItems.isEmpty
                    ? Center(
                        child: Text(
                          gallery.demoMode
                              ? context.l.galleryNoDemoImages.toUpperCase()
                              : gallery.showFavoritesOnly
                                  ? context.l.galleryNoFavorites.toUpperCase()
                                  : gallery.activeAlbumId != null
                                      ? context.l.galleryNoImagesInAlbum.toUpperCase()
                                      : context.l.galleryNoImagesFound.toUpperCase(),
                          style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(10), letterSpacing: 2),
                        ))
                    : Stack(
                        children: [
                          _buildGrid(activeItems, mobile),
                          // Desktop drag rectangle overlay
                          if (_isRectDragging && _dragStart != null && _dragCurrent != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _DragRectPainter(
                                    start: _dragStart!,
                                    end: _dragCurrent!,
                                  ),
                                ),
                              ),
                            ),
                          // Bulk action bar
                          if (_isSelectionMode)
                            _buildBulkActionBar(activeItems),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      GalleryNotifier gallery, List<GalleryItem> items, bool mobile, int maxCols, int minCols) {
    final t = context.t;
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: t.background,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: mobile ? 56 : 40,
        leading: IconButton(
          icon: Icon(Icons.close, size: mobile ? 22 : 16, color: t.textSecondary),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          context.l.gallerySelectedCount(_selectedIndices.length).toUpperCase(),
          style: TextStyle(
            letterSpacing: 2,
            fontSize: mobile ? t.fontSize(14) : t.fontSize(10),
            fontWeight: FontWeight.w900,
            color: t.textSecondary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedIndices.length == items.length
                  ? Icons.deselect
                  : Icons.select_all,
              size: mobile ? 22 : 16,
              color: t.textDisabled,
            ),
            tooltip: _selectedIndices.length == items.length ? context.l.galleryDeselectAll : context.l.gallerySelectAll,
            onPressed: () => _selectAll(items),
          ),
        ],
      );
    }

    return AppBar(
      title: _isSearching
          ? (mobile
              ? null
              : TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: t.accent, fontSize: t.fontSize(12)),
                  decoration: InputDecoration(
                    hintText: context.l.gallerySearchTags.toUpperCase(),
                    hintStyle: TextStyle(
                        color: t.textDisabled, fontSize: t.fontSize(10), letterSpacing: 2),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => gallery.setSearchQuery(value),
                ))
          : (mobile
              ? null
              : Text((gallery.demoMode ? context.l.galleryDemoTitle : context.l.galleryTitle).toUpperCase(),
                  style: TextStyle(
                      letterSpacing: 4,
                      fontSize: t.fontSize(10),
                      fontWeight: FontWeight.w900,
                      color: t.textSecondary))),
      bottom: (mobile && _isSearching)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: t.accent, fontSize: t.fontSize(14)),
                  decoration: InputDecoration(
                    hintText: context.l.gallerySearchTags.toUpperCase(),
                    hintStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(12), letterSpacing: 2),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => gallery.setSearchQuery(value),
                ),
              ),
            )
          : null,
      backgroundColor: t.background,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: mobile ? 56 : 40,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, size: mobile ? 20 : 14, color: t.textDisabled),
        onPressed: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              gallery.setSearchQuery("");
            });
          } else {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add_photo_alternate, size: mobile ? 22 : 16, color: t.textDisabled),
          tooltip: context.l.galleryImport,
          onPressed: _importImages,
        ),
        IconButton(
          icon: Icon(
            gallery.showFavoritesOnly ? Icons.star : Icons.star_outline,
            size: mobile ? 22 : 16,
            color: gallery.showFavoritesOnly ? Colors.amber : t.textDisabled,
          ),
          tooltip: context.l.galleryFavoritesFilter,
          onPressed: () {
            gallery.showFavoritesOnly = !gallery.showFavoritesOnly;
          },
        ),
        PopupMenuButton<GallerySortMode>(
          icon: Icon(Icons.sort, size: mobile ? 20 : 16, color: t.textDisabled),
          tooltip: context.l.gallerySort,
          color: t.surfaceHigh,
          onSelected: (mode) => gallery.setSortMode(mode),
          itemBuilder: (context) => [
            for (final mode in GallerySortMode.values)
              PopupMenuItem(
                value: mode,
                child: Row(
                  children: [
                    if (gallery.sortMode == mode)
                      Icon(Icons.check, size: 14, color: t.accent)
                    else
                      const SizedBox(width: 14),
                    const SizedBox(width: 8),
                    Text(
                      _sortModeLabel(context, mode),
                      style: TextStyle(
                        color: gallery.sortMode == mode ? t.accent : t.textSecondary,
                        fontSize: t.fontSize(mobile ? 12 : 10),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.checklist, size: mobile ? 20 : 16, color: t.textDisabled),
          tooltip: context.l.gallerySelectMode,
          onPressed: () {
            setState(() {
              _isSelectionMode = true;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.grid_view, size: mobile ? 20 : 16, color: t.textDisabled),
          tooltip: context.l.galleryColumnsCount(_crossAxisCount!),
          onPressed: () {
            setState(() {
              _crossAxisCount = _crossAxisCount! >= maxCols ? minCols : _crossAxisCount! + 1;
            });
            context.read<PreferencesService>().setGalleryGridColumns(_crossAxisCount!);
          },
        ),
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search,
              size: mobile ? 20 : 16, color: t.textDisabled),
          onPressed: () {
            setState(() {
              if (_isSearching) {
                _searchController.clear();
                gallery.setSearchQuery("");
              }
              _isSearching = !_isSearching;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGrid(List<GalleryItem> items, bool mobile) {
    final grid = GridView.builder(
      key: _gridKey,
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount!,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGridItem(items, index, mobile),
    );

    if (mobile) {
      return GestureDetector(
        onLongPressStart: (details) {
          final idx = _cellIndexFromOffset(details.localPosition, items.length);
          if (idx != null) {
            setState(() {
              _isDragging = true;
              if (!_isSelectionMode) {
                _isSelectionMode = true;
                _selectedIndices.clear();
              }
              _dragSelectedIndices.clear();
              _dragSelectedIndices.add(idx);
              _selectedIndices.add(idx);
            });
          }
        },
        onLongPressMoveUpdate: (details) {
          if (!_isDragging) return;
          final idx = _cellIndexFromOffset(details.localPosition, items.length);
          if (idx != null && !_dragSelectedIndices.contains(idx)) {
            setState(() {
              _dragSelectedIndices.add(idx);
              _selectedIndices.add(idx);
            });
          }
        },
        onLongPressEnd: (_) {
          setState(() {
            _isDragging = false;
            _dragSelectedIndices.clear();
          });
        },
        child: grid,
      );
    }

    // Desktop: rectangle drag selection
    return GestureDetector(
      onPanStart: _isSelectionMode
          ? (details) {
              setState(() {
                _isRectDragging = true;
                _dragStart = details.localPosition;
                _dragCurrent = details.localPosition;
              });
            }
          : null,
      onPanUpdate: _isSelectionMode
          ? (details) {
              if (!_isRectDragging) return;
              setState(() {
                _dragCurrent = details.localPosition;
              });
              // Live selection feedback
              final indices = _indicesInRect(_dragStart!, _dragCurrent!, items.length);
              setState(() {
                _dragSelectedIndices
                  ..clear()
                  ..addAll(indices);
              });
            }
          : null,
      onPanEnd: _isSelectionMode
          ? (_) {
              setState(() {
                _selectedIndices.addAll(_dragSelectedIndices);
                _dragSelectedIndices.clear();
                _isRectDragging = false;
                _dragStart = null;
                _dragCurrent = null;
              });
            }
          : null,
      child: grid,
    );
  }

  Widget _buildGridItem(List<GalleryItem> items, int index, bool mobile) {
    final t = context.t;
    final item = items[index];
    final isSelected = _selectedIndices.contains(index) || _dragSelectedIndices.contains(index);
    final showInfo = _hoveredIndex == index && !_isSelectionMode;

    Widget tile = Container(
      decoration: BoxDecoration(
        color: t.borderSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? t.accent : t.borderSubtle,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(item.file, fit: BoxFit.cover),
          // Dim overlay when selected
          if (isSelected)
            Container(color: t.background.withValues(alpha: 0.3)),
          // Info overlay on hover / long-press
          if (showInfo)
            Positioned.fill(
              child: Container(
                color: t.background.withValues(alpha: 0.75),
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.prompt != null && item.prompt!.isNotEmpty)
                      Text(
                        item.prompt!.length > 60 ? '${item.prompt!.substring(0, 60)}...' : item.prompt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(mobile ? 10 : 8), fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      item.basename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(mobile ? 8 : 7)),
                    ),
                  ],
                ),
              ),
            ),
          // Favorite star badge (top-left)
          if (item.isFavorite)
            Positioned(
              top: 4,
              left: 4,
              child: Icon(Icons.star, size: mobile ? 18 : 14, color: Colors.amber),
            ),
          // Canvas layers badge (bottom-left)
          if (item.hasCanvasState)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: t.accentEdit.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.palette, size: mobile ? 16 : 13, color: Colors.white),
              ),
            ),
          // Selection checkmark (top-right)
          if (_isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: mobile ? 24 : 20,
                height: mobile ? 24 : 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? t.accent : t.background.withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected ? t.accent : t.accent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: mobile ? 14 : 12, color: t.background)
                    : null,
              ),
            ),
        ],
      ),
    );

    // Wrap with hover detection on desktop
    if (!mobile) {
      tile = MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: tile,
      );
    }

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(index);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageDetailView(initialIndex: index),
            ),
          );
        }
      },
      onLongPress: mobile
          ? null // Handled by parent GestureDetector for drag support
          : () {
              if (!_isSelectionMode) {
                _enterSelectionMode(index);
              }
            },
      child: tile,
    );
  }

  Widget _buildBulkActionBar(List<GalleryItem> items) {
    final t = context.t;
    final mobile = isMobile(context);
    final gallery = context.watch<GalleryNotifier>();
    final selectedItems =
        _selectedIndices.where((i) => i < items.length).map((i) => items[i]).toList();
    final count = _selectedIndices.length;

    return Positioned(
      left: 16,
      right: 16,
      bottom: mobile ? MediaQuery.of(context).padding.bottom + 16 : 16,
      child: AnimatedSlide(
        offset: count > 0 ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: count > 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 16 : 12,
              vertical: mobile ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.borderMedium),
              boxShadow: [
                BoxShadow(
                  color: t.background.withValues(alpha: 0.8),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Spacer(),
                if (count == 2)
                  _ActionButton(
                    icon: Icons.compare,
                    label: context.l.galleryCompare.toUpperCase(),
                    color: t.accent,
                    mobile: mobile,
                    iconOnly: mobile,
                    onTap: () {
                      final sorted = _selectedIndices.toList()..sort();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComparisonView(
                            itemA: items[sorted[0]],
                            itemB: items[sorted[1]],
                          ),
                        ),
                      );
                    },
                  ),
                if (count == 2)
                  SizedBox(width: mobile ? 12 : 8),
                _ActionButton(
                  icon: Icons.copy,
                  label: context.l.galleryCopy.toUpperCase(),
                  color: t.accent,
                  mobile: mobile,
                  iconOnly: mobile,
                  onTap: count > 0 ? () {
                    final gallery = context.read<GalleryNotifier>();
                    gallery.copyToClipboard(selectedItems);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l.galleryImagesCopied(selectedItems.length),
                          style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
                      backgroundColor: const Color(0xFF0A1A0A),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: t.accent.withValues(alpha: 0.3)),
                      ),
                    ));
                    _exitSelectionMode();
                  } : null,
                ),
                SizedBox(width: mobile ? 12 : 8),
                if (gallery.hasClipboard && gallery.activeAlbumId != null)
                  _ActionButton(
                    icon: Icons.paste,
                    label: context.l.galleryPaste.toUpperCase(),
                    color: t.accentSuccess,
                    mobile: mobile,
                    iconOnly: mobile,
                    onTap: () {
                      final pasteCount = gallery.clipboard.length;
                      gallery.pasteToAlbum(gallery.activeAlbumId!);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.l.galleryImagesPasted(pasteCount),
                            style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(11))),
                        backgroundColor: const Color(0xFF0A1A0A),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
                        ),
                      ));
                    },
                  ),
                if (gallery.hasClipboard && gallery.activeAlbumId != null)
                  SizedBox(width: mobile ? 12 : 8),
                _ActionButton(
                  icon: Icons.photo_album,
                  label: context.l.galleryAlbum.toUpperCase(),
                  color: t.accent,
                  mobile: mobile,
                  iconOnly: mobile,
                  onTap: count > 0 ? () => _showAddToAlbumDialog(selectedItems) : null,
                ),
                SizedBox(width: mobile ? 12 : 8),
                _ActionButton(
                  icon: Icons.save_alt,
                  label: context.l.commonExport.toUpperCase(),
                  color: t.accent,
                  mobile: mobile,
                  iconOnly: mobile,
                  onTap: count > 0 ? () => _bulkExport(selectedItems) : null,
                ),
                SizedBox(width: mobile ? 12 : 8),
                if (context.read<MLNotifier>().hasBgRemovalModel)
                  _ActionButton(
                    icon: Icons.content_cut,
                    label: 'REMOVE BG',
                    color: t.accent,
                    mobile: mobile,
                    iconOnly: mobile,
                    onTap: count > 0 ? () => _bulkRemoveBg(selectedItems) : null,
                  ),
                if (context.read<MLNotifier>().hasBgRemovalModel)
                  SizedBox(width: mobile ? 12 : 8),
                if (context.read<MLNotifier>().hasUpscaleModel)
                  _ActionButton(
                    icon: Icons.zoom_out_map,
                    label: 'UPSCALE',
                    color: t.accent,
                    mobile: mobile,
                    iconOnly: mobile,
                    onTap: count > 0 ? () => _bulkUpscale(selectedItems) : null,
                  ),
                if (context.read<MLNotifier>().hasUpscaleModel)
                  SizedBox(width: mobile ? 12 : 8),
                if (context.read<MLNotifier>().hasSegmentationModel && count == 1)
                  _ActionButton(
                    icon: Icons.auto_awesome,
                    label: 'SEGMENT',
                    color: t.accent,
                    mobile: mobile,
                    iconOnly: mobile,
                    onTap: () => _openSegmentation(selectedItems.first),
                  ),
                if (context.read<MLNotifier>().hasSegmentationModel && count == 1)
                  SizedBox(width: mobile ? 12 : 8),
                // Send to Canvas (single image)
                if (count == 1)
                  _ActionButton(
                    icon: Icons.brush,
                    label: 'CANVAS',
                    color: t.accentEdit,
                    mobile: mobile,
                    iconOnly: mobile,
                    onTap: () => _openInCanvas(selectedItems.first),
                  ),
                if (count == 1)
                  SizedBox(width: mobile ? 12 : 8),
                _ActionButton(
                  icon: Icons.star,
                  label: context.l.galleryFavorite.toUpperCase(),
                  color: Colors.amber,
                  mobile: mobile,
                  iconOnly: mobile,
                  onTap: count > 0 ? () => _bulkFavorite(selectedItems) : null,
                ),
                SizedBox(width: mobile ? 12 : 8),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: context.l.commonDelete.toUpperCase(),
                  color: t.accentDanger,
                  mobile: mobile,
                  iconOnly: mobile,
                  onTap: count > 0 ? () => _bulkDelete(selectedItems) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool mobile;
  final bool iconOnly;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.mobile,
    this.iconOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: mobile ? 20 : 14, color: color),
              if (!iconOnly) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: mobile ? t.fontSize(10) : t.fontSize(8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final bool mobile;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _AlbumChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.mobile,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ActionChip(
          label: Text(
            '$label ($count)',
            style: TextStyle(
              color: isActive ? t.background : t.textSecondary,
              fontSize: t.fontSize(mobile ? 10 : 8),
              letterSpacing: 1,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isActive ? t.accent : t.borderSubtle,
          side: BorderSide(color: isActive ? t.accent : t.borderMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 4),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _DragRectPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  _DragRectPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(_DragRectPainter oldDelegate) =>
      start != oldDelegate.start || end != oldDelegate.end;
}

class ImageDetailView extends StatefulWidget {
  final int initialIndex;

  const ImageDetailView({super.key, required this.initialIndex});

  @override
  State<ImageDetailView> createState() => _ImageDetailViewState();
}

class _ImageDetailViewState extends State<ImageDetailView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  Map<String, dynamic>? _settings;
  bool _isLoadingMetadata = true;
  bool _isExporting = false;
  bool _showControls = true;
  bool _promptExpanded = false;
  Timer? _hideControlsTimer;
  final FocusNode _focusNode = FocusNode();

  // Per-page zoom controllers
  final Map<int, TransformationController> _zoomControllers = {};
  bool _isZoomed = false;

  // Double-tap zoom animation
  late final AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  Offset? _lastDoubleTapLocal;

  GalleryItem get _currentItem {
    final gallery = Provider.of<GalleryNotifier>(context, listen: false);
    final items = gallery.activeItems;
    if (_currentIndex < items.length) return items[_currentIndex];
    return items.last;
  }

  TransformationController _getZoomController(int index) {
    return _zoomControllers.putIfAbsent(index, () => TransformationController());
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_zoomAnimation != null) {
          final controller = _zoomControllers[_currentIndex];
          if (controller != null) {
            controller.value = _zoomAnimation!.value;
          }
        }
      });
    _loadMetadata();
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _zoomAnimController.dispose();
    _hideControlsTimer?.cancel();
    _pageController.dispose();
    _focusNode.dispose();
    for (final c in _zoomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _showControlsAndReset() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _scheduleHideControls();
  }

  Future<void> _loadMetadata() async {
    final gallery = Provider.of<GalleryNotifier>(context, listen: false);
    final items = gallery.activeItems;
    if (_currentIndex >= items.length) {
      setState(() => _isLoadingMetadata = false);
      return;
    }
    final metadata = await gallery.getMetadata(items[_currentIndex]);

    if (!mounted) return;
    if (metadata != null && metadata.containsKey('Comment')) {
      final settings = parseCommentJson(metadata['Comment']!);
      setState(() {
        _settings = settings;
        _isLoadingMetadata = false;
      });
    } else {
      setState(() {
        _settings = null;
        _isLoadingMetadata = false;
      });
    }
  }

  void _onPageChanged(int index) {
    // Stop any in-flight zoom animation before resetting
    _zoomAnimController.stop();

    // Reset previous page zoom
    final prevController = _zoomControllers[_currentIndex];
    if (prevController != null) {
      prevController.value = Matrix4.identity();
    }

    setState(() {
      _currentIndex = index;
      _isLoadingMetadata = true;
      _promptExpanded = false;
      _isZoomed = false;
    });
    _loadMetadata();

    // Preload adjacent images
    final gallery = Provider.of<GalleryNotifier>(context, listen: false);
    final items = gallery.activeItems;
    if (index + 1 < items.length) {
      precacheImage(FileImage(items[index + 1].file), context).catchError((_) {});
    }
    if (index - 1 >= 0) {
      precacheImage(FileImage(items[index - 1].file), context).catchError((_) {});
    }
  }

  void _onInteractionEnd(TransformationController controller) {
    final scale = controller.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    if (details.pointerCount >= 2) {
      // Pinch detected — disable PageView scrolling immediately
      if (!_isZoomed) {
        setState(() => _isZoomed = true);
      }
    }
  }

  void _handleDoubleTap(TransformationController controller) {
    final current = controller.value.clone();
    final scale = current.getMaxScaleOnAxis();

    Matrix4 target;
    if (scale > 1.05) {
      target = Matrix4.identity();
      setState(() => _isZoomed = false);
    } else {
      const zoomScale = 2.5;
      final pos = _lastDoubleTapLocal ?? Offset.zero;
      final dx = pos.dx * (1 - zoomScale);
      final dy = pos.dy * (1 - zoomScale);
      target = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(dx, dy, 0.0)
        // ignore: deprecated_member_use
        ..scale(zoomScale, zoomScale, 1.0);
      setState(() => _isZoomed = true);
    }

    _zoomAnimation = Matrix4Tween(begin: current, end: target).animate(
      CurvedAnimation(parent: _zoomAnimController, curve: Curves.easeOutCubic),
    );
    _zoomAnimController.forward(from: 0);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final gallery = Provider.of<GalleryNotifier>(context, listen: false);
    final items = gallery.activeItems;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        if (_currentIndex < items.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (_currentIndex > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        Navigator.pop(context);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Future<void> _exportImage() async {
    final t = context.tRead;
    final prefs = context.read<PreferencesService>();
    final item = _currentItem;
    setState(() => _isExporting = true);
    try {
      final sourceFile = item.file;
      final fileName = p.basename(sourceFile.path);

      if (Platform.isAndroid || Platform.isIOS) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) await Gal.requestAccess();
        var bytes = await sourceFile.readAsBytes();
        if (prefs.stripMetadataOnExport) {
          bytes = stripMetadata(bytes);
        }
        final name = p.basenameWithoutExtension(sourceFile.path);
        await Gal.putImageBytes(bytes, name: name);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l.gallerySavedToDevice,
                style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
            backgroundColor: const Color(0xFF0A1A0A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
            ),
          ));
        }
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: context.l.galleryExportImageDialog,
          fileName: fileName,
          type: FileType.image,
        );
        if (result == null) return;

        if (prefs.stripMetadataOnExport) {
          var bytes = await sourceFile.readAsBytes();
          bytes = stripMetadata(bytes);
          await File(result).writeAsBytes(bytes);
        } else {
          await sourceFile.copy(result);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l.gallerySavedTo(p.basename(result)),
                style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
            backgroundColor: const Color(0xFF0A1A0A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
            ),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        final t = context.tRead;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l.galleryExportFailed(e.toString()),
              style: TextStyle(color: t.accent, fontSize: t.fontSize(11))),
          backgroundColor: const Color(0xFF1A0A0A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: t.accentDanger.withValues(alpha: 0.3)),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleRemoveBg(GalleryItem item) async {
    final ml = context.read<MLNotifier>();
    final gallery = context.read<GalleryNotifier>();
    final t = context.tRead;

    final bytes = await item.file.readAsBytes();
    if (!mounted) return;

    final result = await ml.removeBackground(bytes);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('BG REMOVAL FAILED',
            style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(11))),
        backgroundColor: const Color(0xFF1A0A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentDanger.withValues(alpha: 0.3)),
        ),
      ));
      return;
    }

    // Show BG removal overlay
    if (!mounted) return;
    final saved = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: t.background,
        child: BGRemovalOverlay(
          resultImage: result,
          onSave: (img) => Navigator.pop(ctx, img),
          onDiscard: () => Navigator.pop(ctx),
        ),
      ),
    );

    if (saved != null && mounted) {
      final baseName = p.basenameWithoutExtension(item.file.path);
      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-T]'), '').substring(8, 14);
      final outputName = 'BG_${baseName}_$timestamp.png';
      await gallery.saveMLResult(saved, outputName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('BG REMOVED: SAVED AS $outputName',
              style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(11))),
          backgroundColor: const Color(0xFF0A1A0A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
          ),
        ));
      }
    }
  }

  Future<void> _handleUpscale(GalleryItem item) async {
    final ml = context.read<MLNotifier>();
    final gallery = context.read<GalleryNotifier>();
    final t = context.tRead;

    final bytes = await item.file.readAsBytes();
    if (!mounted) return;

    final result = await ml.upscaleImage(bytes);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('UPSCALE FAILED',
            style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(11))),
        backgroundColor: const Color(0xFF1A0A0A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: t.accentDanger.withValues(alpha: 0.3)),
        ),
      ));
      return;
    }

    final baseName = p.basenameWithoutExtension(item.file.path);
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\-T]'), '').substring(8, 14);
    final outputName = 'UP_${baseName}_$timestamp.png';

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UpscaleComparisonView(
            originalBytes: bytes,
            upscaledBytes: result,
            outputName: outputName,
            onSave: () {
              gallery.saveMLResultWithMetadata(result, outputName, sourceBytes: bytes);
            },
          ),
        ),
      );
    }
  }

  void _launchSlideshow() {
    final gallery = context.read<GalleryNotifier>();
    final slideshowNotifier = context.read<SlideshowNotifier>();
    final item = _currentItem;
    final config = slideshowNotifier.defaultConfig ?? const SlideshowConfig(
      id: '_quick_play',
      name: 'Quick Play',
    );
    var playlist = slideshowNotifier.buildPlaylist(config, gallery);
    // Rotate playlist to start at current image
    final idx = playlist.indexWhere((i) => i.basename == item.basename);
    if (idx > 0) {
      playlist = [...playlist.sublist(idx), ...playlist.sublist(0, idx)];
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlideshowPlayer(config: config, playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final gallery = context.watch<GalleryNotifier>();
    final mobile = isMobile(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final items = gallery.activeItems;

    // Guard: if all images deleted, pop
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return Scaffold(backgroundColor: t.background);
    }

    // Clamp index if items were deleted
    if (_currentIndex >= items.length) {
      _currentIndex = items.length - 1;
    }

    final item = items[_currentIndex];

    return Scaffold(
      backgroundColor: t.background,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: GestureDetector(
          onTap: _showControlsAndReset,
          child: MouseRegion(
            onHover: (_) => _showControlsAndReset(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: PageView with per-page InteractiveViewer
                PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: _onPageChanged,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final pageItem = items[index];
                    final zoomController = _getZoomController(index);
                    return GestureDetector(
                      onDoubleTapDown: (details) =>
                          _lastDoubleTapLocal = details.localPosition,
                      onDoubleTap: () => _handleDoubleTap(zoomController),
                      child: InteractiveViewer(
                        transformationController: zoomController,
                        onInteractionStart: _onInteractionStart,
                        onInteractionEnd: (_) => _onInteractionEnd(zoomController),
                        child: Center(
                          child: Image.file(pageItem.file),
                        ),
                      ),
                    );
                  },
                ),

                // Layer 2: Top overlay
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(
                            top: topPadding + 8,
                            left: 8,
                            right: 8,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                t.background.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios,
                                    size: mobile ? 20 : 14, color: t.textSecondary),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              // Position indicator
                              Text(
                                '${_currentIndex + 1} / ${items.length}',
                                style: TextStyle(
                                  color: t.textDisabled,
                                  fontSize: t.fontSize(mobile ? 11 : 9),
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  item.isFavorite ? Icons.star : Icons.star_outline,
                                  size: mobile ? 22 : 18,
                                  color: item.isFavorite ? Colors.amber : t.textSecondary,
                                ),
                                tooltip: context.l.galleryToggleFavorite,
                                onPressed: () {
                                  gallery.toggleFavorite(item);
                                  setState(() {});
                                },
                              ),
                              _isExporting
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: mobile ? 22 : 18,
                                        height: mobile ? 22 : 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: t.textSecondary),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(Icons.save_alt,
                                          size: mobile ? 22 : 18, color: t.textSecondary),
                                      tooltip: context.l.galleryExportImage,
                                      onPressed: _exportImage,
                                    ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    size: mobile ? 22 : 18, color: t.accentDanger),
                                tooltip: context.l.galleryDeleteImageTooltip,
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      final t = context.tRead;
                                      return AlertDialog(
                                        backgroundColor: t.surfaceHigh,
                                        title: Text(context.l.galleryDeleteImage.toUpperCase(),
                                            style: TextStyle(
                                                fontSize: t.fontSize(10),
                                                letterSpacing: 2,
                                                color: t.textSecondary)),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text(context.l.commonCancel.toUpperCase(),
                                                  style: TextStyle(
                                                      color: t.textDisabled,
                                                      fontSize: t.fontSize(9)))),
                                          TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: Text(context.l.commonDelete.toUpperCase(),
                                                  style: TextStyle(
                                                      color: t.accentDanger,
                                                      fontSize: t.fontSize(9)))),
                                        ],
                                      );
                                    },
                                  );
                                  if (!context.mounted || confirm != true) return;
                                  await Provider.of<GalleryNotifier>(context, listen: false)
                                      .deleteItem(item);
                                  if (!context.mounted) return;
                                  final newItems = Provider.of<GalleryNotifier>(context, listen: false).activeItems;
                                  if (newItems.isEmpty) {
                                    Navigator.pop(context);
                                  } else {
                                    setState(() {
                                      if (_currentIndex >= newItems.length) {
                                        _currentIndex = newItems.length - 1;
                                      }
                                      _isLoadingMetadata = true;
                                    });
                                    _loadMetadata();
                                  }
                                },
                              ),
                            ],
                          ),
                      ),
                    ),
                  ),
                ),

                // Layer 3: Bottom overlay
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          bottom: bottomPadding + 12,
                          left: 16,
                          right: 16,
                          top: 32,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              t.background.withValues(alpha: 0.9),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Prompt text (expandable)
                            if (_isLoadingMetadata)
                              LinearProgressIndicator(
                                  minHeight: 1,
                                  backgroundColor: Colors.transparent,
                                  color: t.textMinimal)
                            else if (_settings != null) ...[
                              GestureDetector(
                                onTap: () => setState(() => _promptExpanded = !_promptExpanded),
                                child: Text(
                                  (_settings!['prompt'] ?? context.l.galleryNoPrompt.toUpperCase()).toString().toUpperCase(),
                                  maxLines: _promptExpanded ? 20 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: t.textSecondary,
                                    fontSize: mobile ? t.fontSize(12) : t.fontSize(9),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Info chips row
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _InfoChip(label: context.l.galleryScale.toUpperCase(), value: _settings!['scale']?.toString() ?? "N/A"),
                                    _InfoChip(label: context.l.gallerySteps.toUpperCase(), value: _settings!['steps']?.toString() ?? "N/A"),
                                    _InfoChip(label: context.l.gallerySampler.toUpperCase(), value: _settings!['sampler']?.toString() ?? "N/A"),
                                    _InfoChip(label: context.l.gallerySeed.toUpperCase(), value: _settings!['seed']?.toString() ?? "N/A"),
                                  ],
                                ),
                              ),
                            ] else
                              Text(context.l.galleryNoMetadata.toUpperCase(),
                                  style: TextStyle(
                                      color: t.textDisabled,
                                      fontSize: t.fontSize(9),
                                      letterSpacing: 1)),
                            const SizedBox(height: 12),
                            // Action buttons row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ViewerAction(
                                    icon: Icons.upload_outlined,
                                    label: context.l.galleryPrompt.toUpperCase(),
                                    color: t.accent,
                                    mobile: mobile,
                                    onTap: () {
                                      context.read<GenerationNotifier>().importImageMetadata(item.file);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  _ViewerAction(
                                    icon: Icons.brush_outlined,
                                    label: context.l.galleryImg2img.toUpperCase(),
                                    color: t.accentEdit,
                                    mobile: mobile,
                                    onTap: () async {
                                      final bytes = await item.file.readAsBytes();
                                      if (!context.mounted) return;
                                      String? prompt;
                                      String? negativePrompt;
                                      final prefs = context.read<PreferencesService>();
                                      if (prefs.img2imgImportPrompt) {
                                        final metadata = extractMetadata(bytes);
                                        if (metadata != null && metadata.containsKey('Comment')) {
                                          final json = parseCommentJson(metadata['Comment']!);
                                          if (json != null) {
                                            prompt = json['prompt'] as String?;
                                            negativePrompt = json['uc'] as String?;
                                          }
                                        }
                                      }
                                      if (!context.mounted) return;
                                      context.read<Img2ImgNotifier>().loadSourceImage(bytes, prompt: prompt, negativePrompt: negativePrompt, filePath: item.file.path);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const ToolsHubScreen(initialToolId: 'img2img')),
                                      );
                                    },
                                  ),
                                  if (context.read<MLNotifier>().hasBgRemovalModel)
                                    _ViewerAction(
                                      icon: context.watch<MLNotifier>().isProcessing
                                          ? Icons.hourglass_top
                                          : Icons.content_cut,
                                      label: 'REMOVE BG',
                                      color: t.accent,
                                      mobile: mobile,
                                      onTap: context.watch<MLNotifier>().isProcessing
                                          ? () {}
                                          : () => _handleRemoveBg(item),
                                    ),
                                  if (context.read<MLNotifier>().hasUpscaleModel)
                                    _ViewerAction(
                                      icon: context.watch<MLNotifier>().isProcessing
                                          ? Icons.hourglass_top
                                          : Icons.zoom_out_map,
                                      label: 'UPSCALE',
                                      color: t.accent,
                                      mobile: mobile,
                                      onTap: context.watch<MLNotifier>().isProcessing
                                          ? () {}
                                          : () => _handleUpscale(item),
                                    ),
                                  _ViewerAction(
                                    icon: Icons.person_outline,
                                    label: context.l.galleryCharRef.toUpperCase(),
                                    color: t.accentRefCharacter,
                                    mobile: mobile,
                                    onTap: () async {
                                      final bytes = await item.file.readAsBytes();
                                      if (!context.mounted) return;
                                      await context.read<DirectorRefNotifier>().addReference(bytes);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(context.l.galleryAddedAsCharRef,
                                            style: TextStyle(color: t.accentRefCharacter, fontSize: t.fontSize(11))),
                                        backgroundColor: const Color(0xFF0A1A0A),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                          side: BorderSide(color: t.accentRefCharacter.withValues(alpha: 0.3)),
                                        ),
                                      ));
                                    },
                                  ),
                                  _ViewerAction(
                                    icon: Icons.palette_outlined,
                                    label: context.l.galleryVibe.toUpperCase(),
                                    color: t.accentVibeTransfer,
                                    mobile: mobile,
                                    onTap: () async {
                                      try {
                                        final bytes = await item.file.readAsBytes();
                                        if (!context.mounted) return;
                                        await context.read<VibeTransferNotifier>().addVibe(bytes);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(context.l.galleryAddedAsVibe,
                                              style: TextStyle(color: t.accentVibeTransfer, fontSize: t.fontSize(11))),
                                          backgroundColor: const Color(0xFF0A1A0A),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            side: BorderSide(color: t.accentVibeTransfer.withValues(alpha: 0.3)),
                                          ),
                                        ));
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(context.l.galleryVibeTransferFailed(e.toString()),
                                              style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(11))),
                                          backgroundColor: const Color(0xFF1A0A0A),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                            side: BorderSide(color: t.accentDanger.withValues(alpha: 0.3)),
                                          ),
                                        ));
                                      }
                                    },
                                  ),
                                  _ViewerAction(
                                    icon: Icons.slideshow_outlined,
                                    label: context.l.gallerySlideshow.toUpperCase(),
                                    color: t.textSecondary,
                                    mobile: mobile,
                                    onTap: _launchSlideshow,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // ML Processing overlay
                const MLProcessingOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool mobile;
  final VoidCallback onTap;

  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.mobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: mobile ? 26 : 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: mobile ? t.fontSize(8) : t.fontSize(7),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 8, vertical: mobile ? 6 : 4),
      decoration: BoxDecoration(
        color: t.borderSubtle,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t.textDisabled, fontSize: mobile ? t.fontSize(9) : t.fontSize(7), fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: t.textSecondary, fontSize: mobile ? t.fontSize(11) : t.fontSize(9), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
