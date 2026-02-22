import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/responsive.dart';
import '../../../generation/providers/generation_notifier.dart';
import '../../canvas/providers/canvas_notifier.dart';
import '../../canvas/services/canvas_gallery_service.dart';
import '../../canvas/widgets/canvas_editor.dart';
import '../providers/img2img_notifier.dart';
import '../services/img2img_request_builder.dart';
import '../../../../core/ml/ml_notifier.dart';
import '../../ml/widgets/segmentation_overlay.dart';
import 'mask_canvas.dart';
import 'mask_toolbar.dart';
import 'img2img_settings_panel.dart';
import 'source_image_picker.dart';

/// Top-level img2img editor.
/// No session -> shows source image picker.
/// Active session -> shows canvas + toolbar + settings + generate button.
class Img2ImgEditor extends StatefulWidget {
  const Img2ImgEditor({super.key});

  @override
  State<Img2ImgEditor> createState() => _Img2ImgEditorState();
}

class _Img2ImgEditorState extends State<Img2ImgEditor> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController(
    text: 'lowres, {bad}, error, fewer, extra, missing, worst quality, jpeg artifacts, bad quality, watermark, unfinished, displeasing, chromatic aberration, signature, extra digits, artistic error, username, scan, [abstract]',
  );

  bool _showResult = false;
  bool _hadSession = false;

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img2imgNotifier = context.watch<Img2ImgNotifier>();
    final genNotifier = context.watch<GenerationNotifier>();

    // Sync controllers when a new session loads with pre-filled prompts
    final hasSession = img2imgNotifier.hasSession;
    if (hasSession && !_hadSession) {
      final session = img2imgNotifier.session!;
      if (session.prompt.isNotEmpty) {
        _promptController.text = session.prompt;
      }
      if (session.negativePrompt.isNotEmpty) {
        _negativePromptController.text = session.negativePrompt;
      }
    }
    _hadSession = hasSession;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: img2imgNotifier.hasSession
          ? _buildWorkspace(context, img2imgNotifier, genNotifier)
          : const SourceImagePicker(),
    );
  }

  Widget _buildWorkspace(
    BuildContext context,
    Img2ImgNotifier img2imgNotifier,
    GenerationNotifier genNotifier,
  ) {
    final t = context.t;
    final l = context.l;
    final isLoading = genNotifier.state.isLoading;
    final session = img2imgNotifier.session!;
    final hasResult = session.resultImageBytes != null;

    // If we're showing result but it was cleared, switch back
    if (_showResult && !hasResult) {
      _showResult = false;
    }

    final mobile = isMobile(context);

    Widget canvasArea = Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (_showResult && hasResult)
                _buildResultView(session.resultImageBytes!, img2imgNotifier)
              else
                const MaskCanvas(),

              // Source / Result label badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_showResult && hasResult)
                        ? const Color(0xCC00CC66)
                        : const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (_showResult && hasResult) ? l.img2imgResult : l.img2imgSource,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: t.fontSize(9),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_showResult || !hasResult) const MaskToolbar(),
      ],
    );

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(context, img2imgNotifier, genNotifier, isLoading),
            Expanded(
              child: mobile
                  ? canvasArea
                  : Row(
                      children: [
                        Expanded(flex: 3, child: canvasArea),
                        SizedBox(
                          width: 280,
                          child: Img2ImgSettingsPanel(
                            promptController: _promptController,
                            negativePromptController: _negativePromptController,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        // Mobile FAB for settings
        if (mobile)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              tooltip: context.l.img2imgSettings,
              backgroundColor: t.accentEdit,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: t.surfaceHigh,
                  builder: (_) => DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    maxChildSize: 0.9,
                    minChildSize: 0.3,
                    expand: false,
                    builder: (_, scrollController) => SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Img2ImgSettingsPanel(
                          promptController: _promptController,
                          negativePromptController: _negativePromptController,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.tune, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildResultView(Uint8List resultBytes, Img2ImgNotifier img2imgNotifier) {
    final t = context.t;
    final l = context.l;

    return Container(
      color: t.background,
      child: Column(
        children: [
          // Result image
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.memory(
                resultBytes,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),

          // Action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back to canvas
                TextButton.icon(
                  onPressed: () => setState(() => _showResult = false),
                  icon: const Icon(Icons.brush, size: 14),
                  label: Text(l.img2imgCanvas),
                  style: TextButton.styleFrom(
                    foregroundColor: t.textTertiary,
                    textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                const SizedBox(width: 16),
                // Use as source
                ElevatedButton.icon(
                  onPressed: () async {
                    await img2imgNotifier.useResultAsSource();
                    setState(() => _showResult = false);
                  },
                  icon: const Icon(Icons.refresh, size: 14),
                  label: Text(l.img2imgUseAsSource),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentEdit,
                    foregroundColor: t.textPrimary,
                    textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Img2ImgNotifier img2imgNotifier,
    GenerationNotifier genNotifier,
    bool isLoading,
  ) {
    final t = context.t;
    final l = context.l;
    final session = img2imgNotifier.session;
    final hasResult = session?.resultImageBytes != null;
    final ml = context.watch<MLNotifier>();

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
            onPressed: () => img2imgNotifier.clearSession(),
            tooltip: l.img2imgBackToPicker,
          ),
          const Spacer(),

          // Edit in Canvas button (only when session exists)
          if (session != null) ...[
            SizedBox(
              height: 36,
              child: isMobile(context)
                  ? IconButton(
                      onPressed: () => _openCanvasEditor(context, img2imgNotifier),
                      icon: const Icon(Icons.palette, size: 14),
                      tooltip: l.canvasEditInCanvas,
                      style: IconButton.styleFrom(foregroundColor: t.accentEdit),
                    )
                  : TextButton.icon(
                      onPressed: () => _openCanvasEditor(context, img2imgNotifier),
                      icon: Icon(Icons.palette, size: 14),
                      label: Text(l.canvasEditInCanvas),
                      style: TextButton.styleFrom(
                        foregroundColor: t.accentEdit,
                        textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
          ],

          // ML: Remove BG button
          if (session != null && ml.hasBgRemovalModel) ...[
            SizedBox(
              height: 36,
              child: ml.isProcessing
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : TextButton.icon(
                      onPressed: () => _handleMLRemoveBg(img2imgNotifier),
                      icon: Icon(Icons.content_cut, size: 14),
                      label: isMobile(context) ? const SizedBox.shrink() : Text(context.l.mlRemoveBg.toUpperCase()),
                      style: TextButton.styleFrom(
                        foregroundColor: t.accent,
                        textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
          ],

          // ML: Upscale button (only when result exists)
          if (hasResult && ml.hasUpscaleModel) ...[
            SizedBox(
              height: 36,
              child: ml.isProcessing
                  ? const SizedBox.shrink()
                  : TextButton.icon(
                      onPressed: () => _handleMLUpscale(img2imgNotifier),
                      icon: Icon(Icons.zoom_out_map, size: 14),
                      label: isMobile(context) ? const SizedBox.shrink() : Text(context.l.mlUpscale.toUpperCase()),
                      style: TextButton.styleFrom(
                        foregroundColor: t.accent,
                        textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
          ],

          // ML: Segment button
          if (session != null && ml.selectedSegmentationModelId != null) ...[
            SizedBox(
              height: 36,
              child: ml.isProcessing
                  ? const SizedBox.shrink()
                  : TextButton.icon(
                      onPressed: () => _handleMLSegment(img2imgNotifier),
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: isMobile(context) ? const SizedBox.shrink() : Text(context.l.mlSegment.toUpperCase()),
                      style: TextButton.styleFrom(
                        foregroundColor: t.accent,
                        textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
          ],

          // Result / Canvas toggle (only when result exists)
          if (hasResult) ...[
            SizedBox(
              height: 36,
              child: IconButton(
                onPressed: () => setState(() => _showResult = !_showResult),
                icon: Icon(Icons.swap_horiz, size: 18),
                tooltip: _showResult ? l.img2imgCanvas : l.img2imgResult,
                style: IconButton.styleFrom(
                  foregroundColor: t.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],

          // Generate button — icon-only on mobile
          if (isMobile(context))
            SizedBox(
              height: 36,
              child: IconButton(
                onPressed: isLoading ? null : () => _generate(img2imgNotifier, genNotifier),
                icon: isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.background),
                      )
                    : const Icon(Icons.auto_awesome, size: 14),
                tooltip: isLoading ? l.img2imgGenerating : l.img2imgGenerate,
                style: IconButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.background,
                ),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _generate(img2imgNotifier, genNotifier),
                icon: isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.background),
                      )
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(isLoading ? l.img2imgGenerating : l.img2imgGenerate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.background,
                  textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openCanvasEditor(BuildContext context, Img2ImgNotifier img2imgNotifier) async {
    final session = img2imgNotifier.session;
    if (session == null) return;

    final canvasNotifier = context.read<CanvasNotifier>();

    // Check for sidecar canvas state from a previous flatten
    if (session.sourceFilePath != null) {
      final restored =
          await CanvasGalleryService.loadSession(session.sourceFilePath!);
      if (restored != null) {
        canvasNotifier.restoreSession(restored);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CanvasEditor()),
        );
        return;
      }
    }

    // No sidecar — fresh session
    canvasNotifier.startSession(
      session.sourceImageBytes,
      session.sourceWidth,
      session.sourceHeight,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CanvasEditor()),
    );
  }

  Future<void> _handleMLRemoveBg(Img2ImgNotifier img2imgNotifier) async {
    final session = img2imgNotifier.session;
    if (session == null) return;

    final ml = context.read<MLNotifier>();
    // Process whichever image is currently displayed
    final imageBytes = (_showResult && session.resultImageBytes != null)
        ? session.resultImageBytes!
        : session.sourceImageBytes;

    final result = await ml.removeBackground(imageBytes);
    if (result != null && mounted) {
      await img2imgNotifier.replaceSourceImage(result);
      setState(() => _showResult = false);
    }
  }

  Future<void> _handleMLUpscale(Img2ImgNotifier img2imgNotifier) async {
    final session = img2imgNotifier.session;
    if (session == null || session.resultImageBytes == null) return;

    final ml = context.read<MLNotifier>();
    final result = await ml.upscaleImage(session.resultImageBytes!);
    if (result != null && mounted) {
      await img2imgNotifier.replaceSourceImage(result);
      setState(() => _showResult = false);
    }
  }

  void _handleMLSegment(Img2ImgNotifier img2imgNotifier) {
    final session = img2imgNotifier.session;
    if (session == null) return;

    final imageBytes = (_showResult && session.resultImageBytes != null)
        ? session.resultImageBytes!
        : session.sourceImageBytes;

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
                  await img2imgNotifier.replaceSourceImage(resultBytes);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    setState(() => _showResult = false);
                  }
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

  Future<void> _generate(
    Img2ImgNotifier img2imgNotifier,
    GenerationNotifier genNotifier,
  ) async {
    final session = img2imgNotifier.session;
    if (session == null) return;

    genNotifier.setLoading(true);

    // Sync prompt text to session
    img2imgNotifier.setPrompt(_promptController.text);
    img2imgNotifier.setNegativePrompt(_negativePromptController.text);

    try {
      // Build the request using current generation settings for resolution
      final genState = genNotifier.state;
      final request = await Img2ImgRequestBuilder.build(
        session: session.copyWith(
          prompt: _promptController.text,
          negativePrompt: _negativePromptController.text,
        ),
        targetWidth: session.sourceWidth,
        targetHeight: session.sourceHeight,
        scale: genState.scale,
        steps: genState.steps.toInt(),
        sampler: genState.sampler,
      );

      final resultBytes = await genNotifier.generateImg2Img(
        request,
        sourceImageBytes: session.sourceImageBytes,
      );

      // Show result in the editor if generation succeeded
      if (resultBytes != null) {
        img2imgNotifier.setResultImage(resultBytes);
        setState(() => _showResult = true);
      }
    } catch (e) {
      genNotifier.setLoading(false);
      debugPrint('Img2Img generate error: $e');
      if (mounted) {
        showErrorSnackBar(context, context.l.img2imgGenerationFailed(e.toString()));
      }
    }
  }
}
