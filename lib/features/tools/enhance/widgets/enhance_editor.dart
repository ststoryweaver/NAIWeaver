import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/timestamp_utils.dart';
import '../../../../core/widgets/comparison_slider.dart';
import '../../../../core/widgets/vision_slider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../../../generation/providers/generation_notifier.dart';
import '../providers/enhance_notifier.dart';

class EnhanceEditor extends StatefulWidget {
  const EnhanceEditor({super.key});

  @override
  State<EnhanceEditor> createState() => _EnhanceEditorState();
}

class _EnhanceEditorState extends State<EnhanceEditor> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EnhanceNotifier>();

    // Sync negative prompt on first build
    if (!_initialized && notifier.hasSource) {
      _negativePromptController.text = notifier.negativePrompt;
      _initialized = true;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: notifier.hasSource
          ? _buildWorkspace(context, notifier)
          : _buildPicker(context, notifier),
    );
  }

  Widget _buildPicker(BuildContext context, EnhanceNotifier notifier) {
    final genNotifier = context.watch<GenerationNotifier>();
    final galleryNotifier = context.watch<GalleryNotifier>();
    final hasCurrentImage = genNotifier.state.generatedImage != null;
    final t = context.t;
    final l = context.l;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hd, size: 48, color: t.textMinimal),
            const SizedBox(height: 16),
            Text(
              l.enhanceTitle,
              style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(12),
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.enhanceDesc,
              style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(10)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (hasCurrentImage) ...[
              _PickerOption(
                icon: Icons.flash_on,
                label: l.enhanceUseCurrent,
                description: l.enhanceUseCurrentDesc,
                accentColor: t.accent,
                onTap: () {
                  notifier.setSourceImage(genNotifier.state.generatedImage!);
                  _promptController.text = genNotifier.promptController.text;
                  _negativePromptController.text = notifier.negativePrompt;
                  _initialized = true;
                },
              ),
              const SizedBox(height: 12),
            ],

            _PickerOption(
              icon: Icons.photo_library_outlined,
              label: l.img2imgUploadFromDevice,
              description: l.img2imgUploadFromDeviceDesc,
              accentColor: t.accentEdit,
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.image);
                if (result != null && result.files.single.path != null) {
                  final bytes = await File(result.files.single.path!).readAsBytes();
                  notifier.setSourceImage(bytes);
                  _negativePromptController.text = notifier.negativePrompt;
                  _initialized = true;
                }
              },
            ),
            const SizedBox(height: 12),

            if (!galleryNotifier.demoMode && galleryNotifier.items.isNotEmpty) ...[
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
                  itemCount: galleryNotifier.items.length,
                  itemBuilder: (context, index) {
                    final item = galleryNotifier.items[index];
                    return GestureDetector(
                      onTap: () async {
                        final bytes = await item.file.readAsBytes();
                        notifier.setSourceImage(bytes);
                        _negativePromptController.text = notifier.negativePrompt;
                        _initialized = true;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: t.surfaceHigh,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: t.borderSubtle),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.file(item.file, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                        ),
                      ),
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

  Widget _buildWorkspace(BuildContext context, EnhanceNotifier notifier) {
    final mobile = isMobile(context);
    final t = context.t;

    Widget imageArea = _buildImageArea(context, notifier);

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(context, notifier),
            Expanded(
              child: mobile
                  ? imageArea
                  : Row(
                      children: [
                        Expanded(flex: 3, child: imageArea),
                        SizedBox(
                          width: 300,
                          child: SingleChildScrollView(
                            child: _buildConfigPanel(context, notifier),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        if (mobile)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              tooltip: context.l.enhanceSettingsTooltip,
              backgroundColor: t.accentEdit,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: t.surfaceHigh,
                  builder: (_) => DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    maxChildSize: 0.9,
                    minChildSize: 0.3,
                    expand: false,
                    builder: (_, scrollController) => ListenableBuilder(
                      listenable: notifier,
                      builder: (_, _) => SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildConfigPanel(context, notifier),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.tune, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, EnhanceNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 16, color: t.textDisabled),
            onPressed: () => notifier.clear(),
            tooltip: l.img2imgBackToPicker,
          ),
          const Spacer(),
          if (notifier.hasResult && !context.read<GenerationNotifier>().state.autoSaveImages) ...[
            if (mobile)
              SizedBox(
                height: 36,
                child: IconButton(
                  onPressed: () => _saveResult(notifier),
                  icon: const Icon(Icons.save_alt, size: 14),
                  tooltip: l.commonSave,
                  style: IconButton.styleFrom(
                    backgroundColor: t.accentSuccess,
                    foregroundColor: t.background,
                  ),
                ),
              )
            else
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _saveResult(notifier),
                  icon: const Icon(Icons.save_alt, size: 14),
                  label: Text(l.commonSave),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentSuccess,
                    foregroundColor: t.background,
                    textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
          if (mobile && notifier.hasResult)
            SizedBox(
              height: 36,
              child: IconButton(
                onPressed: notifier.isProcessing ? null : () async {
                  final gen = context.read<GenerationNotifier>();
                  notifier.setPrompt(_promptController.text);
                  notifier.setNegativePrompt(_negativePromptController.text);
                  await notifier.enhance();
                  if (notifier.hasResult && mounted) {
                    if (gen.state.autoSaveImages) {
                      _saveResult(notifier);
                    }
                  }
                },
                icon: notifier.isProcessing
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: t.background))
                    : const Icon(Icons.auto_awesome, size: 14),
                style: IconButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.background,
                ),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: notifier.isProcessing ? null : () async {
                  final gen = context.read<GenerationNotifier>();
                  notifier.setPrompt(_promptController.text);
                  notifier.setNegativePrompt(_negativePromptController.text);
                  await notifier.enhance();
                  if (notifier.hasResult && mounted) {
                    if (gen.state.autoSaveImages) {
                      _saveResult(notifier);
                    }
                  }
                },
                icon: notifier.isProcessing
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: t.background))
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(notifier.isProcessing
                    ? (notifier.status.isNotEmpty ? notifier.status.toUpperCase() : l.enhanceProcessing)
                    : l.enhanceProcess),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.background,
                  textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageArea(BuildContext context, EnhanceNotifier notifier) {
    final t = context.t;
    final loc = AppLocalizations.of(context);

    return Stack(
      children: [
        if (notifier.hasResult)
          ComparisonSlider(
            beforeBytes: notifier.sourceImageBytes!,
            afterBytes: notifier.resultBytes!,
            beforeLabel: loc.comparisonBefore.toUpperCase(),
            afterLabel: loc.comparisonAfter.toUpperCase(),
          )
        else
          Container(
            color: t.background,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.memory(
                  notifier.sourceImageBytes!,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        if (notifier.error != null)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.accentDanger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: t.accentDanger.withValues(alpha: 0.4)),
              ),
              child: Text(
                notifier.error!,
                style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfigPanel(BuildContext context, EnhanceNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final labelSize = responsiveFont(context, 9, 11);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prompt
          Text(
            l.enhancePrompt,
            style: TextStyle(
              color: t.secondaryText,
              fontSize: t.fontSize(labelSize),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 2,
            style: TextStyle(fontSize: t.fontSize(10), color: t.textPrimary),
            decoration: InputDecoration(
              hintText: l.img2imgPromptHint,
              hintStyle: TextStyle(color: t.hintText, fontSize: t.fontSize(9)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: t.borderSubtle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: t.borderMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: t.borderMedium),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Negative prompt
          Text(
            l.enhanceNegative,
            style: TextStyle(
              color: t.secondaryText,
              fontSize: t.fontSize(labelSize),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _negativePromptController,
            maxLines: 2,
            style: TextStyle(fontSize: t.fontSize(10), color: t.textPrimary),
            decoration: InputDecoration(
              hintText: l.img2imgNegativeHint,
              hintStyle: TextStyle(color: t.hintText, fontSize: t.fontSize(9)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: t.borderSubtle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: t.borderMedium),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: t.borderMedium),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Resolution scale
          Text(
            'RESOLUTION SCALE',
            style: TextStyle(
              color: t.secondaryText,
              fontSize: t.fontSize(labelSize),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final scale in [1.0, 1.5])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${scale}x', style: TextStyle(fontSize: t.fontSize(9), fontWeight: FontWeight.bold, letterSpacing: 1)),
                    selected: notifier.config.scale == scale,
                    onSelected: (_) => notifier.setScale(scale),
                    backgroundColor: t.borderSubtle,
                    selectedColor: t.accent,
                    checkmarkColor: t.background,
                    labelStyle: TextStyle(color: notifier.config.scale == scale ? t.background : t.textTertiary),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    side: BorderSide(color: notifier.config.scale == scale ? t.accent : t.textMinimal, width: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Strength slider
          _SliderRow(
            label: l.enhanceStrength,
            value: notifier.config.strength,
            onChanged: notifier.setStrength,
            t: t,
          ),
          const SizedBox(height: 8),

          // Noise slider
          _SliderRow(
            label: l.enhanceNoise,
            value: notifier.config.noise,
            onChanged: notifier.setNoise,
            t: t,
          ),
          const SizedBox(height: 16),

          // Resolution display
          Text(
            notifier.config.scale > 1.0
                ? '${notifier.sourceWidth}x${notifier.sourceHeight} → ${((notifier.sourceWidth * notifier.config.scale) / 64).round() * 64}x${((notifier.sourceHeight * notifier.config.scale) / 64).round() * 64}'
                : '${notifier.sourceWidth}x${notifier.sourceHeight}',
            style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(labelSize)),
          ),
        ],
      ),
    );
  }

  void _saveResult(EnhanceNotifier notifier) {
    if (notifier.resultBytes == null) return;
    final gallery = context.read<GalleryNotifier>();
    final timestamp = generateTimestamp();
    gallery.saveMLResultWithMetadata(notifier.resultBytes!, 'ENH_$timestamp.png', sourceBytes: notifier.sourceImageBytes);

    if (mounted) {
      showAppSnackBar(context, context.l.enhanceSaved);
    }
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final dynamic t;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: t.secondaryText,
                fontSize: t.fontSize(responsiveFont(context, 9, 11)),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
            ),
          ],
        ),
        VisionSlider.subtle(
          value: value,
          onChanged: onChanged,
          t: t,
          min: 0.0,
          max: 1.0,
          divisions: 20,
        ),
      ],
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  const _PickerOption({
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
