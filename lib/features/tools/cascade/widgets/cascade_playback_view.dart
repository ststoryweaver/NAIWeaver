import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/web_download.dart';
import '../../../../core/widgets/tag_suggestion_overlay.dart';
import '../providers/cascade_notifier.dart';
import '../services/caption_burn_service.dart';
import '../services/cascade_stitching_service.dart';
import 'caption_overlay.dart';
import 'cascade_help_dialog.dart';
import '../../../generation/providers/generation_notifier.dart';
import '../../../../core/services/tag_service.dart';

class CascadePlaybackView extends StatefulWidget {
  const CascadePlaybackView({super.key});

  @override
  State<CascadePlaybackView> createState() => _CascadePlaybackViewState();
}

class _CascadePlaybackViewState extends State<CascadePlaybackView> {
  final Map<int, TextEditingController> _appearanceControllers = {};
  final Map<int, FocusNode> _appearanceFocusNodes = {};
  final Map<int, TextEditingController> _captionControllers = {};
  final TextEditingController _globalSceneController = TextEditingController();
  final FocusNode _globalSceneFocusNode = FocusNode();
  final TextEditingController _globalController = TextEditingController();
  final FocusNode _globalFocusNode = FocusNode();

  // Persistent skip-traversal nodes for the non-focusable action widgets, owned
  // and disposed here instead of allocating a fresh leaked FocusNode every build.
  final FocusNode _generateFocusNode = FocusNode(skipTraversal: true);
  final FocusNode _skipFocusNode = FocusNode(skipTraversal: true);
  final FocusNode _toggleFocusNode = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    for (var c in _appearanceControllers.values) {
      c.dispose();
    }
    for (var f in _appearanceFocusNodes.values) {
      f.dispose();
    }
    for (var c in _captionControllers.values) {
      c.dispose();
    }
    _globalSceneController.dispose();
    _globalSceneFocusNode.dispose();
    _globalController.dispose();
    _globalFocusNode.dispose();
    _generateFocusNode.dispose();
    _skipFocusNode.dispose();
    _toggleFocusNode.dispose();
    super.dispose();
  }

  void _syncControllers(CascadeNotifier notifier) {
    final state = notifier.state;
    if (_globalSceneController.text != state.globalSceneTags) {
      _globalSceneController.text = state.globalSceneTags;
    }
    if (_globalController.text != state.globalInjection) {
      _globalController.text = state.globalInjection;
    }
    for (int i = 0; i < state.characterAppearances.length; i++) {
      final controller = _appearanceControllers.putIfAbsent(i, () => TextEditingController());
      if (controller.text != state.characterAppearances[i]) {
        controller.text = state.characterAppearances[i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Consumer2<CascadeNotifier, GenerationNotifier>(
      builder: (context, cascadeNotifier, genNotifier, child) {
        final state = cascadeNotifier.state;
        if (state.activeCascade == null) {
          return _buildSelector(cascadeNotifier);
        }

        _syncControllers(cascadeNotifier);

        // The panel is bottom-anchored and grows upward with its content. When
        // the keyboard opens or a caption preview inflates it, an unconstrained
        // Column would push the top sections (char appearances) off-screen and
        // out of reach. Cap the height to the space actually available above the
        // bottom anchor and let the content scroll instead.
        final mq = MediaQuery.of(context);
        final maxPanelHeight = mq.size.height - mq.viewInsets.bottom - mq.viewPadding.top - 24;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                t.background.withValues(alpha: 0.8),
                t.background,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxPanelHeight > 0 ? maxPanelHeight : double.infinity),
            child: SingleChildScrollView(
              // Anchor scrolling to the bottom so the playback controls (the
              // primary action) stay visible and the appearance row scrolls
              // into view from the top when needed.
              reverse: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(cascadeNotifier),
                  const SizedBox(height: 12),
                  _buildCastingSheet(cascadeNotifier, genNotifier.tagService),
                  const SizedBox(height: 12),
                  _buildPlaybackController(cascadeNotifier, genNotifier),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelector(CascadeNotifier notifier) {
    final t = context.t;
    final l = context.l;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.background.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.accentCascade.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.cascadeSelect,
              style: TextStyle(color: t.accentCascade, fontSize: t.fontSize(10), fontWeight: FontWeight.w900, letterSpacing: 4),
            ),
            const SizedBox(height: 24),
            if (notifier.state.savedCascades.isEmpty)
              Text(l.cascadeNoSaved, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notifier.state.savedCascades.map((c) => ActionChip(
                  backgroundColor: t.accentCascade.withValues(alpha: 0.1),
                  side: BorderSide(color: t.accentCascade.withValues(alpha: 0.2)),
                  label: Text(c.name, style: TextStyle(color: t.accentCascade, fontSize: t.fontSize(10))),
                  onPressed: () => notifier.setActiveCascade(c),
                )).toList(),
              ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => notifier.setActiveCascade(null),
              child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CascadeNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notifier.state.activeCascade!.name.toUpperCase(),
                style: TextStyle(color: t.accentCascade, fontSize: t.fontSize(10), fontWeight: FontWeight.w900, letterSpacing: 2),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l.cascadeCharactersAndBeats(notifier.state.activeCascade!.characterCount, notifier.state.activeCascade!.beats.length),
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.help_outline, size: mobile ? 16 : 14, color: t.textDisabled),
          onPressed: () => showCascadeHelpDialog(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => notifier.exitCascadeMode(),
          icon: Icon(Icons.close, size: mobile ? 16 : 14, color: t.textDisabled),
          label: Text(
            l.cascadeExitCascade.toUpperCase(),
            style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(mobile ? 10 : 8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 8, vertical: mobile ? 8 : 4),
            side: BorderSide(color: t.borderMedium),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }

  Widget _buildCastingSheet(CascadeNotifier notifier, TagService tagService) {
    final l = context.l;
    final state = notifier.state;
    final beatIndex = state.selectedBeatIndex ?? 0;
    final beats = state.activeCascade?.beats ?? const [];
    // Appearances are stored cascade-wide by cast index. Show one field per
    // cast member on the selected beat, in slot order, each bound to that
    // member's appearance so the field survives slot removal/reorder.
    final castOnBeat = (beatIndex >= 0 && beatIndex < beats.length)
        ? beats[beatIndex].characterSlots.map((s) => s.castIndex).toList()
        : const <int>[];

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: ListView.builder(
            primary: false,
            scrollDirection: Axis.horizontal,
            itemCount: castOnBeat.length,
            itemBuilder: (context, slot) {
              final index = castOnBeat[slot];
              final focusNode = _appearanceFocusNodes.putIfAbsent(index, () => FocusNode());
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 8),
                child: RawAutocomplete<DanbooruTag>(
                  textEditingController: _appearanceControllers[index],
                  focusNode: focusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<DanbooruTag>.empty();
                    final lastPart = textEditingValue.text.split(',').last.trim();
                    final minLength = TagService.containsNonAscii(lastPart) ? 1 : 2;
                    if (lastPart.length < minLength) return const Iterable<DanbooruTag>.empty();
                    return tagService.getSuggestions(lastPart);
                  },
                  displayStringForOption: (DanbooruTag option) =>
                      option.matchedAlias != null ? '${option.matchedAlias} → ${option.tag}' : option.tag,
                  fieldViewBuilder: (context, controller, autocompFocusNode, onFieldSubmitted) {
                    final t = context.t;
                    return TextField(
                      controller: controller,
                      focusNode: autocompFocusNode,
                      onChanged: (val) => notifier.updateAppearance(index, val),
                      style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
                      decoration: InputDecoration(
                        hintText: l.cascadeCharTags(index + 1),
                        // Brighter fill + a visible accent border so the
                        // appearance boxes read as interactive fields against the
                        // black background (the old 5% fill was nearly invisible).
                        hintStyle: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        filled: true,
                        fillColor: t.accentCascade.withValues(alpha: 0.12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: t.accentCascade.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: t.accentCascade.withValues(alpha: 0.3)),
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return _buildOptionsView(context, (option) {
                      final insertText = option.matchedAlias ?? option.tag;
                      final currentText = _appearanceControllers[index]!.text;
                      final lastComma = currentText.lastIndexOf(',');
                      final newText = lastComma == -1
                          ? insertText
                          : '${currentText.substring(0, lastComma + 1)} $insertText';
                      notifier.updateAppearance(index, '$newText, ');
                    }, options);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildGlobalTagBox(
          controller: _globalSceneController,
          focusNode: _globalSceneFocusNode,
          hint: l.cascadeGlobalScene,
          tagService: tagService,
          onChanged: notifier.updateGlobalSceneTags,
        ),
        const SizedBox(height: 8),
        _buildGlobalTagBox(
          controller: _globalController,
          focusNode: _globalFocusNode,
          hint: l.cascadeGlobalStyle,
          tagService: tagService,
          onChanged: notifier.updateGlobalInjection,
        ),
      ],
    );
  }

  /// A single full-width cast-sheet tag box with Danbooru autocomplete. Shared
  /// by the Global Scene and Global Style / Injection boxes, which are visually
  /// identical and differ only in label and which state field they update.
  Widget _buildGlobalTagBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required TagService tagService,
    required ValueChanged<String> onChanged,
  }) {
    return RawAutocomplete<DanbooruTag>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<DanbooruTag>.empty();
        final lastPart = textEditingValue.text.split(',').last.trim();
        final minLength = TagService.containsNonAscii(lastPart) ? 1 : 2;
        if (lastPart.length < minLength) return const Iterable<DanbooruTag>.empty();
        return tagService.getSuggestions(lastPart);
      },
      displayStringForOption: (DanbooruTag option) =>
          option.matchedAlias != null ? '${option.matchedAlias} → ${option.tag}' : option.tag,
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        final t = context.t;
        return TextField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          onChanged: onChanged,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: t.borderSubtle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderSubtle)),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildOptionsView(context, (option) {
          final insertText = option.matchedAlias ?? option.tag;
          final currentText = controller.text;
          final lastComma = currentText.lastIndexOf(',');
          final newText = lastComma == -1
              ? insertText
              : '${currentText.substring(0, lastComma + 1)} $insertText';
          onChanged('$newText, ');
        }, options);
      },
    );
  }

  Widget _buildOptionsView(BuildContext context, AutocompleteOnSelected<DanbooruTag> onSelected, Iterable<DanbooruTag> options) {
    final t = context.t;
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: t.surfaceHigh,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: t.borderMedium),
            boxShadow: [BoxShadow(color: t.background.withValues(alpha: 0.5), blurRadius: 10)],
          ),
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              final color = TagSuggestionOverlay.tagColor(option);
              return InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(color: t.borderSubtle),
                      left: BorderSide(color: color.withValues(alpha: 0.4), width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: option.matchedAlias != null
                            ? Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: option.matchedAlias, style: TextStyle(color: color, fontSize: t.fontSize(9), fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' → ', style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: t.fontSize(8))),
                                  TextSpan(text: option.tag, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: t.fontSize(8))),
                                ]),
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(option.tag,
                                style: TextStyle(color: color, fontSize: t.fontSize(9), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      const SizedBox(width: 4),
                      Text(NumberFormat.compact().format(option.count),
                        style: TextStyle(color: color.withValues(alpha: 0.4), fontSize: t.fontSize(7)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Narration caption controls for the current beat: an optional scrim+caption
  /// preview over the beat image, the free-text caption input, and a show/hide
  /// toggle. Display-only — never alters the saved cascade or preview bytes.
  Widget _buildCaptionSection(CascadeNotifier notifier, int currentIndex) {
    final t = context.t;
    final l = context.l;
    final state = notifier.state;
    final preview = state.beatPreviews[currentIndex];
    final caption = state.beatCaptions[currentIndex] ?? '';
    final beat = state.activeCascade!.beats[currentIndex];
    // Mirror the export framing: use the beat's real aspect ratio + contain so
    // the in-app preview shows exactly what CaptionBurnService will bake. A
    // hardcoded 16:9 cover would crop portrait beats and mis-place the caption.
    final previewAspect = beat.height > 0 ? beat.width / beat.height : 1.0;

    final controller = _captionControllers.putIfAbsent(
      currentIndex,
      () => TextEditingController(text: caption),
    );
    if (controller.text != caption) {
      controller.text = caption;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Caption preview over the current beat image (scrim technique).
        if (preview != null && caption.trim().isNotEmpty && state.captionsVisible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AspectRatio(
                aspectRatio: previewAspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(preview, fit: BoxFit.contain, filterQuality: FilterQuality.low),
                    CaptionOverlay(text: caption),
                  ],
                ),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (val) => notifier.setBeatCaption(currentIndex, val),
                style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: l.cascadeCaptionHint,
                  hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(8)),
                  prefixIcon: Icon(Icons.subtitles_outlined, size: 16, color: t.textDisabled),
                  prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 0),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  filled: true,
                  fillColor: t.borderSubtle,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderSubtle)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              focusNode: _toggleFocusNode,
              icon: Icon(
                state.captionsVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: state.captionsVisible ? t.accentCascade : t.textDisabled,
              ),
              tooltip: l.cascadeCaptionToggle,
              onPressed: notifier.toggleCaptionsVisible,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            _buildExportMenu(notifier, currentIndex),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Export menu: burn the current beat's caption into a single PNG, or assemble
  /// every generated beat into a storyboard strip (vertical / horizontal) with
  /// captions baked in. Gated behind an explicit action so in-app previews and
  /// saved cascades stay clean.
  Widget _buildExportMenu(CascadeNotifier notifier, int currentIndex) {
    final t = context.t;
    final l = context.l;
    final state = notifier.state;
    final hasCurrentPreview = state.beatPreviews[currentIndex] != null;
    final generatedCount = state.beatPreviews.values.where((b) => b != null).length;

    return PopupMenuButton<String>(
      enabled: hasCurrentPreview || generatedCount > 0,
      tooltip: l.cascadeExportTooltip,
      icon: Icon(Icons.ios_share, size: 18, color: t.textDisabled),
      color: t.surfaceHigh,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onSelected: (value) => _handleExport(notifier, currentIndex, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'beat',
          enabled: hasCurrentPreview,
          child: Text(l.cascadeExportBeat, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11))),
        ),
        PopupMenuItem(
          value: 'strip_v',
          enabled: generatedCount > 0,
          child: Text(l.cascadeExportStripVertical, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11))),
        ),
        PopupMenuItem(
          value: 'strip_h',
          enabled: generatedCount > 0,
          child: Text(l.cascadeExportStripHorizontal, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11))),
        ),
      ],
    );
  }

  Future<void> _handleExport(CascadeNotifier notifier, int currentIndex, String action) async {
    final l = context.l;
    final state = notifier.state;
    final cascadeName = state.activeCascade?.name ?? 'cascade';

    try {
      Uint8List bytes;
      String fileName;

      if (action == 'beat') {
        final preview = state.beatPreviews[currentIndex];
        if (preview == null) return;
        bytes = await CaptionBurnService.burnFrame(CaptionFrame(
          imageBytes: preview,
          caption: state.beatCaptions[currentIndex] ?? '',
        ));
        fileName = '${_safeName(cascadeName)}_beat${currentIndex + 1}';
      } else {
        // Build a strip from every generated beat, in beat order.
        final frames = <CaptionFrame>[];
        final beats = state.activeCascade!.beats;
        for (int i = 0; i < beats.length; i++) {
          final preview = state.beatPreviews[i];
          if (preview != null) {
            frames.add(CaptionFrame(
              imageBytes: preview,
              caption: state.beatCaptions[i] ?? '',
            ));
          }
        }
        if (frames.isEmpty) return;
        final result = await CaptionBurnService.buildStoryboardStrip(
          frames,
          layout: action == 'strip_v'
              ? StoryboardLayout.vertical
              : StoryboardLayout.horizontal,
        );
        bytes = result.bytes;
        fileName = '${_safeName(cascadeName)}_storyboard';
        if (result.downscaled && mounted) {
          showAppSnackBar(context, l.cascadeStripDownscaled, color: const Color(0xFFFFB74D));
        }
      }

      if (!mounted) return;
      await _saveOrShareBytes(bytes, fileName);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, '${l.cascadeExportFailed}: $e', color: const Color(0xFFF44336));
      }
    }
  }

  /// Routes export bytes through the platform's save/share path: share sheet on
  /// mobile, save-file dialog on desktop, browser download on web.
  Future<void> _saveOrShareBytes(Uint8List bytes, String fileName) async {
    final l = context.l;
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fullName = '${fileName}_$timestamp.png';

    if (kIsWeb) {
      downloadBytes(bytes, fullName);
      if (mounted) showAppSnackBar(context, l.cascadeExportSaved, color: const Color(0xFF4CAF50));
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: fullName)],
      );
      return;
    }

    // Desktop: save-file dialog.
    final result = await FilePicker.platform.saveFile(
      dialogTitle: l.cascadeExportTooltip,
      fileName: fullName,
      type: FileType.image,
    );
    if (result == null) return;
    await File(result).writeAsBytes(bytes);
    if (mounted) showAppSnackBar(context, l.cascadeExportSaved, color: const Color(0xFF4CAF50));
  }

  String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').trim();
    return cleaned.isEmpty ? 'cascade' : cleaned;
  }

  Widget _buildPlaybackController(CascadeNotifier cascadeNotifier, GenerationNotifier genNotifier) {
    final t = context.t;
    final l = context.l;
    final state = cascadeNotifier.state;
    final currentIndex = state.selectedBeatIndex ?? 0;
    final totalBeats = state.activeCascade!.beats.length;
    final currentBeat = state.activeCascade!.beats[currentIndex];
    // `!= null` (not containsKey) — beatPreviews values are nullable, so a beat
    // can hold a null preview; treat that as "no preview", matching the export
    // menu's gating in _buildExportMenu.
    final hasPreview = state.beatPreviews[currentIndex] != null;

    return Column(
      children: [
        // Beat Timeline
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalBeats,
            itemBuilder: (context, index) {
              final isSelected = index == currentIndex;
              final preview = state.beatPreviews[index];
              final hasCaption = (state.beatCaptions[index] ?? '').trim().isNotEmpty;
              return InkWell(
                // One InkWell per beat is mounted at once, so a shared FocusNode
                // can't be used; these decorative cells never need focus anyway.
                canRequestFocus: false,
                onTap: () {
                  cascadeNotifier.selectBeat(index);
                  // Push preview to main viewer if it exists, and adopt that
                  // beat's saved filename so the album picker checks *this*
                  // image rather than the last generated one.
                  if (preview != null) {
                    genNotifier.setGeneratedImage(
                      preview,
                      metadata: cascadeNotifier.state.beatMetadata[index],
                    );
                    genNotifier.adoptSavedBasename(
                      cascadeNotifier.state.beatSavedBasenames[index],
                    );
                  }
                },
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? t.accentCascade.withValues(alpha: 0.2) : t.borderSubtle,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isSelected ? t.accentCascade : t.borderMedium),
                    image: preview != null ? DecorationImage(image: MemoryImage(preview), fit: BoxFit.cover) : null,
                  ),
                  child: Stack(
                    children: [
                      if (preview == null)
                        Center(child: Text('${index + 1}', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10)))),
                      if (hasCaption)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Icon(Icons.subtitles, size: 10, color: t.accentCascade),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildCaptionSection(cascadeNotifier, currentIndex),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                focusNode: _generateFocusNode,
                onPressed: genNotifier.state.isLoading
                    ? null
                    : () async {
                        final target = cascadeNotifier.captureGenerationTarget(currentBeat.id);
                        if (target == null) return;
                        // render() throws synchronously if cast-time state is
                        // malformed (e.g. fewer appearances than character
                        // slots). Catch it so the tap surfaces an error instead
                        // of silently no-op'ing with no loading indicator.
                        final CascadeStitchedRequest request;
                        try {
                          request = CascadeStitchingService.render(
                            beat: currentBeat,
                            appearances: state.characterAppearances,
                            globalSceneTags: state.globalSceneTags,
                            globalStyle: state.globalInjection,
                            useCoords: state.activeCascade!.effectiveUseCoords(currentBeat),
                            activeStyleNames: currentBeat.activeStyleNames,
                            availableStyles: genNotifier.state.styles,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            showErrorSnackBar(context, l.cascadeBeatRenderError);
                          }
                          return;
                        }
                        final result = await genNotifier.generateCascadeBeat(request);
                        if (mounted && result != null) {
                          cascadeNotifier.completeBeatGeneration(
                            target,
                            result.imageBytes,
                            metadata: result.metadata,
                            savedBasename: result.savedBasename,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: genNotifier.state.isLoading
                    ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: t.background))
                    : Text(
                        hasPreview ? l.cascadeRegenerateBeat(currentIndex + 1) : l.cascadeGenerateBeat(currentIndex + 1),
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
              ),
            ),
            if (hasPreview && !genNotifier.state.isLoading && currentIndex < totalBeats - 1)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  focusNode: _skipFocusNode,
                  icon: Icon(Icons.skip_next, color: t.textSecondary),
                  onPressed: () => cascadeNotifier.selectBeat(currentIndex + 1),
                  tooltip: l.cascadeSkipToNext,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
