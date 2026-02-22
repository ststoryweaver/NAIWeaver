import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/vision_slider.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/timestamp_utils.dart';
import '../../../../core/widgets/comparison_slider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../../../generation/providers/generation_notifier.dart';
import '../models/augment_tool.dart';
import '../providers/director_tools_notifier.dart';
import 'tool_selector.dart';
import 'emotion_mood_picker.dart';

class DirectorToolsEditor extends StatefulWidget {
  const DirectorToolsEditor({super.key});

  @override
  State<DirectorToolsEditor> createState() => _DirectorToolsEditorState();
}

class _DirectorToolsEditorState extends State<DirectorToolsEditor> {
  final TextEditingController _promptController = TextEditingController();
  final _promptKey = GlobalKey();
  final _promptFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _promptFocus.addListener(_onPromptFocusChanged);
  }

  @override
  void dispose() {
    _promptFocus.removeListener(_onPromptFocusChanged);
    _promptFocus.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _onPromptFocusChanged() {
    if (_promptFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 400), _scrollToPrompt);
    }
  }

  void _scrollToPrompt() {
    if (!mounted || !_promptFocus.hasFocus) return;
    final ctx = _promptKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<DirectorToolsNotifier>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: notifier.hasSource
          ? _buildWorkspace(context, notifier)
          : _buildPicker(context, notifier),
    );
  }

  Widget _buildPicker(BuildContext context, DirectorToolsNotifier notifier) {
    final genNotifier = context.watch<GenerationNotifier>();
    final galleryNotifier = context.watch<GalleryNotifier>();
    final hasCurrentImage = genNotifier.state.generatedImage != null;
    final t = context.t;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high, size: 48, color: t.textMinimal),
            const SizedBox(height: 16),
            Text(
              context.l.directorToolsTitle,
              style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(12),
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l.directorToolsDesc,
              style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(10)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (hasCurrentImage) ...[
              _PickerOption(
                icon: Icons.flash_on,
                label: context.l.directorToolsUseCurrent,
                description: context.l.directorToolsUseCurrentDesc,
                accentColor: t.accent,
                onTap: () => notifier.setSourceImage(genNotifier.state.generatedImage!),
              ),
              const SizedBox(height: 12),
            ],

            _PickerOption(
              icon: Icons.photo_library_outlined,
              label: context.l.img2imgUploadFromDevice,
              description: context.l.img2imgUploadFromDeviceDesc,
              accentColor: t.accentEdit,
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.image);
                if (result != null && result.files.single.path != null) {
                  final bytes = await File(result.files.single.path!).readAsBytes();
                  notifier.setSourceImage(bytes);
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

  Widget _buildWorkspace(BuildContext context, DirectorToolsNotifier notifier) {
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
              tooltip: context.l.directorToolsSettingsTooltip,
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

  Widget _buildHeader(BuildContext context, DirectorToolsNotifier notifier) {
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
                  await notifier.process();
                  if (notifier.hasResult && mounted) {
                    if (gen.state.autoSaveImages) {
                      _saveResult(notifier);
                    }
                  }
                },
                icon: notifier.isProcessing
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: t.background))
                    : const Icon(Icons.auto_fix_high, size: 14),
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
                  await notifier.process();
                  if (notifier.hasResult && mounted) {
                    if (gen.state.autoSaveImages) {
                      _saveResult(notifier);
                    }
                  }
                },
                icon: notifier.isProcessing
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: t.background))
                    : const Icon(Icons.auto_fix_high, size: 14),
                label: Text(notifier.isProcessing ? l.directorToolsProcessing : l.directorToolsProcess),
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

  Widget _buildImageArea(BuildContext context, DirectorToolsNotifier notifier) {
    final t = context.t;
    final l = AppLocalizations.of(context);

    return Stack(
      children: [
        if (notifier.hasResult)
          ComparisonSlider(
            beforeBytes: notifier.sourceImageBytes!,
            afterBytes: notifier.resultBytes!,
            beforeLabel: l.comparisonBefore,
            afterLabel: l.comparisonAfter,
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
        // Error overlay
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

  Widget _buildConfigPanel(BuildContext context, DirectorToolsNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final labelSize = responsiveFont(context, 9, 11);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.directorToolsSelectTool,
            style: TextStyle(
              color: t.secondaryText,
              fontSize: t.fontSize(labelSize),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ToolSelector(
            selected: notifier.selectedTool,
            onSelected: notifier.selectTool,
          ),
          const SizedBox(height: 16),

          // Info text about current tool
          Text(
            '${notifier.sourceWidth} x ${notifier.sourceHeight}',
            style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(labelSize)),
          ),
          const SizedBox(height: 12),

          // Defry slider
          if (notifier.selectedTool.hasDefry) ...[
            Text(
              l.directorToolsDefry,
              style: TextStyle(
                color: t.secondaryText,
                fontSize: t.fontSize(labelSize),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: VisionSlider.subtle(
                    value: notifier.defry.toDouble(),
                    onChanged: (v) => notifier.setDefry(v.round()),
                    t: t,
                    min: 0,
                    max: 5,
                    divisions: 5,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${notifier.defry}',
                    style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Mood picker (emotion only)
          if (notifier.selectedTool == AugmentTool.emotion) ...[
            Text(
              l.directorToolsMood,
              style: TextStyle(
                color: t.secondaryText,
                fontSize: t.fontSize(labelSize),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            EmotionMoodPicker(
              selected: notifier.selectedMood,
              onSelected: notifier.setMood,
            ),
            const SizedBox(height: 12),
          ],

          // Prompt field (colorize/emotion)
          if (notifier.selectedTool.hasPrompt) ...[
            Text(
              l.directorToolsPrompt,
              style: TextStyle(
                color: t.secondaryText,
                fontSize: t.fontSize(labelSize),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: _promptKey,
              focusNode: _promptFocus,
              controller: _promptController,
              maxLines: 2,
              onTap: _scrollToPrompt,
              style: TextStyle(fontSize: t.fontSize(10), color: t.textPrimary),
              decoration: InputDecoration(
                hintText: l.directorToolsPromptHint,
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
          ],
        ],
      ),
    );
  }

  void _saveResult(DirectorToolsNotifier notifier) {
    if (notifier.resultBytes == null) return;
    final gallery = context.read<GalleryNotifier>();
    final timestamp = generateTimestamp();
    final toolName = notifier.selectedTool.apiValue.replaceAll('-', '');
    gallery.saveMLResultWithMetadata(notifier.resultBytes!, 'DT_${toolName}_$timestamp.png', sourceBytes: notifier.sourceImageBytes);

    if (mounted) {
      showAppSnackBar(context, context.l.directorToolsSaved);
    }
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
