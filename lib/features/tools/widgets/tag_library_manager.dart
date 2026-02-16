import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../generation/providers/generation_notifier.dart';
import '../../../core/utils/responsive.dart';
import '../providers/tag_library_notifier.dart';

class TagLibraryManager extends StatelessWidget {
  const TagLibraryManager({super.key});

  Color _getCategoryColor(String? category) {
    if (category == null) return Colors.white;
    switch (category.toLowerCase()) {
      case 'copyright':
        return const Color(0xFFD880FF); // Purple
      case 'character':
        return const Color(0xFF00AD00); // Green
      case 'artist':
        return const Color(0xFFFF5858); // Red
      case 'meta':
        return const Color(0xFFFF9229); // Orange
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TagLibraryNotifier>();
    final t = context.t;

    return Column(
      children: [
        _buildHeader(context, notifier, t),
        _buildFilters(context, notifier, t),
        Divider(height: 1, color: t.textMinimal),
        Expanded(
          child: _buildTagList(context, notifier, t),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, TagLibraryNotifier notifier, VisionTokens t) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: t.surfaceHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l.tagLibTitle,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(12),
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon:
                        Icon(Icons.settings, size: 16, color: t.textDisabled),
                    onPressed: () => _showPreviewSettings(context, notifier),
                    tooltip: context.l.tagLibPreviewSettings,
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 16, color: t.textPrimary),
                    onPressed: () => _showAddTagDialog(context, notifier, t),
                    tooltip: context.l.tagLibAddTag,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: notifier.setSearchQuery,
            style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(11)),
            decoration: InputDecoration(
              hintText: context.l.tagLibSearchTags,
              hintStyle: TextStyle(color: t.borderMedium, fontSize: t.fontSize(9), letterSpacing: 2),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, size: 14, color: t.borderMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, TagLibraryNotifier notifier, VisionTokens t) {
    final state = notifier.state;
    final categories = notifier.getCategories();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: t.surfaceMid,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: context.l.tagLibAll,
                  isSelected: state.selectedCategory == null && !state.showFavoritesOnly,
                  color: Colors.white,
                  onSelected: () {
                    if (state.showFavoritesOnly) notifier.toggleFavoritesOnly();
                    notifier.setCategory(null);
                  },
                  t: t,
                ),
                _buildFilterChip(
                  label: context.l.tagLibFavorites,
                  isSelected: state.showFavoritesOnly,
                  color: Colors.redAccent,
                  onSelected: () => notifier.toggleFavoritesOnly(),
                  t: t,
                ),
                _buildFilterChip(
                  label: context.l.tagLibImages,
                  isSelected: state.showWithExamplesOnly,
                  color: Colors.blueAccent,
                  onSelected: () => notifier.toggleWithExamplesOnly(),
                  t: t,
                ),
                ...categories.map((cat) => _buildFilterChip(
                      label: cat.toUpperCase(),
                      isSelected: state.selectedCategory == cat,
                      color: _getCategoryColor(cat),
                      onSelected: () => notifier.setCategory(cat),
                      t: t,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  context.l.tagLibSort,
                  style: TextStyle(color: t.textPrimary.withValues(alpha: 0.2), fontSize: t.fontSize(8), letterSpacing: 2),
                ),
                const SizedBox(width: 8),
                _buildSortOption(notifier, TagSort.countDesc, context.l.tagLibSortCountDesc, t),
                _buildSortOption(notifier, TagSort.countAsc, context.l.tagLibSortCountAsc, t),
                _buildSortOption(notifier, TagSort.alphaAsc, context.l.tagLibSortAZ, t),
                _buildSortOption(notifier, TagSort.alphaDesc, context.l.tagLibSortZA, t),
                _buildSortOption(notifier, TagSort.favoritesFirst, context.l.tagLibSortFavsFirst, t),
                const SizedBox(width: 16),
                Text(
                  context.l.tagLibTagCount(state.tags.length),
                  style: TextStyle(color: t.textPrimary.withValues(alpha: 0.2), fontSize: t.fontSize(8), letterSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onSelected,
    required VisionTokens t,
  }) {
    final activeColor = isSelected ? color : color.withValues(alpha: 0.2);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: activeColor,
              fontSize: t.fontSize(8),
              letterSpacing: 1,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(TagLibraryNotifier notifier, TagSort sort, String label, VisionTokens t) {
    final isSelected = notifier.state.sort == sort;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => notifier.setSort(sort),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? t.textPrimary : t.textDisabled,
            fontSize: t.fontSize(8),
            letterSpacing: 1,
            decoration: isSelected ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTagList(BuildContext context, TagLibraryNotifier notifier, VisionTokens t) {
    final state = notifier.state;
    final mobile = isMobile(context);
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: t.textMinimal));
    }

    return ListView.builder(
      itemCount: state.tags.length,
      itemExtent: 40,
      itemBuilder: (context, index) {
        final tag = state.tags[index];
        final color = _getCategoryColor(tag.typeName);
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.textMinimal, width: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (tag.examplePaths.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _showExamplesOverlay(context, tag),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                        image: File(tag.examplePaths.first).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(tag.examplePaths.first)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 32),
              Expanded(
                flex: mobile ? 1 : 4,
                child: Text(
                  tag.tag,
                  style: TextStyle(color: color, fontSize: t.fontSize(11), fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!mobile) ...[
                Expanded(
                  flex: 1,
                  child: Text(
                    tag.typeName.toUpperCase(),
                    style: TextStyle(color: color.withValues(alpha: 0.3), fontSize: t.fontSize(8)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    NumberFormat.compact().format(tag.count),
                    style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: t.fontSize(9), fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              IconButton(
                icon: Icon(
                  tag.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 14,
                  color: tag.isFavorite ? color : t.textDisabled,
                ),
                onPressed: () => notifier.toggleFavorite(tag),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.image_search, size: 14, color: t.textDisabled),
                onPressed: () => _showQuickPreview(context, tag.tag),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: context.l.tagLibTestTag,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 14, color: t.textDisabled),
                onPressed: () => _confirmDelete(context, notifier, tag, t),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, TagLibraryNotifier notifier, dynamic tag, VisionTokens t) {
    showDialog(
      context: context,
      builder: (context) {
        final l = context.l;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(l.tagLibDeleteTag, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
          content: Text(l.tagLibRemoveConfirm(tag.tag), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(11))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
            TextButton(
              onPressed: () {
                notifier.deleteTag(tag);
                Navigator.pop(context);
              },
              child: Text(l.commonDelete, style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9))),
            ),
          ],
        );
      },
    );
  }

  void _showQuickPreview(BuildContext context, String tag) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _QuickTagPreviewDialog(tag: tag),
    );
  }

  void _showPreviewSettings(BuildContext context, TagLibraryNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tRead.surfaceHigh,
      isScrollControlled: true,
      builder: (context) => _TagPreviewSettingsPanel(notifier: notifier),
    );
  }

  void _showExamplesOverlay(BuildContext context, dynamic tag) {
    showDialog(
      context: context,
      builder: (context) => _TagExamplesOverlay(tag: tag),
    );
  }

  void _showAddTagDialog(BuildContext context, TagLibraryNotifier notifier, VisionTokens t) {
    final nameController = TextEditingController();
    final countController = TextEditingController(text: '0');
    String selectedCategory = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final l = context.l;
          return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(l.tagLibAddNewTag, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
                decoration: InputDecoration(
                  hintText: l.tagLibTagName,
                  hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
                decoration: InputDecoration(
                  hintText: l.tagLibCount,
                  hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                dropdownColor: t.background,
                style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11)),
                items: ['general', 'character', 'copyright', 'meta', 'artist']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.toUpperCase())))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedCategory = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  notifier.addTag(
                    nameController.text,
                    int.tryParse(countController.text) ?? 0,
                    selectedCategory,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(l.tagLibAddTagBtn, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9))),
            ),
          ],
        );
        },
      ),
    );
  }
}

