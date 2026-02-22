import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/vision_slider.dart';
import '../providers/canvas_notifier.dart';
import 'canvas_color_picker.dart';

/// Curated font list for the text tool.
const _fontFamilies = <String?>[
  null, // Default
  'Inter',
  'Roboto',
  'Space Grotesk',
  'Playfair Display',
  'Merriweather',
  'JetBrains Mono',
  'Fira Code',
  'Permanent Marker',
  'Pacifico',
  'Caveat',
];

/// Bottom toolbar for the canvas editor.
/// Desktop: two-row layout (tools + actions, then brush settings).
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

  Widget _buildDesktopToolbar(VisionTokens t, AppLocalizations l, CanvasNotifier notifier) {
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
          // Row 1: tools + color swatch + undo/redo + layer indicator + flatten
          Row(
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
              // Transform tool
              _ToolButton(
                icon: Icons.open_with,
                label: l.canvasTransform,
                isActive: notifier.tool == CanvasTool.transform,
                onTap: () => notifier.setTool(CanvasTool.transform),
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

              // Color swatch (tap to toggle picker)
              Tooltip(
                message: l.canvasColor,
                child: GestureDetector(
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

              const Spacer(),

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
          const SizedBox(height: 4),
          // Row 2: size slider + opacity slider
          Row(
            children: [
              // Size slider + numeric input
              Text(
                l.canvasSize,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VisionSlider.subtle(
                  value: _radiusToSlider(notifier.brushRadius),
                  onChanged: (t) => notifier.setBrushRadius(_sliderToRadius(t)),
                  t: t,
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
              Expanded(
                child: VisionSlider.subtle(
                  value: notifier.brushOpacity,
                  min: 0.05,
                  onChanged: notifier.setBrushOpacity,
                  t: t,
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
          ),
          // Text tool settings row (desktop inline)
          if (notifier.tool == CanvasTool.text) ...[
            const SizedBox(height: 4),
            _buildTextSettingsRow(t, l, notifier),
          ],
          // Expanded color picker below toolbar rows
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

  Widget _buildTextSettingsRow(VisionTokens t, AppLocalizations l, CanvasNotifier notifier) {
    return Row(
      children: [
        // Font dropdown
        Text(
          l.canvasTextFont,
          style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          height: 28,
          child: _FontDropdown(
            value: notifier.pendingTextFontFamily,
            defaultLabel: l.canvasTextDefault,
            onChanged: notifier.setPendingTextFontFamily,
            t: t,
          ),
        ),
        const SizedBox(width: 16),
        // Size slider
        Text(
          l.canvasTextSize,
          style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: VisionSlider.subtle(
            value: notifier.pendingTextFontSize,
            min: 0.01,
            max: 0.20,
            onChanged: notifier.setPendingTextFontSize,
            t: t,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(notifier.pendingTextFontSize * 100).round()}%',
            style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(8)),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 16),
        // Letter spacing slider
        Text(
          l.canvasTextSpacing,
          style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: VisionSlider.subtle(
            value: notifier.pendingTextLetterSpacing,
            min: -0.01,
            max: 0.05,
            onChanged: notifier.setPendingTextLetterSpacing,
            t: t,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            (notifier.pendingTextLetterSpacing * 100).toStringAsFixed(1),
            style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(8)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showTextSettingsSheet(BuildContext context, VisionTokens t, AppLocalizations l, CanvasNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: notifier,
          child: _MobileTextSettingsSheet(t: t, l: l),
        );
      },
    );
  }

  Widget _buildMobileToolbar(VisionTokens t, AppLocalizations l, CanvasNotifier notifier) {
    final session = notifier.session!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: scrollable tools | color swatch | undo/redo | flatten icon
          Row(
            children: [
              // Scrollable tool buttons
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ToolButton(
                        icon: Icons.brush,
                        label: l.canvasPaint,
                        isActive: notifier.tool == CanvasTool.paint,
                        onTap: () => notifier.setTool(CanvasTool.paint),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.auto_fix_high,
                        label: l.canvasErase,
                        isActive: notifier.tool == CanvasTool.erase,
                        onTap: () => notifier.setTool(CanvasTool.erase),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.horizontal_rule,
                        label: l.canvasLine,
                        isActive: notifier.tool == CanvasTool.line,
                        onTap: () => notifier.setTool(CanvasTool.line),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.crop_square,
                        label: l.canvasRectangle,
                        isActive: notifier.tool == CanvasTool.rectangle,
                        onTap: () => notifier.setTool(CanvasTool.rectangle),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.circle_outlined,
                        label: l.canvasCircle,
                        isActive: notifier.tool == CanvasTool.circle,
                        onTap: () => notifier.setTool(CanvasTool.circle),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.format_color_fill,
                        label: l.canvasFill,
                        isActive: notifier.tool == CanvasTool.fill,
                        onTap: () => notifier.setTool(CanvasTool.fill),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.text_fields,
                        label: l.canvasText,
                        isActive: notifier.tool == CanvasTool.text,
                        onTap: () => notifier.setTool(CanvasTool.text),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.colorize,
                        label: l.canvasEyedropper,
                        isActive: notifier.tool == CanvasTool.eyedropper,
                        onTap: () => notifier.setTool(CanvasTool.eyedropper),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.open_with,
                        label: l.canvasTransform,
                        isActive: notifier.tool == CanvasTool.transform,
                        onTap: () => notifier.setTool(CanvasTool.transform),
                        t: t,
                        iconOnly: true,
                      ),
                      const SizedBox(width: 2),
                      _ToolButton(
                        icon: Icons.gesture,
                        label: l.canvasSmooth,
                        isActive: notifier.smoothStrokes,
                        onTap: notifier.toggleSmoothStrokes,
                        t: t,
                        iconOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Color swatch
              Tooltip(
                message: l.canvasColor,
                child: GestureDetector(
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
              ),
              const SizedBox(width: 4),
              // Undo
              IconButton(
                icon: Icon(Icons.undo, size: 18, color: t.textTertiary),
                onPressed: session.canUndo ? notifier.undo : null,
                tooltip: l.canvasUndo,
                splashRadius: 14,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              // Redo
              IconButton(
                icon: Icon(Icons.redo, size: 18, color: t.textTertiary),
                onPressed: session.canRedo ? notifier.redo : null,
                tooltip: l.canvasRedo,
                splashRadius: 14,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              // Flatten icon button
              Tooltip(
                message: l.canvasFlatten,
                child: GestureDetector(
                  onTap: session.hasStrokes ? widget.onFlatten : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: session.hasStrokes ? t.accentEdit : t.surfaceHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: session.hasStrokes ? t.textPrimary : t.textMinimal,
                    ),
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
                child: VisionSlider.subtle(
                  value: _radiusToSlider(notifier.brushRadius),
                  onChanged: (t) => notifier.setBrushRadius(_sliderToRadius(t)),
                  t: t,
                  thumbRadius: 5,
                  overlayRadius: 10,
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${(notifier.brushRadius * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(7)),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l.canvasOpacity,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(7), letterSpacing: 1),
              ),
              Expanded(
                child: VisionSlider.subtle(
                  value: notifier.brushOpacity,
                  min: 0.05,
                  onChanged: notifier.setBrushOpacity,
                  t: t,
                  thumbRadius: 5,
                  overlayRadius: 10,
                ),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${(notifier.brushOpacity * 100).round()}%',
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(7)),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Text settings pop-out button (mobile)
          if (notifier.tool == CanvasTool.text)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => _showTextSettingsSheet(context, t, l, notifier),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: t.accentEdit.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: t.accentEdit.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune, size: 14, color: t.accentEdit),
                      const SizedBox(width: 6),
                      Text(
                        '${l.canvasTextFont} / ${l.canvasTextSize} / ${l.canvasTextSpacing}',
                        style: TextStyle(
                          color: t.accentEdit,
                          fontSize: t.fontSize(7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

/// Bottom sheet for mobile text tool settings.
class _MobileTextSettingsSheet extends StatelessWidget {
  final VisionTokens t;
  final AppLocalizations l;

  const _MobileTextSettingsSheet({required this.t, required this.l});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CanvasNotifier>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: t.textMinimal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Font picker
          Text(
            l.canvasTextFont,
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: _FontDropdown(
              value: notifier.pendingTextFontFamily,
              defaultLabel: l.canvasTextDefault,
              onChanged: notifier.setPendingTextFontFamily,
              t: t,
            ),
          ),
          const SizedBox(height: 16),
          // Size slider
          Row(
            children: [
              Text(
                l.canvasTextSize,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VisionSlider.subtle(
                  value: notifier.pendingTextFontSize,
                  min: 0.01,
                  max: 0.20,
                  onChanged: notifier.setPendingTextFontSize,
                  t: t,
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(notifier.pendingTextFontSize * 100).round()}%',
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(8)),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Spacing slider
          Row(
            children: [
              Text(
                l.canvasTextSpacing,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VisionSlider.subtle(
                  value: notifier.pendingTextLetterSpacing,
                  min: -0.01,
                  max: 0.05,
                  onChanged: notifier.setPendingTextLetterSpacing,
                  t: t,
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  (notifier.pendingTextLetterSpacing * 100).toStringAsFixed(1),
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(8)),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Font family dropdown with each font rendered in its own typeface.
class _FontDropdown extends StatelessWidget {
  final String? value;
  final String defaultLabel;
  final ValueChanged<String?> onChanged;
  final VisionTokens t;

  const _FontDropdown({
    required this.value,
    required this.defaultLabel,
    required this.onChanged,
    required this.t,
  });

  TextStyle _styleForFont(String? family, {double? fontSize}) {
    final size = fontSize ?? 12.0;
    if (family == null) {
      return TextStyle(color: t.textSecondary, fontSize: size);
    }
    try {
      return GoogleFonts.getFont(family, textStyle: TextStyle(color: t.textSecondary, fontSize: size));
    } catch (_) {
      return TextStyle(color: t.textSecondary, fontSize: size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          menuMaxHeight: 300,
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: t.surfaceHigh,
          icon: Icon(Icons.arrow_drop_down, size: 16, color: t.textMinimal),
          items: _fontFamilies.map((family) {
            final label = family ?? defaultLabel;
            return DropdownMenuItem<String?>(
              value: family,
              child: Text(
                label,
                style: _styleForFont(family, fontSize: t.fontSize(8)),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VisionTokens t;
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
          horizontal: iconOnly ? 5 : 10,
          vertical: iconOnly ? 5 : 6,
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
                size: 15,
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
