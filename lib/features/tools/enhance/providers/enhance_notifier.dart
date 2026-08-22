import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../../../core/models/nai_model.dart';
import '../../../../core/services/novel_ai_service.dart';
import '../../../generation/models/nai_character.dart';
import '../models/enhance_config.dart';

class EnhanceNotifier extends ChangeNotifier {
  NovelAIService? _service;
  NaiModel _model = NaiModel.fallback;

  static const String defaultNegativePrompt = 'lowres, {bad}, error, fewer, extra, missing, worst quality, jpeg artifacts, bad quality, watermark, unfinished, displeasing, chromatic aberration, signature, extra digits, artistic error, username, scan, [abstract]';

  Uint8List? _sourceImageBytes;
  int _sourceWidth = 0;
  int _sourceHeight = 0;
  String _prompt = '';
  String _negativePrompt = defaultNegativePrompt;
  EnhanceConfig _config = const EnhanceConfig();
  Uint8List? _resultBytes;
  bool _isProcessing = false;
  String? _error;
  String _status = '';

  String? _promptPrefix;
  String? _promptSuffix;
  String? _styleNegativeContent;
  List<NaiCharacter> _characters = const [];
  List<NaiInteraction> _interactions = const [];
  bool _useCoords = false;

  Uint8List? get sourceImageBytes => _sourceImageBytes;
  int get sourceWidth => _sourceWidth;
  int get sourceHeight => _sourceHeight;
  String get prompt => _prompt;
  String get negativePrompt => _negativePrompt;
  EnhanceConfig get config => _config;
  Uint8List? get resultBytes => _resultBytes;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String get status => _status;
  bool get hasSource => _sourceImageBytes != null;
  bool get hasResult => _resultBytes != null;

  void updateService(NovelAIService? service) {
    _service = service;
  }

  /// Enhance renders with the same model as the main editor (it used to be
  /// hard-wired to V4.5 Full regardless of the CURATED toggle).
  void updateModel(NaiModel model) {
    _model = model;
  }

  Future<void> setSourceImage(Uint8List bytes) async {
    final decoded = await compute(_decodeImageDimensions, bytes);
    if (decoded == null) return;
    _sourceImageBytes = bytes;
    _sourceWidth = decoded.$1;
    _sourceHeight = decoded.$2;
    _resultBytes = null;
    _error = null;
    notifyListeners();
  }

  void setPrompt(String value) {
    _prompt = value;
  }

  void setNegativePrompt(String value) {
    _negativePrompt = value;
  }

  void setStrength(double value) {
    _config = _config.copyWith(strength: value.clamp(0.0, 1.0));
    notifyListeners();
  }

  void setNoise(double value) {
    _config = _config.copyWith(noise: value.clamp(0.0, 1.0));
    notifyListeners();
  }

  void setScale(double value) {
    _config = _config.copyWith(scale: value);
    notifyListeners();
  }

  void setStyleData({
    String? promptPrefix,
    String? promptSuffix,
    String? styleNegativeContent,
  }) {
    _promptPrefix = promptPrefix;
    _promptSuffix = promptSuffix;
    _styleNegativeContent = styleNegativeContent;
  }

  void setCharacterData({
    List<NaiCharacter> characters = const [],
    List<NaiInteraction> interactions = const [],
    bool useCoords = false,
  }) {
    _characters = characters;
    _interactions = interactions;
    _useCoords = useCoords;
  }

  Future<void> enhance() async {
    if (_service == null || _sourceImageBytes == null) return;
    _isProcessing = true;
    _error = null;
    _resultBytes = null;
    _status = 'Enhancing...';
    notifyListeners();

    try {
      // Step 1: Resize and encode source for img2img
      final sourceBase64 = await compute(_resizeAndEncode, _ResizeParams(
        bytes: _sourceImageBytes!,
        width: _sourceWidth,
        height: _sourceHeight,
      ));

      // Step 2: Generate enhanced image via img2img
      // Apply resolution scale and round to nearest multiple of 64
      final outWidth = ((_sourceWidth * _config.scale) / 64).round() * 64;
      final outHeight = ((_sourceHeight * _config.scale) / 64).round() * 64;

      final effectiveNegative = _styleNegativeContent != null && _styleNegativeContent!.isNotEmpty
          ? '$_negativePrompt, $_styleNegativeContent'
          : _negativePrompt;

      final result = await _service!.generateImage(
        prompt: _prompt,
        negativePrompt: effectiveNegative,
        width: outWidth,
        height: outHeight,
        seed: DateTime.now().microsecondsSinceEpoch % 4294967295,
        action: 'img2img',
        sourceImageBase64: sourceBase64,
        img2imgStrength: _config.strength,
        img2imgNoise: _config.noise,
        promptPrefix: _promptPrefix,
        promptSuffix: _promptSuffix,
        characters: _characters,
        interactions: _interactions,
        useCoords: _useCoords,
        model: _model,
      );

      _resultBytes = result.imageBytes;
      _status = '';
    } on UnauthorizedException {
      _error = 'Authentication error: check API key';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isProcessing = false;
      _status = '';
      notifyListeners();
    }
  }

  void clearResult() {
    _resultBytes = null;
    _error = null;
    notifyListeners();
  }

  void clear() {
    _sourceImageBytes = null;
    _sourceWidth = 0;
    _sourceHeight = 0;
    _resultBytes = null;
    _error = null;
    _isProcessing = false;
    _status = '';
    _prompt = '';
    _negativePrompt = defaultNegativePrompt;
    _config = const EnhanceConfig();
    _promptPrefix = null;
    _promptSuffix = null;
    _styleNegativeContent = null;
    _characters = const [];
    _interactions = const [];
    _useCoords = false;
    notifyListeners();
  }
}

(int, int)? _decodeImageDimensions(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return (decoded.width, decoded.height);
}

class _ResizeParams {
  final Uint8List bytes;
  final int width;
  final int height;
  _ResizeParams({required this.bytes, required this.width, required this.height});
}

String _resizeAndEncode(_ResizeParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) throw Exception('Failed to decode source image');
  final resized = img.copyResize(decoded, width: params.width, height: params.height);
  final rgb = resized.convert(numChannels: 3);
  final pngBytes = img.encodePng(rgb);
  return base64Encode(pngBytes);
}
