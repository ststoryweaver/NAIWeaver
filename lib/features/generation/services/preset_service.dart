import '../../../core/services/presets.dart';
import '../../../core/services/styles.dart';

/// Wraps preset and style file I/O, owning the file paths.
class PresetFileService {
  final String presetsFilePath;
  final String stylesFilePath;

  PresetFileService({
    required this.presetsFilePath,
    required this.stylesFilePath,
  });

  Future<List<GenerationPreset>> loadPresets() =>
      PresetStorage.loadPresets(presetsFilePath);

  Future<void> savePresets(List<GenerationPreset> presets) =>
      PresetStorage.savePresets(presetsFilePath, presets);

  Future<List<PromptStyle>> loadStyles() =>
      StyleStorage.loadStyles(stylesFilePath);
}
