import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/img2img_session.dart';

class Img2ImgNotifier extends ChangeNotifier {
  Img2ImgSession? _session;
  Img2ImgSession? get session => _session;

  /// Current in-progress stroke (built up during a pan gesture).
  List<Offset>? _currentStrokePoints;
  double _brushRadius = 0.05;
  bool _isEraseMode = false;

  double get brushRadius => _brushRadius;
  bool get isEraseMode => _isEraseMode;
  bool get hasSession => _session != null;
  bool get hasMask => _session?.hasMask ?? false;

  /// Load a source image from raw bytes. Decodes to get dimensions.
  Future<void> loadSourceImage(Uint8List bytes, {String? prompt, String? negativePrompt}) async {
    final decoded = await compute(_decodeImageDimensions, bytes);
    if (decoded == null) return;

    _session = Img2ImgSession(
      sourceImageBytes: bytes,
      sourceWidth: decoded.$1,
      sourceHeight: decoded.$2,
      prompt: prompt ?? '',
      negativePrompt: negativePrompt ?? '',
    );
    notifyListeners();
  }

  void clearSession() {
    _session = null;
    notifyListeners();
  }

  // --- Brush settings ---

  void setBrushRadius(double radius) {
    _brushRadius = radius.clamp(0.005, 0.2);
    notifyListeners();
  }

  void setEraseMode(bool erase) {
    _isEraseMode = erase;
    notifyListeners();
  }

  // --- Stroke management ---

  void beginStroke(Offset normalizedPoint) {
    _currentStrokePoints = [normalizedPoint];
    notifyListeners();
  }

  void addStrokePoint(Offset normalizedPoint) {
    _currentStrokePoints?.add(normalizedPoint);
    notifyListeners();
  }

  void endStroke() {
    if (_session == null || _currentStrokePoints == null || _currentStrokePoints!.isEmpty) {
      _currentStrokePoints = null;
      return;
    }

    final stroke = MaskStroke(
      points: List<Offset>.from(_currentStrokePoints!),
      radius: _brushRadius,
      isErase: _isEraseMode,
    );

    _session = _session!.copyWith(
      maskStrokes: [..._session!.maskStrokes, stroke],
    );
    _currentStrokePoints = null;
    notifyListeners();
  }

  /// Returns current in-progress stroke for live preview rendering.
  MaskStroke? get activeStroke {
    if (_currentStrokePoints == null || _currentStrokePoints!.isEmpty) return null;
    return MaskStroke(
      points: _currentStrokePoints!,
      radius: _brushRadius,
      isErase: _isEraseMode,
    );
  }

  void undoLastStroke() {
    if (_session == null || _session!.maskStrokes.isEmpty) return;
    _session = _session!.copyWith(
      maskStrokes: _session!.maskStrokes.sublist(0, _session!.maskStrokes.length - 1),
    );
    notifyListeners();
  }

  void clearMask() {
    if (_session == null) return;
    _session = _session!.copyWith(maskStrokes: []);
    notifyListeners();
  }

  // --- Settings ---

  void updateSettings(Img2ImgSettings settings) {
    if (_session == null) return;
    _session = _session!.copyWith(settings: settings);
    notifyListeners();
  }

  void setStrength(double value) {
    if (_session == null) return;
    _session = _session!.copyWith(
      settings: _session!.settings.copyWith(strength: value),
    );
    notifyListeners();
  }

  void setNoise(double value) {
    if (_session == null) return;
    _session = _session!.copyWith(
      settings: _session!.settings.copyWith(noise: value),
    );
    notifyListeners();
  }

  void setColorCorrect(bool value) {
    if (_session == null) return;
    _session = _session!.copyWith(
      settings: _session!.settings.copyWith(colorCorrect: value),
    );
    notifyListeners();
  }

  void setMaskBlur(int value) {
    if (_session == null) return;
    _session = _session!.copyWith(
      settings: _session!.settings.copyWith(maskBlur: value),
    );
    notifyListeners();
  }

  void setResultImage(Uint8List bytes) {
    if (_session == null) return;
    _session = _session!.copyWith(resultImageBytes: bytes);
    notifyListeners();
  }

  void clearResult() {
    if (_session == null) return;
    _session = _session!.copyWith(clearResult: true);
    notifyListeners();
  }

  /// Replace the source image with the current result for iterative inpainting.
  Future<void> useResultAsSource() async {
    if (_session == null || _session!.resultImageBytes == null) return;
    final resultBytes = _session!.resultImageBytes!;

    final decoded = await compute(_decodeImageDimensions, resultBytes);
    if (decoded == null) return;

    _session = Img2ImgSession(
      sourceImageBytes: resultBytes,
      sourceWidth: decoded.$1,
      sourceHeight: decoded.$2,
      settings: _session!.settings,
      prompt: _session!.prompt,
      negativePrompt: _session!.negativePrompt,
    );
    notifyListeners();
  }

  /// Replace the source image with new bytes (e.g. from canvas editor).
  /// Decodes dimensions, replaces source, clears mask strokes and result.
  Future<void> replaceSourceImage(Uint8List bytes) async {
    final decoded = await compute(_decodeImageDimensions, bytes);
    if (decoded == null) return;

    _session = Img2ImgSession(
      sourceImageBytes: bytes,
      sourceWidth: decoded.$1,
      sourceHeight: decoded.$2,
      settings: _session?.settings ?? const Img2ImgSettings(),
      prompt: _session?.prompt ?? '',
      negativePrompt: _session?.negativePrompt ?? '',
    );
    notifyListeners();
  }

  void setPrompt(String value) {
    if (_session == null) return;
    _session = _session!.copyWith(prompt: value);
    // Don't notify for every keystroke to avoid rebuilds
  }

  void setNegativePrompt(String value) {
    if (_session == null) return;
    _session = _session!.copyWith(negativePrompt: value);
  }
}

/// Decode image to get width/height. Runs in isolate.
(int, int)? _decodeImageDimensions(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return (decoded.width, decoded.height);
}
