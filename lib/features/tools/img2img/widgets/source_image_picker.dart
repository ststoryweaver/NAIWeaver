import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/widgets/custom_resolution_dialog.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../../../generation/providers/generation_notifier.dart';
import '../../../generation/widgets/settings_panel.dart';
import '../../canvas/providers/canvas_notifier.dart';
import '../../canvas/widgets/canvas_editor.dart';
import '../providers/img2img_notifier.dart';

/// Picker screen shown when no source image is loaded.
/// Offers: use current generation, pick from gallery, or load from file.
class SourceImagePicker extends StatelessWidget {
  const SourceImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final genNotifier = context.watch<GenerationNotifier>();
    final galleryNotifier = context.watch<GalleryNotifier>();
    final img2imgNotifier = context.read<Img2ImgNotifier>();
    final hasCurrentImage = genNotifier.state.generatedImage != null;
    final t = context.t;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search, size: 48, color: t.textMinimal),
            const SizedBox(height: 16),
            Text(
              'SELECT SOURCE IMAGE',
              style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(12),
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an image to use as the base for img2img or inpainting',
              style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(10)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Use current generation
            if (hasCurrentImage) ...[
              _SourceOption(
                icon: Icons.flash_on,
                label: 'USE CURRENT GENERATION',
                description: 'Use the last generated image as source',
                accentColor: t.accent,
                onTap: () {
                  final prefs = context.read<PreferencesService>();
                  String? prompt;
                  String? negativePrompt;
                  if (prefs.img2imgImportPrompt) {
                    prompt = genNotifier.promptController.text;
                    negativePrompt = genNotifier.negativePromptController.text;
                  }
                  img2imgNotifier.loadSourceImage(genNotifier.state.generatedImage!, prompt: prompt, negativePrompt: negativePrompt);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Upload from device
            _SourceOption(
              icon: Icons.photo_library_outlined,
              label: context.l.img2imgUploadFromDevice,
              description: context.l.img2imgUploadFromDeviceDesc,
              accentColor: t.accentEdit,
              onTap: () async {
                final prefs = context.read<PreferencesService>();
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.single.path != null) {
                  final bytes = await File(result.files.single.path!).readAsBytes();
                  String? prompt;
                  String? negativePrompt;
                  if (prefs.img2imgImportPrompt) {
                    final metadata = extractMetadata(bytes);
                    if (metadata != null && metadata.containsKey('Comment')) {
                      final json = parseCommentJson(metadata['Comment']!);
                      if (json != null) {
                        prompt = json['prompt'] as String?;
                        negativePrompt = json['uc'] as String?;
                      }
                    }
                  }
                  img2imgNotifier.loadSourceImage(bytes, prompt: prompt, negativePrompt: negativePrompt);
                }
              },
            ),
            const SizedBox(height: 12),

            // Blank canvas
            _SourceOption(
              icon: Icons.note_add,
              label: context.l.img2imgBlankCanvas,
              description: context.l.img2imgBlankCanvasDesc,
              accentColor: t.accentSuccess,
              onTap: () => _showBlankCanvasDialog(context),
            ),
            const SizedBox(height: 12),

            // Gallery grid
            if (galleryNotifier.items.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'FROM GALLERY',
                    style: TextStyle(
                      color: t.textDisabled,
                      fontSize: t.fontSize(9),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 280,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: galleryNotifier.items.length.clamp(0, 20),
                  itemBuilder: (context, index) {
                    final item = galleryNotifier.items[index];
                    return _GalleryThumbnail(
                      file: item.file,
                      onTap: () async {
                        final prefs = context.read<PreferencesService>();
                        final bytes = await item.file.readAsBytes();
                        String? prompt;
                        String? negativePrompt;
                        if (prefs.img2imgImportPrompt) {
                          final metadata = extractMetadata(bytes);
                          if (metadata != null && metadata.containsKey('Comment')) {
                            final json = parseCommentJson(metadata['Comment']!);
                            if (json != null) {
                              prompt = json['prompt'] as String?;
                              negativePrompt = json['uc'] as String?;
                            }
                          }
                        }
                        img2imgNotifier.loadSourceImage(bytes, prompt: prompt, negativePrompt: negativePrompt, filePath: item.file.path);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showBlankCanvasDialog(BuildContext context) {
  final t = context.tRead;
  final l = context.l;
  final genNotifier = context.read<GenerationNotifier>();
  final resOptions = AdvancedSettingsPanel.resolutionOptions(context);

  // Default to current generation resolution
  final currentW = genNotifier.state.width.toInt();
  final currentH = genNotifier.state.height.toInt();
  final currentValue = '${currentW}x$currentH';
  String selectedValue = resOptions.any((o) => o.value == currentValue)
      ? currentValue
      : resOptions.first.value;
  // Track ad-hoc custom entry that isn't in the saved list
  ResolutionOption? adHocCustom;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Build items, including ad-hoc custom if present
          final allOptions = [...resOptions, if (adHocCustom != null && !resOptions.any((o) => o.value == adHocCustom!.value)) adHocCustom!];

          return AlertDialog(
            backgroundColor: t.surfaceHigh,
            title: Text(
              l.img2imgBlankCanvasSize,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: t.fontSize(11),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: t.borderSubtle,
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<String>(
                value: selectedValue,
                dropdownColor: t.surfaceHigh,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(11),
                  letterSpacing: 1,
                ),
                onChanged: (val) async {
                  if (val == '__custom__') {
                    final result = await showCustomResolutionDialog(ctx);
                    if (result != null) {
                      setDialogState(() {
                        adHocCustom = result;
                        selectedValue = result.value;
                      });
                    }
                    return;
                  }
                  if (val != null) {
                    setDialogState(() => selectedValue = val);
                  }
                },
                items: [
                  ...allOptions.map((opt) => DropdownMenuItem<String>(
                        value: opt.value,
                        child: Text(opt.displayLabel,
                            style: TextStyle(fontSize: t.fontSize(10))),
                      )),
                  DropdownMenuItem<String>(
                    value: '__custom__',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 14, color: t.accentSuccess),
                        const SizedBox(width: 8),
                        Text(l.resCustomEntry.toUpperCase(),
                            style: TextStyle(fontSize: t.fontSize(10), color: t.accentSuccess)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  l.commonCancel.toUpperCase(),
                  style: TextStyle(
                      color: t.textDisabled, fontSize: t.fontSize(9)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _createBlankCanvas(context, selectedValue);
                },
                child: Text(
                  l.commonConfirm.toUpperCase(),
                  style: TextStyle(
                      color: t.accentSuccess, fontSize: t.fontSize(9)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _createBlankCanvas(BuildContext context, String resolution) {
  final parts = resolution.split('x');
  final w = int.parse(parts[0]);
  final h = int.parse(parts[1]);

  // Generate a white PNG in-memory
  final blankImage = img.Image(width: w, height: h, numChannels: 4);
  img.fill(blankImage, color: img.ColorRgba8(255, 255, 255, 255));
  final bytes = Uint8List.fromList(img.encodePng(blankImage));

  final img2imgNotifier = context.read<Img2ImgNotifier>();
  final canvasNotifier = context.read<CanvasNotifier>();

  img2imgNotifier.loadSourceImage(bytes);
  canvasNotifier.startSession(bytes, w, h);

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CanvasEditor()),
  );
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: t.fontSize(10),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: accentColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  final File file;
  final VoidCallback onTap;

  const _GalleryThumbnail({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceHigh,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: t.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 200,
          ),
        ),
      ),
    );
  }
}
