import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../l10n/l10n_extensions.dart';
import '../ml/ml_notifier.dart';
import '../ml/widgets/upscale_comparison_view.dart';
import '../services/preferences_service.dart';
import '../theme/theme_extensions.dart';
import '../theme/vision_tokens.dart';
import '../services/novel_ai_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/responsive.dart';
import '../utils/timestamp_utils.dart';
import '../../features/gallery/providers/gallery_notifier.dart';
import '../../features/generation/providers/generation_notifier.dart';
import '../../features/tools/enhance/providers/enhance_notifier.dart';
import '../../features/tools/director_tools/providers/director_tools_notifier.dart';
import '../../features/tools/img2img/providers/img2img_notifier.dart';
import '../../features/tools/tools_hub_screen.dart';
import '../../features/tools/cascade/providers/cascade_notifier.dart';

/// Quick action buttons (SAVE, EDIT, REMOVE BG, UPSCALE, ENHANCE, DIRECTOR TOOLS)
/// that float over the generated image preview on the main screen.
class QuickActionOverlay extends StatelessWidget {
  const QuickActionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenerationNotifier>();
    final state = notifier.state;
    final mobile = isMobile(context);
    final t = context.t;
    final l = context.l;
    final ml = context.watch<MLNotifier>();
    final prefs = context.read<PreferencesService>();
    final upscaleBackend = prefs.upscaleBackend;
    final bgRemovalBackend = prefs.bgRemovalBackend;

    // Nothing to show when there is no image or generation is in progress.
    if (state.generatedImage == null || state.isLoading) {
      return const SizedBox.shrink();
    }

    // Button step size: compact icon-only buttons with small gap
    final double step = mobile ? 40 : 32;

    // Calculate dynamic top offsets
    double nextTop = 12;

    final bool showSave = !state.autoSaveImages && !notifier.imageSaved;
    final double saveTop = nextTop;
    if (showSave) nextTop += step;

    final bool showExport = prefs.showExportButton && !kIsWeb;
    final double exportTop = nextTop;
    if (showExport) nextTop += step;

    final bool showCopy = prefs.showCopyButton && !kIsWeb;
    final double copyTop = nextTop;
    if (showCopy) nextTop += step;

    final gallery = context.watch<GalleryNotifier>();
    final bool showAlbum = gallery.albums.isNotEmpty;
    final double albumTop = nextTop;
    if (showAlbum) nextTop += step;

    final bool showEdit = state.showEditButton;
    final double editTop = nextTop;
    if (showEdit) nextTop += step;

    final bool showBgRemoval = state.showBgRemovalButton &&
        (ml.hasBgRemovalModel || bgRemovalBackend == 'novelai');
    final double bgRemovalTop = nextTop;
    if (showBgRemoval) nextTop += step;

    final bool showUpscale = state.showUpscaleButton &&
        (ml.hasUpscaleModel || upscaleBackend == 'novelai');
    final double upscaleTop = nextTop;
    if (showUpscale) nextTop += step;

    final bool showEnhance = state.showEnhanceButton;
    final double enhanceTop = nextTop;
    if (showEnhance) nextTop += step;

    final bool showDirectorTools = state.showDirectorToolsButton;
    final double directorToolsTop = nextTop;

    return Stack(
      children: [
        // SAVE button (keeps current text style — different category)
        if (showSave)
          Positioned(
            top: saveTop,
            right: 20,
            child: _SaveButton(
              onTap: () async {
                await notifier.saveCurrentImage();
                // Same bookkeeping as the album picker: if this is a cascade
                // beat, remember its filename so switching beats and back
                // doesn't offer SAVE again (and write a duplicate).
                final saved = notifier.lastSavedBasename;
                if (saved != null && context.mounted) {
                  context.read<CascadeNotifier>().recordBasenameForImage(
                        notifier.state.generatedImage,
                        saved,
                      );
                }
              },
              icon: Icons.save_alt,
              label: l.mainSave.toUpperCase(),
              color: t.accentSuccess,
              mobile: mobile,
            ),
          ),

        // EXPORT to device
        if (showExport)
          Positioned(
            top: exportTop,
            right: 20,
            child: _ActionButton(
              onTap: () => notifier.exportToDevice(context),
              icon: Icons.download,
              label: l.mainExport,
              color: t.accent,
              mobile: mobile,
            ),
          ),

        // COPY (desktop clipboard) / SHARE (mobile share sheet)
        if (showCopy)
          Positioned(
            top: copyTop,
            right: 20,
            child: _ActionButton(
              onTap: () => notifier.copyToClipboard(context),
              icon: mobile ? Icons.share : Icons.copy,
              label: mobile ? 'SHARE' : 'COPY',
              color: t.accent,
              mobile: mobile,
            ),
          ),

        // ALBUM
        if (showAlbum)
          Positioned(
            top: albumTop,
            right: 20,
            child: _ActionButton(
              onTap: () => _showAlbumPicker(context, notifier, t),
              icon: Icons.photo_album_outlined,
              label: 'ALBUM',
              color: t.accent,
              mobile: mobile,
            ),
          ),

        // EDIT
        if (showEdit)
          Positioned(
            top: editTop,
            right: 20,
            child: _ActionButton(
              onTap: () {
                context.read<Img2ImgNotifier>().loadSourceImage(state.generatedImage!);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ToolsHubScreen(initialToolId: 'img2img')),
                );
              },
              icon: Icons.brush,
              label: l.mainEdit,
              color: t.accentEdit,
              mobile: mobile,
            ),
          ),

