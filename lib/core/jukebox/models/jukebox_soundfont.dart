class JukeboxSoundFont {
  final String id;
  final String name;
  final String description;
  final String? assetPath;
  final String? downloadUrl;
  final String? filename;
  final String? sha256;
  final int fileSizeBytes;
  final bool isGag;

  const JukeboxSoundFont({
    required this.id,
    required this.name,
    required this.description,
    this.assetPath,
    this.downloadUrl,
    this.filename,
    this.sha256,
    required this.fileSizeBytes,
    this.isGag = false,
  });

  bool get isBundled => assetPath != null;
  bool get isDownloadable => downloadUrl != null;

  String get fileSizeLabel {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'assetPath': assetPath,
        'downloadUrl': downloadUrl,
        'filename': filename,
        'sha256': sha256,
        'fileSizeBytes': fileSizeBytes,
        'isGag': isGag,
      };

  factory JukeboxSoundFont.fromJson(Map<String, dynamic> json) {
    return JukeboxSoundFont(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      assetPath: json['assetPath'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      filename: json['filename'] as String?,
      sha256: json['sha256'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      isGag: json['isGag'] as bool? ?? false,
    );
  }
}
