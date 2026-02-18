import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/tag_suggestion_overlay.dart';
import '../../../wildcard_processor.dart';
import '../providers/wildcard_notifier.dart';

class WildcardManager extends StatefulWidget {
  const WildcardManager({super.key});

  @override
  State<WildcardManager> createState() => _WildcardManagerState();
}

class _WildcardManagerState extends State<WildcardManager> {
  bool _showingEditor = false;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<WildcardNotifier>();
    final mobile = isMobile(context);
    final t = context.t;

    if (mobile) {
      return Column(
        children: [
          _buildHeader(t),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: _showingEditor && notifier.state.selectedFile != null
                ? Column(
                    children: [
                      _buildMobileEditorBar(notifier, t),
                      Expanded(child: _buildEditor(context, notifier, t)),
                    ],
                  )
                : _buildFileList(context, notifier, t, fullWidth: true),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(t),
        Divider(height: 1, color: t.textMinimal),
        Expanded(
          child: Row(
            children: [
              _buildFileList(context, notifier, t),
              VerticalDivider(width: 1, color: t.textMinimal),
              Expanded(
                child: _buildEditor(context, notifier, t),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileEditorBar(WildcardNotifier notifier, VisionTokens t) {
    final fileName = notifier.state.selectedFile != null
        ? p.basenameWithoutExtension(notifier.state.selectedFile!.path).toUpperCase()
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: t.surfaceMid,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 18, color: t.textDisabled),
            onPressed: () => setState(() => _showingEditor = false),
          ),
          const SizedBox(width: 8),
          Text(fileName, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(11), letterSpacing: 1, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeader(VisionTokens t) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: t.surfaceHigh,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.wildcardManager,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: t.fontSize(16),
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.wildcardManageDesc,
                  style: TextStyle(color: t.hintText, fontSize: t.fontSize(9), letterSpacing: 2),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.help_outline, size: 18, color: t.textDisabled),
            onPressed: () => _showWildcardHelp(t),
            tooltip: l.wildcardHelp,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, WildcardNotifier notifier, VisionTokens t, {bool fullWidth = false}) {
    final state = notifier.state;
    return Container(
      width: fullWidth ? double.infinity : 220,
      color: t.surfaceMid,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l.wildcardFiles,
                  style: TextStyle(color: t.secondaryText, fontSize: t.fontSize(8), letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 14, color: t.secondaryText),
                  onPressed: () => _showCreateDialog(context, notifier, t),
                  tooltip: context.l.wildcardNew,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: state.files.length,
              onReorder: notifier.reorderFiles,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: t.surfaceHigh,
                  borderRadius: BorderRadius.circular(4),
                  elevation: 4,
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final file = state.files[index];
                final isSelected = state.selectedFile?.path == file.path;
                final fileName = p.basenameWithoutExtension(file.path);

                final isFav = notifier.isFavorite(file);

                return InkWell(
                  key: ValueKey(file.path),
                  onTap: () {
                    notifier.selectFile(file);
                    if (isMobile(context)) setState(() => _showingEditor = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: isSelected ? t.borderSubtle : Colors.transparent,
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_handle, size: 14, color: t.textDisabled),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isFav ? Icons.star : Icons.description_outlined,
                          size: 12,
                          color: isFav
                              ? const Color(0xFFFFD740)
                              : (isSelected ? t.textPrimary : t.secondaryText),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? t.textPrimary : t.secondaryText,
                              fontSize: t.fontSize(11),
                              letterSpacing: 1,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.star : Icons.star_border,
                              size: 12,
                              color: isFav ? const Color(0xFFFFD740) : t.textDisabled,
                            ),
                            onPressed: () => notifier.toggleFavorite(file),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 12, color: t.textDisabled),
                            onPressed: () => notifier.deleteFile(file),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context, WildcardNotifier notifier, VisionTokens t) {
    final state = notifier.state;
    if (state.selectedFile == null) {
      return Center(
        child: Text(
          context.l.wildcardSelectOrCreate,
          style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9), letterSpacing: 2),
        ),
      );
    }

    final hasResults = state.invalidTags.isNotEmpty || state.validCount > 0;
    final totalChecked = state.validCount + state.invalidTags.length;
    final currentMode = notifier.getFileMode(state.selectedFile!);
    final l = context.l;

    return Column(
      children: [
        SizedBox(
          height: 30,
          child: TagSuggestionOverlay(
            suggestions: state.tagSuggestions,
            onTagSelected: notifier.applyTagSuggestion,
          ),
        ),
        // Validation toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: t.surfaceMid,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.verified_outlined, size: 16, color: t.textSecondary),
                onPressed: notifier.validateCurrentFile,
                tooltip: context.l.wildcardValidateTags,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              if (hasResults) ...[
                const SizedBox(width: 8),
                Text(
                  context.l.wildcardRecognized(state.validCount, totalChecked),
                  style: TextStyle(
                    color: state.invalidTags.isEmpty ? const Color(0xFF4CAF50) : const Color(0xFFFFC107),
                    fontSize: t.fontSize(9),
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(),
              if (hasResults)
                IconButton(
                  icon: Icon(Icons.close, size: 14, color: t.textDisabled),
                  onPressed: notifier.clearValidation,
                  tooltip: context.l.wildcardClear,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              const SizedBox(width: 4),
              Text(
                l.wildcardMode,
                style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 1),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                child: DropdownButton<WildcardMode>(
                  value: currentMode,
                  dropdownColor: t.surfaceHigh,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(9), letterSpacing: 1),
                  items: WildcardMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(_modeLabel(mode, l)),
                    );
                  }).toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      notifier.setFileMode(state.selectedFile!, mode);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            textAlignVertical: TextAlignVertical.top,
            onTapOutside: (_) {
              Future.delayed(const Duration(milliseconds: 200), () {
                notifier.clearTagSuggestions();
              });
            },
            controller: notifier.editorController,
            maxLines: null,
            expands: true,
            onChanged: (val) {
              notifier.handleTagSuggestions(val, notifier.editorController.selection);
              notifier.saveCurrentFile();
            },
            style: TextStyle(
              color: t.textSecondary,
              fontSize: t.fontSize(13),
              fontFamily: 'monospace',
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: context.l.wildcardStartTyping,
              hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9), letterSpacing: 2),
              contentPadding: const EdgeInsets.all(24),
              border: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
        ),
        // Invalid tags list
        if (state.invalidTags.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            width: double.infinity,
            color: t.surfaceMid,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: t.textMinimal),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    context.l.wildcardUnrecognized(state.invalidTags.length),
                    style: TextStyle(color: const Color(0xFFFFC107), fontSize: t.fontSize(8), letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                    itemCount: state.invalidTags.length,
                    itemExtent: 20,
                    itemBuilder: (context, index) {
                      return Text(
                        state.invalidTags[index],
                        style: TextStyle(
                          color: const Color(0xFFFF8A65),
                          fontSize: t.fontSize(10),
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _modeLabel(WildcardMode mode, dynamic l) {
    switch (mode) {
      case WildcardMode.random:
        return l.wildcardModeRandom;
      case WildcardMode.sequential:
        return l.wildcardModeSequential;
      case WildcardMode.shuffle:
        return l.wildcardModeShuffle;
      case WildcardMode.weighted:
        return l.wildcardModeWeighted;
    }
  }

  void _showWildcardHelp(VisionTokens t) {
    final l = context.l;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(
            l.wildcardHelpTitle,
            style: TextStyle(fontSize: t.fontSize(11), letterSpacing: 2, color: t.textSecondary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _helpRow(t, '__name__', l.wildcardHelpRandom),
              const SizedBox(height: 12),
              _helpRow(t, '__summer.clothes__', l.wildcardHelpDotSyntax),
              const SizedBox(height: 12),
              _helpRow(t, '__', l.wildcardHelpBrowse),
              const SizedBox(height: 16),
              Text(
                l.wildcardHelpNesting,
                style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                l.wildcardHelpNestingDesc,
                style: TextStyle(color: t.hintText, fontSize: t.fontSize(9), height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                l.wildcardMode,
                style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              _modeHelpRow(t, l.wildcardModeRandom, l.wildcardModeRandomDesc),
              const SizedBox(height: 2),
              _modeHelpRow(t, l.wildcardModeSequential, l.wildcardModeSequentialDesc),
              const SizedBox(height: 2),
              _modeHelpRow(t, l.wildcardModeShuffle, l.wildcardModeShuffleDesc),
              const SizedBox(height: 2),
              _modeHelpRow(t, l.wildcardModeWeighted, l.wildcardModeWeightedDesc),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.star, size: 14, color: const Color(0xFFFFD740)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.wildcardHelpFavorites,
                      style: TextStyle(color: t.hintText, fontSize: t.fontSize(9), height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: const Color(0xFFFFD740)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.wildcardHelpTip,
                      style: TextStyle(color: t.hintText, fontSize: t.fontSize(9), height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonClose, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9))),
            ),
          ],
        );
      },
    );
  }

  Widget _helpRow(VisionTokens t, String code, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: t.borderSubtle,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: TextStyle(
              color: t.textPrimary,
              fontSize: t.fontSize(10),
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            description,
            style: TextStyle(color: t.hintText, fontSize: t.fontSize(9), height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _modeHelpRow(VisionTokens t, String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(9), fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: t.hintText, fontSize: t.fontSize(9), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WildcardNotifier notifier, VisionTokens t) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final l = context.l;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(l.wildcardCreateTitle, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
            decoration: InputDecoration(
              hintText: l.wildcardFileName,
              hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
            TextButton(
              onPressed: () {
                final sanitized = nameController.text.trim().replaceAll(' ', '.');
                if (sanitized.isNotEmpty) {
                  notifier.createFile(sanitized);
                  Navigator.pop(context);
                }
              },
              child: Text(l.commonCreate, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9))),
            ),
          ],
        );
      },
    );
  }
}
