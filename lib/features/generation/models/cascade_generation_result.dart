import 'dart:typed_data';

/// One completed render, independent of the image currently shown in the UI.
class CascadeGenerationResult {
  final Uint8List imageBytes;
  final Map<String, dynamic> metadata;
  final String? savedBasename;

  CascadeGenerationResult({
    required this.imageBytes,
    required Map<String, dynamic> metadata,
    this.savedBasename,
  }) : metadata = Map.unmodifiable(metadata);
}