        // REMOVE BG
        if (showBgRemoval)
          Positioned(
            top: bgRemovalTop,
            right: 20,
            child: _ActionButton(
              onTap: ml.isProcessing
                  ? null
                  : () async {
                      final sourceBytes = state.generatedImage!;
                      if (bgRemovalBackend == 'novelai') {
                        await _handleNovelAIBgRemoval(context, sourceBytes);
                      } else {
                        final result = await ml.removeBackground(sourceBytes);
                        if (result != null && context.mounted) {
                          final gallery = context.read<GalleryNotifier>();
                          final timestamp = generateTimestamp();
                          await gallery.saveMLResult(result, 'BG_gen_$timestamp.png');
                          if (context.mounted) {
                            showAppSnackBar(context, l.mlBgRemovedAndSaved);
                          }
                        }
                      }
                    },
              icon: Icons.content_cut,
              label: l.mlRemoveBg,
              color: t.accentBgRemoval,
              isProcessing: ml.isProcessing,
              mobile: mobile,
            ),
          ),

        // UPSCALE
        if (showUpscale)
          Positioned(
            top: upscaleTop,
            right: 20,
            child: _ActionButton(
              onTap: ml.isProcessing
                  ? null
                  : () async {
                      final sourceBytes = state.generatedImage!;
                      if (upscaleBackend == 'novelai') {
                        await _handleNovelAIUpscale(context, sourceBytes, state.autoSaveImages);
                      } else {
                        final result = await ml.upscaleImage(sourceBytes);
                        if (result != null && context.mounted) {
                          _showUpscaleComparison(context, sourceBytes, result, state.autoSaveImages);
                        }
                      }
                    },
              icon: Icons.zoom_out_map,
              label: l.mlUpscale,
              color: t.accentUpscale,
              isProcessing: ml.isProcessing,
              mobile: mobile,
            ),
          ),

