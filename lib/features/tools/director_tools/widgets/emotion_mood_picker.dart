import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../models/augment_tool.dart';

class EmotionMoodPicker extends StatelessWidget {
  final EmotionMood selected;
  final ValueChanged<EmotionMood> onSelected;

  const EmotionMoodPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: EmotionMood.values.map((mood) {
        final isActive = mood == selected;
        return InkWell(
          onTap: () => onSelected(mood),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 12 : 8,
              vertical: mobile ? 8 : 4,
            ),
            decoration: BoxDecoration(
              color: isActive ? t.accent.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isActive ? t.accent : t.borderSubtle,
              ),
            ),
            child: Text(
              mood.label.toUpperCase(),
              style: TextStyle(
                color: isActive ? t.accent : t.textDisabled,
                fontSize: t.fontSize(responsiveFont(context, 8, 10)),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
