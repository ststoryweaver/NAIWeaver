import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/jukebox/models/game_score.dart';
import '../../../../core/jukebox/models/jukebox_song.dart';
import '../../../../core/jukebox/providers/jukebox_notifier.dart';
import '../../../../core/jukebox/widgets/falling_notes_view.dart';
import '../../../../core/jukebox/widgets/game_lobby.dart';
import '../../../../core/jukebox/widgets/instrument_picker.dart';
import '../../../../core/jukebox/widgets/piano_keyboard.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/section_title.dart';
import 'jukebox_now_playing.dart';
import 'jukebox_song_list.dart';
import 'jukebox_soundfont_picker.dart';
import 'jukebox_style_section.dart';
import '../../../../core/l10n/l10n_extensions.dart';

class JukeboxPanel extends StatefulWidget {
  const JukeboxPanel({super.key});

  @override
  State<JukeboxPanel> createState() => _JukeboxPanelState();
}

class _JukeboxPanelState extends State<JukeboxPanel> {
  SongCategory? _selectedCategory;
  bool _expandedNowPlaying = false;
  final GlobalKey<FallingNotesViewState> _fallingNotesKey = GlobalKey();
  final Set<int> _activeKeys = {};
  JukeboxNotifier? _jukebox;
  bool _prevKeyboardMode = false;
  bool _prevGameMode = false;

  /// True when the physical device is phone-sized (shortestSide < 600).
  /// Unlike the global `isMobile()` (width < 600), this remains true in
  /// landscape so we keep the mobile layout on rotated phones.
  bool _isPhoneDevice(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide < 600;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final jukebox = context.read<JukeboxNotifier>();
    if (_jukebox != jukebox) {
      _jukebox?.removeListener(_onJukeboxChanged);
      _jukebox = jukebox;
      _jukebox!.addListener(_onJukeboxChanged);
      _prevKeyboardMode = jukebox.keyboardMode;
      _prevGameMode = jukebox.gameMode;
    }
  }

  void _onJukeboxChanged() {
    final kb = _jukebox!.keyboardMode;
    final gm = _jukebox!.gameMode;
    if ((_prevKeyboardMode && !kb) || (_prevGameMode && !gm)) {
      _activeKeys.clear();
    }
    _prevKeyboardMode = kb;
    _prevGameMode = gm;
  }

