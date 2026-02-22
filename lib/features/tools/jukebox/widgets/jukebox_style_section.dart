import 'package:flutter/material.dart';
import '../../../../core/jukebox/models/jukebox_song.dart';
import '../../../../core/jukebox/providers/jukebox_notifier.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/widgets/color_swatch_row.dart';
import '../../../../core/widgets/vision_slider.dart';

/// Karaoke style customization: colors, visualizer style, intensity sliders,
/// font scale, and a reset button.
class JukeboxStyleSection extends StatelessWidget {
  final JukeboxNotifier jukebox;
  final VisionTokens t;

  const JukeboxStyleSection({super.key, required this.jukebox, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlight color
        ColorSwatchRow(
          label: 'HIGHLIGHT',
          current: jukebox.karaokeHighlightColor,
          themeDefault: t.accent,
          onChanged: (c) => jukebox.setKaraokeHighlightColor(c),
          t: t,
        ),
        const SizedBox(height: 10),
        // Upcoming color
        ColorSwatchRow(
          label: 'UPCOMING',
          current: jukebox.karaokeUpcomingColor,
          themeDefault: t.textPrimary,
          onChanged: (c) => jukebox.setKaraokeUpcomingColor(c),
          t: t,
        ),
        const SizedBox(height: 10),
        // Next line color
        ColorSwatchRow(
          label: 'NEXT LINE',
          current: jukebox.karaokeNextLineColor,
          themeDefault: t.textMinimal,
          onChanged: (c) => jukebox.setKaraokeNextLineColor(c),
          t: t,
        ),
        const SizedBox(height: 10),
        // Glow color
        ColorSwatchRow(
          label: 'GLOW',
          current: jukebox.visualizerColor,
          themeDefault: t.accent,
          onChanged: (c) => jukebox.setVisualizerColor(c),
          t: t,
        ),
        const SizedBox(height: 16),

        // Visualizer style chips
        Text('VISUALIZER',
            style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(7),
                letterSpacing: 1)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: VisualizerStyle.values.map((style) {
              final selected = jukebox.visualizerStyle == style;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => jukebox.setVisualizerStyle(style),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? t.accent.withValues(alpha: 0.15) : t.borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selected ? t.accent : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(style.name.toUpperCase(),
                        style: TextStyle(
                            color: selected ? t.accent : t.textSecondary,
                            fontSize: t.fontSize(7),
                            letterSpacing: 1,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Intensity / Speed / Density sliders
        _buildVizSlider('INTENSITY', jukebox.vizIntensity, (v) => jukebox.setVizIntensity(v)),
        const SizedBox(height: 4),
        _buildVizSlider('SPEED', jukebox.vizSpeed, (v) => jukebox.setVizSpeed(v)),
        const SizedBox(height: 4),
        _buildVizSlider('DENSITY', jukebox.vizDensity, (v) => jukebox.setVizDensity(v)),

        const SizedBox(height: 16),

        // Font scale slider
        Row(
          children: [
            Text('SIZE',
                style: TextStyle(
                    color: t.textDisabled,
                    fontSize: t.fontSize(7),
                    letterSpacing: 1)),
            Expanded(
              child: VisionSlider.accent(
                value: jukebox.karaokeFontScale,
                min: 0.5,
                max: 2.0,
                onChanged: (v) => jukebox.setKaraokeFontScale(v),
                t: t,
              ),
            ),
            Text('${(jukebox.karaokeFontScale * 100).round()}%',
                style: TextStyle(
                    color: t.textDisabled,
                    fontSize: t.fontSize(7),
                    letterSpacing: 1)),
          ],
        ),

        const SizedBox(height: 12),

        // Reset button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: jukebox.resetKaraokeStyle,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text('RESET TO DEFAULTS',
                style: TextStyle(
                    color: t.textDisabled,
                    fontSize: t.fontSize(7),
                    letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildVizSlider(String label, double value, void Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: TextStyle(
                  color: t.textDisabled,
                  fontSize: t.fontSize(7),
                  letterSpacing: 1)),
        ),
        Expanded(
          child: VisionSlider.accent(
            value: value,
            onChanged: onChanged,
            t: t,
          ),
        ),
        Text('${(value * 100).round()}%',
            style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(7),
                letterSpacing: 1)),
      ],
    );
  }
}

/// Desktop settings section: repeat mode and shuffle toggle.
class JukeboxSettingsSection extends StatelessWidget {
  final JukeboxNotifier jukebox;
  final VisionTokens t;

  const JukeboxSettingsSection({super.key, required this.jukebox, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Repeat
        Row(
          children: [
            IconButton(
              icon: Icon(
                jukebox.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                size: 16,
                color: jukebox.repeatMode != RepeatMode.off ? t.accent : t.textDisabled,
              ),
              onPressed: jukebox.cycleRepeatMode,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            const SizedBox(width: 8),
            Text(
              'REPEAT: ${jukebox.repeatMode.name.toUpperCase()}',
              style: TextStyle(
                  color: t.textDisabled,
                  fontSize: t.fontSize(8),
                  letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Shuffle
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                size: 16,
                color: jukebox.shuffle ? t.accent : t.textDisabled,
              ),
              onPressed: jukebox.toggleShuffle,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            const SizedBox(width: 8),
            Text(
              'SHUFFLE: ${jukebox.shuffle ? "ON" : "OFF"}',
              style: TextStyle(
                  color: t.textDisabled,
                  fontSize: t.fontSize(8),
                  letterSpacing: 1),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact mobile settings row (repeat, shuffle, visualizer toggle) shown
/// in the mobile expanded now-playing view.
class JukeboxMobileSettingsRow extends StatelessWidget {
  final JukeboxNotifier jukebox;
  final VisionTokens t;

  const JukeboxMobileSettingsRow({super.key, required this.jukebox, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            jukebox.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
            size: 16,
            color: jukebox.repeatMode != RepeatMode.off ? t.accent : t.textDisabled,
          ),
          onPressed: jukebox.cycleRepeatMode,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
        const SizedBox(width: 4),
        Text(
          jukebox.repeatMode.name.toUpperCase(),
          style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(7),
              letterSpacing: 1),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            Icons.shuffle,
            size: 16,
            color: jukebox.shuffle ? t.accent : t.textDisabled,
          ),
          onPressed: jukebox.toggleShuffle,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
        const SizedBox(width: 4),
        Text(
          jukebox.shuffle ? 'ON' : 'OFF',
          style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(7),
              letterSpacing: 1),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            jukebox.showKaraokeInPanel ? Icons.visibility : Icons.visibility_off,
            size: 16,
            color: jukebox.showKaraokeInPanel ? t.accent : t.textDisabled,
          ),
          onPressed: jukebox.toggleKaraokeInPanel,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }
}
