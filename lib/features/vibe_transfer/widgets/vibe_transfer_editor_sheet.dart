import 'package:flutter/material.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/editable_slider_value.dart';
import '../../../core/widgets/enabled_toggle.dart';
import '../../../core/widgets/vision_slider.dart';
import '../models/vibe_transfer.dart';

class VibeTransferEditorSheet extends StatefulWidget {
  final VibeTransfer vibe;
  final Function(double) onStrengthChanged;
  final Function(double) onInfoExtractedChanged;
  final VoidCallback onToggleEnabled;
  final VoidCallback onRemove;

  const VibeTransferEditorSheet({
    super.key,
    required this.vibe,
    required this.onStrengthChanged,
    required this.onInfoExtractedChanged,
    required this.onToggleEnabled,
    required this.onRemove,
  });

  @override
  State<VibeTransferEditorSheet> createState() => _VibeTransferEditorSheetState();
}

class _VibeTransferEditorSheetState extends State<VibeTransferEditorSheet> {
  late double _strength;
  late double _infoExtracted;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _strength = widget.vibe.strength;
    _infoExtracted = widget.vibe.infoExtracted;
    _enabled = widget.vibe.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      color: t.surfaceMid,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l.refVibeEditorTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: t.fontSize(12),
                    letterSpacing: 4,
                    color: t.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EnabledToggle(
                      enabled: _enabled,
                      accent: t.accentVibeTransfer,
                      onTap: () {
                        setState(() => _enabled = !_enabled);
                        widget.onToggleEnabled();
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        widget.onRemove();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.delete_outline, color: t.accentDanger, size: 18),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image preview
            Center(
              child: Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: t.accentVibeTransfer, width: 1.5),
                  image: DecorationImage(
                    image: MemoryImage(widget.vibe.originalImageBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Strength slider
            _buildSlider(
              label: context.l.refStrength,
              value: _strength,
              onChanged: (v) {
                setState(() => _strength = v);
                widget.onStrengthChanged(v);
              },
            ),
            const SizedBox(height: 16),

            // Info Extracted slider
            _buildSlider(
              label: context.l.refInfoExtracted,
              value: _infoExtracted,
              onChanged: (v) {
                setState(() => _infoExtracted = v);
                widget.onInfoExtractedChanged(v);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: t.fontSize(9),
                letterSpacing: 2,
                color: t.textDisabled,
              ),
            ),
            EditableSliderValue(
              value: value,
              softMin: 0.0,
              softMax: 1.0,
              decimals: 2,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: t.fontSize(10),
                color: t.textTertiary,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        VisionSlider(
          value: value.clamp(0.0, 1.0),
          onChanged: onChanged,
          min: 0.0,
          max: 1.0,
          activeColor: t.accentVibeTransfer.withValues(alpha: 0.5),
          inactiveColor: t.textMinimal,
          thumbColor: t.accentVibeTransfer,
          thumbRadius: 6,
        ),
      ],
    );
  }
}
