import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/canvas_action.dart';
import '../models/canvas_layer.dart';
import '../models/canvas_session.dart';
import '../models/paint_stroke.dart';

/// Tool mode for the canvas editor.
enum CanvasTool { paint, erase, line, rectangle, circle, fill, text, eyedropper, transform }

/// Manages a canvas editing session: layer CRUD, stroke lifecycle,
/// action-based undo/redo, brush settings.
class CanvasNotifier extends ChangeNotifier {
  CanvasSession? _session;
  CanvasSession? get session => _session;
  bool get hasSession => _session != null;

  // --- Brush settings ---
  CanvasTool _tool = CanvasTool.paint;
  double _brushRadius = 0.02;
  double _brushOpacity = 1.0;
  int _brushColor = 0xFF000000; // default black

  CanvasTool get tool => _tool;
  double get brushRadius => _brushRadius;
  double get brushOpacity => _brushOpacity;
  int get brushColor => _brushColor;
  Color get brushColorAsColor => Color(_brushColor);

  // --- Smooth strokes ---
  bool _smoothStrokes = true;
  bool get smoothStrokes => _smoothStrokes;

  // --- Persistent text-tool settings ---
  double _pendingTextFontSize = 0.05;
  String? _pendingTextFontFamily;
  double _pendingTextLetterSpacing = 0.0;

  double get pendingTextFontSize => _pendingTextFontSize;
  String? get pendingTextFontFamily => _pendingTextFontFamily;
  double get pendingTextLetterSpacing => _pendingTextLetterSpacing;

  void setPendingTextFontSize(double size) {
    _pendingTextFontSize = size.clamp(0.01, 0.20);
    notifyListeners();
  }

  void setPendingTextFontFamily(String? family) {
    _pendingTextFontFamily = family;
    notifyListeners();
  }

  void setPendingTextLetterSpacing(double spacing) {
    _pendingTextLetterSpacing = spacing.clamp(-0.01, 0.05);
    notifyListeners();
  }

  // --- Pending text editing state ---
  Offset? _pendingTextPosition; // normalized tap position
  String _pendingTextContent = '';

  Offset? get pendingTextPosition => _pendingTextPosition;
  String get pendingTextContent => _pendingTextContent;
  bool get hasPendingText => _pendingTextPosition != null;

  void beginTextEditing(Offset normalizedPos) {
    _pendingTextPosition = normalizedPos;
    _pendingTextContent = '';
    notifyListeners();
  }

  void updatePendingText(String text) {
    _pendingTextContent = text;
    notifyListeners();
  }

  void commitPendingText() {
    if (_pendingTextPosition == null || _pendingTextContent.trim().isEmpty) {
      cancelPendingText();
      return;
    }
    addTextStroke(
      position: _pendingTextPosition!,
      text: _pendingTextContent.trim(),
      fontSize: _pendingTextFontSize,
      fontFamily: _pendingTextFontFamily,
      letterSpacing: _pendingTextLetterSpacing,
    );
    _pendingTextPosition = null;
    _pendingTextContent = '';
    notifyListeners();
  }

  void cancelPendingText() {
    _pendingTextPosition = null;
    _pendingTextContent = '';
    notifyListeners();
  }

  // --- Eyedropper state ---
  CanvasTool? _previousToolBeforeEyedropper;

  // --- Active stroke (in-progress) ---
  List<Offset>? _currentStrokePoints;

  int _nextLayerNumber = 2;

