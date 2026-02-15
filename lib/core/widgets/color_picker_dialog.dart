import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_extensions.dart';

/// A simple hex color picker dialog with a curated grid + hex text input.
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String label;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.label,
  });

  static Future<Color?> show(BuildContext context, {required Color initialColor, required String label}) {
    return showDialog<Color>(
      context: context,
      builder: (_) => ColorPickerDialog(initialColor: initialColor, label: label),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selected;
  late TextEditingController _hexController;

  static const List<Color> _palette = [
    // Neutrals
    Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF121212),
    Color(0xFF1E1E1E), Color(0xFF2A2A2A), Color(0xFF3A3A3A),
    Color(0xFF555555), Color(0xFF808080), Color(0xFFAAAAAA),
    Color(0xFFD0D0D0), Color(0xFFE0E0E0), Color(0xFFFFFFFF),
    // Blues
    Color(0xFF0A0E1A), Color(0xFF141929), Color(0xFF1A237E),
    Color(0xFF283593), Color(0xFF3F51B5), Color(0xFF7B8FCC),
    // Reds / Pinks
    Color(0xFF1A0000), Color(0xFFB71C1C), Color(0xFFFF5252),
    Color(0xFFFF0066), Color(0xFFFF4081), Color(0xFFE91E63),
    // Greens
    Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFF69F0AE),
    Color(0xFFA5D6A7), Color(0xFF00E676), Color(0xFF76FF03),
    // Yellows / Oranges
    Color(0xFFFF6F00), Color(0xFFFFAB00), Color(0xFFFFD600),
    Color(0xFFFAFAFA), Color(0xFFFFF176), Color(0xFFFFE082),
    // Purples / Cyans
    Color(0xFF4A148C), Color(0xFF7C4DFF), Color(0xFFB388FF),
    Color(0xFF00BCD4), Color(0xFF00E5FF), Color(0xFF84FFFF),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor;
    _hexController = TextEditingController(text: _colorToHex(_selected));
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

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      backgroundColor: t.surfaceHigh,
      title: Text(
        widget.label.toUpperCase(),
        style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), letterSpacing: 2),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current color preview
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: _selected,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: t.borderMedium),
              ),
            ),
            const SizedBox(height: 16),
            // Color grid
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _palette.map((c) {
                final isSelected = c.toARGB32() == _selected.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selected = c;
                      _hexController.text = _colorToHex(c);
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? t.accent : t.borderSubtle,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Hex input
            Row(
              children: [
                Text('#', style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(14))),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13), fontFamily: 'monospace'),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: 'FFFFFF',
                      hintStyle: TextStyle(color: t.textMinimal),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        setState(() => _selected = c);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('APPLY', style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9))),
        ),
      ],
    );
  }
}
