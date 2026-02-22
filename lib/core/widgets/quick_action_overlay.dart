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
              onTap: () => notifier.saveCurrentImage(),
              icon: Icons.save_alt,
              label: l.mainSave.toUpperCase(),
              color: t.accentSuccess,
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

      final result = await service.upscaleImage(
        imageBase64: base64Encode(sourceBytes),
        width: decoded.$1,
        height: decoded.$2,
        scale: scale,
      );

      if (context.mounted) {
        _showUpscaleComparison(context, sourceBytes, result, autoSave);
      }
    } catch (e) {
      if (context.mounted) {
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

      final result = await service.augmentImage(
        imageBase64: base64Encode(sourceBytes),
        width: decoded.$1,
        height: decoded.$2,
        reqType: 'bg-removal',
      );

      if (context.mounted) {
        final gallery = context.read<GalleryNotifier>();
        final timestamp = generateTimestamp();
        await gallery.saveMLResult(result, 'BG_gen_$timestamp.png');
        if (context.mounted) {
          showAppSnackBar(context, l.mlBgRemovedAndSaved);
        }
      }
    } catch (e) {
      if (context.mounted) {
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
          onSave: () {
            gallery.saveMLResultWithMetadata(result, outputName,
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
