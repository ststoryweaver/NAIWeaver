import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/checkerboard.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';

class ImagePreviewViewer extends StatefulWidget {
  final Uint8List? generatedImage;
  final bool isLoading;
  final bool isDragging;
  final Animation<double> pulseAnimation;

  const ImagePreviewViewer({
    super.key,
    required this.generatedImage,
    required this.isLoading,
    required this.isDragging,
    required this.pulseAnimation,
  });

  @override
  State<ImagePreviewViewer> createState() => _ImagePreviewViewerState();
}

class _ImagePreviewViewerState extends State<ImagePreviewViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late final AnimationController _zoomAnimController;
  Animation<Matrix4>? _zoomAnimation;
  Offset? _lastDoubleTapLocal;

  /// Whether the current image has genuinely transparent pixels, and its
  /// aspect ratio. Both are derived from the bytes, so they are computed once
  /// per image in [_analyseImage] rather than on every build — the
  /// transparency check decodes the PNG.
  bool _hasTransparency = false;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _analyseImage();
    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void didUpdateWidget(ImagePreviewViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset zoom when image changes
    if (oldWidget.generatedImage != widget.generatedImage) {
      _zoomAnimController.stop();
      _transformController.value = Matrix4.identity();
      _analyseImage();
    }
  }

  /// Recomputes the cached transparency flag and aspect ratio for the current
  /// image. Cheap header parse for the size; full decode for transparency, so
  /// it runs only when the image actually changes.
  void _analyseImage() {
    final bytes = widget.generatedImage;
    if (bytes == null) {
      _hasTransparency = false;
      _aspectRatio = null;
      return;
    }
    final size = pngSize(bytes);
    _aspectRatio = size == null ? null : size.width / size.height;
    // Only pay for the decode when the encoding could carry alpha at all.
    _hasTransparency = pngHasTransparentPixels(bytes);
  }

  /// The image, with a transparency checkerboard sized to the image itself.
  ///
  /// The checkerboard used to be a Positioned.fill sibling of the image, which
  /// stretched it across the whole preview box while BoxFit.contain letterboxed
  /// the image inside it — so the grid bled into the empty bands (most visible
  /// as a strip under the image on Android portrait, where the preview reserves
  /// room for the prompt sheet). Wrapping both in one AspectRatio keeps the
  /// checkerboard behind the pixels and nowhere else.
  Widget _buildImage(VisionTokens t) {
    final image = Image.memory(
      widget.generatedImage!,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // Bytes that pass the API-layer signature check can still be a truncated
      // image; degrade to a placeholder instead of an error widget (issue #24).
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: t.textPrimary.withValues(alpha: 0.2),
      ),
    );

    // V5 can return real RGBA; show a checkerboard so a transparent background
    // reads as transparent. Opaque renders get no grid at all.
    if (!_hasTransparency) return image;

    final checkered = Stack(
      fit: StackFit.passthrough,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: CheckerboardPainter()),
        ),
        image,
      ],
    );

    final ratio = _aspectRatio;
    if (ratio == null) return checkered;
    return AspectRatio(aspectRatio: ratio, child: checkered);
  }

  @override
  void dispose() {
    _zoomAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final current = _transformController.value.clone();
    final scale = current.getMaxScaleOnAxis();

    Matrix4 target;
    if (scale > 1.05) {
      // Zoomed in → animate back to identity
      target = Matrix4.identity();
    } else {
      // Zoomed out → animate to 2x centered on tap position
      const zoomScale = 2.5;
      final pos = _lastDoubleTapLocal ?? Offset.zero;
      // Translate so the tapped point stays in place after scaling
      final dx = pos.dx * (1 - zoomScale);
      final dy = pos.dy * (1 - zoomScale);
      // ignore: deprecated_member_use
      target = Matrix4.identity()..translate(dx, dy, 0.0)..scale(zoomScale, zoomScale, 1.0);
    }

    _zoomAnimation = Matrix4Tween(begin: current, end: target).animate(
      CurvedAnimation(parent: _zoomAnimController, curve: Curves.easeOutCubic),
    );
    _zoomAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: widget.pulseAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            decoration: BoxDecoration(
              color: t.textPrimary.withValues(alpha: 0.01),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isLoading
                  ? t.textPrimary.withValues(alpha: widget.pulseAnimation.value)
                  : (widget.isDragging ? t.accent : t.borderSubtle),
                width: (widget.isLoading || widget.isDragging) ? 2 : 1,
              ),
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              if (widget.generatedImage != null)
                GestureDetector(
                  onDoubleTapDown: (details) => _lastDoubleTapLocal = details.localPosition,
                  onDoubleTap: _handleDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: _buildImage(t),
                    ),
                  ),
                )
              else
                Center(child: Icon(Icons.blur_on, size: 40, color: t.textPrimary.withValues(alpha: 0.03))),
              if (widget.isDragging)
                Container(
                  color: t.background.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download, size: 48, color: t.textPrimary),
                        const SizedBox(height: 16),
                        Text("DROP TO IMPORT SETTINGS", style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(12), letterSpacing: 2, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
