import 'dart:ui' as ui;

import '../../../../core/utils/file_picker_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/responsive.dart';
import 'canvas_help_dialog.dart';
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
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void dispose() {
    _editorFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final notifier = context.read<CanvasNotifier>();

    // Don't intercept shortcuts when text tool editor is active
    if (notifier.hasPendingText) return KeyEventResult.ignored;

    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;

    // Undo / Redo
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (shift) {
        notifier.redo();
      } else {
        notifier.undo();
      }
      return KeyEventResult.handled;
    }
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyY) {
      notifier.redo();
      return KeyEventResult.handled;
    }

    // Don't intercept single-key shortcuts when a modifier is held
    if (ctrl || HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }

    // Tool switching
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyB:
        notifier.setTool(CanvasTool.paint);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyE:
        notifier.setTool(CanvasTool.erase);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyG:
        notifier.setTool(CanvasTool.fill);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyT:
        notifier.setTool(CanvasTool.text);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyC:
        notifier.setTool(CanvasTool.eyedropper);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyV:
        notifier.setTool(CanvasTool.transform);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyL:
        notifier.setTool(CanvasTool.line);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyR:
        notifier.setTool(CanvasTool.rectangle);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyO:
        notifier.setTool(CanvasTool.circle);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyS:
        notifier.setTool(CanvasTool.select);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyA:
        notifier.setTool(CanvasTool.lasso);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (notifier.hasSelection) {
          notifier.cancelSelection();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        if (notifier.hasSelection) {
          notifier.deleteSelectionContents();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      // Brush size (pixel steps)
      case LogicalKeyboardKey.bracketLeft:
        notifier.setBrushDiameterPx(
            notifier.brushDiameterPx - notifier.brushStepPx);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.bracketRight:
        notifier.setBrushDiameterPx(
            notifier.brushDiameterPx + notifier.brushStepPx);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CanvasNotifier>();
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return Focus(
      focusNode: _editorFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
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
    ),
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
          child: const RepaintBoundary(child: LayerPanel()),
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
          // Help
          IconButton(
            icon: Icon(Icons.help_outline, size: 16, color: t.textTertiary),
            onPressed: () => showCanvasHelpDialog(context),
            tooltip: l.canvasHelp,
          ),
          // Resize canvas
          if (session != null)
            IconButton(
              icon: Icon(Icons.aspect_ratio, size: 16, color: t.textTertiary),
              onPressed: () => _showResizeDialog(context, notifier, t),
              tooltip: 'Resize Canvas',
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
      final t = context.tRead;
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

  void _showResizeDialog(BuildContext context, CanvasNotifier notifier, VisionTokens t) {
    final session = notifier.session;
    if (session == null) return;
    showDialog(
      context: context,
      builder: (_) => _CanvasResizeDialog(
        currentWidth: session.sourceWidth,
        currentHeight: session.sourceHeight,
        onApply: (newWidth, newHeight, anchorX, anchorY) {
          notifier.resizeCanvas(newWidth, newHeight, anchorX, anchorY);
        },
      ),
    );
  }

  Future<void> _importImage() async {
    final notifier = context.read<CanvasNotifier>();
    if (notifier.session == null) return;

    try {
      final result = await pickImageFiles();
      if (result == null || result.files.isEmpty) return;

      final bytes = await readPickedFileBytes(result.files.single);
      if (bytes == null) return;
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

/// Dialog for resizing the canvas with an anchor grid.
class _CanvasResizeDialog extends StatefulWidget {
  final int currentWidth;
  final int currentHeight;
  final void Function(int newWidth, int newHeight, int anchorX, int anchorY) onApply;

  const _CanvasResizeDialog({
    required this.currentWidth,
    required this.currentHeight,
    required this.onApply,
  });

  @override
  State<_CanvasResizeDialog> createState() => _CanvasResizeDialogState();
}

class _CanvasResizeDialogState extends State<_CanvasResizeDialog> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  int _anchorRow = 1; // 0=top, 1=center, 2=bottom
  int _anchorCol = 1; // 0=left, 1=center, 2=right

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(text: widget.currentWidth.toString());
    _heightController = TextEditingController(text: widget.currentHeight.toString());
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _addToWidth(int amount) {
    final current = int.tryParse(_widthController.text) ?? widget.currentWidth;
    _widthController.text = (current + amount).clamp(64, 9999).toString();
  }

  void _addToHeight(int amount) {
    final current = int.tryParse(_heightController.text) ?? widget.currentHeight;
    _heightController.text = (current + amount).clamp(64, 9999).toString();
  }

  void _apply() {
    final newW = int.tryParse(_widthController.text) ?? widget.currentWidth;
    final newH = int.tryParse(_heightController.text) ?? widget.currentHeight;
    if (newW == widget.currentWidth && newH == widget.currentHeight) {
      Navigator.pop(context);
      return;
    }

    final dw = newW - widget.currentWidth;
    final dh = newH - widget.currentHeight;

    // Compute anchor offset based on grid position
    final anchorX = (_anchorCol * dw / 2).round();
    final anchorY = (_anchorRow * dh / 2).round();

    widget.onApply(newW, newH, anchorX, anchorY);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(
        'RESIZE CANVAS',
        style: TextStyle(
          fontSize: t.fontSize(10),
          letterSpacing: 2,
          color: t.textSecondary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dimension inputs
          Row(
            children: [
              Expanded(child: _buildDimInput('WIDTH', _widthController, t)),
              const SizedBox(width: 16),
              Expanded(child: _buildDimInput('HEIGHT', _heightController, t)),
            ],
          ),
          const SizedBox(height: 12),
          // Quick-add buttons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _quickButton('+480 W', () => _addToWidth(480), t),
              _quickButton('+480 H', () => _addToHeight(480), t),
              _quickButton('+256 W', () => _addToWidth(256), t),
              _quickButton('+256 H', () => _addToHeight(256), t),
            ],
          ),
          const SizedBox(height: 16),
          // Anchor label
          Text(
            'ANCHOR',
            style: TextStyle(
              fontSize: t.fontSize(8),
              letterSpacing: 2,
              color: t.textDisabled,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 3x3 anchor grid
          _buildAnchorGrid(t),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
        ),
        TextButton(
          onPressed: _apply,
          child: Text('APPLY', style: TextStyle(color: t.accentEdit, fontSize: t.fontSize(9))),
        ),
      ],
    );
  }

  Widget _buildDimInput(String label, TextEditingController controller, VisionTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: t.fontSize(8), letterSpacing: 1, color: t.textDisabled, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: t.fontSize(11), color: t.textPrimary),
          decoration: InputDecoration(
            fillColor: t.borderSubtle.withValues(alpha: 0.5),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _quickButton(String label, VoidCallback onTap, VisionTokens t) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: t.borderMedium),
        ),
        child: Text(label, style: TextStyle(fontSize: t.fontSize(8), color: t.textSecondary, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildAnchorGrid(VisionTokens t) {
    return SizedBox(
      width: 90,
      height: 90,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: List.generate(9, (index) {
          final row = index ~/ 3;
          final col = index % 3;
          final isSelected = row == _anchorRow && col == _anchorCol;
          return GestureDetector(
            onTap: () => setState(() {
              _anchorRow = row;
              _anchorCol = col;
            }),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? t.accentEdit : t.borderSubtle,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? t.accentEdit : t.borderMedium,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.circle, size: 8, color: t.background)
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
