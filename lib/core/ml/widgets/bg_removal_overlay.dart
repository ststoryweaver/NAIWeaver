import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/vision_slider.dart';
import '../../utils/responsive.dart';
import '../ml_model_entry.dart';
import '../ml_model_registry.dart';
import '../ml_notifier.dart';

class BGRemovalOverlay extends StatefulWidget {
  final Uint8List resultImage;
  final void Function(Uint8List finalImage) onSave;
  final VoidCallback onDiscard;
  final void Function(Uint8List finalImage)? onSendToCanvas;
  final bool autoSave;

  const BGRemovalOverlay({
    super.key,
    required this.resultImage,
    required this.onSave,
    required this.onDiscard,
    this.onSendToCanvas,
    this.autoSave = false,
  });

  @override
  State<BGRemovalOverlay> createState() => _BGRemovalOverlayState();
}

class _BGRemovalOverlayState extends State<BGRemovalOverlay> {
  // Binary mask controls
  double _threshold = 0.5;
  double _featherRadius = 0;
  // Alpha matte controls
  double _opacityMultiplier = 1.0;
  double _edgeRefinement = 0;

  Uint8List? _previewImage;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _previewImage = widget.resultImage;
  }

  bool get _isMatteMode {
    final ml = context.read<MLNotifier>();
    final modelId = ml.selectedBgRemovalModelId;
    if (modelId == null) return false;
    final config = MLModelRegistry.configFor(modelId);
    return config?.outputType == MLOutputType.alphaMatte;
  }

  Future<void> _updatePreview() async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      final ml = context.read<MLNotifier>();
      final Uint8List? updated;
      if (_isMatteMode) {
        updated = await ml.reapplyBgMatte(
          opacityMultiplier: _opacityMultiplier,
          edgeRefinementRadius: _edgeRefinement,
        );
      } else {
        updated = await ml.reapplyBgMask(
          threshold: _threshold,
          featherRadius: _featherRadius,
        );
      }
      if (mounted) {
        setState(() => _previewImage = updated);
      }
    } catch (e) {
      debugPrint('BG preview update error: $e');
    } finally {
      _isUpdating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    final isMatte = _isMatteMode;

    return Column(
      children: [
        // Preview area with checkerboard background
        Expanded(
          child: Container(
            color: t.background,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Checkerboard pattern behind transparent areas
                CustomPaint(painter: _CheckerboardPainter()),
                // Result image
                if (_previewImage != null)
                  FittedBox(
                    fit: BoxFit.contain,
                    child: Image.memory(
                      _previewImage!,
                      gaplessPlayback: true,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Toolbar
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 16 : 12,
            vertical: mobile ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: t.surfaceHigh,
            border: Border(top: BorderSide(color: t.borderSubtle)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMatte) ...[
                // Opacity slider (matte mode)
                _SliderRow(
                  label: 'OPACITY',
                  value: _opacityMultiplier,
                  min: 0.0,
                  max: 1.0,
                  valueLabel: _opacityMultiplier.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => _opacityMultiplier = v);
                    _updatePreview();
                  },
                ),
                // Edge refinement slider (matte mode)
                _SliderRow(
                  label: 'EDGE REFINE',
                  value: _edgeRefinement,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  valueLabel: '${_edgeRefinement.round()}px',
                  onChanged: (v) {
                    setState(() => _edgeRefinement = v);
                    _updatePreview();
                  },
                ),
              ] else ...[
                // Threshold slider (binary mask mode)
                _SliderRow(
                  label: 'THRESHOLD',
                  value: _threshold,
                  min: 0.0,
                  max: 1.0,
                  valueLabel: _threshold.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => _threshold = v);
                    _updatePreview();
                  },
                ),
                // Feather slider (binary mask mode)
                _SliderRow(
                  label: 'FEATHER',
                  value: _featherRadius,
                  min: 0,
                  max: 20,
                  divisions: 20,
                  valueLabel: '${_featherRadius.round()}px',
                  onChanged: (v) {
                    setState(() => _featherRadius = v);
                    _updatePreview();
                  },
                ),
              ],
              const SizedBox(height: 8),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<MLNotifier>().clearBgResult();
                      widget.onDiscard();
                    },
                    child: Text(
                      'DISCARD',
                      style: TextStyle(
                        color: t.textDisabled,
                        fontSize: t.fontSize(mobile ? 10 : 8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (widget.onSendToCanvas != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        widget.onSendToCanvas!(_previewImage ?? widget.resultImage);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.accentEdit,
                        side: BorderSide(color: t.accentEdit),
                        textStyle: TextStyle(
                          fontSize: t.fontSize(mobile ? 10 : 8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('CANVAS'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_previewImage ?? widget.resultImage);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.accent,
                      foregroundColor: t.background,
                      textStyle: TextStyle(
                        fontSize: t.fontSize(mobile ? 10 : 8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: Text(widget.autoSave ? 'DONE' : 'SAVE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);

    return Row(
      children: [
        SizedBox(
          width: mobile ? 80 : 70,
          child: Text(
            label,
            style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(mobile ? 9 : 7),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: VisionSlider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: t.accent,
            inactiveColor: t.borderMedium,
            thumbColor: t.accent,
            thumbRadius: 6,
            overlayRadius: 12,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            valueLabel,
            style: TextStyle(
              color: t.textSecondary,
              fontSize: t.fontSize(mobile ? 10 : 8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 12.0;
    final lightPaint = Paint()..color = const Color(0xFF3A3A3A);
    final darkPaint = Paint()..color = const Color(0xFF2A2A2A);

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isLight = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isLight ? lightPaint : darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
