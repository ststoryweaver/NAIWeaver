import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/vision_slider.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../models/slideshow_config.dart';
import '../providers/slideshow_notifier.dart';
import '../../../../core/jukebox/jukebox_registry.dart';
import '../../../../core/jukebox/models/jukebox_song.dart';
import '../../jukebox/widgets/jukebox_panel.dart';
import 'image_source_selector.dart';
import 'slideshow_player.dart';

class SlideshowLauncher extends StatefulWidget {
  const SlideshowLauncher({super.key});

  @override
  State<SlideshowLauncher> createState() => _SlideshowLauncherState();
}

class _SlideshowLauncherState extends State<SlideshowLauncher> {
  bool _showingEditor = false;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SlideshowNotifier>();
    final mobile = isMobile(context);
    final t = context.t;

    if (mobile) {
      return Column(
        children: [
          _buildHeader(context, notifier, t),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: _showingEditor && notifier.activeConfig != null
                ? Column(
                    children: [
                      _buildMobileEditorBar(notifier, t),
                      Expanded(child: _buildEditor(context, notifier, t)),
                    ],
                  )
                : _buildConfigList(context, notifier, t, fullWidth: true),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(context, notifier, t),
        Divider(height: 1, color: t.textMinimal),
        Expanded(
          child: Row(
            children: [
              _buildConfigList(context, notifier, t),
              VerticalDivider(width: 1, color: t.textMinimal),
              Expanded(child: _buildEditor(context, notifier, t)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileEditorBar(SlideshowNotifier notifier, VisionTokens t) {
    final name = notifier.activeConfig?.name.toUpperCase() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: t.surfaceMid,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 18, color: t.textDisabled),
            onPressed: () => setState(() => _showingEditor = false),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: t.textSecondary,
                    fontSize: t.fontSize(11),
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, SlideshowNotifier notifier, VisionTokens t) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: t.surfaceHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l.slideshowTitle,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(12),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.music_note, size: 18, color: t.accent),
                tooltip: l.jukeboxTitle,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog.fullscreen(
                      backgroundColor: Colors.black,
                      child: const JukeboxPanel(),
                    ),
                  );
                },
              ),
              TextButton.icon(
                onPressed: () => _playAll(context, notifier),
                icon: Icon(Icons.play_arrow, size: 16, color: t.accent),
                label: Text(l.slideshowPlayAll,
                    style: TextStyle(
                        color: t.accent,
                        fontSize: t.fontSize(9),
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: t.accent.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigList(
      BuildContext context, SlideshowNotifier notifier, VisionTokens t,
      {bool fullWidth = false}) {
    final l = context.l;
    return Container(
      width: fullWidth ? double.infinity : 220,
      color: t.surfaceMid,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.slideshowConfigs,
                    style: TextStyle(
                        color: t.secondaryText,
                        fontSize: t.fontSize(8),
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add, size: 14, color: t.secondaryText),
                  onPressed: () {
                    notifier.createNew();
                    _save(context, notifier);
                    if (isMobile(context)) {
                      setState(() => _showingEditor = true);
                    }
                  },
                  tooltip: l.slideshowNewConfig,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: notifier.configs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.slideshowNoConfigs,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: t.textMinimal,
                            fontSize: t.fontSize(9),
                            letterSpacing: 1,
                            height: 1.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: notifier.configs.length,
                    itemBuilder: (context, index) {
                      final config = notifier.configs[index];
                      final isSelected =
                          notifier.activeConfig?.id == config.id;
                      return InkWell(
                        onTap: () {
                          notifier.selectConfig(config);
                          if (isMobile(context)) {
                            setState(() => _showingEditor = true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          color: isSelected
                              ? t.borderSubtle
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(Icons.slideshow,
                                  size: 12,
                                  color: isSelected
                                      ? t.textPrimary
                                      : t.secondaryText),
                              if (notifier.defaultConfigId == config.id)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.star, size: 10, color: t.accent),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? t.textPrimary
                                            : t.secondaryText,
                                        fontSize: t.fontSize(9),
                                        letterSpacing: 1,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _sourceLabel(context, config),
                                        style: TextStyle(
                                          color: isSelected
                                              ? t.textTertiary
                                              : t.textMinimal,
                                          fontSize: t.fontSize(7),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                IconButton(
                                  icon: Icon(Icons.play_arrow,
                                      size: 16, color: t.accent),
                                  onPressed: () =>
                                      _play(context, notifier, config),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                ),
                              if (isSelected)
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 12, color: t.textDisabled),
                                  onPressed: () => _showDeleteConfirm(
                                      context, notifier, config, t),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(
      BuildContext context, SlideshowNotifier notifier, VisionTokens t) {
    final l = context.l;
    final config = notifier.activeConfig;
    if (config == null) {
      return Center(
        child: Text(l.slideshowSelectOrCreate,
            style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(9),
                letterSpacing: 2)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                _sectionTitle(l.slideshowNameLabel, t),
                _textField(
                  value: config.name,
                  onChanged: (val) {
                    notifier.updateConfig(config.copyWith(name: val));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                const SizedBox(height: 24),

                // Image source
                _sectionTitle(l.slideshowSourceLabel, t),
                ImageSourceSelector(
                  config: config,
                  onChanged: (updated) {
                    notifier.updateConfig(updated);
                    _save(context, notifier);
                  },
                ),
                const SizedBox(height: 24),

                // Transition
                _sectionTitle(l.slideshowTransition, t),
                _buildTransitionGrid(context, config, notifier, t),
                const SizedBox(height: 16),
                _buildSlider(
                  label: l.slideshowTransitionDuration,
                  value: config.transitionDuration,
                  min: 0.3,
                  max: 2.0,
                  suffix: 's',
                  onChanged: (v) {
                    notifier.updateConfig(
                        config.copyWith(transitionDuration: v));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                const SizedBox(height: 24),

                // Timing
                _sectionTitle(l.slideshowTiming, t),
                _buildSlider(
                  label: l.slideshowSlideDuration,
                  value: config.slideDuration,
                  min: 3.0,
                  max: 30.0,
                  suffix: 's',
                  onChanged: (v) {
                    notifier
                        .updateConfig(config.copyWith(slideDuration: v));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                const SizedBox(height: 24),

                // Ken Burns
                _sectionTitle(l.slideshowKenBurns, t),
                _buildToggle(
                  label: l.slideshowEnabled,
                  value: config.kenBurnsEnabled &&
                      !config.manualZoomEnabled,
                  onChanged: (v) {
                    notifier.updateConfig(config.copyWith(
                        kenBurnsEnabled: v,
                        manualZoomEnabled: v ? false : config.manualZoomEnabled));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                if (config.kenBurnsEnabled && !config.manualZoomEnabled)
                  _buildSlider(
                    label: l.slideshowIntensity,
                    value: config.kenBurnsIntensity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) {
                      notifier.updateConfig(
                          config.copyWith(kenBurnsIntensity: v));
                      _save(context, notifier);
                    },
                    t: t,
                  ),
                const SizedBox(height: 16),

                // Manual zoom
                _buildToggle(
                  label: l.slideshowManualZoom,
                  value: config.manualZoomEnabled,
                  onChanged: (v) {
                    notifier.updateConfig(config.copyWith(
                        manualZoomEnabled: v,
                        kenBurnsEnabled: v ? false : config.kenBurnsEnabled));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                const SizedBox(height: 24),

                // Playback
                _sectionTitle(l.slideshowPlayback, t),
                _buildToggle(
                  label: l.slideshowShuffle,
                  value: config.shuffleEnabled,
                  onChanged: (v) {
                    notifier.updateConfig(
                        config.copyWith(shuffleEnabled: v));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                const SizedBox(height: 8),
                _buildToggle(
                  label: l.slideshowLoop,
                  value: config.loopEnabled,
                  onChanged: (v) {
                    notifier
                        .updateConfig(config.copyWith(loopEnabled: v));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                const SizedBox(height: 24),

                // Music
                _sectionTitle('MUSIC', t),
                _buildToggle(
                  label: 'ENABLE MUSIC',
                  value: config.musicEnabled,
                  onChanged: (v) {
                    notifier.updateConfig(config.copyWith(musicEnabled: v));
                    _save(context, notifier);
                  },
                  t: t,
                ),
                if (config.musicEnabled) ...[
                  const SizedBox(height: 12),
                  // Song picker
                  _buildMusicSongPicker(config, notifier, t),
                  const SizedBox(height: 12),
                  // Category filter
                  _buildMusicCategoryPicker(config, notifier, t),
                  const SizedBox(height: 12),
                  // Volume
                  _buildSlider(
                    label: 'MUSIC VOLUME',
                    value: config.musicVolume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) {
                      notifier.updateConfig(config.copyWith(musicVolume: v));
                      _save(context, notifier);
                    },
                    t: t,
                  ),
                  const SizedBox(height: 12),
                  // SoundFont picker
                  _buildMusicSoundFontPicker(config, notifier, t),
                  const SizedBox(height: 12),
                  // Karaoke toggle
                  _buildToggle(
                    label: 'KARAOKE LYRICS',
                    value: config.karaokeEnabled,
                    onChanged: (v) {
                      notifier.updateConfig(config.copyWith(karaokeEnabled: v));
                      _save(context, notifier);
                    },
                    t: t,
                  ),
                ],
                const SizedBox(height: 24),

                // Default slideshow
                _sectionTitle(l.slideshowDefault, t),
                _buildToggle(
                  label: l.slideshowUseAsDefault,
                  value: notifier.defaultConfigId == config.id,
                  onChanged: (v) {
                    final newId = v ? config.id : null;
                    notifier.setDefaultConfigId(newId);
                    context.read<PreferencesService>().setDefaultSlideshowId(newId);
                  },
                  t: t,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        // Play button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: t.surfaceMid,
          child: ElevatedButton.icon(
            onPressed: () => _play(context, notifier, config),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: Text(l.slideshowPlay,
                style: TextStyle(
                    fontSize: t.fontSize(11),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.background,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransitionGrid(
      BuildContext context, SlideshowConfig config, SlideshowNotifier notifier, VisionTokens t) {
    final l = context.l;
    final types = TransitionType.values;
    final labels = [l.slideshowTransFade, l.slideshowTransSlideL, l.slideshowTransSlideR, l.slideshowTransSlideUp, l.slideshowTransZoom, l.slideshowTransXZoom];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(types.length, (i) {
        final selected = config.transition == types[i];
        return InkWell(
          onTap: () {
            notifier.updateConfig(config.copyWith(transition: types[i]));
            _save(context, notifier);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? t.accent.withValues(alpha: 0.15) : t.borderSubtle,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: selected ? t.accent : Colors.transparent, width: 1),
            ),
            child: Text(labels[i],
                style: TextStyle(
                    color: selected ? t.accent : t.textSecondary,
                    fontSize: t.fontSize(8),
                    letterSpacing: 1,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }),
    );
  }

  Widget _sectionTitle(String title, VisionTokens t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
              color: t.textTertiary,
              fontSize: t.fontSize(8),
              letterSpacing: 2,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _textField({
    required String value,
    required ValueChanged<String> onChanged,
    required VisionTokens t,
  }) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: onChanged,
      style: TextStyle(
          color: t.textSecondary, fontSize: t.fontSize(13), height: 1.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: t.borderSubtle,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    String? suffix,
    required ValueChanged<double> onChanged,
    required VisionTokens t,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: t.textDisabled,
                    fontSize: t.fontSize(8),
                    letterSpacing: 1)),
            Text(
                '${value.toStringAsFixed(1)}${suffix ?? ''}',
                style: TextStyle(
                    color: t.textSecondary,
                    fontSize: t.fontSize(9),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        VisionSlider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          activeColor: t.textPrimary.withValues(alpha: 0.2),
          inactiveColor: t.borderSubtle,
          thumbColor: t.textPrimary,
          thumbRadius: 6,
          overlayRadius: 12,
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required VisionTokens t,
  }) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.6,
          child: SizedBox(
            height: 24,
            width: 32,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: t.textPrimary,
              activeTrackColor: t.textDisabled,
              inactiveThumbColor: t.textMinimal,
              inactiveTrackColor: t.borderSubtle,
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(8),
                letterSpacing: 1)),
      ],
    );
  }

  String _sourceLabel(BuildContext context, SlideshowConfig config) {
    final l = context.l;
    switch (config.sourceType) {
      case ImageSourceType.allImages:
        return l.slideshowSourceAllImages;
      case ImageSourceType.album:
        return l.slideshowSourceAlbum;
      case ImageSourceType.favorites:
        return l.slideshowSourceFavorites;
      case ImageSourceType.custom:
        return l.slideshowSourceCustom(config.customImageBasenames.length);
    }
  }

  void _play(
      BuildContext context, SlideshowNotifier notifier, SlideshowConfig config) {
    final gallery = context.read<GalleryNotifier>();
    final playlist = notifier.buildPlaylist(config, gallery);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SlideshowPlayer(config: config, playlist: playlist),
      ),
    );
  }

  void _playAll(BuildContext context, SlideshowNotifier notifier) {
    final config = notifier.defaultConfig ?? const SlideshowConfig(
      id: '_quick_play',
      name: 'Quick Play',
    );
    _play(context, notifier, config);
  }

  void _save(BuildContext context, SlideshowNotifier notifier) {
    final prefs = context.read<PreferencesService>();
    prefs.setSlideshowConfigs(notifier.toJsonString());
  }

  Widget _buildMusicSongPicker(SlideshowConfig config, SlideshowNotifier notifier, VisionTokens t) {
    final songs = JukeboxRegistry.allSongs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SONGS (TAP TO SELECT, EMPTY = ALL)',
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(7), letterSpacing: 1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: songs.map((song) {
            final selected = config.musicSongIds.contains(song.id);
            return InkWell(
              onTap: () {
                final ids = List<String>.from(config.musicSongIds);
                if (selected) {
                  ids.remove(song.id);
                } else {
                  ids.add(song.id);
                }
                notifier.updateConfig(config.copyWith(musicSongIds: ids));
                _save(context, notifier);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? t.accent.withValues(alpha: 0.15) : t.borderSubtle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: selected ? t.accent : Colors.transparent),
                ),
                child: Text(song.title.toUpperCase(),
                    style: TextStyle(
                        color: selected ? t.accent : t.textSecondary,
                        fontSize: t.fontSize(7),
                        letterSpacing: 0.5,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMusicCategoryPicker(SlideshowConfig config, SlideshowNotifier notifier, VisionTokens t) {
    final categories = [null, ...SongCategory.values];
    final labels = ['ALL', ...SongCategory.values.map((c) => JukeboxRegistry.categoryDisplayName(c))];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(categories.length, (i) {
        final catIndex = categories[i]?.index;
        final selected = config.musicCategoryIndex == catIndex;
        return InkWell(
          onTap: () {
            if (catIndex == null) {
              notifier.updateConfig(config.copyWith(clearMusicCategory: true));
            } else {
              notifier.updateConfig(config.copyWith(musicCategoryIndex: catIndex));
            }
            _save(context, notifier);
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? t.accent.withValues(alpha: 0.15) : t.borderSubtle,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: selected ? t.accent : Colors.transparent),
            ),
            child: Text(labels[i],
                style: TextStyle(
                    color: selected ? t.accent : t.textSecondary,
                    fontSize: t.fontSize(8),
                    letterSpacing: 1,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }),
    );
  }

  Widget _buildMusicSoundFontPicker(SlideshowConfig config, SlideshowNotifier notifier, VisionTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SOUNDFONT',
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Default option
            _sfChip(null, 'DEFAULT', config.musicSoundFontId == null, notifier, config, t),
            ...JukeboxRegistry.allSoundFonts.map((sf) =>
                _sfChip(sf.id, sf.name.toUpperCase(), config.musicSoundFontId == sf.id, notifier, config, t)),
          ],
        ),
      ],
    );
  }

  Widget _sfChip(String? sfId, String label, bool selected, SlideshowNotifier notifier, SlideshowConfig config, VisionTokens t) {
    return InkWell(
      onTap: () {
        if (sfId == null) {
          notifier.updateConfig(config.copyWith(clearMusicSoundFontId: true));
        } else {
          notifier.updateConfig(config.copyWith(musicSoundFontId: sfId));
        }
        _save(context, notifier);
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? t.accent.withValues(alpha: 0.15) : t.borderSubtle,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? t.accent : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? t.accent : t.textSecondary,
                fontSize: t.fontSize(7),
                letterSpacing: 1,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Future<void> _showDeleteConfirm(BuildContext context, SlideshowNotifier notifier,
      SlideshowConfig config, VisionTokens t) async {
    final l = context.l;
    final confirm = await showConfirmDialog(
      context,
      title: l.slideshowDeleteConfig,
      message: l.slideshowDeleteConfirm(config.name.toUpperCase()),
      confirmLabel: l.commonDelete,
      confirmColor: t.accentDanger,
    );
    if (confirm == true && context.mounted) {
      notifier.deleteConfig(config.id);
      _save(context, notifier);
    }
  }
}
