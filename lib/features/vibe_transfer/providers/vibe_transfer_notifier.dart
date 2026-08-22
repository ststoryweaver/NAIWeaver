import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/models/nai_model.dart';
import '../../../core/services/novel_ai_service.dart';
import '../../director_ref/services/reference_image_processor.dart';
import '../models/vibe_transfer.dart';

class VibeTransferNotifier extends ChangeNotifier {
  List<VibeTransfer> _vibes = [];
  bool _isProcessing = false;
  int _idCounter = 0;
  NovelAIService? _service;
  NaiModel _model = NaiModel.fallback;

  List<VibeTransfer> get vibes => _vibes;
  bool get isProcessing => _isProcessing;

  void updateService(NovelAIService service) {
    _service = service;
  }

  /// The active image model; decides which id `/ai/encode-vibe` sees.
  void updateModel(NaiModel model) {
    _model = model;
  }

  Future<void> addVibe(Uint8List imageBytes) async {
    if (_service == null) {
      throw UnauthorizedException('API key not configured');
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final (preview, b64) =
          await ReferenceImageProcessor.processVibeImage(imageBytes);

      final vibeVectorBytes = await _service!.encodeVibeImage(
        imageBase64: b64,
        informationExtracted: 1.0,
        model: _model,
      );
      final vibeVectorB64 = base64Encode(vibeVectorBytes);

      final vibe = VibeTransfer(
        id: 'vibe_${_idCounter++}',
        originalImageBytes: imageBytes,
        processedPreview: preview,
        vibeVectorBase64: vibeVectorB64,
      );
      _vibes = List.from(_vibes)..add(vibe);
    } catch (e) {
      debugPrint('VibeTransferNotifier: Failed to process vibe: $e');
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void removeVibe(String id) {
    _vibes = _vibes.where((v) => v.id != id).toList();
    notifyListeners();
  }

  void updateStrength(String id, double strength) {
    _vibes = _vibes.map((v) {
      if (v.id == id) return v.copyWith(strength: strength);
      return v;
    }).toList();
    notifyListeners();
  }

  void updateInfoExtracted(String id, double infoExtracted) {
    _vibes = _vibes.map((v) {
      if (v.id == id) return v.copyWith(infoExtracted: infoExtracted);
      return v;
    }).toList();
    notifyListeners();
  }

  /// Toggles whether a vibe is included in generation. The encoded vector is
  /// retained, so re-enabling never triggers another encode round-trip.
  void toggleEnabled(String id) {
    _vibes = _vibes.map((v) {
      if (v.id == id) return v.copyWith(enabled: !v.enabled);
      return v;
    }).toList();
    notifyListeners();
  }

  void setVibes(List<VibeTransfer> vibes) {
    _vibes = vibes;
    _idCounter = vibes.length;
    notifyListeners();
  }

  void clearAll() {
    _vibes = [];
    notifyListeners();
  }

  VibeTransferPayload? buildPayload() {
    final active = _vibes.where((v) => v.enabled).toList();
    if (active.isEmpty) return null;

    final vectors = <String>[];
    final strengths = <double>[];
    final infoExtracted = <double>[];

    for (final vibe in active) {
      vectors.add(vibe.vibeVectorBase64);
      strengths.add(vibe.strength);
      infoExtracted.add(vibe.infoExtracted);
    }

    return VibeTransferPayload(
      vibeVectors: vectors,
      strengths: strengths,
      infoExtracted: infoExtracted,
    );
  }
}
