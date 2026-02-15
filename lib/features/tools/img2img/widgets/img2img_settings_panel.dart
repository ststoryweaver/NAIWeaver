import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../providers/img2img_notifier.dart';

class Img2ImgSettingsPanel extends StatefulWidget {
  final TextEditingController promptController;
  final TextEditingController negativePromptController;

  const Img2ImgSettingsPanel({
    super.key,
    required this.promptController,
    required this.negativePromptController,
  });

  @override
  State<Img2ImgSettingsPanel> createState() => _Img2ImgSettingsPanelState();
}

class _Img2ImgSettingsPanelState extends State<Img2ImgSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<Img2ImgNotifier>();
    final session = notifier.session;
    if (session == null) return const SizedBox.shrink();
    final settings = session.settings;
    final t = context.t;
    final l = context.l;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceMid,
        border: Border(left: BorderSide(color: t.borderSubtle)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.img2imgSettings,
              style: TextStyle(
                color: t.textTertiary,
                fontSize: t.fontSize(9),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Prompt field
            Text(l.img2imgPrompt, style: _labelStyle(t)),
            const SizedBox(height: 4),
            TextField(
              controller: widget.promptController,
              maxLines: 3,
              onChanged: notifier.setPrompt,
              style: TextStyle(fontSize: t.fontSize(12), color: t.textPrimary),
              decoration: _inputDecoration(l.img2imgPromptHint, t),
            ),
            const SizedBox(height: 12),

            // Negative prompt field
            Text(l.img2imgNegative, style: _labelStyle(t)),
            const SizedBox(height: 4),
            TextField(
              controller: widget.negativePromptController,
              maxLines: 2,
              onChanged: notifier.setNegativePrompt,
              style: TextStyle(fontSize: t.fontSize(12), color: t.textPrimary),
              decoration: _inputDecoration(l.img2imgNegativeHint, t),
            ),
            const SizedBox(height: 16),

            // Strength slider
            _buildSlider(
              label: l.img2imgStrength,
              value: settings.strength,
              min: 0.0,
              max: 1.0,
              onChanged: notifier.setStrength,
              t: t,
            ),
            const SizedBox(height: 8),

            // Noise slider
            _buildSlider(
              label: l.img2imgNoise,
              value: settings.noise,
              min: 0.0,
              max: 1.0,
              onChanged: notifier.setNoise,
              t: t,
            ),
            // Mask blur slider (only when mask is active)
            if (session.hasMask) ...[
              const SizedBox(height: 8),
              _buildSlider(
                label: l.img2imgMaskBlur,
                value: settings.maskBlur.toDouble(),
                min: 0,
                max: 20,
                onChanged: (v) => notifier.setMaskBlur(v.round()),
                t: t,
                asInteger: true,
              ),
            ],

            const SizedBox(height: 12),

            // Color correct toggle
            Row(
              children: [
                Text(l.img2imgColorCorrect, style: _labelStyle(t)),
                const Spacer(),
                Switch(
                  value: settings.colorCorrect,
                  onChanged: notifier.setColorCorrect,
                  activeThumbColor: t.textPrimary,
                  activeTrackColor: t.textDisabled,
                  inactiveThumbColor: t.textDisabled,
                  inactiveTrackColor: t.textMinimal,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Source info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.textPrimary.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.img2imgSourceInfo, style: _labelStyle(t)),
                  const SizedBox(height: 4),
                  Text(
                    '${session.sourceWidth} x ${session.sourceHeight}',
                    style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(11)),
                  ),
                  Text(
                    session.hasMask ? l.img2imgMaskStrokes(session.maskStrokes.length) : l.img2imgNoMask,
                    style: TextStyle(
                      color: session.hasMask ? t.accentEdit : t.textDisabled,
                      fontSize: t.fontSize(10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required VisionTokens t,
    bool asInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: _labelStyle(t)),
            const Spacer(),
            Text(
              asInteger ? value.round().toString() : value.toStringAsFixed(2),
              style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: t.textDisabled,
            inactiveTrackColor: t.textMinimal,
            thumbColor: t.textPrimary,
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, VisionTokens t) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      fillColor: t.background,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: t.borderMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: t.borderMedium),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: t.borderStrong),
      ),
    );
  }
}

TextStyle _labelStyle(VisionTokens t) {
  return TextStyle(
    color: t.textDisabled,
    fontSize: t.fontSize(8),
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );
}
