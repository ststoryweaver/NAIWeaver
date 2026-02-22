import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/responsive.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../../img2img/providers/img2img_notifier.dart';
import '../models/canvas_layer.dart';
import '../models/paint_stroke.dart';
import '../providers/canvas_notifier.dart';
import '../services/canvas_flatten_service.dart';
import '../services/canvas_gallery_service.dart';
import 'canvas_paint_surface.dart';
import 'canvas_toolbar.dart';
import 'layer_panel.dart';

/// Full-screen canvas editor page.
/// Header + paint surface + toolbar + layer panel sidebar (desktop) / FAB (mobile).
/// Handles the flatten-and-return flow back to img2img.
class CanvasEditor extends StatefulWidget {
  const CanvasEditor({super.key});

  @override
  State<CanvasEditor> createState() => _CanvasEditorState();
}

class _CanvasEditorState extends State<CanvasEditor> {
  bool _isFlattening = false;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CanvasNotifier>();
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, t, l, notifier),
            Expanded(
              child: mobile
                  ? _buildMobileBody(t)
                  : _buildDesktopBody(t),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: CanvasToolbar(
                onFlatten: _flatten,
                onShowLayers: mobile ? () => _showLayerSheet(context, t) : null,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildDesktopBody(VisionTokens t) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: t.background,
            child: const CanvasPaintSurface(),
          ),
        ),
        SizedBox(
          width: 200,
          child: const LayerPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileBody(VisionTokens t) {
    return Container(
      color: t.background,
      child: const CanvasPaintSurface(),
    );
  }

  void _showLayerSheet(BuildContext context, VisionTokens t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.surfaceMid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        // Re-provide the notifier to the bottom sheet context
        return ChangeNotifierProvider.value(
          value: context.read<CanvasNotifier>(),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.7,
            builder: (_, controller) {
              return const LayerPanel();
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, VisionTokens t, AppLocalizations l,
      CanvasNotifier notifier) {
    final session = notifier.session;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 16, color: t.textDisabled),
            onPressed: () => _handleBack(context, notifier, l),
            tooltip: l.canvasBack,
          ),
          if (!isMobile(context)) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.canvasEditorTitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: t.fontSize(12),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  if (session != null)
                    Text(
                      '${session.sourceWidth} x ${session.sourceHeight}',
                      style: TextStyle(
                        color: t.accentEdit,
                        fontSize: t.fontSize(8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (session != null && isMobile(context))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: context.l.canvasLayers,
                child: InkWell(
                onTap: () => _showLayerSheet(context, t),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.accentEdit.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: t.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers, size: 16, color: t.accentEdit),
                      const SizedBox(width: 6),
                      if (session.activeLayer != null)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: Text(
                            session.activeLayer!.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.textDisabled,
                              fontSize: t.fontSize(9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '(${session.layers.length})',
                        style: TextStyle(
                          color: t.textMinimal,
                          fontSize: t.fontSize(9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          // Import image as layer
          if (session != null)
            IconButton(
              icon: Icon(Icons.add_photo_alternate_outlined,
                  size: 16, color: t.textTertiary),
              onPressed: _importImage,
              tooltip: l.canvasImportImage,
            ),
          if (_isFlattening)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: t.accentEdit),
            ),
        ],
      ),
    );
  }

  Future<void> _handleBack(
      BuildContext context, CanvasNotifier notifier, AppLocalizations l) async {
    final session = notifier.session;
    if (session != null && session.hasStrokes) {
      final t = context.t;
      final confirm = await showConfirmDialog(
        context,
        title: l.canvasDiscardTitle,
        message: l.canvasDiscardMessage,
        confirmLabel: l.canvasDiscard,
        confirmColor: t.accentDanger,
      );
      if (confirm == true) {
        notifier.clearSession();
        if (context.mounted) Navigator.pop(context);
      }
    } else {
      notifier.clearSession();
      Navigator.pop(context);
    }
  }

  Future<void> _importImage() async {
    final notifier = context.read<CanvasNotifier>();
    if (notifier.session == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final bytes = await File(filePath).readAsBytes();
      final name = result.files.single.name;
      notifier.addImageLayer(bytes, name: name);
      notifier.setTool(CanvasTool.transform);
    } catch (e) {
      debugPrint('Image import failed: $e');
    }
  }

  Future<Map<String, Uint8List>> _prerenderTextOverlays(
    List<CanvasLayer> layers,
    int width,
    int height,
  ) async {
    final result = <String, Uint8List>{};

    for (final layer in layers) {
      if (!layer.visible) continue;
      final textStrokes = layer.strokes
          .where((s) => s.strokeType == StrokeType.text && s.text != null)
          .toList();
      if (textStrokes.isEmpty) continue;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      for (final stroke in textStrokes) {
        final pos = Offset(
          stroke.points.first.dx * width,
          stroke.points.first.dy * height,
        );
        final fontSize = (stroke.fontSize ?? 0.05) * height;
        final letterSpacing = (stroke.letterSpacing ?? 0.0) * height;
        final color = Color(stroke.colorValue)
            .withValues(alpha: stroke.opacity);
        TextStyle style = TextStyle(
          color: color,
          fontSize: fontSize,
          letterSpacing: letterSpacing,
        );
        if (stroke.fontFamily != null) {
          try {
            style = GoogleFonts.getFont(stroke.fontFamily!, textStyle: style);
          } catch (_) {
            // Fall back to default if font not available
          }
        }
        final textPainter = TextPainter(
          text: TextSpan(text: stroke.text, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, pos);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        result[layer.id] = byteData.buffer.asUint8List();
      }
      image.dispose();
      picture.dispose();
    }

    return result;
  }

  Future<void> _flatten() async {
    final notifier = context.read<CanvasNotifier>();
    final img2imgNotifier = context.read<Img2ImgNotifier>();
    final galleryNotifier = context.read<GalleryNotifier>();
    final session = notifier.session;
    if (session == null || !session.hasStrokes) return;

    setState(() => _isFlattening = true);

    try {
      final textOverlays = await _prerenderTextOverlays(
        session.visibleLayers,
        session.sourceWidth,
        session.sourceHeight,
      );

      final flattenedBytes = await CanvasFlattenService.flatten(
        sourceBytes: session.sourceImageBytes,
        sourceWidth: session.sourceWidth,
        sourceHeight: session.sourceHeight,
        visibleLayers: session.visibleLayers,
        textOverlays: textOverlays,
      );

      // Save to gallery with sidecar files for later restoration
      final savedFile = await CanvasGalleryService.saveToGallery(
        session,
        flattenedBytes,
        galleryNotifier.outputDir,
      );
      galleryNotifier.addFile(savedFile, DateTime.now());

      await img2imgNotifier.replaceSourceImage(
        flattenedBytes,
        filePath: savedFile.path,
      );
      notifier.clearSession();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Canvas flatten error: $e');
      if (mounted) {
        setState(() => _isFlattening = false);
        showErrorSnackBar(context, context.l.canvasFlattenFailed(e.toString()));
      }
    }
  }
}
