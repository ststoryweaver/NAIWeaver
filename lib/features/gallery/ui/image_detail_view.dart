import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/timestamp_utils.dart';
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
import '../../../core/ml/widgets/upscale_comparison_view.dart';
import '../../tools/enhance/providers/enhance_notifier.dart';
import '../../tools/director_tools/providers/director_tools_notifier.dart';

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

  // Action buttons scroll indicator
  final ScrollController _actionScrollController = ScrollController();
  bool _showScrollIndicator = true;

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
    _actionScrollController.addListener(_checkActionOverflow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActionOverflow());
    _loadMetadata();
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _zoomAnimController.dispose();
    _hideControlsTimer?.cancel();
    _pageController.dispose();
    _actionScrollController.dispose();
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
      _showScrollIndicator = true;
    });
    _loadMetadata();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActionOverflow());

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

  void _checkActionOverflow() {
    if (!_actionScrollController.hasClients) return;
    final pos = _actionScrollController.position;
    final shouldShow = pos.maxScrollExtent > 0 && pos.pixels < pos.maxScrollExtent - 2;
    if (shouldShow != _showScrollIndicator) {
      setState(() => _showScrollIndicator = shouldShow);
    }
  }

  /// Returns (label, color) for post-processed images based on filename prefix.
  (String, Color)? _getPostProcessingBadge(GalleryItem item) {
    final name = p.basename(item.file.path);
    final t = context.tRead;
    if (name.startsWith('NAI_UP_')) return ('NAI UPSCALE', t.accentEdit);
    if (name.startsWith('DT_')) {
      // Parse tool name from DT_{tool}_ prefix
      final parts = name.split('_');
      final toolName = parts.length >= 3 ? parts[1].toUpperCase() : 'TOOL';
      return ('DIRECTOR: $toolName', t.accent);
    }
    if (name.startsWith('ENH_')) return ('ENHANCED', t.accentSuccess);
    if (name.startsWith('BG_')) return ('BG REMOVED', t.accentEdit);
    if (name.startsWith('UP_')) return ('UPSCALED', t.accent);
    return null;
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
          showAppSnackBar(context, context.l.gallerySavedToDevice, color: t.accent);
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
          showAppSnackBar(context, context.l.gallerySavedTo(p.basename(result)), color: t.accent);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, context.l.galleryExportFailed(e.toString()));
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
      showErrorSnackBar(context, 'BG REMOVAL FAILED');
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
          autoSave: context.read<GenerationNotifier>().state.autoSaveImages,
        ),
      ),
    );

    if (saved != null && mounted) {
      final baseName = p.basenameWithoutExtension(item.file.path);
      final timestamp = generateTimestamp();
      final outputName = 'BG_${baseName}_$timestamp.png';
      await gallery.saveMLResultWithMetadata(saved, outputName, sourceBytes: bytes);
      if (mounted) {
        showAppSnackBar(context, context.l.mlBgRemovedSavedAs(outputName));
      }
    }
  }

  Future<void> _handleUpscale(GalleryItem item) async {
    final ml = context.read<MLNotifier>();
    final gallery = context.read<GalleryNotifier>();

    final bytes = await item.file.readAsBytes();
    if (!mounted) return;

    final result = await ml.upscaleImage(bytes);
    if (!mounted) return;

    if (result == null) {
      showErrorSnackBar(context, context.l.mlUpscaleFailed);
      return;
    }

    final baseName = p.basenameWithoutExtension(item.file.path);
    final timestamp = generateTimestamp();
    final outputName = 'UP_${baseName}_$timestamp.png';

    if (mounted) {
      final gen = context.read<GenerationNotifier>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UpscaleComparisonView(
            originalBytes: bytes,
            upscaledBytes: result,
            outputName: outputName,
            autoSave: gen.state.autoSaveImages,
            onSave: () {
              gallery.saveMLResultWithMetadata(result, outputName, sourceBytes: bytes);
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleNaiUpscale(GalleryItem item) async {
    final gen = context.read<GenerationNotifier>();
    if (gen.state.apiKey.isEmpty) {
      showErrorSnackBar(context, context.l.naiApiKeyRequired);
      return;
    }
    final gallery = context.read<GalleryNotifier>();

    final bytes = await item.file.readAsBytes();
    if (!mounted) return;

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final w = frame.image.width;
    final h = frame.image.height;
    frame.image.dispose();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final t = ctx.tRead;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.l.naiUpscaling, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
            ],
          ),
        );
      },
    );

    try {
      final imageBase64 = base64Encode(bytes);
      final result = await gen.service.upscaleImage(
        imageBase64: imageBase64,
        width: w,
        height: h,
        scale: 4,
      );
      if (!mounted) return;
      Navigator.of(context).pop();

      final baseName = p.basenameWithoutExtension(item.file.path);
      final timestamp = generateTimestamp();
      final outputName = 'NAI_UP_${baseName}_$timestamp.png';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UpscaleComparisonView(
            originalBytes: bytes,
            upscaledBytes: result,
            outputName: outputName,
            autoSave: gen.state.autoSaveImages,
            onSave: () {
              gallery.saveMLResultWithMetadata(result, outputName, sourceBytes: bytes);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showErrorSnackBar(context, context.l.naiUpscaleFailed);
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
                          child: Listener(
                            onPointerDown: (_) => _showControlsAndReset(),
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
                                  color: item.isFavorite ? t.accentFavorite : t.textSecondary,
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
                                  final confirm = await showConfirmDialog(
                                    context,
                                    title: context.l.galleryDeleteImage,
                                    confirmLabel: context.l.commonDelete,
                                    confirmColor: t.accentDanger,
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
                        child: Listener(
                          onPointerDown: (_) => _showControlsAndReset(),
                          onPointerMove: (_) => _showControlsAndReset(),
                          child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post-processing badge
                            if (_getPostProcessingBadge(item) case (final label, final color))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: color.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: t.fontSize(mobile ? 9 : 7),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
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
                                    shadows: [
                                      Shadow(color: Colors.black, blurRadius: 4),
                                      Shadow(color: Colors.black, blurRadius: 8),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Info chips row
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (_settings!['width'] != null && _settings!['height'] != null)
                                      _InfoChip(label: context.l.galleryResolution.toUpperCase(), value: '${_settings!['width']}x${_settings!['height']}'),
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
                                      letterSpacing: 1,
                                      shadows: [
                                        Shadow(color: Colors.black, blurRadius: 4),
                                        Shadow(color: Colors.black, blurRadius: 8),
                                      ])),
                            const SizedBox(height: 12),
                            // Action buttons row
                            Stack(
                              children: [
                                SingleChildScrollView(
                                  controller: _actionScrollController,
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
                                  _ViewerAction(
                                    icon: Icons.hd,
                                    label: context.l.galleryEnhance.toUpperCase(),
                                    color: t.accent,
                                    mobile: mobile,
                                    onTap: () async {
                                      final bytes = await item.file.readAsBytes();
                                      if (!context.mounted) return;
                                      context.read<EnhanceNotifier>().setSourceImage(bytes);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => const ToolsHubScreen(initialToolId: 'enhance'),
                                      ));
                                    },
                                  ),
                                  _ViewerAction(
                                    icon: Icons.auto_fix_high,
                                    label: context.l.galleryDirectorTools.toUpperCase(),
                                    color: t.accent,
                                    mobile: mobile,
                                    onTap: () async {
                                      final bytes = await item.file.readAsBytes();
                                      if (!context.mounted) return;
                                      context.read<DirectorToolsNotifier>().setSourceImage(bytes);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => const ToolsHubScreen(initialToolId: 'director_tools'),
                                      ));
                                    },
                                  ),
                                  if (context.read<MLNotifier>().hasBgRemovalModel)
                                    _ViewerAction(
                                      icon: context.watch<MLNotifier>().isProcessing
                                          ? Icons.hourglass_top
                                          : Icons.content_cut,
                                      label: context.l.mlRemoveBg.toUpperCase(),
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
                                      label: context.l.mlUpscale.toUpperCase(),
                                      color: t.accent,
                                      mobile: mobile,
                                      onTap: context.watch<MLNotifier>().isProcessing
                                          ? () {}
                                          : () => _handleUpscale(item),
                                    ),
                                  if (context.read<GenerationNotifier>().state.apiKey.isNotEmpty)
                                    _ViewerAction(
                                      icon: Icons.cloud_upload_outlined,
                                      label: context.l.naiUpscale.toUpperCase(),
                                      color: t.accentEdit,
                                      mobile: mobile,
                                      onTap: () => _handleNaiUpscale(item),
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
                                      showAppSnackBar(context, context.l.galleryAddedAsCharRef, color: t.accentRefCharacter);
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
                                        showAppSnackBar(context, context.l.galleryAddedAsVibe, color: t.accentVibeTransfer);
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        showErrorSnackBar(context, context.l.galleryVibeTransferFailed(e.toString()));
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
                            if (_showScrollIndicator)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 32,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerRight,
                                            end: Alignment.centerLeft,
                                            colors: [
                                              t.background.withValues(alpha: 0.9),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, size: 16, color: t.textDisabled),
                                    ],
                                  ),
                                ),
                              ),
                              ],
                            ),
                          ],
                        ),
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
