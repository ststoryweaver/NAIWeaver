enum TransitionType {
  fade,
  slideLeft,
  slideRight,
  slideUp,
  zoom,
  crossZoom,
}

enum ImageSourceType {
  allImages,
  album,
  favorites,
  custom,
}

class SlideshowConfig {
  final String id;
  final String name;
  final ImageSourceType sourceType;
  final String? albumId;
  final List<String> customImageBasenames;
  final TransitionType transition;
  final double transitionDuration; // seconds, 0.5–2.0
  final double slideDuration; // seconds, 3–30
  final bool kenBurnsEnabled;
  final double kenBurnsIntensity; // 0.0–1.0
  final bool manualZoomEnabled;
  final bool shuffleEnabled;
  final bool loopEnabled;

  const SlideshowConfig({
    required this.id,
    this.name = 'Untitled',
    this.sourceType = ImageSourceType.allImages,
    this.albumId,
    this.customImageBasenames = const [],
    this.transition = TransitionType.fade,
    this.transitionDuration = 0.8,
    this.slideDuration = 5.0,
    this.kenBurnsEnabled = true,
    this.kenBurnsIntensity = 0.5,
    this.manualZoomEnabled = false,
    this.shuffleEnabled = false,
    this.loopEnabled = true,
  });

  SlideshowConfig copyWith({
    String? id,
    String? name,
    ImageSourceType? sourceType,
    String? albumId,
    bool clearAlbumId = false,
    List<String>? customImageBasenames,
    TransitionType? transition,
    double? transitionDuration,
    double? slideDuration,
    bool? kenBurnsEnabled,
    double? kenBurnsIntensity,
    bool? manualZoomEnabled,
    bool? shuffleEnabled,
    bool? loopEnabled,
  }) {
    return SlideshowConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceType: sourceType ?? this.sourceType,
      albumId: clearAlbumId ? null : (albumId ?? this.albumId),
      customImageBasenames: customImageBasenames ?? this.customImageBasenames,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      slideDuration: slideDuration ?? this.slideDuration,
      kenBurnsEnabled: kenBurnsEnabled ?? this.kenBurnsEnabled,
      kenBurnsIntensity: kenBurnsIntensity ?? this.kenBurnsIntensity,
      manualZoomEnabled: manualZoomEnabled ?? this.manualZoomEnabled,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      loopEnabled: loopEnabled ?? this.loopEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sourceType': sourceType.index,
        'albumId': albumId,
        'customImageBasenames': customImageBasenames,
        'transition': transition.index,
        'transitionDuration': transitionDuration,
        'slideDuration': slideDuration,
        'kenBurnsEnabled': kenBurnsEnabled,
        'kenBurnsIntensity': kenBurnsIntensity,
        'manualZoomEnabled': manualZoomEnabled,
        'shuffleEnabled': shuffleEnabled,
        'loopEnabled': loopEnabled,
      };

  factory SlideshowConfig.fromJson(Map<String, dynamic> json) {
    return SlideshowConfig(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled',
      sourceType: ImageSourceType.values[json['sourceType'] as int? ?? 0],
      albumId: json['albumId'] as String?,
      customImageBasenames: (json['customImageBasenames'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      transition: TransitionType.values[json['transition'] as int? ?? 0],
      transitionDuration: (json['transitionDuration'] as num?)?.toDouble() ?? 0.8,
      slideDuration: (json['slideDuration'] as num?)?.toDouble() ?? 5.0,
      kenBurnsEnabled: json['kenBurnsEnabled'] as bool? ?? true,
      kenBurnsIntensity: (json['kenBurnsIntensity'] as num?)?.toDouble() ?? 0.5,
      manualZoomEnabled: json['manualZoomEnabled'] as bool? ?? false,
      shuffleEnabled: json['shuffleEnabled'] as bool? ?? false,
      loopEnabled: json['loopEnabled'] as bool? ?? true,
    );
  }
}