  /// Start a new canvas session from source image bytes.
  void startSession(Uint8List sourceBytes, int width, int height) {
    const defaultLayerId = 'layer_1';
    final defaultLayer = CanvasLayer(
      id: defaultLayerId,
      name: 'Layer 1',
    );
    _nextLayerNumber = 2;
    _session = CanvasSession(
      sourceImageBytes: sourceBytes,
      sourceWidth: width,
      sourceHeight: height,
      layers: [defaultLayer],
      activeLayerId: defaultLayerId,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    notifyListeners();
  }

  /// Restore a session (e.g. from persistence), preserving history.
  void restoreSession(CanvasSession session) {
    _session = session;
    // Determine next layer number from existing names
    _nextLayerNumber = 1;
    for (final layer in session.layers) {
      final match = RegExp(r'^Layer (\d+)').firstMatch(layer.name);
      if (match != null) {
        final num = int.parse(match.group(1)!);
        if (num >= _nextLayerNumber) _nextLayerNumber = num + 1;
      }
    }
    notifyListeners();
  }

  void clearSession() {
    _session = null;
    _currentStrokePoints = null;
    _pendingTextPosition = null;
    _pendingTextContent = '';
    notifyListeners();
  }

  // --- Tool selection ---

  void setTool(CanvasTool tool) {
    if (tool == CanvasTool.eyedropper) {
      _previousToolBeforeEyedropper = _tool;
    }
    _tool = tool;
    notifyListeners();
  }

  void toggleSmoothStrokes() {
    _smoothStrokes = !_smoothStrokes;
    notifyListeners();
  }

  void pickColorFromCanvas(int colorValue) {
    _brushColor = colorValue;
    // Switch back to previous tool
    _tool = _previousToolBeforeEyedropper ?? CanvasTool.paint;
    _previousToolBeforeEyedropper = null;
    notifyListeners();
  }

  void setBrushRadius(double radius) {
    _brushRadius = radius.clamp(0.002, 0.15);
    notifyListeners();
  }

  void setBrushOpacity(double opacity) {
    _brushOpacity = opacity.clamp(0.05, 1.0);
    notifyListeners();
  }

  void setBrushColor(int colorValue) {
    _brushColor = colorValue;
    notifyListeners();
  }

  // --- Stroke management ---

  void beginStroke(Offset normalizedPoint) {
    _currentStrokePoints = [normalizedPoint];
    notifyListeners();
  }

  void addStrokePoint(Offset normalizedPoint) {
    if (_currentStrokePoints == null) return;
    // Shape tools keep exactly 2 points (start + current)
    if (_tool == CanvasTool.line ||
        _tool == CanvasTool.rectangle ||
        _tool == CanvasTool.circle) {
      if (_currentStrokePoints!.length == 1) {
        _currentStrokePoints!.add(normalizedPoint);
      } else {
        _currentStrokePoints![1] = normalizedPoint;
      }
    } else {
      _currentStrokePoints!.add(normalizedPoint);
    }
    notifyListeners();
  }

  StrokeType _toolToStrokeType() {
    return switch (_tool) {
      CanvasTool.line => StrokeType.line,
      CanvasTool.rectangle => StrokeType.rectangle,
      CanvasTool.circle => StrokeType.circle,
      CanvasTool.fill => StrokeType.fill,
      _ => StrokeType.freehand,
    };
  }

  void endStroke() {
    if (_session == null ||
        _currentStrokePoints == null ||
        _currentStrokePoints!.isEmpty) {
      _currentStrokePoints = null;
      return;
    }

    final activeLayer = _session!.activeLayer;
    if (activeLayer == null) {
      _currentStrokePoints = null;
      return;
    }

    final strokeType = _toolToStrokeType();
    final stroke = PaintStroke(
      points: List<Offset>.from(_currentStrokePoints!),
      radius: _brushRadius,
      colorValue: _brushColor,
      opacity: _brushOpacity,
      isErase: _tool == CanvasTool.erase,
      strokeType: strokeType,
      smooth: strokeType == StrokeType.freehand && _smoothStrokes,
    );

    _currentStrokePoints = null;
    _pushAction(AddStrokeAction(
      layerId: activeLayer.id,
      stroke: stroke,
    ));
  }

  /// Apply a fill stroke that covers the entire canvas with the current color+opacity.
  void applyFill(Offset normalizedPoint) {
    if (_session == null) return;
    final activeLayer = _session!.activeLayer;
    if (activeLayer == null) return;
    final stroke = PaintStroke(
      points: [normalizedPoint],
      radius: 0,
      colorValue: _brushColor,
      opacity: _brushOpacity,
      strokeType: StrokeType.fill,
    );
    _pushAction(AddStrokeAction(layerId: activeLayer.id, stroke: stroke));
  }

  /// Add a text stroke at the given position.
  void addTextStroke({
    required Offset position,
    required String text,
    required double fontSize,
    String? fontFamily,
    double? letterSpacing,
  }) {
    if (_session == null) return;
    final activeLayer = _session!.activeLayer;
    if (activeLayer == null) return;
    final stroke = PaintStroke(
      points: [position],
      radius: 0,
      colorValue: _brushColor,
      opacity: _brushOpacity,
      strokeType: StrokeType.text,
      text: text,
      fontSize: fontSize,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
    );
    _pushAction(AddStrokeAction(layerId: activeLayer.id, stroke: stroke));
  }

  /// Returns current in-progress stroke for live preview rendering.
  PaintStroke? get activeStroke {
    if (_currentStrokePoints == null || _currentStrokePoints!.isEmpty) {
      return null;
    }
    final strokeType = _toolToStrokeType();
    return PaintStroke(
      points: _currentStrokePoints!,
      radius: _brushRadius,
      colorValue: _brushColor,
      opacity: _brushOpacity,
      isErase: _tool == CanvasTool.erase,
      strokeType: strokeType,
      smooth: strokeType == StrokeType.freehand && _smoothStrokes,
    );
  }

  // --- Layer management ---

  void setActiveLayer(String layerId) {
    if (_session == null) return;
    if (_session!.layers.any((l) => l.id == layerId)) {
      _session = _session!.copyWith(activeLayerId: layerId);
      notifyListeners();
    }
  }

  void addLayer() {
    if (_session == null) return;
    final id = 'layer_${DateTime.now().microsecondsSinceEpoch}';
    final name = 'Layer $_nextLayerNumber';
    _nextLayerNumber++;

    final layer = CanvasLayer(id: id, name: name);
    _pushAction(AddLayerAction(layer: layer));
    // After adding, set the new layer as active
    _session = _session!.copyWith(activeLayerId: id);
    notifyListeners();
  }

  void removeLayer(String layerId) {
    if (_session == null) return;
    final idx = _session!.layers.indexWhere((l) => l.id == layerId);
    if (idx < 0) return;
    // Don't allow deleting the last layer
    if (_session!.layers.length <= 1) return;

    final removedLayer = _session!.layers[idx];
    _pushAction(RemoveLayerAction(removedLayer: removedLayer, index: idx));

    // If we removed the active layer, switch to nearest
    if (_session!.activeLayerId == layerId) {
      // layers already updated by _pushAction
      final newActive = _session!.layers.isNotEmpty
          ? _session!.layers[idx.clamp(0, _session!.layers.length - 1)].id
          : '';
      _session = _session!.copyWith(activeLayerId: newActive);
      notifyListeners();
    }
  }

  void duplicateLayer(String layerId) {
    if (_session == null) return;
    final srcIdx = _session!.layers.indexWhere((l) => l.id == layerId);
    if (srcIdx < 0) return;

    final src = _session!.layers[srcIdx];
    final newId = 'layer_${DateTime.now().microsecondsSinceEpoch}';
    final copy = src.copyWith(
      id: newId,
      name: '${src.name} copy',
      strokes: List<PaintStroke>.from(src.strokes),
    );
    final insertIdx = srcIdx + 1;
    _pushAction(
        DuplicateLayerAction(duplicatedLayer: copy, insertIndex: insertIdx));
    _session = _session!.copyWith(activeLayerId: newId);
    notifyListeners();
  }

  void renameLayer(String layerId, String newName) {
    if (_session == null) return;
    final layer = _session!.layers.firstWhere((l) => l.id == layerId,
        orElse: () => const CanvasLayer(id: '', name: ''));
    if (layer.id.isEmpty || layer.name == newName) return;

    _pushAction(RenameLayerAction(
      layerId: layerId,
      oldName: layer.name,
      newName: newName,
    ));
  }

  void setLayerVisibility(String layerId, bool visible) {
    if (_session == null) return;
    final layer = _session!.layers.firstWhere((l) => l.id == layerId,
        orElse: () => const CanvasLayer(id: '', name: ''));
    if (layer.id.isEmpty || layer.visible == visible) return;

    _pushAction(SetLayerVisibilityAction(
      layerId: layerId,
      oldVisible: layer.visible,
      newVisible: visible,
    ));
  }

  void setLayerOpacity(String layerId, double opacity) {
    if (_session == null) return;
    final layer = _session!.layers.firstWhere((l) => l.id == layerId,
        orElse: () => const CanvasLayer(id: '', name: ''));
    if (layer.id.isEmpty || layer.opacity == opacity) return;

    _pushAction(SetLayerOpacityAction(
      layerId: layerId,
      oldOpacity: layer.opacity,
      newOpacity: opacity,
    ));
  }

  void setLayerBlendMode(String layerId, CanvasBlendMode mode) {
    if (_session == null) return;
    final layer = _session!.layers.firstWhere((l) => l.id == layerId,
        orElse: () => const CanvasLayer(id: '', name: ''));
    if (layer.id.isEmpty || layer.blendMode == mode) return;

    _pushAction(SetLayerBlendModeAction(
      layerId: layerId,
      oldMode: layer.blendMode,
      newMode: mode,
    ));
  }

  void reorderLayer(int oldIndex, int newIndex) {
    if (_session == null) return;
    if (oldIndex == newIndex) return;
    _pushAction(
        ReorderLayerAction(oldIndex: oldIndex, newIndex: newIndex));
  }

  void clearLayer(String layerId) {
    if (_session == null) return;
    final layer = _session!.layers.firstWhere((l) => l.id == layerId,
        orElse: () => const CanvasLayer(id: '', name: ''));
    if (layer.id.isEmpty || layer.strokes.isEmpty) return;

    _pushAction(ClearLayerAction(
      layerId: layerId,
      removedStrokes: List<PaintStroke>.from(layer.strokes),
    ));
  }

  // --- Image layer management ---

  /// Add an image as a new layer.
  void addImageLayer(Uint8List bytes, {String? name}) {
    if (_session == null) return;
    final id = 'layer_${DateTime.now().microsecondsSinceEpoch}';
    final layerName = name ?? 'Image $_nextLayerNumber';
    _nextLayerNumber++;

    final layer = CanvasLayer(
      id: id,
      name: layerName,
      imageBytes: bytes,
      imageX: 0.0,
      imageY: 0.0,
      imageScale: 1.0,
      imageRotation: 0.0,
    );

    _pushAction(AddImageLayerAction(layer: layer));
    _session = _session!.copyWith(activeLayerId: id);
    notifyListeners();
  }

  // Transform tool state
  double? _transformStartX;
  double? _transformStartY;
  double? _transformStartScale;
  double? _transformStartRotation;

  void beginTransform() {
    if (_session == null) return;
    final layer = _session!.activeLayer;
    if (layer == null || !layer.isImageLayer) return;

    _transformStartX = layer.imageX;
    _transformStartY = layer.imageY;
    _transformStartScale = layer.imageScale;
    _transformStartRotation = layer.imageRotation;
  }

  void updateTransform({
    double? dx,
    double? dy,
    double? scale,
    double? rotation,
  }) {
    if (_session == null) return;
    final layer = _session!.activeLayer;
    if (layer == null || !layer.isImageLayer) return;

    final layers = List<CanvasLayer>.from(_session!.layers);
    final idx = layers.indexWhere((l) => l.id == layer.id);
    if (idx < 0) return;

    layers[idx] = layers[idx].copyWith(
      imageX: dx ?? layer.imageX,
      imageY: dy ?? layer.imageY,
      imageScale: scale ?? layer.imageScale,
      imageRotation: rotation ?? layer.imageRotation,
    );
    _session = _session!.copyWith(layers: layers);
    notifyListeners();
  }

  void endTransform() {
    if (_session == null || _transformStartX == null) return;
    final layer = _session!.activeLayer;
    if (layer == null || !layer.isImageLayer) return;

    _pushAction(TransformImageLayerAction(
      layerId: layer.id,
      oldX: _transformStartX!,
      oldY: _transformStartY!,
      oldScale: _transformStartScale!,
      oldRotation: _transformStartRotation!,
      newX: layer.imageX,
      newY: layer.imageY,
      newScale: layer.imageScale,
      newRotation: layer.imageRotation,
    ));

    _transformStartX = null;
    _transformStartY = null;
    _transformStartScale = null;
    _transformStartRotation = null;
  }

  // --- Undo / Redo ---

  void undo() {
    if (_session == null || !_session!.canUndo) return;
    final action = _session!.history[_session!.historyIndex - 1];
    _revertAction(action);
    _session = _session!.copyWith(historyIndex: _session!.historyIndex - 1);
    notifyListeners();
  }

  void redo() {
    if (_session == null || !_session!.canRedo) return;
    final action = _session!.history[_session!.historyIndex];
    _applyAction(action);
    _session = _session!.copyWith(historyIndex: _session!.historyIndex + 1);
    notifyListeners();
  }

  // --- Action system ---

  void _pushAction(CanvasAction action) {
    // Discard future branch
    final trimmedHistory =
        _session!.history.sublist(0, _session!.historyIndex);
    _session = _session!.copyWith(
      history: [...trimmedHistory, action],
      historyIndex: trimmedHistory.length + 1,
    );
    _applyAction(action);
    notifyListeners();
  }

  void _applyAction(CanvasAction action) {
    final layers = List<CanvasLayer>.from(_session!.layers);
    action.apply(layers, activeLayerId: _session!.activeLayerId);
    _session = _session!.copyWith(layers: layers);
  }

  void _revertAction(CanvasAction action) {
    final layers = List<CanvasLayer>.from(_session!.layers);
    action.revert(layers);
    _session = _session!.copyWith(layers: layers);
  }
}
