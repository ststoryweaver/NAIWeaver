import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../models/augment_tool.dart';

class ToolSelector extends StatelessWidget {
  final AugmentTool selected;
  final ValueChanged<AugmentTool> onSelected;

  const ToolSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: AugmentTool.values.map((tool) {
        final isActive = tool == selected;
        return InkWell(
          onTap: () => onSelected(tool),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 14 : 10,
              vertical: mobile ? 10 : 6,
            ),
            decoration: BoxDecoration(
              color: isActive ? t.accent.withValues(alpha: 0.15) : t.borderSubtle,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isActive ? t.accent : t.borderMedium,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tool.icon, size: 14, color: isActive ? t.accent : t.textDisabled),
                const SizedBox(width: 6),
                Text(
                  tool.label.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? t.accent : t.textDisabled,
                    fontSize: t.fontSize(responsiveFont(context, 9, 11)),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
