import 'models/jukebox_song.dart';
import 'models/jukebox_soundfont.dart';

/// Static catalog of all bundled songs and soundfonts.
class JukeboxRegistry {
  JukeboxRegistry._();

  // ──────────────────────────────────────────
  // SoundFonts
  // ──────────────────────────────────────────

  static const _sfBaseUrl =
      'https://github.com/ststoryweaver/NAIWeaver/releases/download/soundfonts-v1';

  static const List<JukeboxSoundFont> allSoundFonts = [
    // Bundled default — always available
    JukeboxSoundFont(
      id: 'nes_chiptune',
      name: 'NES Chiptune',
      description: '8-bit retro NES sounds',
      assetPath: 'assets/soundfonts/NES_Chiptune.sf2',
      filename: 'NES_Chiptune.sf2',
      fileSizeBytes: 6744228, // ~6.4 MB
    ),
    // Downloadable soundfonts
    JukeboxSoundFont(
      id: 'generaluser_gs',
      name: 'GeneralUser GS',
      description: 'High quality General MIDI soundfont',
      downloadUrl: '$_sfBaseUrl/GeneralUser_GS.sf2',
      filename: 'GeneralUser_GS.sf2',
      fileSizeBytes: 32322864, // ~30.8 MB
      sha256: 'c278464b823daf9c52106c0957f752817da0e52964817ff682fe3a8d2f8446ce',
    ),
    JukeboxSoundFont(
      id: 'cat_screams',
      name: 'Cat Screams',
      description: 'Every instrument is a screaming cat',
      downloadUrl: '$_sfBaseUrl/Cat_Screams.sf2',
      filename: 'Cat_Screams.sf2',
      fileSizeBytes: 18420, // ~18 KB
      isGag: true,
      sha256: '7e102d9b8a72da08e331e37f679f9dff3a3cb0923225cd62d3c461a0fbc34d87',
    ),
    JukeboxSoundFont(
      id: 'music_box',
      name: 'Music Box',
      description: 'Delicate music box tones',
      downloadUrl: '$_sfBaseUrl/Music_Box.sf2',
      filename: 'Music_Box.sf2',
      fileSizeBytes: 9932494, // ~9.5 MB
      sha256: '4972160c4d2b5fb2b79a8f6ab7a27465f69c892739d548557e442ad83ee6e0ff',
    ),
  ];

  static JukeboxSoundFont get defaultSoundFont => allSoundFonts.first;

  static List<JukeboxSoundFont> get downloadableSoundFonts =>
      allSoundFonts.where((sf) => sf.isDownloadable).toList();

  static JukeboxSoundFont? findSoundFontById(String id) {
    for (final sf in allSoundFonts) {
      if (sf.id == id) return sf;
    }
    return null;
  }

  // ──────────────────────────────────────────
  // Songs
  // ──────────────────────────────────────────

