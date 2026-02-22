import 'package:flutter/material.dart';
import '../theme/vision_tokens.dart';

/// Default swatch palette for color selection rows.
const kDefaultSwatchColors = <Color>[
  Color(0xFF64FFDA), // teal
  Color(0xFFFFD740), // gold
  Color(0xFFFF80AB), // pink
  Color(0xFF80D8FF), // cyan
  Color(0xFFFFFFFF), // white
  Color(0xFFB388FF), // purple
  Color(0xFFFF8A65), // coral
  Color(0xFFCCFF90), // lime
];

/// A labeled row of color swatches with optional "DEFAULT" reset button.
class ColorSwatchRow extends StatelessWidget {
  final String label;
  final Color? current;
  final Color themeDefault;
  final ValueChanged<Color?> onChanged;
  final VisionTokens t;
  final List<Color> swatches;

  const ColorSwatchRow({
    super.key,
    required this.label,
    required this.current,
    required this.themeDefault,
    required this.onChanged,
    required this.t,
    this.swatches = kDefaultSwatchColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(7),
              letterSpacing: 1,
            ),
          ),
        ),
        ...swatches.map((color) {
          final isSelected =
              current != null && current!.toARGB32() == color.toARGB32();
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => onChanged(color),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        if (current != null)
          GestureDetector(
            onTap: () => onChanged(null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: t.borderSubtle),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'DEFAULT',
                style: TextStyle(
                  color: t.textMinimal,
                  fontSize: t.fontSize(6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
