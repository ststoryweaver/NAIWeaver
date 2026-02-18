import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/canvas_notifier.dart';
import 'canvas_color_picker.dart';

/// Bottom toolbar for the canvas editor.
/// Desktop: single row with all controls.
/// Mobile: compact layout with sliders below.
class CanvasToolbar extends StatefulWidget {
  final VoidCallback onFlatten;
  final VoidCallback? onShowLayers;

  const CanvasToolbar({super.key, required this.onFlatten, this.onShowLayers});

  @override
  State<CanvasToolbar> createState() => _CanvasToolbarState();
}

class _CanvasToolbarState extends State<CanvasToolbar> {
  bool _showColorPicker = false;

  // Logarithmic size slider mapping
  static const double _minRadius = 0.002;
  static const double _maxRadius = 0.15;

  double _radiusToSlider(double radius) {
    final clamped = radius.clamp(_minRadius, _maxRadius);
    return (log(clamped) - log(_minRadius)) / (log(_maxRadius) - log(_minRadius));
  }

  double _sliderToRadius(double t) {
    return _minRadius * pow(_maxRadius / _minRadius, t);
  }

  // Numeric input controllers (desktop only)
  late final TextEditingController _sizeController;
  late final TextEditingController _opacityController;
  late final FocusNode _sizeFocus;
  late final FocusNode _opacityFocus;

  @override
  void initState() {
    super.initState();
    _sizeController = TextEditingController();
    _opacityController = TextEditingController();
    _sizeFocus = FocusNode();
    _opacityFocus = FocusNode();
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _opacityController.dispose();
    _sizeFocus.dispose();
    _opacityFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CanvasNotifier>();
    final session = notifier.session;
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    if (session == null) return const SizedBox.shrink();

    // Update controllers when not focused
    if (!_sizeFocus.hasFocus) {
      _sizeController.text = (notifier.brushRadius * 100).toStringAsFixed(1);
    }
    if (!_opacityFocus.hasFocus) {
      _opacityController.text = (notifier.brushOpacity * 100).round().toString();
    }

    if (mobile) {
      return _buildMobileToolbar(t, l, notifier);
    }
    return _buildDesktopToolbar(t, l, notifier);
  }

