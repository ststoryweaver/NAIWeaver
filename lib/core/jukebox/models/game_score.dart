import 'dart:convert';

enum HitGrade { perfect, great, good, miss }

/// Tracks scoring for the falling notes game.
class GameScore {
  int perfects = 0;
  int greats = 0;
  int goods = 0;
  int misses = 0;
  int combo = 0;
  int maxCombo = 0;
  int score = 0;

  // Timing windows (milliseconds from hit line center)
  static const perfectWindow = 50; // +/- 50ms
  static const greatWindow = 100; // +/- 100ms
  static const goodWindow = 200; // +/- 200ms
  // Beyond 200ms = miss

  // Points per grade
  static const _perfectPoints = 300;
  static const _greatPoints = 200;
  static const _goodPoints = 100;

  int get totalHits => perfects + greats + goods + misses;
  int get successfulHits => perfects + greats + goods;

  static HitGrade judge(int deltaMs) {
    final abs = deltaMs.abs();
    if (abs <= perfectWindow) return HitGrade.perfect;
    if (abs <= greatWindow) return HitGrade.great;
    if (abs <= goodWindow) return HitGrade.good;
    return HitGrade.miss;
  }

  void recordHit(HitGrade grade) {
    switch (grade) {
      case HitGrade.perfect:
        perfects++;
        combo++;
        score += _perfectPoints * _comboMultiplier;
      case HitGrade.great:
        greats++;
        combo++;
        score += _greatPoints * _comboMultiplier;
      case HitGrade.good:
        goods++;
        combo++;
        score += _goodPoints * _comboMultiplier;
      case HitGrade.miss:
        misses++;
        combo = 0;
    }
    if (combo > maxCombo) maxCombo = combo;
  }

  // Combo multiplier: floor(combo / 10) + 1, capped at 4x
  int get _comboMultiplier => ((combo ~/ 10) + 1).clamp(1, 4);
  int get comboMultiplier => _comboMultiplier;

  double get accuracy => totalHits == 0 ? 0 : successfulHits / totalHits;

  String get rank {
    if (accuracy >= 0.95 && misses == 0) return 'S';
    if (accuracy >= 0.90) return 'A';
    if (accuracy >= 0.75) return 'B';
    if (accuracy >= 0.50) return 'C';
    return 'D';
  }
}

/// Persisted high score entry for a song.
class HighScoreEntry {
  final String songId;
  final int channel;
  final int score;
  final int maxCombo;
  final String rank;
  final double accuracy;
  final DateTime date;

  const HighScoreEntry({
    required this.songId,
    this.channel = 0,
    required this.score,
    required this.maxCombo,
    required this.rank,
    required this.accuracy,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'channel': channel,
        'score': score,
        'maxCombo': maxCombo,
        'rank': rank,
        'accuracy': accuracy,
        'date': date.toIso8601String(),
      };

  factory HighScoreEntry.fromJson(Map<String, dynamic> json) {
    return HighScoreEntry(
      songId: json['songId'] as String,
      channel: json['channel'] as int? ?? 0,
      score: json['score'] as int,
      maxCombo: json['maxCombo'] as int,
      rank: json['rank'] as String,
      accuracy: (json['accuracy'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  static String encodeList(List<HighScoreEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<HighScoreEntry> decodeList(String json) {
    if (json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => HighScoreEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
