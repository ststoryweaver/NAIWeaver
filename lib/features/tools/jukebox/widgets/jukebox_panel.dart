import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/jukebox/models/jukebox_song.dart';
import '../../../../core/jukebox/models/jukebox_soundfont.dart';
import '../../../../core/jukebox/jukebox_registry.dart';
import '../../../../core/jukebox/providers/jukebox_notifier.dart';
import '../../../../core/jukebox/widgets/karaoke_overlay.dart';
import '../../../../core/jukebox/widgets/karaoke_visualizer.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/responsive.dart';

class JukeboxPanel extends StatefulWidget {
  const JukeboxPanel({super.key});

  @override
  State<JukeboxPanel> createState() => _JukeboxPanelState();
}

class _JukeboxPanelState extends State<JukeboxPanel> {
  SongCategory? _selectedCategory;
  bool _expandedNowPlaying = false;

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();
    final mobile = isMobile(context);
    final t = context.t;

    if (!jukebox.synthAvailable) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off, color: t.textMinimal, size: 48),
            const SizedBox(height: 16),
            Text(
              'MUSIC PLAYBACK UNAVAILABLE',
              style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(10),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDesktopPlatform()
                  ? 'FluidSynth DLL not found'
                  : 'Synthesizer unavailable',
              style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(8),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    if (mobile) {
      return Column(
        children: [
          _buildHeader(context, jukebox, t),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: Column(
              children: [
                _buildCategoryChips(t),
                Expanded(child: _buildSongList(jukebox, t)),
                _buildMobileNowPlaying(jukebox, t),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(context, jukebox, t),
        Divider(height: 1, color: t.textMinimal),
        Expanded(
          child: Row(
            children: [
              // Left: Category browser + song list
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    _buildCategoryChips(t),
                    Expanded(child: _buildSongList(jukebox, t)),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: t.textMinimal),
              // Right: Now Playing + Settings
              Expanded(
                child: _buildRightPanel(jukebox, t),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, JukeboxNotifier jukebox, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: t.surfaceHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('JUKEBOX',
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(12),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900)),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  final songs = _selectedCategory != null
                      ? JukeboxRegistry.songsByCategory(_selectedCategory!)
                      : JukeboxRegistry.allSongs;
                  jukebox.playQueue(songs, shuffleQueue: true);
                },
                icon: Icon(Icons.shuffle, size: 16, color: t.accent),
                label: Text('SHUFFLE ALL',
                    style: TextStyle(
                        color: t.accent,
                        fontSize: t.fontSize(9),
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: t.accent.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  final songs = _selectedCategory != null
                      ? JukeboxRegistry.songsByCategory(_selectedCategory!)
                      : JukeboxRegistry.allSongs;
                  jukebox.playQueue(songs);
                },
                icon: Icon(Icons.play_arrow, size: 16, color: t.accent),
                label: Text('PLAY ALL',
                    style: TextStyle(
                        color: t.accent,
                        fontSize: t.fontSize(9),
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: t.accent.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(dynamic t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: t.surfaceMid,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _categoryChip(null, 'ALL', t),
            ...SongCategory.values.map((cat) => _categoryChip(
                cat, JukeboxRegistry.categoryDisplayName(cat), t)),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(SongCategory? cat, String label, dynamic t) {
    final selected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = cat),
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
          child: Text(label,
              style: TextStyle(
                  color: selected ? t.accent : t.textSecondary,
                  fontSize: t.fontSize(8),
                  letterSpacing: 1,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildSongList(JukeboxNotifier jukebox, dynamic t) {
    final songs = _selectedCategory != null
        ? JukeboxRegistry.songsByCategory(_selectedCategory!)
        : JukeboxRegistry.allSongs;

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrent = jukebox.currentSong?.id == song.id;

        return InkWell(
          onTap: () => jukebox.playSong(song),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: isCurrent ? t.borderSubtle : Colors.transparent,
            child: Row(
              children: [
                if (isCurrent && jukebox.isPlaying)
                  Icon(Icons.equalizer, size: 14, color: t.accent)
                else
                  Icon(Icons.music_note, size: 14, color: t.textMinimal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? t.textPrimary : t.textSecondary,
                          fontSize: t.fontSize(9),
                          letterSpacing: 1,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (song.artist != null)
                        Text(
                          song.artist!.toUpperCase(),
                          style: TextStyle(
                            color: t.textMinimal,
                            fontSize: t.fontSize(7),
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),
                ),
                if (song.isKaraoke)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text('KAR',
                        style: TextStyle(
                            color: t.accent,
                            fontSize: t.fontSize(6),
                            fontWeight: FontWeight.bold)),
                  ),
                if (song.durationSeconds != null)
                  Text(
                    _formatDuration(Duration(seconds: song.durationSeconds!)),
                    style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(8),
                    ),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.add, size: 14, color: t.textDisabled),
                  onPressed: () {
                    jukebox.addToQueue(song);
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Add to queue',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Desktop Right Panel
  // ─────────────────────────────────────────

  Widget _buildRightPanel(JukeboxNotifier jukebox, dynamic t) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Now Playing
                _buildNowPlayingSection(jukebox, t),

                // Karaoke + Visualizer
                if (jukebox.showKaraokeInPanel &&
                    jukebox.currentSong != null &&
                    jukebox.currentSong!.isKaraoke) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: t.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: t.borderSubtle),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          KaraokeVisualizer(),
                          KaraokeOverlay(),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // SoundFont Picker
                _buildSectionTitle('SOUNDFONT', t),
                _buildSoundFontPicker(jukebox, t),
                const SizedBox(height: 24),

                // Settings
                _buildSectionTitle('SETTINGS', t),
                _buildSettingsSection(jukebox, t),
                const SizedBox(height: 24),

                // Karaoke Style
                _buildSectionTitle('KARAOKE STYLE', t),
                _buildKaraokeStyleSection(jukebox, t),
                const SizedBox(height: 24),

                // Queue
                _buildSectionTitle('QUEUE (${jukebox.queue.length})', t),
                _buildQueue(jukebox, t),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNowPlayingSection(JukeboxNotifier jukebox, dynamic t) {
    final song = jukebox.currentSong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionTitle('NOW PLAYING', t)),
            if (song != null && song.isKaraoke)
              IconButton(
                icon: Icon(
                  jukebox.showKaraokeInPanel ? Icons.lyrics : Icons.lyrics_outlined,
                  size: 16,
                  color: jukebox.showKaraokeInPanel ? t.accent : t.textDisabled,
                ),
                onPressed: jukebox.toggleKaraokeInPanel,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                tooltip: 'Toggle karaoke display',
              ),
          ],
        ),
        if (song == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('NO SONG PLAYING',
                  style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(9),
                      letterSpacing: 2)),
            ),
          )
        else ...[
          Text(
            song.title.toUpperCase(),
            style: TextStyle(
              color: t.textPrimary,
              fontSize: t.fontSize(14),
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (song.artist != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                song.artist!.toUpperCase(),
                style: TextStyle(
                  color: t.textTertiary,
                  fontSize: t.fontSize(10),
                  letterSpacing: 1,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(song.categoryLabel,
                      style: TextStyle(
                          color: t.textDisabled,
                          fontSize: t.fontSize(7),
                          letterSpacing: 1)),
                ),
                if (song.isKaraoke) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text('KARAOKE',
                        style: TextStyle(
                            color: t.accent,
                            fontSize: t.fontSize(7),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTransportControls(jukebox, t),
        ],
      ],
    );
  }

  Widget _buildTransportControls(JukeboxNotifier jukebox, dynamic t) {
    return Column(
      children: [
        // Seek bar
        Row(
          children: [
            Text(
              _formatDuration(jukebox.position),
              style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(7)),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: t.accent,
                  inactiveTrackColor: t.borderSubtle,
                  thumbColor: t.accent,
                ),
                child: Slider(
                  value: jukebox.duration.inMilliseconds > 0
                      ? (jukebox.position.inMilliseconds / jukebox.duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: (v) {
                    final target = Duration(milliseconds: (v * jukebox.duration.inMilliseconds).round());
                    jukebox.seek(target);
                  },
                ),
              ),
            ),
            Text(
              _formatDuration(jukebox.duration),
              style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(7)),
            ),
          ],
        ),
        // Transport buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.skip_previous, color: t.textSecondary, size: 28),
              onPressed: jukebox.previous,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                jukebox.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: t.accent,
                size: 44,
              ),
              onPressed: jukebox.isPlaying ? jukebox.pause : jukebox.resume,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.skip_next, color: t.textSecondary, size: 28),
              onPressed: jukebox.next,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Volume
        Row(
          children: [
            IconButton(
              icon: Icon(
                jukebox.isMuted ? Icons.volume_off : Icons.volume_up,
                size: 16,
                color: t.textDisabled,
              ),
              onPressed: jukebox.toggleMute,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                  activeTrackColor: t.textPrimary.withValues(alpha: 0.3),
                  inactiveTrackColor: t.borderSubtle,
                  thumbColor: t.textPrimary,
                ),
                child: Slider(
                  value: jukebox.isMuted ? 0.0 : jukebox.volume,
                  onChanged: (v) => jukebox.setVolume(v),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoundFontPicker(JukeboxNotifier jukebox, dynamic t) {
    return Column(
      children: JukeboxRegistry.allSoundFonts.map((sf) {
        final selected = jukebox.activeSoundFont.id == sf.id;
        final available = jukebox.isSoundFontAvailable(sf);
        final dlState = jukebox.sfDownloadState(sf.id);
        final isDownloading = dlState.status == SoundFontDownloadStatus.downloading;
        final isError = dlState.status == SoundFontDownloadStatus.error;
        final isDownloaded = jukebox.downloadedSoundFontIds.contains(sf.id);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: selected ? t.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? t.accent : t.borderSubtle,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: available ? () => jukebox.setSoundFont(sf) : null,
                child: Row(
                  children: [
                    if (sf.isGag)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.sentiment_very_satisfied, size: 14, color: t.accent),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sf.name.toUpperCase(),
                              style: TextStyle(
                                  color: available
                                      ? (selected ? t.accent : t.textSecondary)
                                      : t.textDisabled,
                                  fontSize: t.fontSize(9),
                                  letterSpacing: 1,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                          Text(sf.description,
                              style: TextStyle(
                                  color: t.textMinimal,
                                  fontSize: t.fontSize(7),
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    // Status badges & actions
                    if (sf.isBundled && !sf.isDownloadable) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text('BUNDLED',
                            style: TextStyle(
                                color: t.textMinimal,
                                fontSize: t.fontSize(6),
                                letterSpacing: 0.5)),
                      ),
                    ] else if (isDownloading) ...[
                      // Cancel button during download
                      InkWell(
                        onTap: () => jukebox.cancelSoundFontDownload(sf.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text('CANCEL',
                              style: TextStyle(
                                  color: t.accent,
                                  fontSize: t.fontSize(7),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                    ] else if (isError) ...[
                      InkWell(
                        onTap: () => jukebox.downloadSoundFont(sf),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text('RETRY',
                              style: TextStyle(
                                  color: t.accent,
                                  fontSize: t.fontSize(7),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                    ] else if (isDownloaded) ...[
                      if (selected)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.check, size: 14, color: t.accent),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 14, color: t.textMinimal),
                        onPressed: () => _confirmDeleteSoundFont(context, jukebox, sf, t),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        tooltip: 'Delete soundfont',
                      ),
                    ] else ...[
                      // Not downloaded — show download button
                      Text(sf.fileSizeLabel,
                          style: TextStyle(
                              color: t.textMinimal,
                              fontSize: t.fontSize(7))),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => jukebox.downloadSoundFont(sf),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text('DOWNLOAD',
                              style: TextStyle(
                                  color: t.accent,
                                  fontSize: t.fontSize(7),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                    if (selected && sf.isBundled)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 14, color: t.accent),
                      ),
                  ],
                ),
              ),
              // Progress bar during download
              if (isDownloading) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: dlState.progress,
                          backgroundColor: t.borderSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(dlState.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: t.textMinimal,
                            fontSize: t.fontSize(7))),
                  ],
                ),
              ],
              // Error message
              if (isError && dlState.errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(dlState.errorMessage!,
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: t.fontSize(7))),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmDeleteSoundFont(
      BuildContext context, JukeboxNotifier jukebox, JukeboxSoundFont sf, dynamic t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text('DELETE SOUNDFONT',
            style: TextStyle(
                color: t.textPrimary,
                fontSize: t.fontSize(11),
                letterSpacing: 2,
                fontWeight: FontWeight.bold)),
        content: Text(
          'Delete ${sf.name}? You can re-download it later.',
          style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL',
                style: TextStyle(
                    color: t.textDisabled,
                    fontSize: t.fontSize(8),
                    letterSpacing: 1)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              jukebox.deleteSoundFont(sf);
            },
            child: Text('DELETE',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: t.fontSize(8),
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(JukeboxNotifier jukebox, dynamic t) {
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

  // ─────────────────────────────────────────
  // Karaoke Style Customization
  // ─────────────────────────────────────────

  static const _swatchColors = [
    Color(0xFF64FFDA), // teal
    Color(0xFFFFD740), // gold
    Color(0xFFFF80AB), // pink
    Color(0xFF80D8FF), // cyan
    Color(0xFFFFFFFF), // white
    Color(0xFFB388FF), // purple
    Color(0xFFFF8A65), // coral
    Color(0xFFCCFF90), // lime
  ];

  Widget _buildKaraokeStyleSection(JukeboxNotifier jukebox, dynamic t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlight color
        _buildColorRow('HIGHLIGHT', jukebox.karaokeHighlightColor, t.accent as Color,
            (c) => jukebox.setKaraokeHighlightColor(c), t),
        const SizedBox(height: 10),
        // Upcoming color
        _buildColorRow('UPCOMING', jukebox.karaokeUpcomingColor, t.textPrimary as Color,
            (c) => jukebox.setKaraokeUpcomingColor(c), t),
        const SizedBox(height: 10),
        // Next line color
        _buildColorRow('NEXT LINE', jukebox.karaokeNextLineColor, t.textMinimal as Color,
            (c) => jukebox.setKaraokeNextLineColor(c), t),
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
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: t.accent,
                  inactiveTrackColor: t.borderSubtle,
                  thumbColor: t.accent,
                ),
                child: Slider(
                  value: jukebox.karaokeFontScale,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) => jukebox.setKaraokeFontScale(v),
                ),
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

  Widget _buildColorRow(String label, Color? current, Color themeDefault,
      void Function(Color?) onSet, dynamic t) {
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
        ..._swatchColors.map((color) {
          final isSelected = current != null && current.toARGB32() == color.toARGB32();
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => onSet(color),
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
            onTap: () => onSet(null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: t.borderSubtle),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('DEFAULT',
                  style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(6),
                      letterSpacing: 0.5)),
            ),
          ),
      ],
    );
  }

  Widget _buildQueue(JukeboxNotifier jukebox, dynamic t) {
    if (jukebox.queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('QUEUE IS EMPTY',
            style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(8),
                letterSpacing: 1)),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jukebox.queue.length,
      onReorder: jukebox.reorderQueue,
      itemBuilder: (context, index) {
        final song = jukebox.queue[index];
        final isCurrent = jukebox.currentSong != null && song.id == jukebox.currentSong!.id;
        return ListTile(
          key: ValueKey('${song.id}_$index'),
          dense: true,
          leading: Icon(
            isCurrent ? Icons.equalizer : Icons.drag_handle,
            size: 14,
            color: isCurrent ? t.accent : t.textMinimal,
          ),
          title: Text(
            song.title.toUpperCase(),
            style: TextStyle(
              color: isCurrent ? t.accent : t.textSecondary,
              fontSize: t.fontSize(8),
              letterSpacing: 1,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.close, size: 12, color: t.textMinimal),
            onPressed: () => jukebox.removeFromQueue(index),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // Mobile Expandable Now Playing
  // ─────────────────────────────────────────

  Widget _buildMobileNowPlaying(JukeboxNotifier jukebox, dynamic t) {
    if (jukebox.currentSong == null) return const SizedBox.shrink();

    final song = jukebox.currentSong!;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _expandedNowPlaying ? screenHeight * 0.7 : null,
      color: t.surfaceMid,
      child: Column(
        mainAxisSize: _expandedNowPlaying ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Drag handle
          GestureDetector(
            onVerticalDragUpdate: (d) {
              if (d.primaryDelta != null) {
                if (d.primaryDelta! < -5) setState(() => _expandedNowPlaying = true);
                if (d.primaryDelta! > 5) setState(() => _expandedNowPlaying = false);
              }
            },
            onTap: () => setState(() => _expandedNowPlaying = !_expandedNowPlaying),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.textMinimal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          if (!_expandedNowPlaying) ...[
            // Compact transport bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      song.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: t.fontSize(9),
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 20, color: t.textSecondary),
                    onPressed: jukebox.previous,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: Icon(
                      jukebox.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 24,
                      color: t.accent,
                    ),
                    onPressed: jukebox.isPlaying ? jukebox.pause : jukebox.resume,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 20, color: t.textSecondary),
                    onPressed: jukebox.next,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  Icon(
                    Icons.expand_less,
                    size: 16,
                    color: t.textMinimal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],

          if (_expandedNowPlaying)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Now Playing info
                    Text(
                      song.title.toUpperCase(),
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: t.fontSize(14),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (song.artist != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          song.artist!.toUpperCase(),
                          style: TextStyle(
                            color: t.textTertiary,
                            fontSize: t.fontSize(10),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.borderSubtle,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(song.categoryLabel,
                                style: TextStyle(
                                    color: t.textDisabled,
                                    fontSize: t.fontSize(7),
                                    letterSpacing: 1)),
                          ),
                          if (song.isKaraoke) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text('KARAOKE',
                                  style: TextStyle(
                                      color: t.accent,
                                      fontSize: t.fontSize(7),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full transport controls
                    _buildTransportControls(jukebox, t),

                    // Karaoke + visualizer (if karaoke song)
                    if (jukebox.showKaraokeInPanel &&
                        song.isKaraoke &&
                        jukebox.lyrics.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: t.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: t.borderSubtle),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              KaraokeVisualizer(),
                              KaraokeOverlay(),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // SoundFont picker
                    _buildSectionTitle('SOUNDFONT', t),
                    _buildSoundFontPicker(jukebox, t),
                    const SizedBox(height: 16),

                    // Compact settings row
                    _buildSectionTitle('SETTINGS', t),
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
                        if (song.isKaraoke) ...[
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              jukebox.showKaraokeInPanel ? Icons.lyrics : Icons.lyrics_outlined,
                              size: 16,
                              color: jukebox.showKaraokeInPanel ? t.accent : t.textDisabled,
                            ),
                            onPressed: jukebox.toggleKaraokeInPanel,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Queue
                    _buildSectionTitle('QUEUE (${jukebox.queue.length})', t),
                    _buildQueue(jukebox, t),
                    const SizedBox(height: 16),

                    // Karaoke style
                    _buildSectionTitle('KARAOKE STYLE', t),
                    _buildKaraokeStyleSection(jukebox, t),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, dynamic t) {
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
