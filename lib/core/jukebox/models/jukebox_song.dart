enum SongCategory {
  classical,
  anime,
  game,
  jazz,
  ambient,
  holiday,
  meme,
  rock,
  custom,
}

enum VisualizerStyle { particles, bars, rings, wave, starfield, plasma }

class JukeboxSong {
  final String id;
  final String title;
  final String? artist;
  final SongCategory category;
  final String? assetPath;
  final String? filePath;
  final bool isKaraoke;
  final int? durationSeconds;

  const JukeboxSong({
    required this.id,
    required this.title,
    this.artist,
    required this.category,
    this.assetPath,
    this.filePath,
    this.isKaraoke = false,
    this.durationSeconds,
  });

  String get categoryLabel => category.name.toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'category': category.index,
        'assetPath': assetPath,
        'filePath': filePath,
        'isKaraoke': isKaraoke,
        'durationSeconds': durationSeconds,
      };

  factory JukeboxSong.fromJson(Map<String, dynamic> json) {
    return JukeboxSong(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      category: SongCategory.values[json['category'] as int? ?? 0],
      assetPath: json['assetPath'] as String?,
      filePath: json['filePath'] as String?,
      isKaraoke: json['isKaraoke'] as bool? ?? false,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }
}