  static const List<JukeboxSong> allSongs = [
    // --- Classical ---
    JukeboxSong(id: 'fur_elise', title: 'Fur Elise', artist: 'Beethoven', category: SongCategory.classical, assetPath: 'assets/midi/classical/fur_elise.mid', durationSeconds: 180),
    JukeboxSong(id: 'moonlight_sonata', title: 'Moonlight Sonata', artist: 'Beethoven', category: SongCategory.classical, assetPath: 'assets/midi/classical/moonlight_sonata.mid', durationSeconds: 360),
    JukeboxSong(id: 'canon_in_d', title: 'Canon in D', artist: 'Pachelbel', category: SongCategory.classical, assetPath: 'assets/midi/classical/canon_in_d.mid', durationSeconds: 300),
    JukeboxSong(id: 'clair_de_lune', title: 'Clair de Lune', artist: 'Debussy', category: SongCategory.classical, assetPath: 'assets/midi/classical/clair_de_lune.mid', durationSeconds: 300),
    JukeboxSong(id: 'turkish_march', title: 'Turkish March', artist: 'Mozart', category: SongCategory.classical, assetPath: 'assets/midi/classical/turkish_march.mid', durationSeconds: 210),
    JukeboxSong(id: 'spring_vivaldi', title: 'Spring', artist: 'Vivaldi', category: SongCategory.classical, assetPath: 'assets/midi/classical/spring.mid', durationSeconds: 200),
    JukeboxSong(id: 'nocturne_op9', title: 'Nocturne Op.9 No.2', artist: 'Chopin', category: SongCategory.classical, assetPath: 'assets/midi/classical/nocturne_op9.mid', durationSeconds: 270),
    JukeboxSong(id: 'ode_to_joy', title: 'Ode to Joy', artist: 'Beethoven', category: SongCategory.classical, assetPath: 'assets/midi/classical/ode_to_joy.mid', durationSeconds: 180),
    JukeboxSong(id: 'gymnopedie_1', title: 'Gymnopedie No.1', artist: 'Satie', category: SongCategory.classical, assetPath: 'assets/midi/classical/gymnopedie_1.mid', durationSeconds: 180),
    JukeboxSong(id: 'waltz_of_flowers', title: 'Waltz of the Flowers', artist: 'Tchaikovsky', category: SongCategory.classical, assetPath: 'assets/midi/classical/waltz_of_flowers.mid', durationSeconds: 400),

    // --- Anime ---
    JukeboxSong(id: 'cruel_angel', title: 'Cruel Angel Thesis', category: SongCategory.anime, assetPath: 'assets/midi/anime/cruel_angel.mid', isKaraoke: true, durationSeconds: 260),
    JukeboxSong(id: 'tank', title: 'Tank!', category: SongCategory.anime, assetPath: 'assets/midi/anime/tank.mid', durationSeconds: 210),
    JukeboxSong(id: 'lilium', title: 'Lilium', category: SongCategory.anime, assetPath: 'assets/midi/anime/lilium.mid', isKaraoke: true, durationSeconds: 200),
    JukeboxSong(id: 'unravel', title: 'Unravel', category: SongCategory.anime, assetPath: 'assets/midi/anime/unravel.mid', isKaraoke: true, durationSeconds: 240),
    JukeboxSong(id: 'butterfly_digimon', title: 'Butterfly', category: SongCategory.anime, assetPath: 'assets/midi/anime/butterfly.mid', isKaraoke: true, durationSeconds: 250),
    JukeboxSong(id: 'moonlight_densetsu', title: 'Moonlight Densetsu', category: SongCategory.anime, assetPath: 'assets/midi/anime/moonlight_densetsu.mid', isKaraoke: true, durationSeconds: 200),
    JukeboxSong(id: 'sobakasu', title: 'Sobakasu', category: SongCategory.anime, assetPath: 'assets/midi/anime/sobakasu.mid', durationSeconds: 230),
    JukeboxSong(id: 'haruhi_bouken', title: 'Bouken Desho Desho', category: SongCategory.anime, assetPath: 'assets/midi/anime/bouken_desho.mid', durationSeconds: 260),
    JukeboxSong(id: 'komm_susser_tod', title: 'Komm Susser Tod', category: SongCategory.anime, assetPath: 'assets/midi/anime/komm_susser_tod.mid', isKaraoke: true, durationSeconds: 450),
    JukeboxSong(id: 'guren_no_yumiya', title: 'Guren no Yumiya', category: SongCategory.anime, assetPath: 'assets/midi/anime/guren_no_yumiya.mid', durationSeconds: 320),

    // --- Game ---
    JukeboxSong(id: 'zelda_overworld', title: 'Overworld Theme', artist: 'Zelda', category: SongCategory.game, assetPath: 'assets/midi/game/zelda_overworld.mid', durationSeconds: 120),
    JukeboxSong(id: 'mario_overworld', title: 'Overworld Theme', artist: 'Super Mario', category: SongCategory.game, assetPath: 'assets/midi/game/mario_overworld.mid', durationSeconds: 90),
    JukeboxSong(id: 'ff_prelude', title: 'Prelude', artist: 'Final Fantasy', category: SongCategory.game, assetPath: 'assets/midi/game/ff_prelude.mid', durationSeconds: 150),
    JukeboxSong(id: 'ff_victory', title: 'Victory Fanfare', artist: 'Final Fantasy', category: SongCategory.game, assetPath: 'assets/midi/game/ff_victory.mid', durationSeconds: 30),
    JukeboxSong(id: 'megalovania', title: 'Megalovania', artist: 'Undertale', category: SongCategory.game, assetPath: 'assets/midi/game/megalovania.mid', durationSeconds: 150),
    JukeboxSong(id: 'tetris_theme', title: 'Korobeiniki', artist: 'Tetris', category: SongCategory.game, assetPath: 'assets/midi/game/tetris.mid', durationSeconds: 120),
    JukeboxSong(id: 'chrono_trigger', title: 'Wind Scene', artist: 'Chrono Trigger', category: SongCategory.game, assetPath: 'assets/midi/game/chrono_wind.mid', durationSeconds: 180),
    JukeboxSong(id: 'sonic_green_hill', title: 'Green Hill Zone', artist: 'Sonic', category: SongCategory.game, assetPath: 'assets/midi/game/green_hill.mid', durationSeconds: 100),
    JukeboxSong(id: 'pokemon_battle', title: 'Battle Theme', artist: 'Pokemon', category: SongCategory.game, assetPath: 'assets/midi/game/pokemon_battle.mid', durationSeconds: 120),
    JukeboxSong(id: 'castlevania_vampire', title: 'Vampire Killer', artist: 'Castlevania', category: SongCategory.game, assetPath: 'assets/midi/game/vampire_killer.mid', durationSeconds: 150),

    // --- Jazz ---
    JukeboxSong(id: 'autumn_leaves', title: 'Autumn Leaves', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/autumn_leaves.mid', durationSeconds: 240),
    JukeboxSong(id: 'take_five', title: 'Take Five', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/take_five.mid', durationSeconds: 320),
    JukeboxSong(id: 'fly_me_to_moon', title: 'Fly Me to the Moon', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/fly_me_to_moon.kar', isKaraoke: true, durationSeconds: 200),
    JukeboxSong(id: 'blue_bossa', title: 'Blue Bossa', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/blue_bossa.mid', durationSeconds: 280),
    JukeboxSong(id: 'girl_from_ipanema', title: 'Girl from Ipanema', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/girl_ipanema.mid', durationSeconds: 320),
    JukeboxSong(id: 'summertime', title: 'Summertime', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/summertime.mid', isKaraoke: true, durationSeconds: 200),
    JukeboxSong(id: 'so_what', title: 'So What', artist: 'Miles Davis', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/so_what.mid', durationSeconds: 540),
    JukeboxSong(id: 'round_midnight', title: 'Round Midnight', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/round_midnight.mid', durationSeconds: 360),
    JukeboxSong(id: 'misty', title: 'Misty', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/misty.mid', durationSeconds: 200),
    JukeboxSong(id: 'all_blues', title: 'All Blues', artist: 'Miles Davis', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/all_blues.mid', durationSeconds: 690),

    // --- Ambient ---
    JukeboxSong(id: 'ambient_rain', title: 'Rainy Day', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/rainy_day.mid', durationSeconds: 300),
    JukeboxSong(id: 'ambient_forest', title: 'Forest Whispers', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/forest_whispers.mid', durationSeconds: 360),
    JukeboxSong(id: 'ambient_ocean', title: 'Ocean Drift', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/ocean_drift.mid', durationSeconds: 400),
    JukeboxSong(id: 'ambient_stars', title: 'Stargazing', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/stargazing.mid', durationSeconds: 300),
    JukeboxSong(id: 'ambient_zen', title: 'Zen Garden', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/zen_garden.mid', durationSeconds: 300),
    JukeboxSong(id: 'ambient_dawn', title: 'Dawn Chorus', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/dawn_chorus.mid', durationSeconds: 360),
    JukeboxSong(id: 'ambient_aurora', title: 'Aurora', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/aurora.mid', durationSeconds: 400),
    JukeboxSong(id: 'ambient_moonpool', title: 'Moon Pool', category: SongCategory.ambient, assetPath: 'assets/midi/ambient/moon_pool.mid', durationSeconds: 300),

    // --- Holiday ---
    JukeboxSong(id: 'jingle_bells', title: 'Jingle Bells', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/jingle_bells.mid', isKaraoke: true, durationSeconds: 120),
    JukeboxSong(id: 'silent_night', title: 'Silent Night', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/silent_night.mid', isKaraoke: true, durationSeconds: 180),
    JukeboxSong(id: 'deck_the_halls', title: 'Deck the Halls', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/deck_the_halls.mid', isKaraoke: true, durationSeconds: 90),
    JukeboxSong(id: 'auld_lang_syne', title: 'Auld Lang Syne', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/auld_lang_syne.mid', isKaraoke: true, durationSeconds: 120),
    JukeboxSong(id: 'greensleeves', title: 'Greensleeves', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/greensleeves.mid', durationSeconds: 200),
    JukeboxSong(id: 'sakura_sakura', title: 'Sakura Sakura', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/sakura.mid', durationSeconds: 120),
    JukeboxSong(id: 'tanabata', title: 'Tanabata-sama', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/tanabata.mid', isKaraoke: true, durationSeconds: 90),
    JukeboxSong(id: 'rudolph', title: 'Rudolph the Red-Nosed Reindeer', category: SongCategory.holiday, assetPath: 'assets/midi/holiday/rudolph.mid', isKaraoke: true, durationSeconds: 150),

    // --- Meme ---
    JukeboxSong(id: 'rickroll', title: 'Never Gonna Give You Up', category: SongCategory.meme, assetPath: 'assets/midi/meme/rickroll.kar', isKaraoke: true, durationSeconds: 210),
    JukeboxSong(id: 'nyan_cat', title: 'Nyan Cat', category: SongCategory.meme, assetPath: 'assets/midi/meme/nyan_cat.mid', durationSeconds: 180),
    JukeboxSong(id: 'all_star', title: 'All Star', category: SongCategory.meme, assetPath: 'assets/midi/meme/all_star.mid', isKaraoke: true, durationSeconds: 200),
    JukeboxSong(id: 'running_90s', title: 'Running in the 90s', category: SongCategory.meme, assetPath: 'assets/midi/meme/running_90s.mid', durationSeconds: 270),
    JukeboxSong(id: 'shooting_stars', title: 'Shooting Stars', category: SongCategory.meme, assetPath: 'assets/midi/meme/shooting_stars.mid', durationSeconds: 220),
    JukeboxSong(id: 'coffin_dance', title: 'Coffin Dance', category: SongCategory.meme, assetPath: 'assets/midi/meme/coffin_dance.mid', durationSeconds: 180),
    JukeboxSong(id: 'he_man', title: 'What\'s Going On', category: SongCategory.meme, assetPath: 'assets/midi/meme/he_man.mid', durationSeconds: 200),
    JukeboxSong(id: 'thomas_theme', title: 'Thomas the Tank Engine', category: SongCategory.meme, assetPath: 'assets/midi/meme/thomas.mid', durationSeconds: 120),
    JukeboxSong(id: 'keyboard_cat', title: 'Keyboard Cat', category: SongCategory.meme, assetPath: 'assets/midi/meme/keyboard_cat.mid', durationSeconds: 60),
    JukeboxSong(id: 'sandstorm', title: 'Sandstorm', artist: 'Darude', category: SongCategory.meme, assetPath: 'assets/midi/meme/sandstorm.mid', durationSeconds: 230),

    // --- Rock / Early 2000s ---
    JukeboxSong(id: 'chop_suey', title: 'Chop Suey!', artist: 'System of a Down', category: SongCategory.rock, assetPath: 'assets/midi/rock/chop_suey.mid', durationSeconds: 210),
    JukeboxSong(id: 'aerials', title: 'Aerials', artist: 'System of a Down', category: SongCategory.rock, assetPath: 'assets/midi/rock/aerials.mid', durationSeconds: 250),
    JukeboxSong(id: 'in_the_end', title: 'In The End', artist: 'Linkin Park', category: SongCategory.rock, assetPath: 'assets/midi/rock/in_the_end.mid', durationSeconds: 220),
    JukeboxSong(id: 'bohemian_rhapsody', title: 'Bohemian Rhapsody', artist: 'Queen', category: SongCategory.rock, assetPath: 'assets/midi/rock/bohemian_rhapsody.kar', isKaraoke: true, durationSeconds: 355),
    JukeboxSong(id: 'take_on_me', title: 'Take On Me', artist: 'A-ha', category: SongCategory.rock, assetPath: 'assets/midi/rock/take_on_me.kar', isKaraoke: true, durationSeconds: 225),
    JukeboxSong(id: 'livin_on_prayer', title: "Livin' on a Prayer", artist: 'Bon Jovi', category: SongCategory.rock, assetPath: 'assets/midi/rock/livin_on_prayer.kar', isKaraoke: true, durationSeconds: 250),

    // --- Extra Anime ---
    JukeboxSong(id: 'sadness_sorrow', title: 'Sadness and Sorrow', category: SongCategory.anime, assetPath: 'assets/midi/anime/sadness_sorrow.mid', durationSeconds: 180),
    JukeboxSong(id: 'binks_sake', title: "Bink's Sake", category: SongCategory.anime, assetPath: 'assets/midi/anime/binks_sake.mid', durationSeconds: 150),
    JukeboxSong(id: 'dragon_soul', title: 'Dragon Soul', category: SongCategory.anime, assetPath: 'assets/midi/anime/dragon_soul.mid', durationSeconds: 200),
    JukeboxSong(id: 'jiyuu_tsubasa', title: 'Jiyuu no Tsubasa', category: SongCategory.anime, assetPath: 'assets/midi/anime/jiyuu_tsubasa.mid', durationSeconds: 270),
  ];

  static List<JukeboxSong> songsByCategory(SongCategory category) {
    return allSongs.where((s) => s.category == category).toList();
  }

  static JukeboxSong? findSongById(String id) {
    for (final song in allSongs) {
      if (song.id == id) return song;
    }
    return null;
  }

  static String categoryDisplayName(SongCategory cat) {
    switch (cat) {
      case SongCategory.classical:
        return 'CLASSICAL';
      case SongCategory.anime:
        return 'ANIME';
      case SongCategory.game:
        return 'GAME';
      case SongCategory.jazz:
        return 'JAZZ';
      case SongCategory.ambient:
        return 'AMBIENT';
      case SongCategory.holiday:
        return 'HOLIDAY';
      case SongCategory.meme:
        return 'MEME';
      case SongCategory.rock:
        return 'ROCK';
    }
  }
}
