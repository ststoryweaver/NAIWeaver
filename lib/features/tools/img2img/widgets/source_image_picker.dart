import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../../../generation/providers/generation_notifier.dart';
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
                  img2imgNotifier.loadSourceImage(genNotifier.state.generatedImage!);
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
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.single.path != null) {
                  final bytes = await File(result.files.single.path!).readAsBytes();
                  img2imgNotifier.loadSourceImage(bytes);
                }
              },
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
                        final bytes = await item.file.readAsBytes();
                        img2imgNotifier.loadSourceImage(bytes);
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