        // ENHANCE
        if (showEnhance)
          Positioned(
            top: enhanceTop,
            right: 20,
            child: _ActionButton(
              onTap: () {
                context.read<EnhanceNotifier>().setSourceImage(state.generatedImage!);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'enhance')),
                );
              },
              icon: Icons.hd,
              label: l.quickActionEnhance,
              color: t.accent,
              mobile: mobile,
            ),
          ),

        // DIRECTOR TOOLS
        if (showDirectorTools)
          Positioned(
            top: directorToolsTop,
            right: 20,
            child: _ActionButton(
              onTap: () {
                context.read<DirectorToolsNotifier>().setSourceImage(state.generatedImage!);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'director_tools')),
                );
              },
              icon: Icons.auto_fix_high,
              label: l.quickActionDirectorTools,
              color: t.accent,
              mobile: mobile,
            ),
          ),
      ],
    );
  }

  Future<void> _handleNovelAIUpscale(BuildContext context, Uint8List sourceBytes, bool autoSave) async {
    final service = context.read<GenerationNotifier>().service;
    final l = context.l;

    try {
      final decoded = await compute(_decodeImageDimensions, sourceBytes);
      if (decoded == null || !context.mounted) return;

      final scale = NovelAIService.bestUpscaleScale(decoded.$1, decoded.$2);
      if (scale == null) {
        if (context.mounted) {
          showErrorSnackBar(context, 'Image too large for NAI upscale (${decoded.$1}x${decoded.$2} exceeds 2048px limit per side)');
        }
        return;
      }

      if (!context.mounted) return;
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
                Text(l.naiUpscaling, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
              ],
            ),
          );
        },
      );

      final result = await service.upscaleImage(
        imageBase64: base64Encode(sourceBytes),
        width: decoded.$1,
        height: decoded.$2,
        scale: scale,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        _showUpscaleComparison(context, sourceBytes, result, autoSave);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context, l.naiUpscaleFailed);
      }
    }
  }

  Future<void> _handleNovelAIBgRemoval(BuildContext context, Uint8List sourceBytes) async {
    final service = context.read<GenerationNotifier>().service;
    final l = context.l;

    try {
      final decoded = await compute(_decodeImageDimensions, sourceBytes);
      if (decoded == null || !context.mounted) return;

      if (!context.mounted) return;
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
                Text(l.mlRemovingBg, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
              ],
            ),
          );
        },
      );

      final result = await service.augmentImage(
        imageBase64: base64Encode(sourceBytes),
        width: decoded.$1,
        height: decoded.$2,
        reqType: 'bg-removal',
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        final gallery = context.read<GalleryNotifier>();
        final timestamp = generateTimestamp();
        await gallery.saveMLResult(result, 'BG_gen_$timestamp.png');
        if (context.mounted) {
          showAppSnackBar(context, l.mlBgRemovedAndSaved);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context, 'NAI BG REMOVAL FAILED');
      }
    }
  }

  void _showUpscaleComparison(BuildContext context, Uint8List sourceBytes, Uint8List result, bool autoSave) {
    final gallery = context.read<GalleryNotifier>();
    final timestamp = generateTimestamp();
    final outputName = 'UP_gen_$timestamp.png';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpscaleComparisonView(
          originalBytes: sourceBytes,
          upscaledBytes: result,
          outputName: outputName,
          autoSave: autoSave,
          onSave: () async {
            await gallery.saveMLResultWithMetadata(result, outputName,
                sourceBytes: sourceBytes);
          },
        ),
      ),
    );
  }
}

(int, int)? _decodeImageDimensions(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return (decoded.width, decoded.height);
}

void _showAlbumPicker(
  BuildContext context,
  GenerationNotifier notifier,
  VisionTokens t,
) async {
  final basename = await notifier.ensureSavedAndGetBasename();
  if (basename == null || !context.mounted) return;

  // If this image is a cascade beat preview, remember its filename so
  // switching beats later can restore the right album membership.
  context.read<CascadeNotifier>().recordBasenameForImage(
        notifier.state.generatedImage,
        basename,
      );

  showModalBottomSheet(
    context: context,
    backgroundColor: t.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (_) => _AlbumPickerSheet(basename: basename),
  );
}

/// Album list for the current generated image. Checks reflect this image's
/// membership only — not a session-wide "selected album".
class _AlbumPickerSheet extends StatelessWidget {
  const _AlbumPickerSheet({required this.basename});

  final String basename;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final gallery = context.watch<GalleryNotifier>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 32, height: 3, decoration: BoxDecoration(color: t.borderMedium, borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('ADD TO ALBUM', style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, fontWeight: FontWeight.w900, color: t.textSecondary)),
          ),
          for (final album in gallery.albums)
            ListTile(
              leading: Icon(
                Icons.photo_album,
                size: 18,
                color: album.imageBasenames.contains(basename) ? t.accentSuccess : t.textDisabled,
              ),
              title: Text(album.name, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(12))),
              trailing: album.imageBasenames.contains(basename)
                  ? Icon(Icons.check, size: 16, color: t.accentSuccess)
                  : null,
              onTap: () {
                final alreadyIn = album.imageBasenames.contains(basename);
                if (!alreadyIn) {
                  gallery.addToAlbumByBasename(album.id, basename);
                }
                Navigator.pop(context);
                if (!alreadyIn) {
                  showAppSnackBar(context, 'ADDED TO ${album.name.toUpperCase()}');
                }
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// SAVE button — keeps text+icon style (different category from tool launchers).
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.mobile,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 14 : 10, vertical: mobile ? 10 : 6),
          decoration: BoxDecoration(
            color: t.background.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: mobile ? 16 : 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: t.fontSize(mobile ? 12 : 9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact icon-only quick-action button with tooltip.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    required this.mobile,
    this.isProcessing = false,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool mobile;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final size = mobile ? 36.0 : 28.0;
    final iconSize = mobile ? 18.0 : 14.0;
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: isProcessing
                  ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(strokeWidth: 2, color: color),
                    )
                  : Icon(icon, size: iconSize, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
