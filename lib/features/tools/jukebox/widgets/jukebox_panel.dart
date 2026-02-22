import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/jukebox/models/jukebox_song.dart';
import '../../../../core/jukebox/providers/jukebox_notifier.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/section_title.dart';
import 'jukebox_now_playing.dart';
import 'jukebox_song_list.dart';
import 'jukebox_soundfont_picker.dart';
import 'jukebox_style_section.dart';

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
      return _buildUnavailable(t);
    }

    if (mobile) {
      return Column(
        children: [
          _buildHeader(context, jukebox, t),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: Column(
              children: [
                JukeboxCategoryChips(
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                  t: t,
                ),
                Expanded(
                  child: JukeboxSongList(
                    jukebox: jukebox,
                    t: t,
                    songs: filteredSongs(jukebox, _selectedCategory),
                  ),
                ),
                JukeboxMobileNowPlaying(
                  jukebox: jukebox,
                  t: t,
                  expanded: _expandedNowPlaying,
                  onExpandedChanged: (v) => setState(() => _expandedNowPlaying = v),
                  expandedBody: _buildMobileExpandedBody(jukebox, t),
                ),
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
                    JukeboxCategoryChips(
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                      t: t,
                    ),
                    Expanded(
                      child: JukeboxSongList(
                        jukebox: jukebox,
                        t: t,
                        songs: filteredSongs(jukebox, _selectedCategory),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: t.textMinimal),
              // Right: Now Playing + Settings
              Expanded(child: _buildRightPanel(jukebox, t)),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Synth unavailable placeholder
  // ─────────────────────────────────────────

  Widget _buildUnavailable(VisionTokens t) {
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

  // ─────────────────────────────────────────
  // Header bar
  // ─────────────────────────────────────────

  Widget _buildHeader(BuildContext context, JukeboxNotifier jukebox, VisionTokens t) {
    final mobile = isMobile(context);
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
          if (mobile)
            _buildMobileHeaderActions(jukebox, t)
          else
            _buildDesktopHeaderActions(jukebox, t),
        ],
      ),
    );
  }

  Widget _buildMobileHeaderActions(JukeboxNotifier jukebox, VisionTokens t) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _importSong(jukebox),
          icon: Icon(Icons.file_open, size: 20, color: t.accent),
          tooltip: 'Import',
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () {
            final songs = filteredSongs(jukebox, _selectedCategory);
            jukebox.playQueue(songs, shuffleQueue: true);
          },
          icon: Icon(Icons.shuffle, size: 20, color: t.accent),
          tooltip: 'Shuffle All',
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () {
            final songs = filteredSongs(jukebox, _selectedCategory);
            jukebox.playQueue(songs);
          },
          icon: Icon(Icons.play_arrow, size: 20, color: t.accent),
          tooltip: 'Play All',
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _buildDesktopHeaderActions(JukeboxNotifier jukebox, VisionTokens t) {
    Widget actionButton(VoidCallback onPressed, IconData icon, String label) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: t.accent),
        label: Text(label,
            style: TextStyle(
                color: t.accent,
                fontSize: t.fontSize(9),
                letterSpacing: 1,
                fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          backgroundColor: t.accent.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    return Row(
      children: [
        actionButton(() => _importSong(jukebox), Icons.file_open, 'IMPORT'),
        const SizedBox(width: 8),
        actionButton(() {
          final songs = filteredSongs(jukebox, _selectedCategory);
          jukebox.playQueue(songs, shuffleQueue: true);
        }, Icons.shuffle, 'SHUFFLE ALL'),
        const SizedBox(width: 8),
        actionButton(() {
          final songs = filteredSongs(jukebox, _selectedCategory);
          jukebox.playQueue(songs);
        }, Icons.play_arrow, 'PLAY ALL'),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Desktop right panel
  // ─────────────────────────────────────────

  Widget _buildRightPanel(JukeboxNotifier jukebox, VisionTokens t) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JukeboxNowPlaying(jukebox: jukebox, t: t),
                const SizedBox(height: 24),
                SectionTitle('STYLE', t: t),
                JukeboxStyleSection(jukebox: jukebox, t: t),
                const SizedBox(height: 24),
                SectionTitle('SOUNDFONT', t: t),
                JukeboxSoundFontPicker(jukebox: jukebox, t: t),
                const SizedBox(height: 24),
                SectionTitle('SETTINGS', t: t),
                JukeboxSettingsSection(jukebox: jukebox, t: t),
                const SizedBox(height: 24),
                SectionTitle('QUEUE (${jukebox.queue.length})', t: t),
                JukeboxQueue(jukebox: jukebox, t: t),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Mobile expanded now-playing body
  // ─────────────────────────────────────────

  Widget _buildMobileExpandedBody(JukeboxNotifier jukebox, VisionTokens t) {
    final song = jukebox.currentSong;
    if (song == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song info
          JukeboxNowPlaying.buildSongTitle(song, t),
          if (song.artist != null) JukeboxNowPlaying.buildSongArtist(song, t),
          JukeboxNowPlaying.buildSongBadges(song, t),
          const SizedBox(height: 16),

          // Transport controls
          JukeboxNowPlaying.buildTransportControls(jukebox, t),

          // Visualizer
          if (jukebox.showKaraokeInPanel) ...[
            const SizedBox(height: 16),
            JukeboxNowPlaying.buildVisualizerPreview(context, jukebox, t, height: 120),
          ],

          const SizedBox(height: 16),
          SectionTitle('STYLE', t: t),
          JukeboxStyleSection(jukebox: jukebox, t: t),
          const SizedBox(height: 16),
          SectionTitle('SOUNDFONT', t: t),
          JukeboxSoundFontPicker(jukebox: jukebox, t: t),
          const SizedBox(height: 16),
          SectionTitle('SETTINGS', t: t),
          JukeboxMobileSettingsRow(jukebox: jukebox, t: t),
          const SizedBox(height: 16),
          SectionTitle('QUEUE (${jukebox.queue.length})', t: t),
          JukeboxQueue(jukebox: jukebox, t: t),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // File import
  // ─────────────────────────────────────────

  Future<void> _importSong(JukeboxNotifier jukebox) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kar', 'mid', 'midi'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await jukebox.importSong(path);
  }
}