  @override
  void dispose() {
    _jukebox?.removeListener(_onJukeboxChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();
    final mobile = isMobile(context);
    final t = context.t;
    final l = context.l;

    if (!jukebox.synthAvailable) {
      return _buildUnavailable(t);
    }

    if (mobile || _isPhoneDevice(context)) {
      return Column(
        children: [
          _buildHeader(context, jukebox, t),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: Column(
              children: [
                if (jukebox.keyboardMode) ...[
                  // Route to game lobby screens
                  if (jukebox.lobbyScreen == GameLobbyScreen.songBrowser)
                    const Expanded(child: GameSongBrowser())
                  else if (jukebox.lobbyScreen == GameLobbyScreen.songDetail)
                    const Expanded(child: GameSongDetail())
                  else ...[
                    // Instrument picker + game button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InstrumentPicker(
                              t: t,
                              selectedProgram: jukebox.keyboardProgram,
                              onChanged: jukebox.setKeyboardInstrument,
                            ),
                          ),
                          if (jukebox.currentSong != null && !jukebox.gameMode) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: jukebox.openGameBrowser,
                              icon: Icon(Icons.sports_esports, size: 18, color: t.accent),
                              tooltip: l.jukeboxGameModeTooltip,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ],
                          if (jukebox.gameMode)
                            IconButton(
                              onPressed: () {
                                final savedScore = jukebox.currentScore;
                                final songId = jukebox.currentSong?.id;
                                jukebox.endGame();
                                _showGameResults(savedScore, songId, jukebox, t);
                              },
                              icon: Icon(Icons.stop, size: 18, color: t.accentDanger),
                              tooltip: l.jukeboxEndGameTooltip,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                        ],
                      ),
                    ),
                    // Falling notes or spacer
                    if (jukebox.gameMode && jukebox.noteBlocks != null)
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.black,
                              child: FallingNotesView(
                                key: _fallingNotesKey,
                                noteBlocks: jukebox.noteBlocks!,
                                targetChannel: jukebox.targetChannel,
                                gameMode: !jukebox.watchMode,
                                activeKeys: _activeKeys,
                                onHit: jukebox.onPlayerHit,
                                onMiss: jukebox.onPlayerMiss,
                                keyboardNoteMin: jukebox.noteRangeForChannel(jukebox.targetChannel)?.$1,
                                keyboardNoteMax: jukebox.noteRangeForChannel(jukebox.targetChannel)?.$2,
                              ),
                            ),
                            if (jukebox.countdown > 0)
                              _buildCountdownOverlay(jukebox.countdown, t),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    SafeArea(
                      top: false,
                      child: LayoutBuilder(builder: (context, constraints) {
                        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                        final kbHeight = isLandscape
                            ? (constraints.maxHeight * 0.35).clamp(80.0, 120.0)
                            : null;
                        final range = jukebox.gameMode
                            ? jukebox.noteRangeForChannel(jukebox.targetChannel)
                            : null;
                        return Container(
                          decoration: BoxDecoration(
                            color: t.surfaceMid,
                            border: Border(top: BorderSide(color: t.borderSubtle)),
                          ),
                          child: PianoKeyboard(
                            t: t,
                            startOctave: 3,
                            octaveCount: 4,
                            height: kbHeight,
                            gameMode: jukebox.gameMode,
                            gameNoteMin: range?.$1,
                            gameNoteMax: range?.$2,
                            highlightedNotes: jukebox.watchMode ? _activeKeys : null,
                            onNoteOn: (note) {
                              setState(() => _activeKeys.add(note));
                              jukebox.playNote(note, 100);
                              _fallingNotesKey.currentState?.tryHit(note);
                            },
                            onNoteOff: (note) {
                              setState(() => _activeKeys.remove(note));
                              jukebox.stopNote(note);
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ] else ...[
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
                if (!jukebox.keyboardMode)
                  JukeboxMobileNowPlaying(
                    jukebox: jukebox,
                    t: t,
                    expanded: _expandedNowPlaying,
                    onExpandedChanged: (v) => setState(() => _expandedNowPlaying = v),
                    expandedBody: _buildMobileExpandedBody(jukebox, t),
                  )
                else if (MediaQuery.of(context).orientation != Orientation.landscape)
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
            context.l.jukeboxMusicUnavailable,
            style: TextStyle(
              color: t.textMinimal,
              fontSize: t.fontSize(10),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isDesktopPlatform()
                ? context.l.jukeboxDllMissing
                : context.l.jukeboxSynthUnavailable,
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
    final l = context.l;
    final mobile = isMobile(context);
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        width: double.infinity,
        color: t.surfaceHigh,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.close, size: 20, color: t.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            const SizedBox(width: 4),
            Text(l.jukeboxTitle,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: t.fontSize(12),
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900)),
            const Spacer(),
            if (mobile)
              _buildMobileHeaderActions(jukebox, t)
            else
              _buildDesktopHeaderActions(jukebox, t),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeaderActions(JukeboxNotifier jukebox, VisionTokens t) {
    final l = context.l;
    return Row(
      children: [
        IconButton(
          onPressed: () => _importSong(jukebox),
          icon: Icon(Icons.file_open, size: 20, color: t.accent),
          tooltip: l.jukeboxImportTooltip,
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
          tooltip: l.jukeboxShuffleAllTooltip,
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
          tooltip: l.jukeboxPlayAllTooltip,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: jukebox.toggleKeyboardMode,
          icon: Icon(Icons.piano, size: 20,
              color: jukebox.keyboardMode ? t.accentEdit : t.accent),
          tooltip: l.jukeboxKeyboardTooltip,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _buildDesktopHeaderActions(JukeboxNotifier jukebox, VisionTokens t) {
    final l = context.l;
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

    Widget toggleButton(VoidCallback onPressed, IconData icon, String label, bool active) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: active ? t.accentEdit : t.accent),
        label: Text(label,
            style: TextStyle(
                color: active ? t.accentEdit : t.accent,
                fontSize: t.fontSize(9),
                letterSpacing: 1,
                fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          backgroundColor: active
              ? t.accentEdit.withValues(alpha: 0.15)
              : t.accent.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    return Row(
      children: [
        actionButton(() => _importSong(jukebox), Icons.file_open, l.jukeboxImport),
        const SizedBox(width: 8),
        actionButton(() {
          final songs = filteredSongs(jukebox, _selectedCategory);
          jukebox.playQueue(songs, shuffleQueue: true);
        }, Icons.shuffle, l.jukeboxShuffleAll),
        const SizedBox(width: 8),
        actionButton(() {
          final songs = filteredSongs(jukebox, _selectedCategory);
          jukebox.playQueue(songs);
        }, Icons.play_arrow, l.jukeboxPlayAll),
        const SizedBox(width: 8),
        toggleButton(
          jukebox.toggleKeyboardMode,
          Icons.piano,
          l.jukeboxKeyboard,
          jukebox.keyboardMode,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Desktop right panel
  // ─────────────────────────────────────────

  Widget _buildRightPanel(JukeboxNotifier jukebox, VisionTokens t) {
    final l = context.l;
    if (jukebox.keyboardMode) {
      return _buildKeyboardPanel(jukebox, t);
    }

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
                SectionTitle(l.jukeboxStyle, t: t),
                JukeboxStyleSection(jukebox: jukebox, t: t),
                const SizedBox(height: 24),
                SectionTitle(l.jukeboxSoundFont, t: t),
                JukeboxSoundFontPicker(jukebox: jukebox, t: t),
                const SizedBox(height: 24),
                SectionTitle(l.jukeboxSettings, t: t),
                JukeboxSettingsSection(jukebox: jukebox, t: t),
                const SizedBox(height: 24),
                SectionTitle(l.jukeboxQueueCount(jukebox.queue.length), t: t),
                JukeboxQueue(jukebox: jukebox, t: t),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardPanel(JukeboxNotifier jukebox, VisionTokens t) {
    final l = context.l;
    // Route to game lobby screens
    if (jukebox.lobbyScreen == GameLobbyScreen.songBrowser) {
      return const GameSongBrowser();
    }
    if (jukebox.lobbyScreen == GameLobbyScreen.songDetail) {
      return const GameSongDetail();
    }

    final hasGame = jukebox.gameMode && jukebox.noteBlocks != null;
    final range = jukebox.gameMode
        ? jukebox.noteRangeForChannel(jukebox.targetChannel)
        : null;

    return Column(
      children: [
        // Top bar: instrument picker + game controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: InstrumentPicker(
                  t: t,
                  selectedProgram: jukebox.keyboardProgram,
                  onChanged: jukebox.setKeyboardInstrument,
                ),
              ),
              const SizedBox(width: 8),
              if (jukebox.currentSong != null && !jukebox.gameMode)
                _buildSmallButton(t, l.jukeboxGame, Icons.sports_esports, () {
                  jukebox.openGameBrowser();
                }),
              if (jukebox.gameMode)
                _buildSmallButton(t, l.jukeboxEnd, Icons.stop, () {
                  final savedScore = jukebox.currentScore;
                  final songId = jukebox.currentSong?.id;
                  jukebox.endGame();
                  _showGameResults(savedScore, songId, jukebox, t);
                }, color: t.accentDanger),
            ],
          ),
        ),
        // Tempo slider
        if (jukebox.currentSong != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(l.jukeboxTempo,
                    style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(8),
                      letterSpacing: 1,
                    )),
                Expanded(
                  child: Slider(
                    value: jukebox.tempo,
                    min: 0.25,
                    max: 2.0,
                    divisions: 7,
                    activeColor: t.accent,
                    inactiveColor: t.borderSubtle,
                    label: '${jukebox.tempo.toStringAsFixed(2)}x',
                    onChanged: jukebox.setTempo,
                  ),
                ),
                Text('${jukebox.tempo.toStringAsFixed(2)}x',
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: t.fontSize(9),
                    )),
              ],
            ),
          ),
        if (!hasGame)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  l.jukeboxKeyboardHint,
                  style: TextStyle(
                    color: t.textMinimal,
                    fontSize: t.fontSize(8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        // Falling notes area (when game/watch active)
        if (hasGame)
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Colors.black,
                  child: FallingNotesView(
                    key: _fallingNotesKey,
                    noteBlocks: jukebox.noteBlocks!,
                    targetChannel: jukebox.targetChannel,
                    gameMode: !jukebox.watchMode,
                    activeKeys: _activeKeys,
                    onHit: jukebox.onPlayerHit,
                    onMiss: jukebox.onPlayerMiss,
                    keyboardNoteMin: range?.$1,
                    keyboardNoteMax: range?.$2,
                  ),
                ),
                if (jukebox.countdown > 0)
                  _buildCountdownOverlay(jukebox.countdown, t),
              ],
            ),
          )
        else
          const Spacer(),
        // Piano keyboard at bottom
        LayoutBuilder(builder: (context, constraints) {
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          final kbHeight = isLandscape
              ? (constraints.maxHeight * 0.35).clamp(80.0, 120.0)
              : null;
          return Container(
            decoration: BoxDecoration(
              color: t.surfaceMid,
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: PianoKeyboard(
              t: t,
              height: kbHeight,
              gameMode: jukebox.gameMode,
              gameNoteMin: range?.$1,
              gameNoteMax: range?.$2,
              highlightedNotes: jukebox.watchMode ? _activeKeys : null,
              onNoteOn: (note) {
                setState(() => _activeKeys.add(note));
                jukebox.playNote(note, 100);
                _fallingNotesKey.currentState?.tryHit(note);
              },
              onNoteOff: (note) {
                setState(() => _activeKeys.remove(note));
                jukebox.stopNote(note);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSmallButton(VisionTokens t, String label, IconData icon,
      VoidCallback onPressed, {Color? color}) {
    final c = color ?? t.accent;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: c),
      label: Text(label,
          style: TextStyle(
            color: c,
            fontSize: t.fontSize(8),
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          )),
      style: TextButton.styleFrom(
        backgroundColor: c.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCountdownOverlay(int countdown, VisionTokens t) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Text(
          '$countdown',
          style: TextStyle(
            color: t.accent,
            fontSize: t.fontSize(48),
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
              Shadow(color: t.accent.withValues(alpha: 0.5), blurRadius: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameResults(GameScore? score, String? songId, JukeboxNotifier jukebox, VisionTokens t) {
    if (score == null) return;

    final highScores = songId != null ? jukebox.highScoresForSong(songId) : <HighScoreEntry>[];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(
          context.l.jukeboxGameResults,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: t.fontSize(14),
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                score.rank,
                style: TextStyle(
                  color: score.rank == 'S'
                      ? const Color(0xFFFFD700)
                      : score.rank == 'A'
                          ? const Color(0xFF22C55E)
                          : t.textPrimary,
                  fontSize: t.fontSize(36),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _resultRow(t, context.l.jukeboxGameScore, '${score.score}'),
            _resultRow(t, context.l.jukeboxGameMaxCombo, '${score.maxCombo}'),
            _resultRow(t, context.l.jukeboxGameAccuracy, '${(score.accuracy * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            _resultRow(t, context.l.jukeboxGamePerfect, '${score.perfects}', color: const Color(0xFFFFD700)),
            _resultRow(t, context.l.jukeboxGameGreat, '${score.greats}', color: const Color(0xFF22C55E)),
            _resultRow(t, context.l.jukeboxGameGood, '${score.goods}', color: const Color(0xFF3B82F6)),
            _resultRow(t, context.l.jukeboxGameMiss, '${score.misses}', color: const Color(0xFFEF4444)),
            if (highScores.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: t.borderSubtle),
              const SizedBox(height: 8),
              Text(
                context.l.jukeboxHighScores,
                style: TextStyle(
                  color: t.textMinimal,
                  fontSize: t.fontSize(9),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              ...highScores.take(3).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('#${i + 1}',
                          style: TextStyle(
                            color: t.textMinimal,
                            fontSize: t.fontSize(9),
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(width: 8),
                      Text(s.rank,
                          style: TextStyle(
                            color: s.rank == 'S'
                                ? const Color(0xFFFFD700)
                                : s.rank == 'A'
                                    ? const Color(0xFF22C55E)
                                    : t.textPrimary,
                            fontSize: t.fontSize(10),
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(width: 8),
                      Text('${s.score}',
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: t.fontSize(9),
                            fontWeight: FontWeight.bold,
                          )),
                      const Spacer(),
                      Text('${(s.accuracy * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: t.fontSize(9),
                          )),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Return to song detail screen if we came from the lobby
              if (jukebox.lobbySong != null) {
                jukebox.returnToSongDetail();
              }
            },
            child: Text('CLOSE',
                style: TextStyle(color: t.accent, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(VisionTokens t, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: color ?? t.textSecondary,
                fontSize: t.fontSize(10),
                letterSpacing: 1,
              )),
          Text(value,
              style: TextStyle(
                color: color ?? t.textPrimary,
                fontSize: t.fontSize(10),
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
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
          SectionTitle(context.l.jukeboxStyle, t: t),
          JukeboxStyleSection(jukebox: jukebox, t: t),
          const SizedBox(height: 16),
          SectionTitle(context.l.jukeboxSoundFont, t: t),
          JukeboxSoundFontPicker(jukebox: jukebox, t: t),
          const SizedBox(height: 16),
          SectionTitle(context.l.jukeboxSettings, t: t),
          JukeboxMobileSettingsRow(jukebox: jukebox, t: t),
          const SizedBox(height: 16),
          SectionTitle(context.l.jukeboxQueueCount(jukebox.queue.length), t: t),
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
