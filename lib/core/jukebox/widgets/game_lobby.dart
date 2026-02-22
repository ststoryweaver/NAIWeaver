import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/channel_info.dart';
import '../models/game_score.dart';
import '../models/jukebox_song.dart';
import '../jukebox_registry.dart';
import '../providers/jukebox_notifier.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/vision_tokens.dart';
import '../../l10n/l10n_extensions.dart';

/// Two-screen game lobby: song browser + song detail with channel select.

/// Returns a localized display string for a [Difficulty] enum value.
String _difficultyLabel(BuildContext context, Difficulty d) {
  final l = context.l;
  return switch (d) {
    Difficulty.easy => l.jukeboxDifficultyEasy,
    Difficulty.medium => l.jukeboxDifficultyMedium,
    Difficulty.hard => l.jukeboxDifficultyHard,
    Difficulty.extreme => l.jukeboxDifficultyExtreme,
  };
}

/// Shared rank color mapping.
Color rankColor(String rank) {
  return switch (rank) {
    'S' => const Color(0xFFFFD700),
    'A' => const Color(0xFF22C55E),
    'B' => const Color(0xFF3B82F6),
    'C' => const Color(0xFFF97316),
    _ => const Color(0xFFEF4444),
  };
}

// ─────────────────────────────────────────
// Screen 1: Song Browser
// ─────────────────────────────────────────

class GameSongBrowser extends StatefulWidget {
  const GameSongBrowser({super.key});

  @override
  State<GameSongBrowser> createState() => _GameSongBrowserState();
}

class _GameSongBrowserState extends State<GameSongBrowser> {
  SongCategory? _selectedCategory;