class _TagExamplesOverlay extends StatelessWidget {
  final dynamic tag;

  const _TagExamplesOverlay({required this.tag});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<TagLibraryNotifier>();
    final t = context.t;
    final color = const TagLibraryManager()._getCategoryColor(tag.typeName);

    return Dialog.fullscreen(
      backgroundColor: t.background.withValues(alpha: 0.9),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              tag.tag.toUpperCase(),
              style: TextStyle(color: color, fontSize: t.fontSize(12), letterSpacing: 4, fontWeight: FontWeight.w900),
            ),
            leading: IconButton(
              icon: Icon(Icons.close, color: t.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 832 / 1216,
              ),
              itemCount: tag.examplePaths.length,
              itemBuilder: (context, index) {
                final path = tag.examplePaths[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: t.textMinimal),
                      ),
                      child: File(path).existsSync()
                          ? Image.file(File(path), fit: BoxFit.contain)
                          : Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: t.textMinimal, size: 32),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: t.accentDanger),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              final l = context.l;
                              return AlertDialog(
                              backgroundColor: t.surfaceHigh,
                              title: Text(l.tagLibDeleteExample, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
                              content: Text(l.tagLibDeleteExampleConfirm, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(11))),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)))),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.commonDelete, style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9)))),
                              ],
                            );
                            },
                          );
                          if (confirm == true) {
                            await notifier.deleteExample(tag.tag, path);
                            if (!context.mounted) return;
                            if (tag.examplePaths.length <= 1) {
                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTagPreviewDialog extends StatefulWidget {
  final String tag;

  const _QuickTagPreviewDialog({required this.tag});

  @override
  State<_QuickTagPreviewDialog> createState() => _QuickTagPreviewDialogState();
}

class _QuickTagPreviewDialogState extends State<_QuickTagPreviewDialog> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final genNotifier = context.read<GenerationNotifier>();
    final libNotifier = context.read<TagLibraryNotifier>();
    final bytes = await genNotifier.generateQuickPreview(widget.tag,
        previewSettings: libNotifier.state.previewSettings);

    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
        if (bytes == null) {
          _error = context.l.tagLibGenerationFailed;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;

    return Dialog(
      backgroundColor: t.surfaceHigh,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l.tagLibTesting(widget.tag.toUpperCase()),
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: t.fontSize(10),
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: t.textDisabled),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 300,
              height: 450,
              decoration: BoxDecoration(
                color: t.background,
                border: Border.all(color: t.textMinimal),
              ),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.textMinimal,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.tagLibGeneratingPreview,
                            style: TextStyle(
                              color: t.textMinimal,
                              fontSize: t.fontSize(8),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: t.accentDanger,
                              fontSize: t.fontSize(9),
                              letterSpacing: 1,
                            ),
                          ),
                        )
                      : Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
            ),
            const SizedBox(height: 16),
            if (_imageBytes != null)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await context.read<TagLibraryNotifier>().saveExample(widget.tag, _imageBytes!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l.tagLibExampleSaved, style: const TextStyle(fontSize: 10, letterSpacing: 2)),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.save, size: 14, color: t.accentSuccess),
                  label: Text(l.tagLibSaveAsExample, style: TextStyle(color: t.accentSuccess, fontSize: t.fontSize(10), letterSpacing: 2)),
                  style: TextButton.styleFrom(backgroundColor: t.borderSubtle),
                ),
              ),
            const SizedBox(height: 16),
            Consumer<TagLibraryNotifier>(
              builder: (context, notifier, child) {
                final s = notifier.state.previewSettings;
                return Text(
                  "P: ${s.positivePrompt.toUpperCase()} | ${s.width.toInt()}X${s.height.toInt()} | STEPS: ${s.steps} | SCALE: ${s.scale}",
                  style: TextStyle(
                    color: t.textMinimal,
                    fontSize: t.fontSize(7),
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPreviewSettingsPanel extends StatefulWidget {
  final TagLibraryNotifier notifier;

  const _TagPreviewSettingsPanel({required this.notifier});

  @override
  State<_TagPreviewSettingsPanel> createState() =>
      _TagPreviewSettingsPanelState();
}

class _TagPreviewSettingsPanelState extends State<_TagPreviewSettingsPanel> {
  late TextEditingController _posController;
  late TextEditingController _negController;
  late TagPreviewSettings _current;

  @override
  void initState() {
    super.initState();
    _current = widget.notifier.state.previewSettings;
    _posController = TextEditingController(text: _current.positivePrompt);
    _negController = TextEditingController(text: _current.negativePrompt);
  }

  @override
  void dispose() {
    _posController.dispose();
    _negController.dispose();
    super.dispose();
  }

  void _update(TagPreviewSettings next) {
    setState(() => _current = next);
    widget.notifier.updatePreviewSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tagLibPreviewSettingsTitle,
            style: TextStyle(
                color: t.textPrimary,
                fontSize: t.fontSize(10),
                letterSpacing: 4,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          _buildTextField(l.tagLibPositivePromptBase, _posController, (val) {
            _update(_current.copyWith(positivePrompt: val));
          }, t),
          const SizedBox(height: 16),
          _buildTextField(l.tagLibNegativePrompt, _negController, (val) {
            _update(_current.copyWith(negativePrompt: val));
          }, t, maxLines: 3),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  l.tagLibSampler,
                  _current.sampler,
                  [
                    "k_euler_ancestral",
                    "k_euler",
                    "k_dpmpp_2s_ancestral",
                    "k_dpmpp_2m",
                    "k_dpmpp_sde"
                  ],
                  (val) => _update(_current.copyWith(sampler: val)),
                  t,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberInput(l.tagLibSteps, _current.steps.toDouble(),
                    (val) => _update(_current.copyWith(steps: val.toInt())),
                    t: t, min: 1, max: 50),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(l.tagLibWidth, _current.width,
                    (val) => _update(_current.copyWith(width: val)),
                    t: t, min: 64, max: 2048, step: 64),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberInput(l.tagLibHeight, _current.height,
                    (val) => _update(_current.copyWith(height: val)),
                    t: t, min: 64, max: 2048, step: 64),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(l.tagLibScale, _current.scale,
                    (val) => _update(_current.copyWith(scale: val)),
                    t: t, min: 1, max: 31),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.tagLibSeed,
                        style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
                    const SizedBox(height: 4),
                    TextField(
                      onChanged: (val) {
                        final s = int.tryParse(val);
                        if (s == null) {
                          _update(_current.copyWith(clearSeed: true));
                        } else {
                          _update(_current.copyWith(seed: s));
                        }
                      },
                      controller: TextEditingController(
                          text: _current.seed?.toString() ?? ""),
                      style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11)),
                      decoration: InputDecoration(
                        hintText: l.tagLibRandom,
                        hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, Function(String) onChanged, VisionTokens t,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.textMinimal)),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(String label, double value, Function(double) onChanged,
      {required VisionTokens t, double min = 0, double max = 100, double step = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toStringAsFixed(0)}",
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 1,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).toInt(),
            onChanged: onChanged,
            activeColor: t.textPrimary,
            inactiveColor: t.textMinimal,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(
      String label, T value, List<T> items, Function(T?) onChanged, VisionTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
        DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: t.background,
          underline: Container(height: 1, color: t.textMinimal),
          icon: Icon(Icons.arrow_drop_down, size: 14, color: t.textDisabled),
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11)),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i, child: Text(i.toString().toUpperCase())))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
