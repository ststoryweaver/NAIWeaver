import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../providers/img2img_notifier.dart';

class MaskToolbar extends StatelessWidget {
  const MaskToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<Img2ImgNotifier>();
    final t = context.t;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          // Undo
          IconButton(
            icon: Icon(Icons.undo, size: 16, color: t.textTertiary),
            onPressed: notifier.hasMask ? notifier.undoLastStroke : null,
            tooltip: 'Undo stroke',
            splashRadius: 16,
          ),
          // Clear
          IconButton(
            icon: Icon(Icons.delete_outline, size: 16, color: t.textTertiary),
            onPressed: notifier.hasMask ? notifier.clearMask : null,
            tooltip: 'Clear mask',
            splashRadius: 16,
          ),

          const SizedBox(width: 16),

          // Brush size slider
          Text(
            'SIZE',
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
                value: notifier.brushRadius,
                min: 0.005,
                max: 0.15,
                onChanged: notifier.setBrushRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
