import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';
import '../../utils/responsive.dart';

class UpscaleComparisonView extends StatefulWidget {
  final Uint8List originalBytes;
  final Uint8List upscaledBytes;
  final String outputName;
  final VoidCallback onSave;

  const UpscaleComparisonView({
    super.key,
    required this.originalBytes,
    required this.upscaledBytes,
    required this.outputName,
    required this.onSave,
  });

  @override
  State<UpscaleComparisonView> createState() => _UpscaleComparisonViewState();
}

class _UpscaleComparisonViewState extends State<UpscaleComparisonView> {
  double _sliderPosition = 0.5;
  final TransformationController _transformController = TransformationController();
  ui.Image? _originalImage;
  ui.Image? _upscaledImage;
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _decodeImages();
  }

  @override
  void dispose() {
    _transformController.dispose();
    _originalImage?.dispose();
    _upscaledImage?.dispose();
    super.dispose();
  }

  Future<void> _decodeImages() async {
    final original = await _decodeImage(widget.originalBytes);
    final upscaled = await _decodeImage(widget.upscaledBytes);
    if (mounted) {
      setState(() {
        _originalImage = original;
        _upscaledImage = upscaled;
        _loading = false;
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _handleSave() {
    if (_saved) return;
    widget.onSave();
    setState(() => _saved = true);
    final t = context.tRead;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('SAVED: ${widget.outputName}',
          style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(11))),
      backgroundColor: const Color(0xFF0A1A0A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: t.accentSuccess.withValues(alpha: 0.3)),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        toolbarHeight: mobile ? 48 : 32,
        leading: IconButton(
          icon: Icon(Icons.close, size: mobile ? 22 : 16, color: t.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'UPSCALE COMPARE',
          style: TextStyle(
            letterSpacing: 4,
            fontSize: t.fontSize(mobile ? 14 : 10),
            fontWeight: FontWeight.w900,
            color: t.textSecondary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saved ? null : _handleSave,
            child: Text(
              _saved ? 'SAVED' : 'SAVE',
              style: TextStyle(
                color: _saved ? t.textDisabled : t.accentSuccess,
                fontSize: t.fontSize(mobile ? 12 : 9),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.accent))
          : LayoutBuilder(
              builder: (context, constraints) {
                return _buildComparisonBody(constraints, mobile);
              },
            ),
    );
  }

  Widget _buildComparisonBody(BoxConstraints constraints, bool mobile) {
    final vt = context.t;
    final upW = _upscaledImage!.width.toDouble();
    final upH = _upscaledImage!.height.toDouble();

    return Stack(
      children: [
        // Interactive viewer with both images
        InteractiveViewer(
          transformationController: _transformController,
          maxScale: 16.0,
          minScale: 0.1,
          constrained: false,
          child: SizedBox(
            width: upW,
            height: upH,
            child: CustomPaint(
              painter: _ComparisonPainter(
                original: _originalImage!,
                upscaled: _upscaledImage!,
                sliderFraction: _sliderPosition,
              ),
              size: Size(upW, upH),
            ),
          ),
        ),
        // Slider overlay
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sliderPosition = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
              });
            },
            onHorizontalDragStart: (details) {
              setState(() {
                _sliderPosition = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
              });
            },
            child: CustomPaint(
              painter: _SliderLinePainter(
                fraction: _sliderPosition,
                color: vt.accent,
              ),
            ),
          ),
        ),
        // Labels
        Positioned(
          left: 8,
          bottom: 8,
          child: _buildLabel('BEFORE', vt),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: _buildLabel('AFTER', vt),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, dynamic vt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: vt.fontSize(10),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _ComparisonPainter extends CustomPainter {
  final ui.Image original;
  final ui.Image upscaled;
  final double sliderFraction;

  _ComparisonPainter({
    required this.original,
    required this.upscaled,
    required this.sliderFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;

    // Draw upscaled as the full background (right/after side)
    canvas.drawImage(upscaled, Offset.zero, paint);

    // Clip left side for original (before) — scaled up to match upscaled dimensions
    final splitX = size.width * sliderFraction;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, splitX, size.height));

    // Draw original scaled to upscaled dimensions (nearest-neighbor via FilterQuality.none)
    final srcRect = Rect.fromLTWH(0, 0, original.width.toDouble(), original.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(original, srcRect, dstRect, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ComparisonPainter oldDelegate) {
    return oldDelegate.sliderFraction != sliderFraction;
  }
}

class _SliderLinePainter extends CustomPainter {
  final double fraction;
  final Color color;

  _SliderLinePainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * fraction;

    // Vertical line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);

    // Circular handle
    final handlePaint = Paint()..color = color;
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final center = Offset(x, size.height / 2);
    canvas.drawCircle(center, 14, handlePaint);
    canvas.drawCircle(center, 14, outlinePaint);

    // Arrow icons on handle
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    // Left arrow
    canvas.drawLine(Offset(x - 5, center.dy), Offset(x - 2, center.dy - 4), arrowPaint);
    canvas.drawLine(Offset(x - 5, center.dy), Offset(x - 2, center.dy + 4), arrowPaint);
    // Right arrow
    canvas.drawLine(Offset(x + 5, center.dy), Offset(x + 2, center.dy - 4), arrowPaint);
    canvas.drawLine(Offset(x + 5, center.dy), Offset(x + 2, center.dy + 4), arrowPaint);
  }

  @override
  bool shouldRepaint(_SliderLinePainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
