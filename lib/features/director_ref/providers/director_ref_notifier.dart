import 'package:flutter/foundation.dart';
import '../models/director_reference.dart';
import '../services/reference_image_processor.dart';

class DirectorRefNotifier extends ChangeNotifier {
  List<DirectorReference> _references = [];
  bool _isProcessing = false;
  int _idCounter = 0;

  List<DirectorReference> get references => _references;
  bool get isProcessing => _isProcessing;

  Future<void> addReference(Uint8List imageBytes) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final (processedBytes, base64) =
          await ReferenceImageProcessor.processImage(imageBytes);
      final ref = DirectorReference(
        id: 'ref_${_idCounter++}',
        originalImageBytes: imageBytes,
        processedBase64: base64,
      );
      _references = List.from(_references)..add(ref);
    } catch (e) {
      debugPrint('DirectorRefNotifier: Failed to process image: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void removeReference(String id) {
    _references = _references.where((r) => r.id != id).toList();
    notifyListeners();
  }

  void updateType(String id, DirectorReferenceType type) {
    _references = _references.map((r) {
      if (r.id == id) return r.copyWith(type: type);
      return r;
    }).toList();
    notifyListeners();
  }

  void updateStrength(String id, double strength) {
    _references = _references.map((r) {
      if (r.id == id) return r.copyWith(strength: strength);
      return r;
    }).toList();
    notifyListeners();
  }

  void updateFidelity(String id, double fidelity) {
    _references = _references.map((r) {
      if (r.id == id) return r.copyWith(fidelity: fidelity);
      return r;
    }).toList();
    notifyListeners();
  }

  /// Replaces all references wholesale (used when applying a preset).
  /// Re-processes each reference to derive processedBase64 from originalImageBytes.
  Future<void> setReferences(List<DirectorReference> refs) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final processed = <DirectorReference>[];
      for (final ref in refs) {
        if (ref.processedBase64.isNotEmpty) {
          processed.add(ref);
        } else {
          final (_, base64) =
              await ReferenceImageProcessor.processImage(ref.originalImageBytes);
          processed.add(ref.copyWith(processedBase64: base64));
        }
      }
      _references = processed;
      _idCounter = processed.length;
    } catch (e) {
      debugPrint('DirectorRefNotifier: Failed to set references: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearAll() {
    _references = [];
    notifyListeners();
  }

  /// Assembles the 5 parallel arrays for API injection.
  /// Returns null if no references are set.
  DirectorRefPayload? buildPayload() {
    if (_references.isEmpty) return null;

    final images = <String>[];
    final descriptions = <Map<String, dynamic>>[];
    final strengths = <double>[];
    final secondaryStrengths = <double>[];
    final infoExtracted = <double>[];

    for (final ref in _references) {
      images.add(ref.processedBase64);
      descriptions.add({
        'caption': {
          'base_caption': ref.type.apiCaption,
          'char_captions': [],
        },
        'legacy_uc': false,
      });
      strengths.add(ref.strength);
      // Fidelity inversion: API value = 1.0 - UI fidelity
      secondaryStrengths.add(1.0 - ref.fidelity);
      infoExtracted.add(1.0);
    }

    return DirectorRefPayload(
      images: images,
      descriptions: descriptions,
      strengths: strengths,
      secondaryStrengths: secondaryStrengths,
      infoExtracted: infoExtracted,
    );
  }
}
