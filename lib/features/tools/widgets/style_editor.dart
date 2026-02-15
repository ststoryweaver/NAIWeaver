import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/tag_suggestion_overlay.dart';
import '../../../styles.dart';
import '../../generation/providers/generation_notifier.dart';
import '../providers/style_notifier.dart';

class StyleEditor extends StatelessWidget {
  const StyleEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final genNotifier = context.watch<GenerationNotifier>();

    return ChangeNotifierProvider(
      create: (_) => StyleNotifier(
        tagService: genNotifier.tagService,
        wildcardService: genNotifier.wildcardService,
        initialStyles: genNotifier.state.styles,
        stylesFilePath: genNotifier.stylesFilePath,
        onStylesChanged: () => genNotifier.refreshStyles(),
      ),
      child: const _StyleEditorContent(),
    );
  }
}

class _StyleEditorContent extends StatefulWidget {
  const _StyleEditorContent();

  @override
  State<_StyleEditorContent> createState() => _StyleEditorContentState();
}

class _StyleEditorContentState extends State<_StyleEditorContent> {
  bool _showingEditor = false;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<StyleNotifier>();
    final mobile = isMobile(context);
    final t = context.t;

    if (mobile) {
      return Column(
        children: [
          _buildHeader(context, notifier, t),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: _showingEditor && notifier.state.selectedStyle != null
                ? Column(
                    children: [
                      _buildMobileEditorBar(notifier, t),
                      Expanded(child: _buildEditor(context, notifier, t)),
                    ],
                  )
                : _buildStyleList(context, notifier, t, fullWidth: true),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildHeader(context, notifier, t),
        Divider(height: 1, color: t.textMinimal),
        Expanded(
          child: Row(
            children: [
              _buildStyleList(context, notifier, t),
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

  Widget _buildMobileEditorBar(StyleNotifier notifier, VisionTokens t) {
    final name = notifier.state.selectedStyle?.name.toUpperCase() ?? '';
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
          Text(name, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(11), letterSpacing: 1, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StyleNotifier notifier, VisionTokens t) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: t.surfaceHigh,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.styleEditor,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: t.fontSize(16),
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.styleManageDesc,
                  style: TextStyle(color: t.hintText, fontSize: t.fontSize(9), letterSpacing: 2),
                ),
              ],
            ),
          ),
          if (notifier.state.isModified) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                if (notifier.hasNameConflict()) {
                  _showOverwriteConfirm(context, notifier, t);
                } else {
                  notifier.saveStyle();
                }
              },
              icon: Icon(Icons.save_outlined, size: 14, color: t.textPrimary),
              label: Text(l.commonSaveChanges, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10), letterSpacing: 1)),
              style: TextButton.styleFrom(
                backgroundColor: t.borderSubtle,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleList(BuildContext context, StyleNotifier notifier, VisionTokens t, {bool fullWidth = false}) {
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
                  context.l.styleList,
                  style: TextStyle(color: t.secondaryText, fontSize: t.fontSize(8), letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 14, color: t.secondaryText),
                  onPressed: () {
                    notifier.createNewStyle();
                    if (isMobile(context)) setState(() => _showingEditor = true);
                  },
                  tooltip: context.l.styleNew,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.textMinimal),
          Expanded(
            child: ListView.builder(
              itemCount: state.styles.length,
              itemBuilder: (context, index) {
                final style = state.styles[index];
                final isSelected = state.selectedStyle?.name == style.name;

                return InkWell(
                  onTap: () {
                    notifier.selectStyle(style);
                    if (isMobile(context)) setState(() => _showingEditor = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: isSelected ? t.borderSubtle : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: isSelected ? t.textPrimary : t.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            style.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            icon: Icon(Icons.copy, size: 12, color: t.textDisabled),
                            onPressed: () => notifier.duplicateStyle(style),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 12, color: t.textDisabled),
                            onPressed: () => _showDeleteConfirm(context, notifier, style, t),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildEditor(BuildContext context, StyleNotifier notifier, VisionTokens t) {
    final state = notifier.state;
    if (state.selectedStyle == null) {
      return Center(
        child: Text(
          context.l.styleSelectToEdit,
          style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9), letterSpacing: 2),
        ),
      );
    }

    final bool isPrefix = state.selectedStyle!.prefix.isNotEmpty || state.selectedStyle!.suffix.isEmpty;

    return Column(
      children: [
        if (state.tagSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: TagSuggestionOverlay(
              suggestions: state.tagSuggestions,
              onTagSelected: notifier.applyTagSuggestion,
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context.l.styleIdentity, t),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: notifier.nameController,
                        label: context.l.styleName,
                        onChanged: (val) => notifier.updateCurrentStyle(name: val),
                        t: t,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l.styleDefaultOnLaunch,
                            style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(8), letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: t.borderSubtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Switch(
                            value: state.selectedStyle?.isDefault ?? false,
                            onChanged: (val) => notifier.updateCurrentStyle(isDefault: val),
                            activeThumbColor: t.textPrimary,
                            activeTrackColor: t.textDisabled,
                            inactiveThumbColor: t.textMinimal,
                            inactiveTrackColor: t.background,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context.l.styleTargetPrompt, t),
                _buildTargetSelector(notifier, t),
                const SizedBox(height: 24),
                _buildSectionTitle(state.isEditingNegative ? context.l.styleNegativeContent : context.l.stylePositiveContent, t),
                Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        notifier.clearTagSuggestions();
                      });
                    }
                  },
                  child: _buildTextField(
                    controller: notifier.contentController,
                    label: context.l.styleContent,
                    maxLines: 4,
                    onChanged: (val) {
                      notifier.handleTagSuggestions(val, notifier.contentController.selection);
                      notifier.updateCurrentStyle(content: val);
                    },
                    t: t,
                  ),
                ),
                if (!state.isEditingNegative) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(context.l.stylePlacement, t),
                  _buildPlacementSelector(notifier, isPrefix, t),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, VisionTokens t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(8), letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    required Function(String) onChanged,
    required VisionTokens t,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(8), letterSpacing: 1)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(13), height: 1.5),
          decoration: InputDecoration(
            filled: true,
            fillColor: t.borderSubtle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetSelector(StyleNotifier notifier, VisionTokens t) {
    return Row(
      children: [
        _buildTargetOption(
          label: context.l.stylePositive,
          isActive: !notifier.state.isEditingNegative,
          onTap: () => notifier.setEditingNegative(false),
          t: t,
        ),
        const SizedBox(width: 12),
        _buildTargetOption(
          label: context.l.styleNegative,
          isActive: notifier.state.isEditingNegative,
          onTap: () => notifier.setEditingNegative(true),
          t: t,
        ),
      ],
    );
  }

  Widget _buildTargetOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required VisionTokens t,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? t.borderSubtle : Colors.transparent,
            border: Border.all(
              color: isActive ? t.textDisabled : t.textMinimal,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? t.textPrimary : t.textDisabled,
                fontSize: t.fontSize(9),
                letterSpacing: 1,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementSelector(StyleNotifier notifier, bool isPrefix, VisionTokens t) {
    return Row(
      children: [
        _buildPlacementOption(
          label: context.l.styleBeginningPrefix,
          isActive: isPrefix,
          onTap: () => notifier.updateCurrentStyle(isPrefix: true),
          t: t,
        ),
        const SizedBox(width: 12),
        _buildPlacementOption(
          label: context.l.styleEndSuffix,
          isActive: !isPrefix,
          onTap: () => notifier.updateCurrentStyle(isPrefix: false),
          t: t,
        ),
      ],
    );
  }

  Widget _buildPlacementOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required VisionTokens t,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? t.borderSubtle : Colors.transparent,
            border: Border.all(
              color: isActive ? t.textDisabled : t.textMinimal,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? t.textPrimary : t.textDisabled,
                fontSize: t.fontSize(9),
                letterSpacing: 1,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, StyleNotifier notifier, PromptStyle style, VisionTokens t) {
    showDialog(
      context: context,
      builder: (context) {
        final l = context.l;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(l.styleDeleteTitle, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
          content: Text(l.styleDeleteConfirm(style.name), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(11))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
            TextButton(
              onPressed: () {
                notifier.deleteStyle(style);
                Navigator.pop(context);
              },
              child: Text(l.commonDelete, style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9))),
            ),
          ],
        );
      },
    );
  }

  void _showOverwriteConfirm(BuildContext context, StyleNotifier notifier, VisionTokens t) {
    showDialog(
      context: context,
      builder: (context) {
        final l = context.l;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(l.styleOverwriteTitle, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
          content: Text(l.styleOverwriteConfirm(notifier.nameController.text),
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(11))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
            TextButton(
              onPressed: () {
                notifier.saveStyle();
                Navigator.pop(context);
              },
              child: Text(l.commonOverwrite, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9))),
            ),
          ],
        );
      },
    );
  }
}