  Widget _buildDesktopToolbar(dynamic t, dynamic l, CanvasNotifier notifier) {
    final session = notifier.session!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Paint tool
                      _ToolButton(
                        icon: Icons.brush,
                        label: l.canvasPaint,
                        isActive: notifier.tool == CanvasTool.paint,
                        onTap: () => notifier.setTool(CanvasTool.paint),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Erase tool
                      _ToolButton(
                        icon: Icons.auto_fix_high,
                        label: l.canvasErase,
                        isActive: notifier.tool == CanvasTool.erase,
                        onTap: () => notifier.setTool(CanvasTool.erase),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Line tool
                      _ToolButton(
                        icon: Icons.horizontal_rule,
                        label: l.canvasLine,
                        isActive: notifier.tool == CanvasTool.line,
                        onTap: () => notifier.setTool(CanvasTool.line),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Rectangle tool
                      _ToolButton(
                        icon: Icons.crop_square,
                        label: l.canvasRectangle,
                        isActive: notifier.tool == CanvasTool.rectangle,
                        onTap: () => notifier.setTool(CanvasTool.rectangle),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Circle tool
                      _ToolButton(
                        icon: Icons.circle_outlined,
                        label: l.canvasCircle,
                        isActive: notifier.tool == CanvasTool.circle,
                        onTap: () => notifier.setTool(CanvasTool.circle),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Fill tool
                      _ToolButton(
                        icon: Icons.format_color_fill,
                        label: l.canvasFill,
                        isActive: notifier.tool == CanvasTool.fill,
                        onTap: () => notifier.setTool(CanvasTool.fill),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Text tool
                      _ToolButton(
                        icon: Icons.text_fields,
                        label: l.canvasText,
                        isActive: notifier.tool == CanvasTool.text,
                        onTap: () => notifier.setTool(CanvasTool.text),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Eyedropper tool
                      _ToolButton(
                        icon: Icons.colorize,
                        label: l.canvasEyedropper,
                        isActive: notifier.tool == CanvasTool.eyedropper,
                        onTap: () => notifier.setTool(CanvasTool.eyedropper),
                        t: t,
                      ),
                      const SizedBox(width: 4),
                      // Smooth toggle
                      _ToolButton(
                        icon: Icons.gesture,
                        label: l.canvasSmooth,
                        isActive: notifier.smoothStrokes,
                        onTap: notifier.toggleSmoothStrokes,
                        t: t,
                      ),

                      const SizedBox(width: 12),
                      Container(width: 1, height: 24, color: t.borderSubtle),
                      const SizedBox(width: 12),

                      // Color picker
                      if (_showColorPicker)
                        CanvasColorPicker(
                          currentColor: notifier.brushColorAsColor,
                          opacity: notifier.brushOpacity,
                          onColorChanged: (c) => notifier.setBrushColor(c.toARGB32()),
                          onOpacityChanged: notifier.setBrushOpacity,
                        )
                      else ...[
                        // Color swatch (tap to toggle picker)
                        GestureDetector(
                          onTap: () => setState(() => _showColorPicker = !_showColorPicker),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: notifier.brushColorAsColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: t.borderMedium, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Size slider + numeric input
                        Text(
                          l.canvasSize,
                          style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: t.textDisabled,
                              inactiveTrackColor: t.textMinimal,
                              thumbColor: t.textPrimary,
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: _radiusToSlider(notifier.brushRadius),
                              min: 0.0,
                              max: 1.0,
                              onChanged: (t) => notifier.setBrushRadius(_sliderToRadius(t)),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 24,
                          child: TextField(
                            controller: _sizeController,
                            focusNode: _sizeFocus,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(8)),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              suffixText: '%',
                              suffixStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: t.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: t.borderSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: t.accentEdit),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null) {
                                notifier.setBrushRadius(parsed / 100);
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Opacity slider + numeric input
                        Text(
                          l.canvasOpacity,
                          style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: t.textDisabled,
                              inactiveTrackColor: t.textMinimal,
                              thumbColor: t.textPrimary,
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: notifier.brushOpacity,
                              min: 0.05,
                              max: 1.0,
                              onChanged: notifier.setBrushOpacity,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 24,
                          child: TextField(
                            controller: _opacityController,
                            focusNode: _opacityFocus,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(8)),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              suffixText: '%',
                              suffixStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: t.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: t.borderSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(3),
                                borderSide: BorderSide(color: t.accentEdit),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null) {
                                notifier.setBrushOpacity(parsed / 100);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Undo
              IconButton(
                icon: Icon(Icons.undo, size: 16, color: t.textTertiary),
                onPressed: session.canUndo ? notifier.undo : null,
                tooltip: l.canvasUndo,
                splashRadius: 16,
              ),
              // Redo
              IconButton(
                icon: Icon(Icons.redo, size: 16, color: t.textTertiary),
                onPressed: session.canRedo ? notifier.redo : null,
                tooltip: l.canvasRedo,
                splashRadius: 16,
              ),

              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: t.borderSubtle),
              const SizedBox(width: 8),

              // Active layer name indicator
              if (session.activeLayer != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers, size: 12, color: t.textMinimal),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          session.activeLayer!.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.textDisabled,
                            fontSize: t.fontSize(8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Flatten & Send
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: session.hasStrokes ? widget.onFlatten : null,
                  icon: const Icon(Icons.check, size: 14),
                  label: Text(l.canvasFlattenSend),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentEdit,
                    foregroundColor: t.textPrimary,
                    disabledBackgroundColor: t.surfaceHigh,
                    disabledForegroundColor: t.textMinimal,
                    textStyle: TextStyle(
                      fontSize: t.fontSize(9),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          // Expanded color picker below toolbar row
          if (_showColorPicker) ...[
            const SizedBox(height: 8),
            CanvasColorPicker(
              currentColor: notifier.brushColorAsColor,
              opacity: notifier.brushOpacity,
              onColorChanged: (c) => notifier.setBrushColor(c.toARGB32()),
              onOpacityChanged: notifier.setBrushOpacity,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileToolbar(dynamic t, dynamic l, CanvasNotifier notifier) {
    final session = notifier.session!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: tools + color swatch + flatten button
          Row(
            children: [
              _ToolButton(
                icon: Icons.brush,
                label: l.canvasPaint,
                isActive: notifier.tool == CanvasTool.paint,
                onTap: () => notifier.setTool(CanvasTool.paint),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.auto_fix_high,
                label: l.canvasErase,
                isActive: notifier.tool == CanvasTool.erase,
                onTap: () => notifier.setTool(CanvasTool.erase),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.horizontal_rule,
                label: l.canvasLine,
                isActive: notifier.tool == CanvasTool.line,
                onTap: () => notifier.setTool(CanvasTool.line),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.crop_square,
                label: l.canvasRectangle,
                isActive: notifier.tool == CanvasTool.rectangle,
                onTap: () => notifier.setTool(CanvasTool.rectangle),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.circle_outlined,
                label: l.canvasCircle,
                isActive: notifier.tool == CanvasTool.circle,
                onTap: () => notifier.setTool(CanvasTool.circle),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.format_color_fill,
                label: l.canvasFill,
                isActive: notifier.tool == CanvasTool.fill,
                onTap: () => notifier.setTool(CanvasTool.fill),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.text_fields,
                label: l.canvasText,
                isActive: notifier.tool == CanvasTool.text,
                onTap: () => notifier.setTool(CanvasTool.text),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.colorize,
                label: l.canvasEyedropper,
                isActive: notifier.tool == CanvasTool.eyedropper,
                onTap: () => notifier.setTool(CanvasTool.eyedropper),
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.gesture,
                label: l.canvasSmooth,
                isActive: notifier.smoothStrokes,
                onTap: notifier.toggleSmoothStrokes,
                t: t,
                iconOnly: true,
              ),
              const SizedBox(width: 8),
              // Color swatch
              GestureDetector(
                onTap: () => setState(() => _showColorPicker = !_showColorPicker),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: notifier.brushColorAsColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: t.borderMedium, width: 1.5),
                  ),
                ),
              ),
              const Spacer(),
              // Flatten button
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: session.hasStrokes ? widget.onFlatten : null,
                  icon: const Icon(Icons.check, size: 14),
                  label: Text(l.canvasFlatten),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentEdit,
                    foregroundColor: t.textPrimary,
                    disabledBackgroundColor: t.surfaceHigh,
                    disabledForegroundColor: t.textMinimal,
                    textStyle: TextStyle(
                      fontSize: t.fontSize(8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: size slider + value | opacity slider + value
          Row(
            children: [
              Text(
                l.canvasSize,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(7), letterSpacing: 1),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: t.textDisabled,
                    inactiveTrackColor: t.textMinimal,
                    thumbColor: t.textPrimary,
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _radiusToSlider(notifier.brushRadius),
                    min: 0.0,
                    max: 1.0,
                    onChanged: (t) => notifier.setBrushRadius(_sliderToRadius(t)),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(notifier.brushRadius * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(7)),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.canvasOpacity,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(7), letterSpacing: 1),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: t.textDisabled,
                    inactiveTrackColor: t.textMinimal,
                    thumbColor: t.textPrimary,
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: notifier.brushOpacity,
                    min: 0.05,
                    max: 1.0,
                    onChanged: notifier.setBrushOpacity,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '${(notifier.brushOpacity * 100).round()}%',
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(7)),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Row 3: undo/redo + layers button
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.undo, size: 18, color: t.textTertiary),
                onPressed: session.canUndo ? notifier.undo : null,
                splashRadius: 16,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.redo, size: 18, color: t.textTertiary),
                onPressed: session.canRedo ? notifier.redo : null,
                splashRadius: 16,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              if (widget.onShowLayers != null)
                GestureDetector(
                  onTap: widget.onShowLayers,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.surfaceHigh,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: t.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers, size: 16, color: t.textTertiary),
                        const SizedBox(width: 6),
                        if (session.activeLayer != null)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 80),
                            child: Text(
                              session.activeLayer!.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.textDisabled,
                                fontSize: t.fontSize(8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: t.accentEdit.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${session.layers.length}',
                            style: TextStyle(
                              color: t.accentEdit,
                              fontSize: t.fontSize(7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Color picker (if expanded)
          if (_showColorPicker) ...[
            const SizedBox(height: 4),
            CanvasColorPicker(
              currentColor: notifier.brushColorAsColor,
              opacity: notifier.brushOpacity,
              onColorChanged: (c) => notifier.setBrushColor(c.toARGB32()),
              onOpacityChanged: notifier.setBrushOpacity,
              compact: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final dynamic t;
  final bool iconOnly;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.t,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: iconOnly ? 6 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? t.accentEdit.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? t.accentEdit : Colors.transparent,
            width: 1,
          ),
        ),
        child: iconOnly
            ? Icon(
                icon,
                size: 16,
                color: isActive ? t.accentEdit : t.textTertiary,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive ? t.accentEdit : t.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? t.accentEdit : t.textTertiary,
                      fontSize: t.fontSize(8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (iconOnly) {
      return Tooltip(message: label, child: button);
    }
    return button;
  }
}
