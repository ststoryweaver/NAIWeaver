import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/tag_suggestion_overlay.dart';
import '../providers/cascade_notifier.dart';
import '../services/cascade_stitching_service.dart';
import '../../../generation/providers/generation_notifier.dart';
import '../../../../tag_service.dart';

class CascadePlaybackView extends StatefulWidget {
  const CascadePlaybackView({super.key});

  @override
  State<CascadePlaybackView> createState() => _CascadePlaybackViewState();
}

class _CascadePlaybackViewState extends State<CascadePlaybackView> {
  final Map<int, TextEditingController> _appearanceControllers = {};
  final Map<int, FocusNode> _appearanceFocusNodes = {};
  final TextEditingController _globalController = TextEditingController();
  final FocusNode _globalFocusNode = FocusNode();

  @override
  void dispose() {
    for (var c in _appearanceControllers.values) {
      c.dispose();
    }
    for (var f in _appearanceFocusNodes.values) {
      f.dispose();
    }
    _globalController.dispose();
    _globalFocusNode.dispose();
    super.dispose();
  }

  void _syncControllers(CascadeNotifier notifier) {
    final state = notifier.state;
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

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notifier.state.activeCascade!.name.toUpperCase(),
              style: TextStyle(color: t.accentCascade, fontSize: t.fontSize(10), fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            Text(
              l.cascadeCharactersAndBeats(notifier.state.activeCascade!.characterCount, notifier.state.activeCascade!.beats.length),
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          focusNode: FocusNode()..skipTraversal = true,
          icon: Icon(Icons.close, size: 16, color: t.textDisabled),
          onPressed: () => notifier.exitCascadeMode(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildCastingSheet(CascadeNotifier notifier, TagService tagService) {
    final l = context.l;

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: ListView.builder(
            primary: false,
            scrollDirection: Axis.horizontal,
            itemCount: notifier.state.characterAppearances.length,
            itemBuilder: (context, index) {
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
                    if (lastPart.length < 2) return const Iterable<DanbooruTag>.empty();
                    return tagService.getSuggestions(lastPart);
                  },
                  displayStringForOption: (DanbooruTag option) => option.tag,
                  fieldViewBuilder: (context, controller, autocompFocusNode, onFieldSubmitted) {
                    final t = context.t;
                    return TextField(
                      controller: controller,
                      focusNode: autocompFocusNode,
                      onChanged: (val) => notifier.updateAppearance(index, val),
                      style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
                      decoration: InputDecoration(
                        hintText: l.cascadeCharTags(index + 1),
                        hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        filled: true,
                        fillColor: t.accentCascade.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return _buildOptionsView(context, (option) {
                      final currentText = _appearanceControllers[index]!.text;
                      final lastComma = currentText.lastIndexOf(',');
                      final newText = lastComma == -1
                          ? option.tag
                          : '${currentText.substring(0, lastComma + 1)} ${option.tag}';
                      notifier.updateAppearance(index, '$newText, ');
                    }, options);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        RawAutocomplete<DanbooruTag>(
          textEditingController: _globalController,
          focusNode: _globalFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable<DanbooruTag>.empty();
            final lastPart = textEditingValue.text.split(',').last.trim();
            if (lastPart.length < 2) return const Iterable<DanbooruTag>.empty();
            return tagService.getSuggestions(lastPart);
          },
          displayStringForOption: (DanbooruTag option) => option.tag,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            final t = context.t;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (val) => notifier.updateGlobalInjection(val),
              style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
              decoration: InputDecoration(
                hintText: l.cascadeGlobalStyle,
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
              final currentText = _globalController.text;
              final lastComma = currentText.lastIndexOf(',');
              final newText = lastComma == -1
                  ? option.tag
                  : '${currentText.substring(0, lastComma + 1)} ${option.tag}';
              notifier.updateGlobalInjection('$newText, ');
            }, options);
          },
        ),
      ],
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
                        child: Text(option.tag,
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

  Widget _buildPlaybackController(CascadeNotifier cascadeNotifier, GenerationNotifier genNotifier) {
    final t = context.t;
    final l = context.l;
    final state = cascadeNotifier.state;
    final currentIndex = state.selectedBeatIndex ?? 0;
    final totalBeats = state.activeCascade!.beats.length;
    final currentBeat = state.activeCascade!.beats[currentIndex];
    final hasPreview = state.beatPreviews.containsKey(currentIndex);

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
              return InkWell(
                focusNode: FocusNode()..skipTraversal = true,
                onTap: () {
                  cascadeNotifier.selectBeat(index);
                  // Push preview to main viewer if it exists
                  if (preview != null) {
                    genNotifier.setGeneratedImage(preview);
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
                  child: preview == null ? Center(child: Text('${index + 1}', style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10)))) : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                focusNode: FocusNode()..skipTraversal = true,
                onPressed: genNotifier.state.isLoading
                    ? null
                    : () async {
                        final request = CascadeStitchingService.render(
                          beat: currentBeat,
                          appearances: state.characterAppearances,
                          globalStyle: state.globalInjection,
                          useCoords: state.activeCascade!.useCoords,
                          activeStyleNames: currentBeat.activeStyleNames,
                          availableStyles: genNotifier.state.styles,
                        );
                        final result = await genNotifier.generateCascadeBeat(request);
                        if (result != null) {
                          cascadeNotifier.setBeatPreview(currentIndex, result);
                          if (currentIndex < totalBeats - 1) {
                            cascadeNotifier.selectBeat(currentIndex + 1);
                          }
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
                  focusNode: FocusNode()..skipTraversal = true,
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
