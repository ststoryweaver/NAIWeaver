import 'package:flutter/material.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../models/director_reference.dart';

String _localizedRefType(BuildContext context, DirectorReferenceType type) {
  final l = context.l;
  switch (type) {
    case DirectorReferenceType.character:
      return l.refTypeCharacter;
    case DirectorReferenceType.style:
      return l.refTypeStyle;
    case DirectorReferenceType.characterAndStyle:
      return l.refTypeCharAndStyle;
  }
}

class DirectorRefEditorSheet extends StatefulWidget {
  final DirectorReference reference;
  final Function(DirectorReferenceType) onTypeChanged;
  final Function(double) onStrengthChanged;
  final Function(double) onFidelityChanged;
  final VoidCallback onRemove;

  const DirectorRefEditorSheet({
    super.key,
    required this.reference,
    required this.onTypeChanged,
    required this.onStrengthChanged,
    required this.onFidelityChanged,
    required this.onRemove,
  });

  @override
  State<DirectorRefEditorSheet> createState() => _DirectorRefEditorSheetState();
}

class _DirectorRefEditorSheetState extends State<DirectorRefEditorSheet> {
  late DirectorReferenceType _type;
  late double _strength;
  late double _fidelity;

  @override
  void initState() {
    super.initState();
    _type = widget.reference.type;
    _strength = widget.reference.strength;
    _fidelity = widget.reference.fidelity;
  }

  Color _colorForType(BuildContext context, DirectorReferenceType type) {
    final t = context.t;
    switch (type) {
      case DirectorReferenceType.character:
        return t.accentRefCharacter;
      case DirectorReferenceType.style:
        return t.accentRefStyle;
      case DirectorReferenceType.characterAndStyle:
        return t.accentRefCharStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      color: t.surfaceMid,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l.refEditorTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: t.fontSize(12),
                  letterSpacing: 4,
                  color: t.textPrimary,
                ),
              ),
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
          const SizedBox(height: 20),

          // Image preview
          Center(
            child: Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _colorForType(context, _type), width: 1.5),
                image: DecorationImage(
                  image: MemoryImage(widget.reference.originalImageBytes),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Type selector
          Text(
            context.l.refTypeLabel,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: t.fontSize(9),
              letterSpacing: 2,
              color: t.textDisabled,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: DirectorReferenceType.values.map((refType) {
              final isSelected = _type == refType;
              final color = _colorForType(context, refType);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _type = refType);
                      widget.onTypeChanged(refType);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : t.borderSubtle,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? color : t.textMinimal,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _localizedRefType(context, refType),
                          style: TextStyle(
                            fontSize: t.fontSize(8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: isSelected ? color : t.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

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

          // Fidelity slider
          _buildSlider(
            label: context.l.refFidelity,
            value: _fidelity,
            onChanged: (v) {
              setState(() => _fidelity = v);
              widget.onFidelityChanged(v);
            },
          ),
          const SizedBox(height: 24),
        ],
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
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: t.fontSize(10),
                color: t.textTertiary,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: t.textDisabled,
            inactiveTrackColor: t.textMinimal,
            thumbColor: t.textPrimary,
            overlayColor: t.textPrimary.withValues(alpha: 0.1),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
