import 'package:flutter/material.dart';
import '../theme/vision_tokens.dart';

/// Themed slider wrapping SliderTheme + Slider with standard Vision styling.
class VisionSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double thumbRadius;
  final double overlayRadius;
  final double trackHeight;

  const VisionSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.thumbRadius = 5,
    this.overlayRadius = 10,
    this.trackHeight = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: trackHeight,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
        overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
        activeTrackColor: activeColor,
        inactiveTrackColor: inactiveColor,
        thumbColor: thumbColor ?? activeColor,
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
      ),
    );
  }

  /// Convenience constructor for the most common pattern: accent-colored slider.
  factory VisionSlider.accent({
    Key? key,
    required double value,
    required ValueChanged<double>? onChanged,
    required VisionTokens t,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
  }) {
    return VisionSlider(
      key: key,
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: t.accent,
      inactiveColor: t.borderSubtle,
      thumbColor: t.accent,
    );
  }

  /// Convenience constructor for subtle/tool sliders (canvas, etc).
  factory VisionSlider.subtle({
    Key? key,
    required double value,
    required ValueChanged<double>? onChanged,
    required VisionTokens t,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    double thumbRadius = 6,
    double overlayRadius = 12,
  }) {
    return VisionSlider(
      key: key,
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: t.textDisabled,
      inactiveColor: t.textMinimal,
      thumbColor: t.textPrimary,
      thumbRadius: thumbRadius,
      overlayRadius: overlayRadius,
    );
  }
}