  List<JukeboxSong> _filteredSongs(JukeboxNotifier jukebox) {
    if (_selectedCategory != null) {
      if (_selectedCategory == SongCategory.custom) {
        return jukebox.customSongs;
      }
      return JukeboxRegistry.songsByCategory(_selectedCategory!);
    }
    return jukebox.allSongs;
  }

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();
    final t = context.t;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Text(
                context.l.jukeboxGameMode,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(12),
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: jukebox.closeGameBrowser,
                icon: Icon(Icons.close, size: 20, color: t.textSecondary),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: t.borderSubtle),
        // Category chips
        _buildCategoryChips(t),
        Divider(height: 1, color: t.borderSubtle),
        // Song list
        Expanded(
          child: _buildSongList(jukebox, t),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(VisionTokens t) {
    final categories = [null, ...SongCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: categories.map((cat) {
          final selected = cat == _selectedCategory;
          final label = cat?.name.toUpperCase() ?? context.l.jukeboxCategoryAll;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              labelStyle: TextStyle(
                color: selected ? Colors.white : t.textSecondary,
                fontSize: t.fontSize(8),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: t.surfaceMid,
              selectedColor: t.accent.withValues(alpha: 0.3),
              side: BorderSide(
                color: selected
                    ? t.accent.withValues(alpha: 0.5)
                    : t.borderSubtle,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSongList(JukeboxNotifier jukebox, VisionTokens t) {
    final songs = _filteredSongs(jukebox);
    if (songs.isEmpty) {
      return Center(
        child: Text(
          context.l.jukeboxNoSongs,
          style: TextStyle(
            color: t.textMinimal,
            fontSize: t.fontSize(10),
            letterSpacing: 2,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        final song = songs[index];
        final scores = jukebox.highScoresForSong(song.id);
        final bestRank = scores.isNotEmpty ? scores.first.rank : null;

        return InkWell(
          onTap: () => jukebox.selectGameSong(song),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: t.fontSize(11),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (song.artist != null)
                            Flexible(
                              child: Text(
                                song.artist!,
                                style: TextStyle(
                                  color: t.textSecondary,
                                  fontSize: t.fontSize(9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (song.artist != null) const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: t.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              song.categoryLabel,
                              style: TextStyle(
                                color: t.accent,
                                fontSize: t.fontSize(7),
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (song.isRecommended) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                context.l.jukeboxRecommendedBadge,
                                style: TextStyle(
                                  color: const Color(0xFFFFD700),
                                  fontSize: t.fontSize(7),
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (bestRank != null)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rankColor(bestRank).withValues(alpha: 0.2),
                      border: Border.all(
                        color: rankColor(bestRank).withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bestRank,
                      style: TextStyle(
                        color: rankColor(bestRank),
                        fontSize: t.fontSize(11),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

}

// ─────────────────────────────────────────
// Screen 2: Song Detail + Channel Select
// ─────────────────────────────────────────

class GameSongDetail extends StatefulWidget {
  const GameSongDetail({super.key});

  @override
  State<GameSongDetail> createState() => _GameSongDetailState();
}

class _GameSongDetailState extends State<GameSongDetail> {
  int? _selectedChannel;
  String? _autoSelectedForSongId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final jukebox = context.read<JukeboxNotifier>();
    final songId = jukebox.lobbySong?.id;
    if (songId != _autoSelectedForSongId) {
      _selectedChannel = null;
      _autoSelectedForSongId = songId;
    }
    if (_selectedChannel == null && jukebox.channelAnalysis != null) {
      _autoSelectChannel(jukebox.channelAnalysis!, recommendedProgram: jukebox.lobbySong?.recommendedProgram);
    }
  }

  void _autoSelectChannel(List<ChannelInfo> channels, {int? recommendedProgram}) {
    // Prefer channel matching the song's recommended program (e.g. alto sax)
    if (recommendedProgram != null) {
      for (final ch in channels) {
        if (ch.isDrums) continue;
        if (ch.programNumber == recommendedProgram) {
          _selectedChannel = ch.channel;
          return;
        }
      }
    }
    // Fallback: auto-select channel with most notes (excluding drums)
    ChannelInfo? best;
    for (final ch in channels) {
      if (ch.isDrums) continue;
      if (best == null || ch.noteCount > best.noteCount) {
        best = ch;
      }
    }
    if (best != null) {
      _selectedChannel = best.channel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();
    final t = context.t;
    final song = jukebox.lobbySong;
    final channels = jukebox.channelAnalysis;

    if (song == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: jukebox.backToSongBrowser,
                icon: Icon(Icons.arrow_back, size: 20, color: t.textSecondary),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: t.fontSize(11),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.artist != null)
                      Text(
                        song.artist!,
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: t.fontSize(9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: t.borderSubtle),
        // Content
        Expanded(
          child: channels == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: t.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l.jukeboxAnalyzing,
                        style: TextStyle(
                          color: t.textMinimal,
                          fontSize: t.fontSize(9),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildContent(jukebox, t, song, channels),
        ),
      ],
    );
  }

  Widget _buildContent(
    JukeboxNotifier jukebox,
    VisionTokens t,
    JukeboxSong song,
    List<ChannelInfo> channels,
  ) {
    final scores = jukebox.highScoresForSong(song.id);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // High scores section
                Text(
                  context.l.jukeboxHighScores,
                  style: TextStyle(
                    color: t.textMinimal,
                    fontSize: t.fontSize(9),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (scores.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      context.l.jukeboxNoScoresYet,
                      style: TextStyle(
                        color: t.textMinimal,
                        fontSize: t.fontSize(9),
                      ),
                    ),
                  )
                else
                  ...scores.take(3).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return _buildScoreRow(t, i + 1, s);
                  }),
                const SizedBox(height: 16),
                Divider(color: t.borderSubtle),
                const SizedBox(height: 12),
                // Channel selection
                Text(
                  context.l.jukeboxSelectInstrument,
                  style: TextStyle(
                    color: t.textMinimal,
                    fontSize: t.fontSize(9),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...channels.map((ch) => _buildChannelRow(t, ch)),
              ],
            ),
          ),
        ),
        // Bottom action buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  t,
                  context.l.jukeboxWatch,
                  Icons.visibility,
                  t.accent,
                  _selectedChannel != null
                      ? () => jukebox.startGameFromLobby(
                          channel: _selectedChannel!, watchOnly: true)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  t,
                  context.l.jukeboxPlayGame,
                  Icons.sports_esports,
                  t.accentEdit,
                  _selectedChannel != null
                      ? () => jukebox.startGameWithCountdown(
                          channel: _selectedChannel!)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(VisionTokens t, int position, HighScoreEntry score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$position',
              style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor(score.rank).withValues(alpha: 0.2),
            ),
            alignment: Alignment.center,
            child: Text(
              score.rank,
              style: TextStyle(
                color: rankColor(score.rank),
                fontSize: t.fontSize(9),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${score.score}',
            style: TextStyle(
              color: t.textPrimary,
              fontSize: t.fontSize(10),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${(score.accuracy * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: t.textSecondary,
              fontSize: t.fontSize(9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRow(VisionTokens t, ChannelInfo ch) {
    final selected = _selectedChannel == ch.channel;
    final disabled = ch.isDrums;

    return InkWell(
      onTap: disabled
          ? null
          : () => setState(() => _selectedChannel = ch.channel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: selected
              ? t.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? t.accent.withValues(alpha: 0.3)
                : t.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: disabled
                      ? t.textMinimal
                      : selected
                          ? t.accent
                          : t.textSecondary,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.accent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Channel + instrument name
            Text(
              context.l.jukeboxChannelLabel(ch.channel),
              style: TextStyle(
                color: disabled ? t.textMinimal : t.textSecondary,
                fontSize: t.fontSize(8),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ch.instrumentName,
                style: TextStyle(
                  color: disabled ? t.textMinimal : t.textPrimary,
                  fontSize: t.fontSize(10),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Note count
            Text(
              '${ch.noteCount}',
              style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(9),
              ),
            ),
            const SizedBox(width: 8),
            // Difficulty badge
            if (!ch.isDrums)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ch.difficultyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _difficultyLabel(context, ch.difficulty),
                  style: TextStyle(
                    color: ch.difficultyColor,
                    fontSize: t.fontSize(7),
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                '---',
                style: TextStyle(
                  color: t.textMinimal,
                  fontSize: t.fontSize(8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    VisionTokens t,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: onPressed != null ? color : t.textMinimal),
      label: Text(
        label,
        style: TextStyle(
          color: onPressed != null ? color : t.textMinimal,
          fontSize: t.fontSize(9),
          letterSpacing: 1,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: onPressed != null
            ? color.withValues(alpha: 0.1)
            : t.surfaceMid,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

}
