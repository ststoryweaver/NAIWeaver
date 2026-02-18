import 'dart:typed_data';

import 'canvas_action.dart';
import 'canvas_layer.dart';

/// Represents a canvas editing session with source image and multiple layers.
/// Undo/redo uses an action-based history — visible history = history[0..historyIndex).
class CanvasSession {
  final Uint8List sourceImageBytes;
  final int sourceWidth;
  final int sourceHeight;
  final List<CanvasLayer> layers; // bottom-to-top order
  final String activeLayerId;
  final List<CanvasAction> history;
  final int historyIndex; // visible history = history[0..historyIndex)
  final String sessionId;

  const CanvasSession({
    required this.sourceImageBytes,
    required this.sourceWidth,
    required this.sourceHeight,
    this.layers = const [],
    required this.activeLayerId,
    this.history = const [],
    this.historyIndex = 0,
    required this.sessionId,
  });

  CanvasLayer? get activeLayer {
    for (final layer in layers) {
      if (layer.id == activeLayerId) return layer;
    }
    return null;
  }

  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < history.length;
  bool get hasStrokes => layers.any((l) => l.strokes.isNotEmpty);
  List<CanvasLayer> get visibleLayers =>
      layers.where((l) => l.visible).toList();

  CanvasSession copyWith({
    Uint8List? sourceImageBytes,
    int? sourceWidth,
    int? sourceHeight,
    List<CanvasLayer>? layers,
    String? activeLayerId,
    List<CanvasAction>? history,
    int? historyIndex,
    String? sessionId,
  }) {
    return CanvasSession(
      sourceImageBytes: sourceImageBytes ?? this.sourceImageBytes,
      sourceWidth: sourceWidth ?? this.sourceWidth,
      sourceHeight: sourceHeight ?? this.sourceHeight,
      layers: layers ?? this.layers,
      activeLayerId: activeLayerId ?? this.activeLayerId,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  /// Serialize session state (excluding sourceImageBytes, which is saved as a
  /// separate binary sidecar file).
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sourceWidth': sourceWidth,
        'sourceHeight': sourceHeight,
        'activeLayerId': activeLayerId,
        'layers': layers.map((l) => l.toJson()).toList(),
        'history': history.map((a) => a.toJson()).toList(),
        'historyIndex': historyIndex,
      };

  /// Deserialize session state. [sourceImageBytes] must be provided separately
  /// (read from the binary sidecar file).
  static CanvasSession fromJson(
      Map<String, dynamic> json, Uint8List sourceImageBytes) {
    return CanvasSession(
      sourceImageBytes: sourceImageBytes,
      sessionId: json['sessionId'] as String,
      sourceWidth: json['sourceWidth'] as int,
      sourceHeight: json['sourceHeight'] as int,
      activeLayerId: json['activeLayerId'] as String,
      layers: (json['layers'] as List)
          .map((j) => CanvasLayer.fromJson(j as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List)
          .map((j) => CanvasAction.fromJson(j as Map<String, dynamic>))
          .toList(),
      historyIndex: json['historyIndex'] as int,
    );
  }
}
