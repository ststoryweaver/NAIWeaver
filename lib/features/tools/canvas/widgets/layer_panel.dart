import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/vision_slider.dart';
import '../models/canvas_layer.dart';
import '../providers/canvas_notifier.dart';

/// Layer management panel — used as desktop sidebar and mobile bottom sheet content.
class LayerPanel extends StatelessWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CanvasNotifier>();
    final session = notifier.session;
    if (session == null) return const SizedBox.shrink();
    final t = context.t;
    final l = context.l;

    final activeLayer = session.activeLayer;

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceMid,
        border: Border(left: BorderSide(color: t.borderSubtle)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              children: [
                Text(
                  l.canvasLayers,
                  style: TextStyle(
                    color: t.textTertiary,
                    fontSize: t.fontSize(9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                _SmallIconButton(
                  icon: Icons.add,
                  tooltip: l.canvasLayerAdd,
                  onTap: notifier.addLayer,
                  t: t,
                ),
              ],
            ),
          ),

          // Layer list (reversed: top layer shown first)
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: EdgeInsets.zero,
              itemCount: session.layers.length,
              onReorder: (oldIndex, newIndex) {
                // ReorderableListView gives indices in reversed display order
                // Convert from display order (reversed) back to data order
                final dataOld = session.layers.length - 1 - oldIndex;
                var dataNew = session.layers.length - 1 - newIndex;
                if (oldIndex < newIndex) {
                  dataNew += 1;
                }
                notifier.reorderLayer(dataOld, dataNew);
              },
              itemBuilder: (context, index) {
                // Display top-to-bottom (reverse of data order)
                final dataIndex = session.layers.length - 1 - index;
                final layer = session.layers[dataIndex];
                final isActive = layer.id == session.activeLayerId;

                return _LayerRow(
                  key: ValueKey(layer.id),
                  layer: layer,
                  isActive: isActive,
                  index: index,
                  t: t,
                  onTap: () => notifier.setActiveLayer(layer.id),
                  onToggleVisibility: () =>
                      notifier.setLayerVisibility(layer.id, !layer.visible),
                  onRename: (name) => notifier.renameLayer(layer.id, name),
                );
              },
            ),
          ),

          // Bottom controls for active layer
          if (activeLayer != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blend mode dropdown
                  Row(
                    children: [
                      Text(
                        l.canvasLayerBlendMode,
                        style: TextStyle(
                          color: t.textDisabled,
                          fontSize: t.fontSize(8),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<CanvasBlendMode>(
                          value: activeLayer.blendMode,
                          isExpanded: true,
                          isDense: true,
                          dropdownColor: t.surfaceHigh,
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: t.fontSize(9),
                          ),
                          underline: const SizedBox.shrink(),
                          items: CanvasBlendMode.values.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label()),
                            );
                          }).toList(),
                          onChanged: (mode) {
                            if (mode != null) {
                              notifier.setLayerBlendMode(
                                  activeLayer.id, mode);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Opacity slider
                  Row(
                    children: [
                      Text(
                        l.canvasLayerOpacity,
                        style: TextStyle(
                          color: t.textDisabled,
                          fontSize: t.fontSize(8),
                          letterSpacing: 1,
                        ),
                      ),
                      Expanded(
                        child: VisionSlider.subtle(
                          value: activeLayer.opacity,
                          onChanged: (v) {
                            notifier.setLayerOpacity(activeLayer.id, v);
                          },
                          t: t,
                          thumbRadius: 5,
                          overlayRadius: 10,
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${(activeLayer.opacity * 100).round()}%',
                          style: TextStyle(
                            color: t.textDisabled,
                            fontSize: t.fontSize(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _PanelButton(
                          label: l.canvasLayerDuplicate,
                          onTap: () =>
                              notifier.duplicateLayer(activeLayer.id),
                          t: t,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PanelButton(
                          label: l.canvasLayerClear,
                          onTap: activeLayer.strokes.isNotEmpty
                              ? () => _confirmClearLayer(
                                  context, notifier, activeLayer, l, t)
                              : null,
                          t: t,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PanelButton(
                          label: l.canvasLayerDelete,
                          onTap: session.layers.length > 1
                              ? () => _confirmDeleteLayer(
                                  context, notifier, activeLayer, l, t)
                              : null,
                          t: t,
                          danger: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeleteLayer(BuildContext context, CanvasNotifier notifier,
      CanvasLayer layer, AppLocalizations l, VisionTokens t) async {
    if (layer.strokes.isEmpty && !layer.isImageLayer) {
      notifier.removeLayer(layer.id);
      return;
    }
    final confirm = await showConfirmDialog(
      context,
      title: l.canvasLayerDelete,
      message: l.canvasLayerDeleteConfirm,
      confirmLabel: l.canvasLayerDelete,
      confirmColor: t.accentDanger,
    );
    if (confirm == true) {
      notifier.removeLayer(layer.id);
    }
  }

  Future<void> _confirmClearLayer(BuildContext context, CanvasNotifier notifier,
      CanvasLayer layer, AppLocalizations l, VisionTokens t) async {
    final confirm = await showConfirmDialog(
      context,
      title: l.canvasLayerClear,
      message: l.canvasLayerClearConfirm,
      confirmLabel: l.canvasLayerClear,
      confirmColor: t.accentDanger,
    );
    if (confirm == true) {
      notifier.clearLayer(layer.id);
    }
  }
}

/// A single layer row in the list.
class _LayerRow extends StatefulWidget {
  final CanvasLayer layer;
  final bool isActive;
  final int index;
  final VisionTokens t;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onRename;

  const _LayerRow({
    super.key,
    required this.layer,
    required this.isActive,
    required this.index,
    required this.t,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onRename,
  });

  @override
  State<_LayerRow> createState() => _LayerRowState();
}

class _LayerRowState extends State<_LayerRow> {
  bool _isEditing = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.layer.name);
  }

  @override
  void didUpdateWidget(_LayerRow old) {
    super.didUpdateWidget(old);
    if (old.layer.name != widget.layer.name && !_isEditing) {
      _nameController.text = widget.layer.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _nameController.text = widget.layer.name;
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.layer.name.length,
      );
    });
  }

  void _finishEditing() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != widget.layer.name) {
      widget.onRename(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final layer = widget.layer;

    // Determine dominant stroke color for the color dot
    Color dotColor = Colors.grey;
    if (layer.isImageLayer) {
      dotColor = Colors.teal;
    } else if (layer.strokes.isNotEmpty) {
      final lastPaint =
          layer.strokes.lastWhere((s) => !s.isErase, orElse: () => layer.strokes.last);
      if (!lastPaint.isErase) {
        dotColor = Color(lastPaint.colorValue);
      }
    }

    return ReorderableDragStartListener(
      index: widget.index,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: _startEditing,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? t.accentEdit.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.isActive ? t.accentEdit : Colors.transparent,
                width: 2,
              ),
              bottom: BorderSide(color: t.borderSubtle, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Visibility toggle
              Tooltip(
                message: context.l.canvasLayerToggleVisibility,
                child: GestureDetector(
                  onTap: widget.onToggleVisibility,
                  child: Icon(
                    layer.visible ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: layer.visible ? t.textTertiary : t.textMinimal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Color dot or image icon
              if (layer.isImageLayer)
                Icon(Icons.image, size: 12, color: dotColor)
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.borderSubtle, width: 0.5),
                  ),
                ),
              const SizedBox(width: 8),
              // Layer name (or inline edit)
              Expanded(
                child: _isEditing
                    ? SizedBox(
                        height: 20,
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: t.fontSize(9),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _finishEditing(),
                          onTapOutside: (_) => _finishEditing(),
                        ),
                      )
                    : Text(
                        layer.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: t.fontSize(9),
                        ),
                      ),
              ),
              // Blend mode label (compact)
              if (layer.blendMode != CanvasBlendMode.normal)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    layer.blendMode.label().substring(0, 3),
                    style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(7),
                      letterSpacing: 0.5,
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

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VisionTokens t;

  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: t.textTertiary),
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VisionTokens t;
  final bool danger;

  const _PanelButton({
    required this.label,
    this.onTap,
    required this.t,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled
                ? (danger ? t.accentDanger.withValues(alpha: 0.5) : t.borderSubtle)
                : t.borderSubtle.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: enabled
                ? (danger ? t.accentDanger : t.textTertiary)
                : t.textMinimal,
            fontSize: t.fontSize(7),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
