import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../../../core/services/novel_ai_service.dart';
import '../models/augment_tool.dart';

class DirectorToolsNotifier extends ChangeNotifier {
  NovelAIService? _service;

  Uint8List? _sourceImageBytes;
  int _sourceWidth = 0;
  int _sourceHeight = 0;
  AugmentTool _selectedTool = AugmentTool.bgRemoval;
  int _defry = 0;
  String _prompt = '';
  EmotionMood _selectedMood = EmotionMood.neutral;
  Uint8List? _resultBytes;
  bool _isProcessing = false;
  String? _error;

  Uint8List? get sourceImageBytes => _sourceImageBytes;
  int get sourceWidth => _sourceWidth;
  int get sourceHeight => _sourceHeight;
  AugmentTool get selectedTool => _selectedTool;
  int get defry => _defry;
  String get prompt => _prompt;
  EmotionMood get selectedMood => _selectedMood;
  Uint8List? get resultBytes => _resultBytes;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  bool get hasSource => _sourceImageBytes != null;
  bool get hasResult => _resultBytes != null;

  void updateService(NovelAIService? service) {
    _service = service;
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

  void selectTool(AugmentTool tool) {
    _selectedTool = tool;
    _resultBytes = null;
    _error = null;
    notifyListeners();
  }

  void setDefry(int value) {
    _defry = value.clamp(0, 5);
    notifyListeners();
  }

  void setPrompt(String value) {
    _prompt = value;
  }

  void setMood(EmotionMood mood) {
    _selectedMood = mood;
    notifyListeners();
  }

  Future<void> process() async {
    if (_service == null || _sourceImageBytes == null) return;
    _isProcessing = true;
    _error = null;
    _resultBytes = null;
    notifyListeners();

    try {
      final imageBase64 = base64Encode(_sourceImageBytes!);

      String? promptToSend;
      if (_selectedTool.hasPrompt) {
        if (_selectedTool == AugmentTool.emotion) {
          promptToSend = '${_selectedMood.apiValue};;$_prompt';
        } else {
          promptToSend = _prompt;
        }
      }

      final result = await _service!.augmentImage(
        imageBase64: imageBase64,
        width: _sourceWidth,
        height: _sourceHeight,
        reqType: _selectedTool.apiValue,
        defry: _selectedTool.hasDefry ? _defry : null,
        prompt: promptToSend,
      );

      _resultBytes = result;
    } on UnauthorizedException {
      _error = 'Authentication error: check API key';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isProcessing = false;
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
    _prompt = '';
    _defry = 0;
    _selectedMood = EmotionMood.neutral;
    _selectedTool = AugmentTool.bgRemoval;
    notifyListeners();
  }
}

(int, int)? _decodeImageDimensions(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return (decoded.width, decoded.height);
}
