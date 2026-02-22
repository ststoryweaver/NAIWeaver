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
      name: 'Cat Meows',
      description: 'Every instrument is a meowing cat',
      downloadUrl: '$_sfBaseUrl/Cat_Screams.sf2',
      filename: 'Cat_Screams.sf2',
      fileSizeBytes: 18420, // ~18 KB
      isGag: true,
      sha256: '7e102d9b8a72da08e331e37f679f9dff3a3cb0923225cd62d3c461a0fbc34d87',
    ),
    // SNES — ExpressiveSNES (CC BY 3.0)
    JukeboxSoundFont(
      id: 'snes_expressive',
      name: 'SNES',
      description: '16-bit Super Nintendo sounds',
      downloadUrl: '$_sfBaseUrl/ExpressiveSNES.sf2',
      filename: 'ExpressiveSNES.sf2',
      fileSizeBytes: 3910878, // ~3.7 MB
      sha256: '089f7974f7049237a2521a2aa0d12215693bc2ccca5bf4882e7499d0fa8aec4a',
    ),
    // Genesis — YM2612 FM synth
    JukeboxSoundFont(
      id: 'genesis_ym2612',
      name: 'Genesis',
      description: 'Sega Genesis YM2612 FM synth',
      downloadUrl: '$_sfBaseUrl/YM2612.sf2',
      filename: 'YM2612.sf2',
      fileSizeBytes: 36940352, // ~35.2 MB
      sha256: '7cd96e44c53dca1d1b3551d47ce225c50251e92f27d54f0f1df28fe7c4c3e20e',
    ),
    // N64 — Roxie's GM Soundfont
    JukeboxSoundFont(
      id: 'n64_roxie',
      name: 'N64',
      description: 'Nintendo 64 game samples',
      downloadUrl: '$_sfBaseUrl/N64_Roxie.sf2',
      filename: 'N64_Roxie.sf2',
      fileSizeBytes: 12763946, // ~12.2 MB
      sha256: '914db339d64abdfca2f0dc9e4791de6e38130fb87dc9cc273656b94a63acaa20',
    ),
    // N64 SDK — official SDK samples
    JukeboxSoundFont(
      id: 'n64_sdk',
      name: 'N64 SDK',
      description: 'Nintendo 64 SDK default samples',
      downloadUrl: '$_sfBaseUrl/N64_SDK_Soundfont.sf2',
      filename: 'N64_SDK_Soundfont.sf2',
      fileSizeBytes: 19665110, // ~18.8 MB
      sha256: '877e7980b7094f3f95822d1aae89cc68b81fd589f38c9747d73ad5bbdcc70961',
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
    // --- Featured ---
    JukeboxSong(id: 'georgia_on_my_mind', title: 'Georgia on My Mind', artist: 'Ray Charles', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/georgia_mind.kar', isKaraoke: true, durationSeconds: 156, isRecommended: true, recommendedProgram: 65),
    JukeboxSong(id: 'wonderful_world', title: 'What a Wonderful World', artist: 'Louis Armstrong', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/wond_world.kar', isKaraoke: true, durationSeconds: 137, isRecommended: true, recommendedProgram: 65),

    // --- Rock ---
    // ABBA
    JukeboxSong(id: 'dancing_queen', title: 'Dancing Queen', artist: 'ABBA', category: SongCategory.rock, assetPath: 'assets/midi/rock/danc_queen.kar', isKaraoke: true, durationSeconds: 237),
    // Bob Marley
    JukeboxSong(id: 'could_you_be_loved', title: 'Could You Be Loved', artist: 'Bob Marley', category: SongCategory.rock, assetPath: 'assets/midi/rock/cld_b_lovd.kar', isKaraoke: true),
    JukeboxSong(id: 'get_up_stand_up', title: 'Get Up Stand Up', artist: 'Bob Marley', category: SongCategory.rock, assetPath: 'assets/midi/rock/get_up.kar', isKaraoke: true),
    JukeboxSong(id: 'no_woman_no_cry', title: 'No Woman No Cry', artist: 'Bob Marley', category: SongCategory.rock, assetPath: 'assets/midi/rock/no_wmn_cry.kar', isKaraoke: true),
    JukeboxSong(id: 'one_love', title: 'One Love', artist: 'Bob Marley', category: SongCategory.rock, assetPath: 'assets/midi/rock/one_love.kar', isKaraoke: true),
    JukeboxSong(id: 'redemption_song', title: 'Redemption Song', artist: 'Bob Marley', category: SongCategory.rock, assetPath: 'assets/midi/rock/redemp_sng.kar', isKaraoke: true, isRecommended: true, recommendedProgram: 85),
    JukeboxSong(id: 'three_little_birds', title: 'Three Little Birds', artist: 'Bob Marley', category: SongCategory.rock, assetPath: 'assets/midi/rock/3_lil_bird.kar', isKaraoke: true),
    // Cat Stevens
    JukeboxSong(id: 'father_and_son', title: 'Father and Son', artist: 'Cat Stevens', category: SongCategory.rock, assetPath: 'assets/midi/rock/father_son.kar', isKaraoke: true),
    JukeboxSong(id: 'father_and_son_v2', title: 'Father and Son (v2)', artist: 'Cat Stevens', category: SongCategory.rock, assetPath: 'assets/midi/rock/fathr_sn_2.kar', isKaraoke: true),
    // Cranberries
    JukeboxSong(id: 'dreams', title: 'Dreams', artist: 'Cranberries', category: SongCategory.rock, assetPath: 'assets/midi/rock/dreams.kar', isKaraoke: true),
    JukeboxSong(id: 'linger', title: 'Linger', artist: 'Cranberries', category: SongCategory.rock, assetPath: 'assets/midi/rock/linger.kar', isKaraoke: true),
    // David Bowie
    JukeboxSong(id: 'changes', title: 'Changes', artist: 'David Bowie', category: SongCategory.rock, assetPath: 'assets/midi/rock/changes.kar', isKaraoke: true),
    JukeboxSong(id: 'space_oddity', title: 'Space Oddity', artist: 'David Bowie', category: SongCategory.rock, assetPath: 'assets/midi/rock/space_odd.kar', isKaraoke: true),
    JukeboxSong(id: 'starman', title: 'Starman', artist: 'David Bowie', category: SongCategory.rock, assetPath: 'assets/midi/rock/starman.kar', isKaraoke: true),
    // Dion
    JukeboxSong(id: 'runaround_sue', title: 'Runaround Sue', artist: 'Dion', category: SongCategory.rock, assetPath: 'assets/midi/rock/run_sue.kar', isKaraoke: true),
    // Dion and the Belmonts
    JukeboxSong(id: 'the_wanderer', title: 'The Wanderer', artist: 'Dion and the Belmonts', category: SongCategory.rock, assetPath: 'assets/midi/rock/wanderer.kar', isKaraoke: true),
    // Eagles
    JukeboxSong(id: 'hotel_california', title: 'Hotel California', artist: 'Eagles', category: SongCategory.rock, assetPath: 'assets/midi/rock/htl_calif.kar', isKaraoke: true, durationSeconds: 396),
    // Elvis Presley
    JukeboxSong(id: 'blue_suede_shoes', title: 'Blue Suede Shoes', artist: 'Elvis Presley', category: SongCategory.rock, assetPath: 'assets/midi/rock/blue_suede.kar', isKaraoke: true),
    JukeboxSong(id: 'love_me_tender', title: 'Love Me Tender', artist: 'Elvis Presley', category: SongCategory.rock, assetPath: 'assets/midi/rock/love_tendr.kar', isKaraoke: true),
    // Green Day
    JukeboxSong(id: 'gd_86', title: '86', artist: 'Green Day', category: SongCategory.rock, assetPath: 'assets/midi/rock/gd_86.kar', isKaraoke: true),
    JukeboxSong(id: 'brain_stew', title: 'Brain Stew', artist: 'Green Day', category: SongCategory.rock, assetPath: 'assets/midi/rock/brain_stew.kar', isKaraoke: true),
    JukeboxSong(id: 'good_riddance', title: 'Good Riddance', artist: 'Green Day', category: SongCategory.rock, assetPath: 'assets/midi/rock/good_rid.kar', isKaraoke: true),
    JukeboxSong(id: 'hitchin_a_ride', title: "Hitchin' a Ride", artist: 'Green Day', category: SongCategory.rock, assetPath: 'assets/midi/rock/hitchin.kar', isKaraoke: true),
    JukeboxSong(id: 'when_i_come_around', title: 'When I Come Around', artist: 'Green Day', category: SongCategory.rock, assetPath: 'assets/midi/rock/whn_i_come.kar', isKaraoke: true),
    // Queen
    JukeboxSong(id: 'show_must_go_on', title: 'The Show Must Go On', artist: 'Queen', category: SongCategory.rock, assetPath: 'assets/midi/rock/show_must.kar', isKaraoke: true, durationSeconds: 250),
    // The Beatles
    JukeboxSong(id: 'all_you_need_is_love', title: 'All You Need Is Love', artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/all_u_need.kar', isKaraoke: true),
    JukeboxSong(id: 'blackbird', title: 'Blackbird', artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/blackbird.kar', isKaraoke: true),
    JukeboxSong(id: 'eleanor_rigby', title: 'Eleanor Rigby', artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/eleanor_r.kar', isKaraoke: true),
    JukeboxSong(id: 'hey_jude', title: 'Hey Jude', artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/hey_jude.kar', isKaraoke: true),
    JukeboxSong(id: 'when_im_64', title: "When I'm 64", artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/when_64.kar', isKaraoke: true),
    JukeboxSong(id: 'when_im_64_v2', title: "When I'm 64 (v2)", artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/when_64_2.kar', isKaraoke: true),
    JukeboxSong(id: 'when_im_64_v3', title: "When I'm 64 (v3)", artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/when_64_3.kar', isKaraoke: true),
    JukeboxSong(id: 'when_im_64_v4', title: "When I'm 64 (v4)", artist: 'The Beatles', category: SongCategory.rock, assetPath: 'assets/midi/rock/when_64_4.kar', isKaraoke: true),
    // The Four Seasons
    JukeboxSong(id: 'december_1963', title: 'December 1963 (Oh What a Night)', artist: 'The Four Seasons', category: SongCategory.rock, assetPath: 'assets/midi/rock/dec_1963.kar', isKaraoke: true),

    // --- Jazz ---
    // Bobby Darin
    JukeboxSong(id: 'dream_lover', title: 'Dream Lover', artist: 'Bobby Darin', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/dream_lovr.kar', isKaraoke: true),
    JukeboxSong(id: 'mack_the_knife', title: 'Mack the Knife', artist: 'Bobby Darin', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/mack_knife.kar', isKaraoke: true),
    JukeboxSong(id: 'mack_the_knife_v2', title: 'Mack the Knife (v2)', artist: 'Bobby Darin', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/mack_knf_2.kar', isKaraoke: true),
    // Earth, Wind & Fire
    JukeboxSong(id: 'after_the_love_has_gone', title: 'After the Love Has Gone', artist: 'Earth, Wind & Fire', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/aft_love.kar', isKaraoke: true),
    JukeboxSong(id: 'boogie_wonderland', title: 'Boogie Wonderland', artist: 'Earth, Wind & Fire', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/boogie_wnd.kar', isKaraoke: true),
    JukeboxSong(id: 'in_the_stone', title: 'In the Stone', artist: 'Earth, Wind & Fire', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/in_stone.kar', isKaraoke: true),
    // Frank Sinatra
    JukeboxSong(id: 'fly_me_to_the_moon', title: 'Fly Me to the Moon', artist: 'Frank Sinatra', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/fly_moon.kar', isKaraoke: true),
    JukeboxSong(id: 'fly_me_to_the_moon_v2', title: 'Fly Me to the Moon (v2)', artist: 'Frank Sinatra', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/fly_moon_2.kar', isKaraoke: true),
    JukeboxSong(id: 'my_way', title: 'My Way', artist: 'Frank Sinatra', category: SongCategory.jazz, assetPath: 'assets/midi/jazz/my_way.kar', isKaraoke: true, durationSeconds: 206),

    // --- Meme ---
    JukeboxSong(id: 'rickroll', title: 'Never Gonna Give You Up', category: SongCategory.meme, assetPath: 'assets/midi/meme/rr.kar', isKaraoke: true, durationSeconds: 210),
    JukeboxSong(id: 'i_will_survive', title: 'I Will Survive', artist: 'Gloria Gaynor', category: SongCategory.meme, assetPath: 'assets/midi/meme/i_survive.kar', isKaraoke: true, durationSeconds: 301),
    JukeboxSong(id: 'macarena', title: 'Macarena', artist: 'Los Del Rio', category: SongCategory.meme, assetPath: 'assets/midi/meme/macarena.kar', isKaraoke: true, durationSeconds: 248),
    JukeboxSong(id: 'cotton_eye_joe', title: 'Cotton Eye Joe', artist: 'Rednex', category: SongCategory.meme, assetPath: 'assets/midi/meme/cot_eye.kar', isKaraoke: true, durationSeconds: 180),
    JukeboxSong(id: 'gangstas_paradise', title: "Gangsta's Paradise", artist: 'Coolio', category: SongCategory.meme, assetPath: 'assets/midi/meme/gang_para.kar', isKaraoke: true, durationSeconds: 241),
    JukeboxSong(id: 'killing_me_softly', title: 'Killing Me Softly', artist: 'Fugees', category: SongCategory.meme, assetPath: 'assets/midi/meme/kill_soft.kar', isKaraoke: true, durationSeconds: 266),
    JukeboxSong(id: 'celebration', title: 'Celebration', artist: 'Kool & The Gang', category: SongCategory.meme, assetPath: 'assets/midi/meme/celeb.kar', isKaraoke: true, durationSeconds: 176),
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
      case SongCategory.custom:
        return 'CUSTOM';
    }
  }
}
