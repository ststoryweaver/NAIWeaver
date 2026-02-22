import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/widgets/vision_slider.dart';

/// Inline HSV color picker for the canvas toolbar.
/// Collapsed: color swatch + quick palette row.
/// Expanded: SV rectangle + hue bar + opacity slider + palette + hex input.
class CanvasColorPicker extends StatefulWidget {
  final Color currentColor;
  final double opacity;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onOpacityChanged;
  final bool compact;

  const CanvasColorPicker({
    super.key,
    required this.currentColor,
    required this.opacity,
    required this.onColorChanged,
    required this.onOpacityChanged,
    this.compact = true,
  });

  @override
  State<CanvasColorPicker> createState() => _CanvasColorPickerState();
}

class _CanvasColorPickerState extends State<CanvasColorPicker> {
  bool _expanded = false;
  late HSVColor _hsv;
  late TextEditingController _hexController;
  final List<Color> _recentColors = [];

  static const List<Color> _palette = [
    Color(0xFF000000), Color(0xFF1E1E1E), Color(0xFF555555),
    Color(0xFFAAAAAA), Color(0xFFFFFFFF), Color(0xFFFF0066),
    Color(0xFFFF5252), Color(0xFFE91E63), Color(0xFFFF6F00),
    Color(0xFFFFD600), Color(0xFF4CAF50), Color(0xFF00BCD4),
    Color(0xFF3F51B5), Color(0xFF7C4DFF), Color(0xFF1A237E),
    Color(0xFF69F0AE),
  ];

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.currentColor);
    _hexController = TextEditingController(text: _colorToHex(widget.currentColor));
  }

  @override
  void didUpdateWidget(CanvasColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      _hsv = HSVColor.fromColor(widget.currentColor);
      _hexController.text = _colorToHex(widget.currentColor);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    return c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final val = int.tryParse(hex, radix: 16);
    if (val == null) return null;
    return Color(val);
  }

  void _selectColor(Color c) {
    _hsv = HSVColor.fromColor(c);
    _hexController.text = _colorToHex(c);
    widget.onColorChanged(c);
    // Track recent colors
    _recentColors.remove(c);
    _recentColors.insert(0, c);
    if (_recentColors.length > 4) _recentColors.removeLast();
  }

  void _updateFromHSV() {
    final c = _hsv.toColor();
    _hexController.text = _colorToHex(c);
    widget.onColorChanged(c);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final currentColor = _hsv.toColor();

    if (!_expanded) {
      return _buildCollapsed(t, currentColor);
    }
    return _buildExpanded(t, currentColor);
  }

  Widget _buildCollapsed(VisionTokens t, Color currentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current color swatch (tap to expand)
        GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: t.borderMedium, width: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Quick palette row
        ...List.generate(
          math.min(6, _palette.length),
          (i) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => _selectColor(_palette[i]),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _palette[i],
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: _palette[i].toARGB32() == currentColor.toARGB32()
                        ? t.accent
                        : t.borderSubtle,
                    width: _palette[i].toARGB32() == currentColor.toARGB32() ? 2 : 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded(VisionTokens t, Color currentColor) {
    final svHeight = widget.compact ? 140.0 : 180.0;
    final hueHeight = widget.compact ? 20.0 : 28.0;
    final swatchSize = widget.compact ? 24.0 : 32.0;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.borderMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button row
          Row(
            children: [
              Text(
                'COLOR',
                style: TextStyle(
                  color: t.textDisabled,
                  fontSize: t.fontSize(8),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: Icon(Icons.close, size: 14, color: t.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // SV Rectangle
          SizedBox(
            height: svHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (d) => _updateSV(d.localPosition, constraints, svHeight),
                  onPanUpdate: (d) => _updateSV(d.localPosition, constraints, svHeight),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, svHeight),
                    painter: _SVRectPainter(hue: _hsv.hue, saturation: _hsv.saturation, value: _hsv.value),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Hue slider
          SizedBox(
            height: hueHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (d) => _updateHue(d.localPosition.dx, constraints.maxWidth),
                  onPanUpdate: (d) => _updateHue(d.localPosition.dx, constraints.maxWidth),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, hueHeight),
                    painter: _HueBarPainter(hue: _hsv.hue, barHeight: hueHeight),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Opacity slider
          Row(
            children: [
              Text(
                'OPACITY',
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(7), letterSpacing: 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VisionSlider(
                  value: widget.opacity,
                  min: 0.05,
                  onChanged: widget.onOpacityChanged,
                  activeColor: currentColor,
                  inactiveColor: t.textMinimal,
                  thumbColor: t.textPrimary,
                  thumbRadius: 6,
                  overlayRadius: 10,
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(widget.opacity * 100).round()}%',
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(8)),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Palette grid
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _palette.map((c) {
              final isSelected = c.toARGB32() == currentColor.toARGB32();
              return GestureDetector(
                onTap: () => _selectColor(c),
                child: Container(
                  width: swatchSize,
                  height: swatchSize,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isSelected ? t.accent : t.borderSubtle,
                      width: isSelected ? 2 : 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Recent colors
          if (_recentColors.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'RECENT',
                  style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(7), letterSpacing: 1),
                ),
                const SizedBox(width: 8),
                ..._recentColors.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () => _selectColor(c),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: t.borderSubtle, width: 0.5),
                      ),
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Hex input
          Row(
            children: [
              Text('#', style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(12))),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _hexController,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: t.fontSize(11),
                    fontFamily: 'monospace',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: 'FFFFFF',
                    hintStyle: TextStyle(color: t.textMinimal),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: t.borderMedium),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: t.accent),
                    ),
                  ),
                  onChanged: (val) {
                    final c = _hexToColor(val);
                    if (c != null) {
                      setState(() {
                        _hsv = HSVColor.fromColor(c);
                      });
                      widget.onColorChanged(c);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Preview swatch
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: currentColor.withValues(alpha: widget.opacity),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: t.borderMedium),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateSV(Offset local, BoxConstraints constraints, double height) {
    final s = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final v = (1.0 - local.dy / height).clamp(0.0, 1.0);
    setState(() {
      _hsv = HSVColor.fromAHSV(1.0, _hsv.hue, s, v);
    });
    _updateFromHSV();
  }

  void _updateHue(double dx, double width) {
    final hue = (dx / width * 360.0).clamp(0.0, 359.99);
    setState(() {
      _hsv = HSVColor.fromAHSV(1.0, hue, _hsv.saturation, _hsv.value);
    });
    _updateFromHSV();
  }
}

/// Paints the Saturation-Value rectangle with a position indicator.
class _SVRectPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;

  _SVRectPainter({required this.hue, required this.saturation, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    // Base hue gradient (left to right: white to full hue)
    final hueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    final rectGradientH = LinearGradient(
      colors: [Colors.white, hueColor],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = rectGradientH);

    // Value gradient (top to bottom: transparent to black)
    final rectGradientV = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = rectGradientV);

    // Position indicator
    final cx = saturation * size.width;
    final cy = (1.0 - value) * size.height;
    canvas.drawCircle(
      Offset(cx, cy),
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_SVRectPainter old) =>
      hue != old.hue || saturation != old.saturation || value != old.value;
}

/// Paints a horizontal hue spectrum bar with a position indicator.
class _HueBarPainter extends CustomPainter {
  final double hue;
  final double barHeight;

  _HueBarPainter({required this.hue, this.barHeight = 20.0});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Hue spectrum gradient
    final colors = List.generate(7, (i) {
      return HSVColor.fromAHSV(1.0, i * 60.0, 1.0, 1.0).toColor();
    });
    final shader = LinearGradient(colors: colors).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..shader = shader,
    );

    // Position indicator
    final x = (hue / 360.0) * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, size.height / 2), width: 6, height: size.height),
        const Radius.circular(2),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HueBarPainter old) => hue != old.hue;
}
